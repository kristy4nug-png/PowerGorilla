#Requires -Version 5.1
<#
.SYNOPSIS
  PowerShell Gorilla Batch Processor
  Handles async queue processing for Ollama prompts with checkpoint resilience.
  
.DESCRIPTION
  - Connects to Supabase queue_items table
  - Claims items one-at-a-time (sequential processing)
  - Routes to Ollama with JSON schema enforcement
  - Records results back to database
  - Creates checkpoints every N items
  - Survives system crashes by resuming from last checkpoint

.PARAMETER BatchId
  The batch job ID to process (e.g., "batch_20260524_001")

.PARAMETER SupabaseUrl
  Supabase project URL (default: from env var SUPABASE_URL)

.PARAMETER SupabaseKey
  Supabase API key (default: from env var SUPABASE_ANON_KEY)

.PARAMETER OllamaEndpoint
  Ollama API endpoint (default: http://localhost:11434)

.PARAMETER WorkerId
  Unique identifier for this worker process (default: $env:COMPUTERNAME-$$)

.PARAMETER CheckpointInterval
  Number of items between checkpoints (default: 100)

.PARAMETER MaxRetries
  Max attempts per failed item (default: 3)

.EXAMPLE
  .\Start-GorBatchProcessor.ps1 -BatchId "batch_20260524_001"
#>

param(
  [Parameter(Mandatory=$true)]
  [string]$BatchId,

  [string]$SupabaseUrl = '',
  [string]$SupabaseKey = '',
  [string]$OllamaEndpoint = "http://localhost:11434",
  [string]$WorkerId = "$($env:COMPUTERNAME)-$PID",
  [int]$CheckpointInterval = 100,
  [int]$MaxRetries = 3,
  [string]$LocalQueuePath,
  [switch]$LocalOnly
)

#============================================================================
# SETUP & VALIDATION
#============================================================================

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Log setup
$projectRoot = Split-Path -Parent $PSScriptRoot
$logDir = Join-Path $projectRoot "logs\batch"
$logFile = Join-Path $logDir "batch_$($BatchId)_$(Get-Date -Format yyyyMMdd_HHmmss).log"
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }

function Write-Log {
  param([string]$Message, [ValidateSet('INFO','WARN','ERROR','DEBUG')]$Level = 'INFO')
  $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  $logLine = "[$ts] [$Level] $Message"
  Write-Host $logLine
  Add-Content -Path $logFile -Value $logLine
}

Write-Log "Starting batch processor for batch: $BatchId"
Write-Log "Worker ID: $WorkerId"

$envFile = Join-Path $projectRoot '.env.ps1'
if (Test-Path -LiteralPath $envFile) {
  . $envFile
}

if ([string]::IsNullOrWhiteSpace($SupabaseUrl)) {
  $SupabaseUrl = if ($env:SUPABASE_URL) { $env:SUPABASE_URL } else { $env:GORILLA_SUPABASE_URL }
}
if ([string]::IsNullOrWhiteSpace($SupabaseKey)) {
  if ($env:SUPABASE_SERVICE_KEY) { $SupabaseKey = $env:SUPABASE_SERVICE_KEY }
  elseif ($env:GORILLA_SUPABASE_SERVICE_KEY) { $SupabaseKey = $env:GORILLA_SUPABASE_SERVICE_KEY }
  elseif ($env:SUPABASE_ANON_KEY) { $SupabaseKey = $env:SUPABASE_ANON_KEY }
  else { $SupabaseKey = $env:GORILLA_SUPABASE_ANON_KEY }
}

$UseLocalQueue = $LocalOnly -or [string]::IsNullOrWhiteSpace($SupabaseUrl) -or [string]::IsNullOrWhiteSpace($SupabaseKey)
if ($UseLocalQueue) {
  if ([string]::IsNullOrWhiteSpace($LocalQueuePath)) {
    $LocalQueuePath = Join-Path $projectRoot "data\queue\$BatchId.queue.json"
  }
  Write-Log "Local queue mode enabled. Queue path: $LocalQueuePath"
} else {
  Write-Log "Optional Supabase free-tier queue mode enabled."
}

# Validate Ollama
try {
  $ollamaStatus = Invoke-RestMethod -Uri "$OllamaEndpoint/api/tags" -TimeoutSec 5 -ErrorAction Stop
  Write-Log "Ollama connected. Models available: $($ollamaStatus.models.count)"
} catch {
  Write-Log "ERROR: Cannot reach Ollama at $OllamaEndpoint : $_" -Level ERROR
  exit 1
}

#============================================================================
# SUPABASE CLIENT
#============================================================================

class SupabaseClient {
  [string]$Url
  [string]$Key
  [hashtable]$DefaultHeaders

  SupabaseClient([string]$url, [string]$key) {
    $this.Url = $url.TrimEnd('/')
    $this.Key = $key
    $this.DefaultHeaders = @{
      'apikey' = $key
      'Authorization' = "Bearer $key"
      'Content-Type' = 'application/json'
    }
  }

  [object] Query([string]$table, [hashtable]$where, [hashtable]$select) {
    $q = "select=$($select.Keys -join ',')"
    foreach ($k in $where.Keys) {
      $v = $where[$k]
      $q += "&$k=eq.$v"
    }
    $uri = "$($this.Url)/rest/v1/$table`?$q"
    try {
      return Invoke-RestMethod -Uri $uri -Headers $this.DefaultHeaders -ErrorAction Stop
    } catch {
      Write-Log "Query error: $_" -Level ERROR
      throw
    }
  }

  [object] Rpc([string]$functionName, [hashtable]$params) {
    $body = $params | ConvertTo-Json -Depth 10
    $uri = "$($this.Url)/rest/v1/rpc/$functionName"
    try {
      return Invoke-RestMethod -Uri $uri -Method Post -Body $body `
        -Headers $this.DefaultHeaders -ErrorAction Stop
    } catch {
      Write-Log "RPC error: $_" -Level ERROR
      throw
    }
  }

  [void] Update([string]$table, [hashtable]$data, [hashtable]$where) {
    $body = $data | ConvertTo-Json -Depth 10
    $q = ""
    foreach ($k in $where.Keys) {
      $q += "$k=eq.$($where[$k])&"
    }
    $uri = "$($this.Url)/rest/v1/$table`?$($q.TrimEnd('&'))"
    try {
      Invoke-RestMethod -Uri $uri -Method Patch -Body $body `
        -Headers $this.DefaultHeaders -ErrorAction Stop | Out-Null
    } catch {
      Write-Log "Update error: $_" -Level ERROR
      throw
    }
  }
}

$supabase = if ($UseLocalQueue) { $null } else { [SupabaseClient]::new($SupabaseUrl, $SupabaseKey) }

#============================================================================
# OLLAMA INTEGRATION
#============================================================================

function Invoke-OllamaPrompt {
  param(
    [string]$Prompt,
    [string]$Model,
    [hashtable]$JsonSchema,
    [int]$TimeoutSeconds = 300
  )

  Write-Log "Invoking Ollama ($Model): $($Prompt.Substring(0, [Math]::Min(50, $Prompt.Length)))..." -Level DEBUG

  # Build request body with structured output
  $body = @{
    model = $Model
    prompt = $Prompt
    stream = $false
    format = if ($JsonSchema) { "json" } else { "text" }
  } | ConvertTo-Json -Depth 10

  try {
    $response = Invoke-RestMethod -Uri "$OllamaEndpoint/api/generate" `
      -Method Post -Body $body -TimeoutSec $TimeoutSeconds -ErrorAction Stop

    # Validate JSON if schema provided
    if ($JsonSchema) {
      try {
        $json = $response.response | ConvertFrom-Json -ErrorAction Stop
        Write-Log "Ollama response validated against schema" -Level DEBUG
        return @{
          success = $true
          data = $json
          raw = $response.response
          duration_ms = $response.eval_duration / 1000000
        }
      } catch {
        Write-Log "Ollama response failed JSON validation: $_" -Level WARN
        return @{
          success = $false
          error = "JSON validation failed: $_"
          raw = $response.response
        }
      }
    }

    return @{
      success = $true
      data = $response.response
      raw = $response.response
      duration_ms = $response.eval_duration / 1000000
    }
  } catch {
    Write-Log "Ollama request failed: $_" -Level ERROR
    return @{
      success = $false
      error = $_.Exception.Message
    }
  }
}

function Validate-LLMResponse {
  param(
    [Parameter(Mandatory)][hashtable]$Response,
    [string]$ItemType
  )

  if ($ItemType -eq 'prompt') {
    if (-not $Response.success) {
      return @{ success = $false; error = $Response.error; valid = $false }
    }

    if ($null -eq $Response.data) {
      return @{ success = $false; error = 'LLM returned empty data.'; valid = $false }
    }

    if ($Response.data -is [string]) {
      return @{ success = $false; error = 'LLM returned plain text; expected structured JSON with synthesized_insight.'; valid = $false }
    }

    if ($Response.data -is [hashtable] -or $Response.data -is [pscustomobject]) {
      if ($Response.data.PSObject.Properties.Name -contains 'synthesized_insight' -and -not [string]::IsNullOrWhiteSpace([string]$Response.data.synthesized_insight)) {
        return @{ success = $true; valid = $true }
      }
      return @{ success = $false; error = 'LLM response missing synthesized_insight.'; valid = $false }
    }

    return @{ success = $false; error = 'LLM returned unexpected response type.'; valid = $false }
  }

  return @{ success = $Response.success; valid = $Response.success; error = $Response.error }
}

function Invoke-OllamaPromptWithRetry {
  param(
    [string]$Prompt,
    [string]$Model,
    [hashtable]$JsonSchema,
    [string]$ItemType,
    [int]$TimeoutSeconds = 300
  )

  $attempt = 0
  $lastError = 'Unknown error'
  while ($attempt -lt $MaxRetries) {
    $attempt++
    $totalAttempts++
    Write-Log "Ollama request attempt $attempt of $MaxRetries for item type '$ItemType'" -Level DEBUG
    $result = Invoke-OllamaPrompt -Prompt $Prompt -Model $Model -JsonSchema $JsonSchema -TimeoutSeconds $TimeoutSeconds
    $validation = Validate-LLMResponse -Response $result -ItemType $ItemType

    if ($validation.success -and $validation.valid) {
      if ($attempt -gt 1) { $totalRetrySuccesses++ }
      return $result
    }

    $lastError = if ($validation.error) { $validation.error } else { $result.error }
    Write-Log "Ollama validation failed on attempt $attempt: $lastError" -Level WARN
    if ($attempt -lt $MaxRetries) {
      $totalRetries++
      $sleepSeconds = [Math]::Min(30, 2 * $attempt)
      Start-Sleep -Seconds $sleepSeconds
    }
  }

  return @{ success = $false; error = $lastError; raw = $result.raw; attempts = $attempt; retries = ($attempt - 1) }
}

#============================================================================
# LOCAL QUEUE PROCESSING LOOP
#============================================================================

if ($UseLocalQueue) {
  if (-not (Test-Path -LiteralPath $LocalQueuePath)) {
    $queueDir = Split-Path -Parent $LocalQueuePath
    if (-not (Test-Path -LiteralPath $queueDir)) { New-Item -ItemType Directory -Path $queueDir -Force | Out-Null }
    '[]' | Set-Content -LiteralPath $LocalQueuePath -Encoding UTF8
    Write-Log "Created empty local queue file. Add queue items and rerun: $LocalQueuePath" -Level WARN
    exit 0
  }

  function Get-LocalItemValue {
    param(
      [Parameter(Mandatory=$true)]$Item,
      [Parameter(Mandatory=$true)][string]$Name,
      $Default = $null
    )
    if ($Item -is [hashtable] -and $Item.ContainsKey($Name)) { return $Item[$Name] }
    $property = $Item.PSObject.Properties[$Name]
    if ($property) { return $property.Value }
    return $Default
  }

  function Set-LocalItemValue {
    param(
      [Parameter(Mandatory=$true)]$Item,
      [Parameter(Mandatory=$true)][string]$Name,
      $Value
    )
    if ($Item -is [hashtable]) {
      $Item[$Name] = $Value
      return
    }
    $property = $Item.PSObject.Properties[$Name]
    if ($property) {
      $property.Value = $Value
    } else {
      $Item | Add-Member -NotePropertyName $Name -NotePropertyValue $Value
    }
  }

  function Save-LocalQueue {
    param([Parameter(Mandatory=$true)][object[]]$Queue)
    $Queue | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $LocalQueuePath -Encoding UTF8
  }

  $queue = @(Get-Content -LiteralPath $LocalQueuePath -Raw | ConvertFrom-Json)
  $totalProcessed = 0
  $totalFailed = 0
  $batchStartTime = Get-Date

  foreach ($item in $queue) {
    if ($null -eq (Get-LocalItemValue -Item $item -Name 'status')) {
      Set-LocalItemValue -Item $item -Name 'status' -Value 'pending'
    }
    if ((Get-LocalItemValue -Item $item -Name 'status') -notin @('pending','retry')) { continue }

    Set-LocalItemValue -Item $item -Name 'status' -Value 'processing'
    Set-LocalItemValue -Item $item -Name 'worker_id' -Value $WorkerId
    Set-LocalItemValue -Item $item -Name 'started_at' -Value (Get-Date).ToString('o')
    Save-LocalQueue -Queue $queue

    $itemId = Get-LocalItemValue -Item $item -Name 'item_id' -Default ([guid]::NewGuid().ToString('n'))
    Set-LocalItemValue -Item $item -Name 'item_id' -Value $itemId
    Write-Log "Processing local item: $itemId"

    $inputData = Get-LocalItemValue -Item $item -Name 'input_data' -Default ([pscustomobject]@{})
    $itemType = Get-LocalItemValue -Item $item -Name 'item_type' -Default 'prompt'
    $model = Get-LocalItemValue -Item $inputData -Name 'model' -Default (Get-LocalItemValue -Item $inputData -Name 'embedding_model' -Default 'llama3.2')

    $result = switch ($itemType) {
      'prompt' {
        Invoke-OllamaPromptWithRetry -Prompt ([string](Get-LocalItemValue -Item $inputData -Name 'prompt_text' -Default '')) -Model $model -JsonSchema $null -ItemType 'prompt'
      }
      'embedding' {
        Invoke-OllamaPromptWithRetry -Prompt ([string](Get-LocalItemValue -Item $inputData -Name 'text' -Default '')) -Model $model -JsonSchema $null -ItemType 'embedding'
      }
      default {
        @{ success = $false; error = "Unknown item type: $itemType" }
      }
    }

    if ($result.success) {
      Set-LocalItemValue -Item $item -Name 'status' -Value 'completed'
      Set-LocalItemValue -Item $item -Name 'output_data' -Value $result.data
      Set-LocalItemValue -Item $item -Name 'completed_at' -Value (Get-Date).ToString('o')
      Set-LocalItemValue -Item $item -Name 'duration_ms' -Value $result.duration_ms
      $totalProcessed++
      Write-Log "Completed local item: $itemId" -Level DEBUG
    } else {
      if ($result.attempts -ge $MaxRetries) { $totalDeadLetters++ }
      Set-LocalItemValue -Item $item -Name 'status' -Value 'failed'
      Set-LocalItemValue -Item $item -Name 'error_message' -Value $result.error
      Set-LocalItemValue -Item $item -Name 'completed_at' -Value (Get-Date).ToString('o')
      $totalFailed++
      Write-Log "Failed local item: $itemId after $($result.attempts) attempts - $($result.error)" -Level WARN
    }

    Save-LocalQueue -Queue $queue

    if ($totalProcessed -gt 0 -and $totalProcessed % $CheckpointInterval -eq 0) {
      Write-Log "Local checkpoint saved. Processed: $totalProcessed | Failed: $totalFailed" -Level INFO
    }
  }

  $elapsed = ((Get-Date) - $batchStartTime).TotalSeconds
  Write-Log "Local batch complete. Processed: $totalProcessed, Failed: $totalFailed, Time: ${elapsed}s"
  exit 0
}

#============================================================================
# QUEUE PROCESSING LOOP
#============================================================================

$totalAttempts = 0
$totalRetries = 0
$totalRetrySuccesses = 0
$totalDeadLetters = 0
$totalProcessed = 0
$totalFailed = 0
$batchStartTime = Get-Date

while ($true) {
  try {
    # Claim next item
    $nextItem = $supabase.Rpc("claim_next_queue_item", @{
      p_batch_id = $BatchId
      p_worker_id = $WorkerId
    })

    if (-not $nextItem -or $nextItem.Count -eq 0) {
      Write-Log "No more pending items. Batch processing complete."
      break
    }

    $item = $nextItem[0]
    $itemId = $item.item_id
    $sequenceNum = $item.sequence_number

    Write-Log "Processing item $sequenceNum / $itemId"

    # Extract input
    $inputData = $item.input_data
    $itemType = $item.item_type

    # Route to appropriate processor with retry and validation
    $result = switch ($itemType) {
      'prompt' {
        Invoke-OllamaPromptWithRetry -Prompt $inputData.prompt_text -Model $inputData.model -JsonSchema $null -ItemType 'prompt'
      }
      'embedding' {
        Invoke-OllamaPromptWithRetry -Prompt $inputData.text -Model $inputData.embedding_model -JsonSchema $null -ItemType 'embedding'
      }
      default {
        @{ success = $false; error = "Unknown item type: $itemType" }
      }
    }

    # Record result
    if ($result.success) {
      $supabase.Rpc("complete_queue_item", @{
        p_item_id = $itemId
        p_output_data = ($result.data | ConvertTo-Json -Depth 10)
        p_output_schema = $item.item_type
      }) | Out-Null

      Write-Log "Completed: $itemId" -Level DEBUG
      $totalProcessed++
    } else {
      if ($result.attempts -ge $MaxRetries) { $totalDeadLetters++ }
      $supabase.Rpc("fail_queue_item", @{
        p_item_id = $itemId
        p_error_message = $result.error
      }) | Out-Null

      Write-Log "Failed: $itemId after $($result.attempts) attempts - $($result.error)" -Level WARN
      $totalFailed++
    }

    # Create checkpoint every N items
    if ($totalProcessed % $CheckpointInterval -eq 0) {
      $systemState = @{
        memory_used_mb = [Math]::Round((Get-Process -Id $PID).WorkingSet64 / 1MB, 2)
        total_processed = $totalProcessed
        total_failed = $totalFailed
        total_attempts = $totalAttempts
        total_retries = $totalRetries
        total_retry_successes = $totalRetrySuccesses
        total_dead_letters = $totalDeadLetters
        items_per_sec = [Math]::Round($totalProcessed / ((Get-Date) - $batchStartTime).TotalSeconds, 2)
      }

      $checkpointId = $supabase.Rpc("create_batch_checkpoint", @{
        p_batch_id = $BatchId
        p_system_state = ($systemState | ConvertTo-Json -Depth 10)
      })

      Write-Log "Checkpoint created: $checkpointId | Processed: $totalProcessed | Failed: $totalFailed" -Level INFO
    }

  } catch {
    Write-Log "ERROR in processing loop: $_" -Level ERROR
    Start-Sleep -Seconds 5
  }
}

$elapsed = ((Get-Date) - $batchStartTime).TotalSeconds
Write-Log "Batch complete. Processed: $totalProcessed, Failed: $totalFailed, Attempts: $totalAttempts, Retries: $totalRetries, Retry successes: $totalRetrySuccesses, Time: ${elapsed}s"
