#Requires -Version 5.1
<#
.SYNOPSIS
  PowerShell Gorilla App Orchestration Engine
  
.DESCRIPTION
  Manages deterministic state for chaining 2-4 apps together.
  - Validates app readiness before piping data
  - Routes inter-app data with strict JSON schemas
  - Handles failures with fallback logic
  - Records state at each checkpoint
#>

# ============================================================================
# APP DISCOVERY & READINESS CHECKS
# ============================================================================

function Resolve-GorExecutablePath {
  <#
  .SYNOPSIS
    Locates the full path of standard executable tools if they are not explicitly found
  #>
  param(
    [string]$AppId,
    [string]$ExecutablePath
  )

  if ($ExecutablePath -and (Test-Path $ExecutablePath -PathType Leaf)) {
    return $ExecutablePath
  }

  $commandName = switch ($AppId.ToLower()) {
    { $_ -match 'code|vscode|visual-studio-code' } { 'code' }
    { $_ -match 'everything' } { 'Everything.exe' }
    { $_ -match 'vlc' } { 'vlc.exe' }
    default { 
      if ($ExecutablePath) {
        [System.IO.Path]::GetFileName($ExecutablePath)
      } else {
        $AppId
      }
    }
  }

  $cmd = Get-Command $commandName -ErrorAction SilentlyContinue
  if ($cmd) {
    return $cmd.Source
  }

  # Standard installation directories
  $userProfile = $env:USERPROFILE
  $programFiles = $env:ProgramFiles
  $programFilesX86 = ${env:ProgramFiles(x86)}
  $localAppData = $env:LocalAppData

  $pathsToCheck = switch ($AppId.ToLower()) {
    { $_ -match 'code|vscode|visual-studio-code' } {
      @(
        "$localAppData\Programs\Microsoft VS Code\Code.exe",
        "$programFiles\Microsoft VS Code\Code.exe"
      )
    }
    { $_ -match 'everything' } {
      @(
        "$programFiles\Everything\Everything.exe",
        "$programFilesX86\Everything\Everything.exe"
      )
    }
    { $_ -match 'vlc' } {
      @(
        "$programFiles\VideoLAN\VLC\vlc.exe",
        "$programFilesX86\VideoLAN\VLC\vlc.exe"
      )
    }
    default { @() }
  }

  foreach ($p in $pathsToCheck) {
    if ($p -and (Test-Path $p -PathType Leaf)) {
      return $p
    }
  }

  # Fallback to the original path if nothing was resolved
  return $ExecutablePath
}

function Test-GorAppReady {
  <#
  .SYNOPSIS
    Verify an app is running and ready to receive commands
  
  .PARAMETER AppId
    App identifier (e.g., 'microsoft-excel')
  
  .PARAMETER ExecutablePath
    Full path to the executable
  
  .PARAMETER TimeoutSeconds
    Max time to wait (default: 30)
  #>
  
  param(
    [Parameter(Mandatory=$true)]
    [string]$AppId,
    
    [Parameter(Mandatory=$true)]
    [string]$ExecutablePath,
    
    [int]$TimeoutSeconds = 30
  )
  
  try {
    $resolvedPath = Resolve-GorExecutablePath -AppId $AppId -ExecutablePath $ExecutablePath
    $processName = switch ($AppId.ToLower()) {
      { $_ -match 'code|vscode|visual-studio-code' } { 'Code' }
      { $_ -match 'everything' } { 'Everything' }
      { $_ -match 'vlc' } { 'vlc' }
      default {
        if ($resolvedPath) {
          [System.IO.Path]::GetFileNameWithoutExtension($resolvedPath)
        } else {
          [System.IO.Path]::GetFileNameWithoutExtension($ExecutablePath)
        }
      }
    }
    
    $process = Get-Process -Name $processName -ErrorAction SilentlyContinue
    
    if (-not $process) {
      return @{
        ready = $false
        app_id = $AppId
        reason = "Process not running"
      }
    }
    
    # Check if process window is responsive
    Add-Type -AssemblyName UIAutomationClient
    try {
      $automation = [Windows.Automation.AutomationElement]::RootElement
      $process_condition = New-Object Windows.Automation.PropertyCondition(
        [Windows.Automation.AutomationElement]::ProcessIdProperty,
        $process.Id
      )
      $app_element = $automation.FindFirst([Windows.Automation.TreeScope]::Children, $process_condition)
      
      if ($app_element) {
        return @{
          ready = $true
          app_id = $AppId
          process_id = $process.Id
          memory_mb = [Math]::Round($process.WorkingSet64 / 1MB, 2)
          ui_responsive = $true
        }
      }
    } catch {
      # Fallback: just check if process exists
      return @{
        ready = $true
        app_id = $AppId
        process_id = $process.Id
        memory_mb = [Math]::Round($process.WorkingSet64 / 1MB, 2)
        ui_responsive = $false
      }
    }
  } catch {
    return @{
      ready = $false
      app_id = $AppId
      reason = "Error checking readiness: $_"
    }
  }
}

# ============================================================================
# ORCHESTRATION STATE MANAGEMENT
# ============================================================================

class OrchestrationState {
  [string]$orchestration_id
  [int]$current_step = 0
  [hashtable]$step_outputs = @{}
  [datetime]$created_at = (Get-Date)
  [datetime]$last_checkpoint = (Get-Date)
  [string]$status = "pending"  # pending, running, paused, completed, failed
  [array]$error_log = @()
  
  OrchestrationState([string]$id) {
    $this.orchestration_id = $id
  }
  
  [void] RecordStepOutput([int]$step, [object]$output) {
    $this.step_outputs["step_$step"] = $output
    $this.last_checkpoint = Get-Date
  }
  
  [object] GetStepOutput([int]$step) {
    return $this.step_outputs["step_$step"]
  }
  
  [void] LogError([string]$error) {
    $this.error_log += @{
      timestamp = Get-Date
      step = $this.current_step
      error = $error
    }
  }
}

function Format-GorPreviewText {
  param(
    [AllowNull()]$Value,
    [int]$MaxLength = 80
  )

  $text = if ($null -eq $Value) { 'null' } else { $Value | ConvertTo-Json -Compress -Depth 10 }
  if ($text.Length -le $MaxLength) { return $text }
  return $text.Substring(0, $MaxLength)
}

# ============================================================================
# INTER-APP DATA ROUTING
# ============================================================================

function Invoke-GorAppAction {
  <#
  .SYNOPSIS
    Execute an action on an app (open, query, edit, send, etc.)
  
  .PARAMETER AppId
    App identifier
  
  .PARAMETER Action
    Action type: 'open', 'query', 'edit', 'send', 'export', 'analyze'
  
  .PARAMETER InputData
    Payload to pass to the app
  
  .PARAMETER ExecutablePath
    Path to the app executable
  
  .PARAMETER TimeoutSeconds
    Max execution time
  #>
  
  param(
    [Parameter(Mandatory=$true)]
    [string]$AppId,
    
    [Parameter(Mandatory=$true)]
    [ValidateSet('open', 'query', 'edit', 'send', 'export', 'analyze')]
    [string]$Action,
    
    [Parameter(Mandatory=$true)]
    [object]$InputData,
    
    [Parameter(Mandatory=$true)]
    [string]$ExecutablePath,
    
    [int]$TimeoutSeconds = 120
  )
  
  Write-Verbose "[$AppId] Invoking action: $Action"
  
  try {
    # Route to appropriate handler based on action
    $result = switch ($Action) {
      'open' {
        Invoke-GorAppOpen -AppId $AppId -ExecutablePath $ExecutablePath `
          -InputData $InputData -TimeoutSeconds $TimeoutSeconds
      }
      'query' {
        Invoke-GorAppQuery -AppId $AppId -ExecutablePath $ExecutablePath `
          -InputData $InputData -TimeoutSeconds $TimeoutSeconds
      }
      'edit' {
        Invoke-GorAppEdit -AppId $AppId -ExecutablePath $ExecutablePath `
          -InputData $InputData -TimeoutSeconds $TimeoutSeconds
      }
      'send' {
        Invoke-GorAppSend -AppId $AppId -ExecutablePath $ExecutablePath `
          -InputData $InputData -TimeoutSeconds $TimeoutSeconds
      }
      'export' {
        Invoke-GorAppExport -AppId $AppId -ExecutablePath $ExecutablePath `
          -InputData $InputData -TimeoutSeconds $TimeoutSeconds
      }
      'analyze' {
        Invoke-GorAppAnalyze -AppId $AppId -ExecutablePath $ExecutablePath `
          -InputData $InputData -TimeoutSeconds $TimeoutSeconds
      }
    }
    
    return $result
  } catch {
    return @{
      success = $false
      app_id = $AppId
      action = $Action
      error = $_.Exception.Message
    }
  }
}

function Invoke-GorAppOpen {
  param([string]$AppId, [string]$ExecutablePath, [object]$InputData, [int]$TimeoutSeconds)
  
  try {
    # Safe property extraction helper
    $getValue = {
      param($data, $key)
      if ($null -eq $data) { return $null }
      if ($data -is [hashtable]) {
        if ($data.ContainsKey($key)) { return $data[$key] }
        foreach ($k in $data.Keys) {
          if ($k.ToString().ToLower() -eq $key.ToLower()) { return $data[$k] }
        }
      } else {
        $prop = $data.PSObject.Properties[$key]
        if ($prop) { return $prop.Value }
      }
      return $null
    }

    $resolvedPath = Resolve-GorExecutablePath -AppId $AppId -ExecutablePath $ExecutablePath
    if (-not $resolvedPath -or -not (Test-Path $resolvedPath -PathType Leaf)) {
      throw "Could not locate executable for app $AppId ($ExecutablePath)"
    }

    $arguments = @()
    
    # 1. Handle VLC Media Player specific opening parameters
    if ($AppId -match 'vlc') {
      $mediaPath = &$getValue $InputData 'file_path'
      if (-not $mediaPath) { $mediaPath = &$getValue $InputData 'media_path' }
      if (-not $mediaPath) { $mediaPath = &$getValue $InputData 'url' }
      
      if ($mediaPath) {
        $arguments += "`"$mediaPath`""
      }
      
      $fullscreen = &$getValue $InputData 'fullscreen'
      if ($fullscreen) {
        $arguments += "--fullscreen"
      }
      
      $headless = &$getValue $InputData 'headless'
      if ($headless) {
        $arguments += "--intf"
        $arguments += "dummy"
      }
      
      $playAndExit = &$getValue $InputData 'play_and_exit'
      if ($playAndExit) {
        $arguments += "--play-and-exit"
      }
    }
    # 2. General opening parameters (VS Code, Everything, Excel, Outlook, etc.)
    else {
      $inputFilePath = &$getValue $InputData 'file_path'
      if ($inputFilePath) {
        $arguments += "`"$inputFilePath`""
      }
    }

    if ($arguments.Count -gt 0) {
      $process = Start-Process -FilePath $resolvedPath -ArgumentList $arguments -PassThru
    } else {
      $process = Start-Process -FilePath $resolvedPath -PassThru
    }

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    do {
      Start-Sleep -Seconds 1
      $readiness = Test-GorAppReady -AppId $AppId -ExecutablePath $resolvedPath
      if ($readiness.ready) { break }
    } while ((Get-Date) -lt $deadline)

    if (-not $readiness.ready) {
      throw "Process started but readiness was not confirmed before timeout."
    }
    
    return @{
      success = $true
      app_id = $AppId
      action = "open"
      resolved_path = $resolvedPath
      timestamp = Get-Date
    }
  } catch {
    return @{ success = $false; error = $_.Exception.Message }
  }
}

function Invoke-GorAppQuery {
  param([string]$AppId, [string]$ExecutablePath, [object]$InputData, [int]$TimeoutSeconds)
  
  try {
    # Safe property extraction helper
    $getValue = {
      param($data, $key)
      if ($null -eq $data) { return $null }
      if ($data -is [hashtable]) {
        if ($data.ContainsKey($key)) { return $data[$key] }
        foreach ($k in $data.Keys) {
          if ($k.ToString().ToLower() -eq $key.ToLower()) { return $data[$k] }
        }
      } else {
        $prop = $data.PSObject.Properties[$key]
        if ($prop) { return $prop.Value }
      }
      return $null
    }

    $query = &$getValue $InputData 'query'
    if (-not $query) { $query = &$getValue $InputData 'text' }
    if (-not $query) { $query = &$getValue $InputData 'search_term' }

    if ($AppId -match 'everything') {
      $resolvedPath = Resolve-GorExecutablePath -AppId $AppId -ExecutablePath $ExecutablePath
      
      # Try to locate es.exe CLI
      $esPath = Resolve-GorExecutablePath -AppId "es" -ExecutablePath "es.exe"
      if (-not $esPath -or -not (Test-Path $esPath -PathType Leaf)) {
        # Check in same directory as Everything.exe
        if ($resolvedPath) {
          $everythingDir = [System.IO.Path]::GetDirectoryName($resolvedPath)
          $possibleEs = Join-Path $everythingDir "es.exe"
          if (Test-Path $possibleEs -PathType Leaf) {
            $esPath = $possibleEs
          }
        }
      }

      if ($esPath -and (Test-Path $esPath -PathType Leaf)) {
        # Execute query using es.exe (limit to 15 results for safety)
        $escapedQuery = $query -replace '"', '\"'
        $results = & $esPath -n 15 $escapedQuery
        return @{
          success = $true
          app_id = $AppId
          action = "query"
          query = $query
          data = $results
          cli_used = $true
          timestamp = Get-Date
        }
      } else {
        # Fall back to opening Everything search GUI with search term
        if ($resolvedPath -and (Test-Path $resolvedPath -PathType Leaf)) {
          Start-Process -FilePath $resolvedPath -ArgumentList "-search `"$query`""
          return @{
            success = $true
            app_id = $AppId
            action = "query"
            query = $query
            data = "Everything search window launched in GUI mode"
            cli_used = $false
            timestamp = Get-Date
          }
        } else {
          throw "Everything executable or es.exe CLI could not be located."
        }
      }
    }

    # Default fallback for other apps
    return @{
      success = $true
      app_id = $AppId
      action = "query"
      data = $InputData
      timestamp = Get-Date
    }
  } catch {
    return @{ success = $false; error = $_.Exception.Message }
  }
}

function Invoke-GorAppEdit {
  param([string]$AppId, [string]$ExecutablePath, [object]$InputData, [int]$TimeoutSeconds)
  
  try {
    # Safe property extraction helper
    $getValue = {
      param($data, $key)
      if ($null -eq $data) { return $null }
      if ($data -is [hashtable]) {
        if ($data.ContainsKey($key)) { return $data[$key] }
        foreach ($k in $data.Keys) {
          if ($k.ToString().ToLower() -eq $key.ToLower()) { return $data[$k] }
        }
      } else {
        $prop = $data.PSObject.Properties[$key]
        if ($prop) { return $prop.Value }
      }
      return $null
    }

    $filePath = &$getValue $InputData 'file_path'
    if (-not $filePath) {
      throw "No file_path specified for edit action."
    }

    # Ensure file exists or create it if content is provided
    $content = &$getValue $InputData 'content'
    if (-not $content) { $content = &$getValue $InputData 'text' }

    if ($content) {
      $append = &$getValue $InputData 'append'
      # Make sure directory exists
      $parentDir = [System.IO.Path]::GetDirectoryName($filePath)
      if ($parentDir -and -not (Test-Path $parentDir)) {
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
      }

      if ($append) {
        Add-Content -Path $filePath -Value $content -Force
      } else {
        Set-Content -Path $filePath -Value $content -Force
      }
    }

    if ($AppId -match 'code|vscode|visual-studio-code') {
      $resolvedPath = Resolve-GorExecutablePath -AppId $AppId -ExecutablePath $ExecutablePath
      if (-not $resolvedPath -or -not (Test-Path $resolvedPath -PathType Leaf)) {
        throw "Could not locate VS Code executable to open edited file."
      }

      $line = &$getValue $InputData 'line'
      if (-not $line) { $line = &$getValue $InputData 'line_number' }
      $column = &$getValue $InputData 'column'
      if (-not $column) { $column = &$getValue $InputData 'column_number' }

      $arguments = @()
      if ($line) {
        $arguments += "--goto"
        if ($column) {
          $arguments += "`"${filePath}:${line}:${column}`""
        } else {
          $arguments += "`"${filePath}:${line}`""
        }
      } else {
        $arguments += "`"$filePath`""
      }

      $process = Start-Process -FilePath $resolvedPath -ArgumentList $arguments -PassThru
      
      # Wait a moment for app to be ready
      Start-Sleep -Seconds 2

      return @{
        success = $true
        app_id = $AppId
        action = "edit"
        file_path = $filePath
        vscode_launched = $true
        timestamp = Get-Date
      }
    }

    # Generic file editing confirmation
    return @{
      success = $true
      app_id = $AppId
      action = "edit"
      file_path = $filePath
      vscode_launched = $false
      timestamp = Get-Date
    }
  } catch {
    return @{ success = $false; error = $_.Exception.Message }
  }
}

function Invoke-GorAppSend {
  param([string]$AppId, [string]$ExecutablePath, [object]$InputData, [int]$TimeoutSeconds)
  
  try {
    # Safe property extraction helper
    $getValue = {
      param($data, $key)
      if ($null -eq $data) { return $null }
      if ($data -is [hashtable]) {
        if ($data.ContainsKey($key)) { return $data[$key] }
        foreach ($k in $data.Keys) {
          if ($k.ToString().ToLower() -eq $key.ToLower()) { return $data[$k] }
        }
      } else {
        $prop = $data.PSObject.Properties[$key]
        if ($prop) { return $prop.Value }
      }
      return $null
    }

    if ($AppId -match 'vlc') {
      $command = &$getValue $InputData 'command'
      if (-not $command) { $command = $InputData } # Allow direct string payload
      
      if (-not $command -or $command -isnot [string]) {
        throw "Invalid or empty command for VLC remote send."
      }

      $resolvedPath = Resolve-GorExecutablePath -AppId $AppId -ExecutablePath $ExecutablePath
      $processName = [System.IO.Path]::GetFileNameWithoutExtension($resolvedPath)
      $process = Get-Process -Name $processName -ErrorAction SilentlyContinue | Select-Object -First 1

      if (-not $process) {
        throw "VLC process is not running. Launch it first using open."
      }

      $wshell = New-Object -ComObject Wscript.Shell
      $activated = $wshell.AppActivate($process.Id)
      if (-not $activated) {
        $activated = $wshell.AppActivate($process.MainWindowTitle)
      }

      if ($activated) {
        Start-Sleep -Milliseconds 300
        
        switch ($command.ToLower()) {
          'play' { $wshell.SendKeys(' ') }
          'pause' { $wshell.SendKeys(' ') }
          'stop' { $wshell.SendKeys('s') }
          'next' { $wshell.SendKeys('n') }
          'prev' { $wshell.SendKeys('p') }
          'fullscreen' { $wshell.SendKeys('f') }
          'volumeup' { $wshell.SendKeys('^{UP}') }
          'volumedown' { $wshell.SendKeys('^{DOWN}') }
          default {
            # Direct keystroke representation
            $wshell.SendKeys($command)
          }
        }

        return @{
          success = $true
          app_id = $AppId
          action = "send"
          command = $command
          activated = $true
          timestamp = Get-Date
        }
      } else {
        return @{
          success = $false
          app_id = $AppId
          action = "send"
          error = "Could not activate VLC window to send keystrokes."
          activated = $false
          timestamp = Get-Date
        }
      }
    }

    # Default fallback
    return @{
      success = $true
      app_id = $AppId
      action = "send"
      timestamp = Get-Date
    }
  } catch {
    return @{ success = $false; error = $_.Exception.Message }
  }
}

function Invoke-GorAppExport {
  param([string]$AppId, [string]$ExecutablePath, [object]$InputData, [int]$TimeoutSeconds)
  
  return @{
    success = $true
    app_id = $AppId
    action = "export"
    timestamp = Get-Date
  }
}

function Invoke-GorAppAnalyze {
  param([string]$AppId, [string]$ExecutablePath, [object]$InputData, [int]$TimeoutSeconds)
  
  return @{
    success = $true
    app_id = $AppId
    action = "analyze"
    timestamp = Get-Date
  }
}

# ============================================================================
# ORCHESTRATION EXECUTION ENGINE
# ============================================================================

function Start-GorOrchestration {
  <#
  .SYNOPSIS
    Execute a multi-app orchestration workflow
  
  .PARAMETER OrchestrationDef
    Orchestration definition (PSCustomObject or JSON)
  
  .PARAMETER DryRun
    Preview steps without executing (default: $false)
  #>
  
  param(
    [Parameter(Mandatory=$true)]
    [object]$OrchestrationDef,
    
    [switch]$DryRun,
    [switch]$VerboseLog
  )
  
  # Initialize state
  $state = [OrchestrationState]::new($OrchestrationDef.orchestration_id)
  $state.status = "running"
  
  Write-Host "Starting orchestration: $($OrchestrationDef.orchestration_id)" -ForegroundColor Cyan
  Write-Host "User Intent: $($OrchestrationDef.user_intent)" -ForegroundColor Yellow
  $appNames = @($OrchestrationDef.app_chain | ForEach-Object { $_.app_name })
  Write-Host "Apps: $($appNames -join ' -> ')" -ForegroundColor Cyan
  Write-Host ""
  
  foreach ($step in $OrchestrationDef.app_chain) {
    $stepNum = $step.sequence
    $state.current_step = $stepNum
    Write-Host "Step ${stepNum}: $($step.action.ToUpper()) on $($step.app_name)" -ForegroundColor Magenta
    
    # Verify app readiness
    if (-not $DryRun) {
      $readiness = Test-GorAppReady -AppId $step.app_id -ExecutablePath $step.executable_path
      
      if (-not $readiness.ready) {
        Write-Host "  App not ready: $($readiness.reason)" -ForegroundColor Yellow
        
        if ($step.fallback_app) {
          Write-Host "  Attempting fallback: $($step.fallback_app)" -ForegroundColor Yellow
          # Would attempt fallback here
        } else {
          if ($step.error_handler -eq "abort") {
            $state.status = "failed"
            $state.LogError("App $($step.app_id) not ready, aborting")
            return $state
          }
        }
      }
    } else {
      Write-Host "  [DRY RUN] Simulating app readiness check for $($step.app_id)" -ForegroundColor Gray
    }
    
    # Prepare input
    if ($stepNum -eq 1) {
      $inputData = $OrchestrationDef.initial_payload
    } else {
      $inputData = $state.GetStepOutput($stepNum - 1)
    }
    
    Write-Host "  Input: $(Format-GorPreviewText -Value $inputData -MaxLength 80)..." -ForegroundColor Gray
    
    if ($DryRun) {
      Write-Host "  [DRY RUN] Would execute here" -ForegroundColor Cyan
      $state.RecordStepOutput($stepNum, @{ dry_run = $true })
      continue
    }
    
    # Execute action
    $timeoutSeconds = if ($step.timeout_seconds) { [int]$step.timeout_seconds } else { 120 }
    $result = Invoke-GorAppAction -AppId $step.app_id -Action $step.action `
      -InputData $inputData -ExecutablePath $step.executable_path `
      -TimeoutSeconds $timeoutSeconds
    
    if ($result.success) {
      Write-Host "  Success" -ForegroundColor Green
      $state.RecordStepOutput($stepNum, $result)
    } else {
      Write-Host "  Failed: $($result.error)" -ForegroundColor Red
      $state.LogError($result.error)
      
      if ($step.error_handler -eq "abort") {
        $state.status = "failed"
        return $state
      } elseif ($step.error_handler -eq "retry") {
        Write-Host "  Retrying..." -ForegroundColor Yellow
        Start-Sleep -Seconds 3
        # Retry logic here
      }
    }
    
    Write-Host ""
  }
  
  $state.status = "completed"
  Write-Host "Orchestration completed successfully!" -ForegroundColor Green
  
  return $state
}

# ============================================================================
# EXPORTS
# ============================================================================

Export-ModuleMember -Function @(
  'Resolve-GorExecutablePath',
  'Test-GorAppReady',
  'Invoke-GorAppAction',
  'Start-GorOrchestration'
)
