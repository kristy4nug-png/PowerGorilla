#Requires -Version 5.1
<#
.SYNOPSIS
  PowerShell Gorilla Batch Management Module
  
.DESCRIPTION
  Functions to create, monitor, and manage batch jobs for Ollama processing.
  Integrates with Supabase queue tables.
#>

# ============================================================================
# BATCH CREATION & SETUP
# ============================================================================

function Get-GorItemValue {
  param(
    [Parameter(Mandatory=$true)]$Item,
    [Parameter(Mandatory=$true)][string]$Name,
    $Default = $null
  )

  if ($Item -is [hashtable] -and $Item.ContainsKey($Name) -and $null -ne $Item[$Name]) {
    return $Item[$Name]
  }

  $property = $Item.PSObject.Properties[$Name]
  if ($property -and $null -ne $property.Value) {
    return $property.Value
  }

  return $Default
}

function New-GorBatch {
  <#
  .SYNOPSIS
    Create a new batch job for processing queue items
  
  .PARAMETER BatchName
    Human-readable name for the batch
  
  .PARAMETER Items
    Array of queue items (PSCustomObjects or hashtables)
  
  .PARAMETER TargetModel
    Ollama model to use (default: llama2)
  
  .PARAMETER CheckpointInterval
    Save checkpoint every N items (default: 100)
  
  .PARAMETER SupabaseClient
    Connected Supabase client
  #>
  
  param(
    [Parameter(Mandatory=$true)]
    [string]$BatchName,
    
    [Parameter(Mandatory=$true)]
    [array]$Items,
    
    [string]$TargetModel = "llama2",
    [int]$CheckpointInterval = 100,
    [object]$SupabaseClient,
    [string]$Description = ""
  )
  
  $batchId = "batch_$(Get-Date -Format yyyyMMdd_HHmmss)_$([System.Guid]::NewGuid().ToString().Substring(0,8))"
  
  # Validate items against schema
  foreach ($item in $Items) {
    if (-not $item.item_id -or -not $item.item_type) {
      throw "Invalid queue item: missing item_id or item_type"
    }
  }
  
  Write-Verbose "Creating batch: $batchId with $($Items.Count) items"
  
  try {
    # Create batch job record
    $batchRecord = @{
      batch_id = $batchId
      batch_name = $BatchName
      description = $Description
      status = 'pending'
      total_items = $Items.Count
      target_model = $TargetModel
      config_json = @{
        checkpoint_interval = $CheckpointInterval
        target_model = $TargetModel
      } | ConvertTo-Json
    }
    
    if ($SupabaseClient) {
      $SupabaseClient.Insert("batch_jobs", $batchRecord)
    }
    
    # Create queue items
    $seqNum = 1
    foreach ($item in $Items) {
      $queueItem = @{
        item_id = $item.item_id
        batch_id = $batchId
        sequence_number = $seqNum++
        item_type = $item.item_type
        status = 'pending'
        input_data = ($item.input_data | ConvertTo-Json -Depth 10)
        input_schema = Get-GorItemValue -Item $item -Name 'input_schema' -Default ''
        output_schema = Get-GorItemValue -Item $item -Name 'output_schema' -Default ''
        priority = Get-GorItemValue -Item $item -Name 'priority' -Default 50
        max_retries = Get-GorItemValue -Item $item -Name 'max_retries' -Default 3
      }
      
      if ($SupabaseClient) {
        $SupabaseClient.Insert("queue_items", $queueItem)
      }
    }
    
    return @{
      batch_id = $batchId
      items_created = $Items.Count
      message = "Batch created successfully"
    }
  } catch {
    throw "Failed to create batch: $_"
  }
}

# ============================================================================
# BATCH MONITORING
# ============================================================================

function Get-GorBatchProgress {
  <#
  .SYNOPSIS
    Get real-time progress of a batch job
  
  .PARAMETER BatchId
    Batch identifier
  
  .PARAMETER SupabaseClient
    Connected Supabase client
  #>
  
  param(
    [Parameter(Mandatory=$true)]
    [string]$BatchId,
    
    [object]$SupabaseClient
  )
  
  if (-not $SupabaseClient) {
    throw "SupabaseClient required"
  }
  
  try {
    $progress = $SupabaseClient.Rpc("get_batch_progress", @{ p_batch_id = $BatchId })
    
    if ($progress -and $progress.Count -gt 0) {
      $p = $progress[0]
      
      $statusMsg = "Batch $BatchId Progress"
      $statusMsg += "`n  Total: $($p.total_items) items"
      $statusMsg += "`n  Completed: $($p.processed_items)"
      $statusMsg += "`n  Failed: $($p.failed_items)"
      $statusMsg += "`n  Pending: $($p.total_items - $p.processed_items - $p.failed_items)"
      $statusMsg += "`n  Complete: $($p.percent_complete)%"
      
      if ($p.est_time_remaining_ms) {
        $remainingSec = $p.est_time_remaining_ms / 1000
        $statusMsg += "`n  Est. Time Remaining: $('{0:hh\:mm\:ss}' -f [timespan]::FromSeconds($remainingSec))"
      }
      
      Write-Output $statusMsg
      return $p
    }
  } catch {
    Write-Error "Failed to get batch progress: $_"
  }
}

function Watch-GorBatch {
  <#
  .SYNOPSIS
    Real-time monitoring of batch progress
  
  .PARAMETER BatchId
    Batch identifier
  
  .PARAMETER RefreshSeconds
    Update interval (default: 5)
  
  .PARAMETER SupabaseClient
    Connected Supabase client
  #>
  
  param(
    [Parameter(Mandatory=$true)]
    [string]$BatchId,
    
    [int]$RefreshSeconds = 5,
    [object]$SupabaseClient
  )
  
  Write-Host "Monitoring batch $BatchId (Ctrl+C to stop)" -ForegroundColor Cyan
  
  while ($true) {
    Clear-Host
    Write-Host "Batch $BatchId - Live Monitor" -ForegroundColor Yellow
    Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
    Write-Host ""
    
    Get-GorBatchProgress -BatchId $BatchId -SupabaseClient $SupabaseClient
    
    Write-Host ""
    Write-Host "Next refresh in $RefreshSeconds seconds..." -ForegroundColor Gray
    Start-Sleep -Seconds $RefreshSeconds
  }
}

# ============================================================================
# BATCH ERROR HANDLING & RECOVERY
# ============================================================================

function Restart-GorBatch {
  <#
  .SYNOPSIS
    Resume a paused or failed batch from the last checkpoint
  
  .PARAMETER BatchId
    Batch identifier
  
  .PARAMETER SupabaseClient
    Connected Supabase client
  #>
  
  param(
    [Parameter(Mandatory=$true)]
    [string]$BatchId,
    
    [object]$SupabaseClient
  )
  
  if (-not $SupabaseClient) {
    throw "SupabaseClient required for restarting remote batches"
  }
  
  try {
    # Get last checkpoint
    $lastCheckpoint = $SupabaseClient.Query(
      "batch_checkpoints",
      @{ batch_id = $BatchId },
      @{ "checkpoint_id" = 1; "last_completed_id" = 1; "checkpoint_number" = 1 }
    ) | Sort-Object -Property checkpoint_number -Descending | Select-Object -First 1
    
    if (-not $lastCheckpoint) {
      Write-Warning "No checkpoint found. Restarting from beginning."
      $SupabaseClient.Rpc("restart_batch_from_checkpoint", @{
        p_batch_id = $BatchId
        p_last_completed_id = ""
      })
      Write-Output "Batch reset to beginning (all items pending)."
      return
    }
    
    Write-Verbose "Resuming from checkpoint: $($lastCheckpoint.checkpoint_id)"
    Write-Verbose "Last completed item: $($lastCheckpoint.last_completed_id)"
    
    # Update all items after last checkpoint back to pending and unlock them atomically via RPC
    $SupabaseClient.Rpc("restart_batch_from_checkpoint", @{
      p_batch_id = $BatchId
      p_last_completed_id = $lastCheckpoint.last_completed_id
    })
    
    Write-Output "Batch resumed from checkpoint $($lastCheckpoint.checkpoint_number) (items after sequence reset to pending)."
  } catch {
    throw "Failed to restart batch: $_"
  }
}

function Get-GorFailedItems {
  <#
  .SYNOPSIS
    Get failed or retry-needed items from a batch
  
  .PARAMETER BatchId
    Batch identifier
  
  .PARAMETER SupabaseClient
    Connected Supabase client
  #>
  
  param(
    [Parameter(Mandatory=$true)]
    [string]$BatchId,
    
    [object]$SupabaseClient
  )
  
  try {
    $failedItems = $SupabaseClient.Query(
      "queue_items",
      @{ batch_id = $BatchId; status = "failed" },
      @{ "item_id" = 1; "sequence_number" = 1; "validation_errors" = 1 }
    )
    
    $retryItems = $SupabaseClient.Query(
      "queue_items",
      @{ batch_id = $BatchId; status = "retry" },
      @{ "item_id" = 1; "sequence_number" = 1; "retry_count" = 1 }
    )
    
    return @{
      failed = $failedItems
      retry = $retryItems
      total_failed = @($failedItems).Count
      total_retry = @($retryItems).Count
    }
  } catch {
    Write-Error "Failed to get failed items: $_"
  }
}

# ============================================================================
# BATCH UTILITIES
# ============================================================================

function Export-GorBatchReport {
  <#
  .SYNOPSIS
    Export batch results and statistics to JSON/CSV
  
  .PARAMETER BatchId
    Batch identifier
  
  .PARAMETER OutputPath
    Where to save the report
  
  .PARAMETER Format
    'json' or 'csv' (default: json)
  #>
  
  param(
    [Parameter(Mandatory=$true)]
    [string]$BatchId,
    
    [Parameter(Mandatory=$true)]
    [string]$OutputPath,
    
    [ValidateSet('json', 'csv')]
    [string]$Format = 'json',
    
    [object]$SupabaseClient
  )
  
  try {
    # Get batch job info
    $batch = $SupabaseClient.Query(
      "batch_jobs",
      @{ batch_id = $BatchId },
      @{ "*" = 1 }
    ) | Select-Object -First 1
    
    # Get all queue items
    $items = $SupabaseClient.Query(
      "queue_items",
      @{ batch_id = $BatchId },
      @{ "*" = 1 }
    )
    
    $report = @{
      batch = $batch
      summary = @{
        total_items = $batch.total_items
        completed = $batch.processed_items
        failed = $batch.failed_items
        pending = $batch.total_items - $batch.processed_items - $batch.failed_items
        completion_percent = [Math]::Round(($batch.processed_items / $batch.total_items * 100), 2)
        duration_seconds = [Math]::Round(($batch.actual_time_ms / 1000), 2)
      }
      items = $items
    }
    
    if ($Format -eq 'json') {
      $report | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath
    } else {
      $items | Select-Object -Property @("item_id", "sequence_number", "status", "duration_ms", "retry_count") |
        Export-Csv -Path $OutputPath -NoTypeInformation
    }
    
    Write-Output "Report exported to: $OutputPath"
  } catch {
    throw "Failed to export report: $_"
  }
}

function Clear-GorBatch {
  <#
  .SYNOPSIS
    Delete a completed batch and all its items
  
  .PARAMETER BatchId
    Batch identifier
  
  .PARAMETER SupabaseClient
    Connected Supabase client
  #>
  
  param(
    [Parameter(Mandatory=$true)]
    [string]$BatchId,
    
    [object]$SupabaseClient,
    
    [switch]$Force
  )
  
  if (-not $Force) {
    $confirm = Read-Host "Delete batch $BatchId and all items? (yes/no)"
    if ($confirm -ne "yes") { return }
  }
  
  try {
    # Delete cascade will handle items automatically
    $SupabaseClient.Delete("batch_jobs", @{ batch_id = $BatchId })
    Write-Output "Batch $BatchId deleted"
  } catch {
    throw "Failed to delete batch: $_"
  }
}

Export-ModuleMember -Function @(
  'New-GorBatch',
  'Get-GorBatchProgress',
  'Watch-GorBatch',
  'Restart-GorBatch',
  'Get-GorFailedItems',
  'Export-GorBatchReport',
  'Clear-GorBatch'
)
