# PowerShell Gorilla Quick Start Guide

**Time to First Working Example: 15 minutes**

---

## Step 1: Verify Prerequisites (5 minutes)

### Check PowerShell Version
```powershell
$PSVersionTable.PSVersion  # Should be 5.1 or higher
```

### Check Ollama Installation
```powershell
# Ollama should be running
curl http://localhost:11434/api/tags

# Pull a small model if needed
ollama pull llama2:7b

# Or for embedding tests:
ollama pull mxbai-embed-large
```

### Verify Supabase Access
```powershell
# Set environment variables
$env:SUPABASE_URL = "https://yourproject.supabase.co"
$env:SUPABASE_ANON_KEY = "your-anon-key-here"

# Test connectivity
Invoke-RestMethod -Uri "$env:SUPABASE_URL/rest/v1/" `
  -Headers @{ "apikey" = $env:SUPABASE_ANON_KEY }
```

---

## Step 2: Deploy Database Schema (3 minutes)

### In Supabase Dashboard

1. Go to **SQL Editor** → **New Query**
2. Copy contents of `supabase/migrations/002_checkpoint_queue.sql`
3. Click **Run**

**Expected Output:** No errors, tables created successfully

### Verify Tables
```sql
-- In Supabase SQL Editor:
SELECT tablename FROM pg_tables WHERE schemaname = 'public';
-- Should include: batch_jobs, queue_items, batch_checkpoints, ollama_metrics
```

---

## Step 3: Run the Demo (5 minutes)

### Option A: Dry-Run (No Apps Required)

```powershell
cd PowerGorilla/scripts

# Run demo mode (shows workflow without launching Excel/Outlook)
.\Example-MultiAppOrchestration.ps1 -Mode demo

# Expected output:
# ✓ Shows multi-app chain
# ✓ Simulates data flow between steps
# ✓ Displays state management
```

### Option B: Batch Test (Realistic Data)

```powershell
cd PowerGorilla/scripts

# Create and queue 100 sample items
.\Example-MultiAppOrchestration.ps1 -Mode batch-test

# Output will show:
# Batch ID: batch_20260524_143022_a1b2c3d4
# Items: 100
# Next steps: How to run processor and monitor
```

---

## Step 4: Process a Batch (5+ minutes)

### Start the Processor

```powershell
# In Terminal 1:
cd PowerGorilla/scripts

.\Start-GorBatchProcessor.ps1 `
  -BatchId "batch_20260524_143022_a1b2c3d4" `
  -CheckpointInterval 10 `
  -Verbose

# Logs appear in: logs/batch/batch_[id]_[timestamp].log
```

### Monitor in Real-Time

```powershell
# In Terminal 2 (while processor runs):
cd PowerGorilla/scripts

Import-Module ..\modules\Batch-Management.psm1

# Watch progress
Watch-GorBatch -BatchId "batch_20260524_143022_a1b2c3d4" -RefreshSeconds 2
```

### Get One-Time Status

```powershell
Get-GorBatchProgress -BatchId "batch_20260524_143022_a1b2c3d4"
```

---

## Step 5: Export Results (1 minute)

### After Batch Completes

```powershell
Export-GorBatchReport `
  -BatchId "batch_20260524_143022_a1b2c3d4" `
  -OutputPath "./batch_results.json" `
  -Format json

# View results
Get-Content ./batch_results.json | ConvertFrom-Json | Format-Table
```

---

## Troubleshooting

### Issue: "Cannot reach Ollama"
```powershell
# Solution: Start Ollama
ollama serve

# Verify:
curl http://localhost:11434/api/tags
```

### Issue: "Supabase connection refused"
```powershell
# Solution: Check environment variables
Write-Output $env:SUPABASE_URL
Write-Output $env:SUPABASE_ANON_KEY

# If empty, set them:
$env:SUPABASE_URL = "https://xxxxx.supabase.co"
$env:SUPABASE_ANON_KEY = "eyJhbGc..."
```

### Issue: "Items stuck in 'processing' state"
```powershell
# Solution: Release stale locks (if item > 5 min old)
# In Supabase SQL Editor:
SELECT * FROM release_stale_locks(5);

# Or restart the processor (checkpoints resume safely)
```

### Issue: "Out of memory while processing"
```powershell
# Solution: Reduce parallel processing
$env:OLLAMA_NUM_PARALLEL = "1"
$env:OLLAMA_KEEP_ALIVE = "-1"

# And use smaller model:
ollama pull phi3  # Much smaller than llama2
```

---

## Understanding the Output

### Batch Processor Log Example

```
[2026-05-24 14:30:22] [INFO] Starting batch processor for batch: batch_20260524_143022_a1b2c3d4
[2026-05-24 14:30:22] [INFO] Worker ID: DESKTOP-ABC-1234
[2026-05-24 14:30:23] [INFO] Ollama connected. Models available: 2
[2026-05-24 14:30:24] [DEBUG] Processing item 1 / item_embed_00001
[2026-05-24 14:30:27] [DEBUG] ✓ Completed: item_embed_00001
[2026-05-24 14:30:30] [DEBUG] Processing item 2 / item_embed_00002
...
[2026-05-24 14:31:45] [INFO] Checkpoint created: batch_20260524_143022_a1b2c3d4_ckpt_1 | Processed: 10 | Failed: 0
[2026-05-24 14:32:10] [INFO] Batch complete. Processed: 100, Failed: 0, Time: 108s
```

### Progress Monitor Example

```
Batch batch_20260524_143022_a1b2c3d4 - Live Monitor
2026-05-24 14:32:15

  Total: 100 items
  Completed: 100
  Failed: 0
  Pending: 0
  Complete: 100%
  Est. Time Remaining: 00:00:00

Next refresh in 2 seconds...
```

### Batch Report Structure

```json
{
  "batch": {
    "batch_id": "batch_20260524_143022_a1b2c3d4",
    "batch_name": "Embed 100 sample prompts",
    "status": "completed",
    "total_items": 100,
    "processed_items": 100,
    "failed_items": 0
  },
  "summary": {
    "total_items": 100,
    "completed": 100,
    "failed": 0,
    "pending": 0,
    "completion_percent": 100,
    "duration_seconds": 108
  },
  "items": [
    {
      "item_id": "item_embed_00001",
      "sequence_number": 1,
      "status": "completed",
      "duration_ms": 3200
    }
    // ... more items
  ]
}
```

---

## Next: Multi-App Orchestration

Once batch processing works, test app orchestration:

```powershell
cd PowerGorilla/scripts

# See how apps chain together
.\Example-MultiAppOrchestration.ps1 -Mode demo

# This demonstrates:
# 1. App readiness checks
# 2. Data passing between apps
# 3. Error handling & fallbacks
# 4. State management across steps
```

---

## For 400K+ Prompts

### Decide Your Strategy

#### Local Processing
```powershell
# Pros: Free, self-contained
# Cons: 14 days on 8GB hardware

# Use this for:
# - Development/testing
# - When you have time
# - Single-machine deployments

$env:OLLAMA_KEEP_ALIVE = "-1"
$env:OLLAMA_NUM_PARALLEL = "1"
# Run processor, come back in 2 weeks
```

#### Chunked Local Batching
```powershell
# Pros: Free, local, resumable
# Cons: Slower than paid cloud processing

# Use this for:
# - Large local jobs
# - Overnight processing
# - Keeping the laptop responsive between chunks
```

#### Local + Optional Free-Tier Sync
```powershell
# 1. Test locally with 100 items
# 2. Continue locally with checkpointed batches
# 3. Sync dashboard data only when the service stays on a free tier
```

---

## Checking System Health

### Ollama Status
```powershell
# Is Ollama running?
Get-Process ollama -ErrorAction SilentlyContinue

# Models loaded?
curl http://localhost:11434/api/tags | ConvertFrom-Json | ForEach-Object { $_.models.name }

# Performance?
Measure-Command {
  Invoke-RestMethod -Uri "http://localhost:11434/api/generate" `
    -Method Post `
    -Body '{"model":"llama2","prompt":"test"}'
}
```

### Supabase Status
```powershell
# Can connect?
Invoke-RestMethod -Uri "$env:SUPABASE_URL/rest/v1/batch_jobs" `
  -Headers @{ "apikey" = $env:SUPABASE_ANON_KEY }

# How many batches?
curl -s "$env:SUPABASE_URL/rest/v1/batch_jobs?select=count()" \
  -H "apikey: $env:SUPABASE_ANON_KEY" | ConvertFrom-Json
```

### Batch Status
```powershell
Get-GorBatchProgress -BatchId "batch_20260524_143022_a1b2c3d4"
```

---

## Support & Resources

- **Architecture details:** See `ARCHITECTURE.md`
- **Schema specifications:** Check `schema/` directory
- **Module documentation:** `Get-Help New-GorBatch -Full`
- **Error logs:** `logs/batch/` directory

---

**You're ready to go!** Start with the demo, then test batch processing, then scale up. 🚀
