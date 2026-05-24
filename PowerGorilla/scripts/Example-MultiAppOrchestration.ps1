#Requires -Version 5.1
<#
.SYNOPSIS
  PowerShell Gorilla - Complete Example: Extract & Email Workflow
  
.DESCRIPTION
  End-to-end example demonstrating:
  1. Multi-app orchestration (Excel to Outlook)
  2. Batch queue processing
  3. Error handling and checkpoints
  4. State management across app boundaries

.NOTES
  Prerequisites:
  - Supabase project configured
  - Ollama running with llama2 model
  - Excel and Outlook installed
  - SUPABASE_URL and SUPABASE_ANON_KEY env vars set
#>

param(
  [ValidateSet('demo', 'real', 'batch-test')]
  [string]$Mode = 'demo'
)

# ============================================================================
# SETUP
# ============================================================================

$ErrorActionPreference = "Stop"

# Import modules
Import-Module "$PSScriptRoot\..\modules\Batch-Management.psm1" -Force
Import-Module "$PSScriptRoot\..\modules\App-Orchestration.psm1" -Force

# Initialize Supabase client (simplified example)
class SimpleSupabaseClient {
  [string]$Url
  [string]$Key
  [hashtable]$data = @{}  # In-memory store for demo
  
  SimpleSupabaseClient([string]$url, [string]$key) {
    $this.Url = $url
    $this.Key = $key
  }
  
  [void] Insert([string]$table, [hashtable]$record) {
    if (-not $this.data.ContainsKey($table)) {
      $this.data[$table] = @()
    }
    $this.data[$table] += $record
    Write-Verbose "Inserted into $table : $($record.Keys -join ',')"
  }
  
  [object[]] Query([string]$table, [hashtable]$where, [hashtable]$select) {
    return $this.data[$table] | Where-Object {
      $matches = $true
      foreach ($k in $where.Keys) {
        if ($_[$k] -ne $where[$k]) { $matches = $false }
      }
      return $matches
    }
  }
}

$supabaseUrl = if ($env:SUPABASE_URL) { $env:SUPABASE_URL } else { "https://example.supabase.co" }
$supabaseKey = if ($env:SUPABASE_ANON_KEY) { $env:SUPABASE_ANON_KEY } else { "dummy-key-for-demo" }
$supabase = [SimpleSupabaseClient]::new($supabaseUrl, $supabaseKey)

# ============================================================================
# EXAMPLE 1: DEMO MODE - Show the flow without executing apps
# ============================================================================

if ($Mode -eq 'demo') {
  Write-Host "=== PowerShell Gorilla - Multi-App Orchestration Demo ===" -ForegroundColor Cyan
  Write-Host ""
  
  # Define the orchestration workflow
  $orchestration = @{
    orchestration_id = "orch_extract_email_$(Get-Date -Format yyyyMMdd_HHmmss)"
    user_intent = "Extract Q2 sales data from Excel and email to the team"
    
    app_chain = @(
      @{
        sequence = 1
        app_id = "microsoft-excel"
        app_name = "Microsoft Excel"
        executable_path = "C:\Program Files\Microsoft Office\root\Office16\EXCEL.EXE"
        action = "query"
        input_schema = "gorilla/excel-input/v1"
        output_schema = "gorilla/excel-output/v1"
        automation_type = "pywinauto"
        requires_ui = $true
        error_handler = "fallback"
        fallback_app = "libre-office-calc"
        timeout_seconds = 120
        retry_count = 1
      },
      @{
        sequence = 2
        app_id = "outlook"
        app_name = "Microsoft Outlook"
        executable_path = "C:\Program Files\Microsoft Office\root\Office16\OUTLOOK.EXE"
        action = "send"
        input_schema = "gorilla/outlook-input/v1"
        output_schema = "gorilla/outlook-output/v1"
        automation_type = "pywinauto"
        requires_ui = $false
        error_handler = "retry"
        timeout_seconds = 60
        retry_count = 2
      }
    )
    
    initial_payload = @{
      file_path = "${env:USERPROFILE}\Documents\Sales_Data.xlsx"
      sheet_name = "Q2_Results"
      range = "A1:F50"
      extract_format = "json"
    }
    
    execution_config = @{
      parallel_allowed = $false
      human_in_loop = $false
      verbose_logging = $true
      ollama_model = "llama2"
    }
  }
  
  Write-Host "Starting Orchestration: $($orchestration.orchestration_id)" -ForegroundColor Yellow
  Write-Host "Intent: $($orchestration.user_intent)" -ForegroundColor Cyan
  Write-Host ""
  
  Write-Host "App Chain:" -ForegroundColor Magenta
  foreach ($step in $orchestration.app_chain) {
    Write-Host "  Step $($step.sequence): [$($step.action.ToUpper())] $($step.app_name)" -ForegroundColor Gray
  }
  
  Write-Host ""
  Write-Host "[DRY RUN MODE] Executing workflow without launching apps..." -ForegroundColor Yellow
  Write-Host ""
  
  # Execute in dry-run mode
  $result = Start-GorOrchestration -OrchestrationDef $orchestration -DryRun
  
  Write-Host "Orchestration State:" -ForegroundColor Cyan
  Write-Host "  Status: $($result.status)" -ForegroundColor Green
  Write-Host "  Current Step: $($result.current_step)"
  Write-Host "  Steps Recorded: $($result.step_outputs.Count)"
  Write-Host "  Errors: $($result.error_log.Count)"
}

# ============================================================================
# EXAMPLE 2: BATCH PROCESSING MODE - Queue 100 items for embedding
# ============================================================================

elseif ($Mode -eq 'batch-test') {
  Write-Host "=== PowerShell Gorilla - Batch Processing Demo ===" -ForegroundColor Cyan
  Write-Host ""
  
  # Create 100 sample queue items
  $queueItems = @()
  for ($i = 1; $i -le 100; $i++) {
    $queueItems += @{
      item_id = "item_embed_$($i.ToString('00000'))"
      sequence_number = $i
      item_type = "embedding"
      priority = 50
      input_schema = "gorilla/embedding-input/v1"
      output_schema = "gorilla/embedding-output/v1"
      input_data = @{
        text = "Sample prompt or text to embed #$i"
        embedding_model = "mxbai-embed-large"
        vector_size = 1024
      }
      max_retries = 2
    }
  }
  
  Write-Host "Creating batch job with $($queueItems.Count) items..." -ForegroundColor Yellow
  
  $batchResult = New-GorBatch `
    -BatchName "Embed 100 sample prompts" `
    -Description "Test batch for vector DB population" `
    -Items $queueItems `
    -TargetModel "mxbai-embed-large" `
    -CheckpointInterval 10 `
    -SupabaseClient $supabase
  
  Write-Host ""
  Write-Host "Batch Created:" -ForegroundColor Green
  Write-Host "  Batch ID: $($batchResult.batch_id)"
  Write-Host "  Items: $($batchResult.items_created)"
  Write-Host ""
  
  Write-Host "Next steps:" -ForegroundColor Cyan
  Write-Host "  1. Run the batch processor:"
  Write-Host "     .\Start-GorBatchProcessor.ps1 -BatchId '$($batchResult.batch_id)'"
  Write-Host ""
  Write-Host "  2. Monitor progress in another terminal:"
  Write-Host "     Get-GorBatchProgress -BatchId '$($batchResult.batch_id)'"
  Write-Host ""
  Write-Host "  3. Export results when complete:"
  Write-Host "     Export-GorBatchReport -BatchId '$($batchResult.batch_id)' -OutputPath './batch_report.json'"
}

# ============================================================================
# EXAMPLE 3: FULL WORKFLOW - Real execution with error handling
# ============================================================================

else {
  Write-Host "=== PowerShell Gorilla - Production Workflow ===" -ForegroundColor Cyan
  Write-Host ""
  Write-Host "This mode requires actual apps installed and running." -ForegroundColor Yellow
  Write-Host "See example 'batch-test' to try with sample data." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Demo complete!" -ForegroundColor Green
