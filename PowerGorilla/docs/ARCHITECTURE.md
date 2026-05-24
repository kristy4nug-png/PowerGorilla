# PowerShell Gorilla - Agentic OS Layer Architecture

## Overview

PowerShell Gorilla is a **deterministic, locally-orchestrated system** that:
- Scans Windows environments for installed executables
- Autonomously chains up to 4 applications together
- Coordinates complex workflows using local Ollama (LLM) as the reasoning engine
- Manages 400,000+ prompts through a resilient checkpoint queue system
- Maintains strict JSON schema validation at every step

---

## System Components

### 1. **Checkpoint Queue System** (Supabase)

#### Core Tables

**`batch_jobs`** - Top-level batch definitions
```
batch_id (PK)        | Unique identifier
batch_name           | Human-readable name
status               | pending | running | paused | completed | failed
total_items          | How many queue items in this batch
processed_items      | Completed successfully
failed_items         | Failed permanently
checkpoint_index     | Last checkpoint number created
last_checkpoint      | Timestamp of last state save
```

**`queue_items`** - Transaction ledger (each item is independently processable)
```
item_id (PK)         | Unique per item
batch_id (FK)        | Parent batch
sequence_number      | Order within batch
status               | pending | processing | completed | failed | retry | skipped
input_data (JSONB)   | Payload to process
output_data (JSONB)  | Result from Ollama/processing
locked_by            | Worker ID holding the lock
locked_at            | When lock was acquired
retry_count          | Current attempt number
max_retries          | Max allowed attempts
validation_errors    | Array of schema validation issues
```

**`batch_checkpoints`** - Resumability snapshots
```
checkpoint_id        | Unique identifier
batch_id (FK)        | Which batch
checkpoint_number    | Sequential counter
last_completed_id    | Item ID of last successful item
items_processed      | Count at this checkpoint
system_state (JSONB) | Memory usage, queue depth, Ollama status
```

**`ollama_metrics`** - Health tracking
```
model_name           | llama2, phi3, etc.
model_loaded         | Is it in memory?
memory_used_mb       | Current consumption
avg_response_ms      | Mean latency
error_rate           | % of failed requests
health_status        | healthy | degraded | offline
```

#### Key SQL Functions

- **`claim_next_queue_item(batch_id, worker_id)`**  
  Atomically claims the next pending item (prevents duplicate processing)

- **`complete_queue_item(item_id, output_data, schema)`**  
  Marks item done and records result

- **`fail_queue_item(item_id, error_message)`**  
  Increments retry counter or marks as failed

- **`get_batch_progress(batch_id)`**  
  Real-time stats: % complete, ETA, throughput

- **`create_batch_checkpoint(batch_id, system_state)`**  
  Saves resumable state snapshot

---

### 2. **Batch Processor Script** (PowerShell)

**Location:** `PowerGorilla/scripts/Start-GorBatchProcessor.ps1`

#### Flow

1. **Startup Validation**
   - Verify Supabase connectivity
   - Check Ollama is running and model is available
   - Log initialization

2. **Processing Loop**
   ```
   WHILE items pending:
     1. Claim next item (atomic)
     2. Route to appropriate processor (prompt, embedding, extraction, etc.)
     3. Send to Ollama with strict JSON schema
     4. Validate response matches output schema
     5. Record result to database
     6. Every N items: Create checkpoint
   ```

3. **Checkpoint Creation**
   - Saves system state (memory, throughput, errors)
   - If system crashes → resume from last checkpoint
   - No re-processing of completed items

#### Environment Variables
```powershell
$env:SUPABASE_URL           # Your Supabase project URL
$env:SUPABASE_ANON_KEY      # Anon key for auth
$env:OLLAMA_KEEP_ALIVE="-1" # Lock model in memory (critical!)
$env:OLLAMA_NUM_PARALLEL=1  # Sequential processing only
```

---

### 3. **Multi-App Orchestration Engine** (PowerShell)

**Location:** `PowerGorilla/modules/App-Orchestration.psm1`

#### How It Works

An **orchestration** is a deterministic sequence of 2-4 apps linked together:

```
User Intent (Ollama interprets)
    ↓
App #1 (e.g., Excel) ──[output schema validation]─→ 
    ↓
App #2 (e.g., Outlook) ──[output schema validation]─→
    ↓
App #3 (optional)
    ↓
Final Result
```

#### State Management

```powershell
$state = [OrchestrationState]::new($orchestration_id)

# After each step:
$state.RecordStepOutput(1, $excelData)  # Step 1 output → Step 2 input
$state.RecordStepOutput(2, $sendResult)

# If app crashes:
$state.GetStepOutput(1)  # Retrieve previous step's data
$state.LogError($error)  # Record for analysis
```

#### App Readiness Checks

Before piping data into an app:
1. **Process exists?** → `Test-GorAppReady`
2. **UI responsive?** → UI Automation check
3. **Ready timeout?** → 30 second max wait

If ready fails:
- Primary: Execute fallback app (e.g., LibreOffice instead of Excel)
- Secondary: Retry with exponential backoff
- Tertiary: Abort or skip (depending on error_handler setting)

---

## JSON Schemas

All data flowing through the system must validate against strict schemas.

### `queue-item.schema.json`
```json
{
  "item_id": "item_20260524_001",
  "batch_id": "batch_20260524_001",
  "item_type": "prompt|embedding|extraction|workflow|app-analysis",
  "input_data": { /* shape depends on item_type */ },
  "output_schema": "gorilla/llm-response/v1",
  "max_retries": 3
}
```

### `app-orchestration.schema.json`
```json
{
  "orchestration_id": "orch_extract_email_20260524",
  "user_intent": "Extract sales data and email it",
  "app_chain": [
    {
      "sequence": 1,
      "app_id": "microsoft-excel",
      "action": "query",
      "input_schema": "gorilla/excel-input/v1",
      "output_schema": "gorilla/excel-output/v1",
      "error_handler": "fallback|retry|abort"
    },
    /* ... app 2, 3, 4 ... */
  ]
}
```

### `batch-job.schema.json`
```json
{
  "batch_id": "batch_20260524_embed_400k",
  "batch_name": "Embed 400K prompts",
  "total_items": 400000,
  "target_model": "mxbai-embed-large",
  "items": [ /* array of queue-items */ ],
  "processing_config": {
    "sequence_only": true,
    "checkpoint_interval": 1000,
    "keep_ollama_alive": true
  }
}
```

---

## Error Handling & Fallback Logic

### Failure Scenarios

| Scenario | Handler | Fallback | Result |
|----------|---------|----------|--------|
| App not running | `ready_check` | Launch it | Retry action |
| App crashes during action | `retry` | Re-open app | Retry up to N times |
| Ollama response invalid JSON | `schema_validation` | Mark failed | Move to next item |
| Out of memory | `skip` | Log and skip | Continue batch |
| Network error (Supabase) | `exponential_backoff` | Retry after delay | Resilient |

### Deterministic Fallback Chain

```powershell
if (AppNotReady) {
  if (FallbackAppExists) {
    SwitchToFallbackApp()
  } else {
    switch ($error_handler) {
      "retry"  { RetryWithBackoff() }
      "skip"   { SkipItem() }
      "abort"  { FailOrchestration() }
    }
  }
}
```

---

## Processing a 400K Prompt Batch

### The Math

- **Model latency:** 3 seconds per prompt (sequential)
- **400,000 prompts × 3 sec = 1,200,000 seconds**
- **= 333 hours = ~14 days continuous**

### Handling the Bottleneck

#### **Option 1: Local Processing (Required Default)**
```powershell
# Hardware: 8GB RAM machine
# Set environment:
$env:OLLAMA_KEEP_ALIVE = "-1"      # Lock model in memory
$env:OLLAMA_NUM_PARALLEL = "1"     # No concurrent requests

# Run processor with checkpoints every 1000 items:
.\Start-GorBatchProcessor.ps1 -BatchId "batch_20260524_400k" `
  -CheckpointInterval 1000

# If system crashes after 50,000 items:
# Restart script and resume from checkpoint 50,000
```

#### **Option 2: Optional Free-Tier Sync Only**
```powershell
# Paid APIs and subscription batch services are blocked by product policy.
# Supabase/Vercel/Expo are optional only when they remain on a free tier.
# Core processing stays on the local machine through Ollama and PowerShell.
```

#### **Option 3: Chunked Local Batches**
```powershell
# Small local batches (100-1000 items) validate the pipeline.
# Larger runs continue locally with checkpoints and resume support.
# This is slower than paid cloud processing but keeps the system free/local.
```

---

## Running the System

### 1. Initialize Database

```bash
# In Supabase SQL Editor, run:
# migrations/001_init.sql (already in your repo)
# migrations/002_checkpoint_queue.sql (newly created)
```

### 2. Start Ollama

```powershell
# Download and run Ollama
ollama run llama2

# In another terminal, verify it's running:
curl http://localhost:11434/api/tags
```

### 3. Create a Batch

```powershell
Import-Module PowerGorilla/modules/Batch-Management.psm1

$items = @(
  @{
    item_id = "item_1"
    item_type = "prompt"
    input_data = @{ prompt_text = "Analyze this app..." }
  }
  # ... more items
)

$batch = New-GorBatch `
  -BatchName "My first batch" `
  -Items $items `
  -TargetModel "llama2"
```

### 4. Run Processor

```powershell
.\PowerGorilla/scripts/Start-GorBatchProcessor.ps1 `
  -BatchId $batch.batch_id `
  -CheckpointInterval 100
```

### 5. Monitor Progress

```powershell
Watch-GorBatch -BatchId $batch.batch_id -RefreshSeconds 5
```

### 6. Export Results

```powershell
Export-GorBatchReport `
  -BatchId $batch.batch_id `
  -OutputPath "./batch_results.json" `
  -Format json
```

---

## Monitoring & Observability

### Real-Time Metrics

```powershell
Get-GorBatchProgress -BatchId "batch_20260524_001"
# Returns:
# {
#   total_items: 400000,
#   processed_items: 125000,
#   percent_complete: 31.25,
#   est_time_remaining_ms: 864000000  # 10 days
# }
```

### Health Checks

```powershell
# Check Ollama health
curl http://localhost:11434/api/generate -Method POST `
  -Body '{"model":"llama2","prompt":"test"}'

# Check batch stale locks (items locked >5 min)
# Supabase function: release_stale_locks()
```

### Logs

- **Batch processor:** `logs/batch/batch_[id]_[timestamp].log`
- **Supabase audit log:** `audit_log` table (append-only)
- **Orchestration errors:** `audit_log` filtered by type='orchestration-error'

---

## Design Principles

### 1. **Deterministic State Management**
- Every step's input/output captured
- Crashes don't cause re-processing (checkpoints)
- State transitions are logged

### 2. **Silent Orchestration**
- No prompts unless human-in-loop is enabled
- Errors logged but don't interrupt batch
- Fallbacks execute automatically

### 3. **High-Throughput Retrieval**
- Single sequential processing (prevents memory explosion)
- Checkpoint every 100-1000 items
- Model stays locked in memory (no unload/reload latency)

### 4. **Schema Enforcement**
- Ollama output validated before passing to next app
- Invalid JSON → marked as failed, not accepted
- No "guessing" about data structure

---

## Next Steps

1. **Deploy the Supabase migration** (`002_checkpoint_queue.sql`)
2. **Test with 100-item batch** using `Example-MultiAppOrchestration.ps1`
3. **Profile Ollama performance** on your hardware
4. **Choose local batch sizing:** small validation batch first, then larger checkpointed local runs
5. **Implement Python/Pywinauto wrappers** for app-specific integrations

---

## References

- **Supabase Docs:** https://supabase.com/docs
- **Ollama Docs:** https://github.com/jmorganca/ollama
- **JSON Schema:** https://json-schema.org/
- **PowerShell Async/State:** https://docs.microsoft.com/en-us/powershell/scripting/learn/

