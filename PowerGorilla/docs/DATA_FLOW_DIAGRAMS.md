# PowerShell Gorilla - Data Flow Diagrams

## 1. Batch Processing Pipeline (400K+ Prompts)

```
┌──────────────────────────────────────────────────────────────────────────┐
│ User creates batch with 400,000 items                                    │
└─────────────────────────────┬──────────────────────────────────────────────┘
                              │
                    ┌─────────▼──────────┐
                    │ New-GorBatch()     │
                    │ Validate items     │
                    │ Insert to Supabase │
                    └─────────┬──────────┘
                              │
            ┌─────────────────┼─────────────────┐
            │                 │                 │
    ┌───────▼─────────┐  ┌──────────────┐  ┌──────────┐
    │ batch_jobs      │  │ queue_items  │  │ Verify   │
    │ (1 row)         │  │ (400K rows)  │  │ schemas  │
    │                 │  │              │  │          │
    │ batch_id: xxx   │  │ item_id: 1   │  │  ✓ Input │
    │ total_items:    │  │ status: ...  │  │  ✓ Output│
    │   400000        │  │ input_data   │  │          │
    │ status: pending │  │              │  │ All OK   │
    └─────────────────┘  └──────┬───────┘  └──────────┘
                                 │
                        ┌────────▼────────┐
                        │ Start processor  │
                        │ Worker: ABC-1234 │
                        └────────┬────────┘
                                 │
                    ╔════════════▼══════════╗
                    ║   PROCESSING LOOP    ║
                    ║   (Sequential only)  ║
                    ╚════════════╦══════════╝
                                 │
                    ┌────────────▼────────────┐
                    │ Claim next pending item │
                    │ SELECT... FOR UPDATE    │
                    │ (atomic, no duplicates) │
                    └────────────┬────────────┘
                                 │
                  ┌──────────────▼──────────────┐
                  │ Check: Is item valid?      │
                  │ Schema check, retry count? │
                  │                            │
                  ├──────┬──────┬──────┬───────┤
                  │      │      │      │       │
           PENDING│  RETRY│FAILED│  OK  │      │
                  │      │      │      │       │
             ┌────▼┐ ┌───▼┐ ┌───▼┐  ┌─▼──┐    │
             │Skip │ │Back│ │Log │  │Send│    │
             │ if  │ │to  │ │err │  │to  │    │
             │500+ │ │retry│ │log │  │Oll.│    │
             │errs │ │if <3│ │    │  │ama │    │
             └─────┘ └────┘ └────┘  └┬───┘    │
                                     │        │
                       ┌─────────────▼──────┐  │
                       │   Ollama Request    │  │
                       │                     │  │
                       │ POST /api/generate  │  │
                       │ {model, prompt,     │  │
                       │  format: "json"}    │  │
                       │                     │  │
                       │ Response (3 sec)    │  │
                       │ {"response": "..."}  │  │
                       └─────────────┬────────┘  │
                                     │          │
                       ┌─────────────▼──────┐  │
                       │ Validate JSON      │  │
                       │ Schema match?      │  │
                       │                    │  │
                       ├───────┬────────────┤  │
                       │       │            │  │
                    VALID  INVALID      PARSE  │
                      │        │         ERROR │
                      │        │            │  │
             ┌────────▼┐   ┌───▼─────┐  ┌─▼──┴─┐
             │ Complete│   │ Fail    │  │ Fail │
             │ item    │   │ item    │  │ item │
             │         │   │         │  │      │
             │ status: │   │ status: │  │ Mark │
             │completed│   │ failed  │  │RETRY │
             └────┬────┘   └────┬────┘  └──┬───┘
                  │             │          │
                  ├─────────────┬┴─────────┤
                  │             │          │
              ┌───▼─────────────▼────────┐ │
              │   Increment counter      │ │
              │   (1 more item done)     │ │
              └───┬──────────────────────┘ │
                  │                        │
                  │  ┌─────────────────┐   │
                  ├─→│ Checkpoint check│   │
                  │  │ Every 1000 items│   │
                  │  └────────┬────────┘   │
                  │           │            │
                  │    ┌──────▼──────┐    │
                  │    │ Save state  │    │
                  │    │ to database  │    │
                  │    │             │    │
                  │    │ checkpoint_ │    │
                  │    │ id: ckpt_1  │    │
                  │    │ last_item:  │    │
                  │    │ item_1000   │    │
                  │    │ memory: 3GB │    │
                  │    └─────────────┘    │
                  │                        │
                  └────────────┬───────────┘
                               │
                    ┌──────────▼──────────┐
                    │ More items pending? │
                    │                     │
                    ├────┬────────────────┤
                    │    │                │
                   YES   NO             └─ DONE
                    │    │
            ┌───────▼┐   └──→ All items processed
            │ Repeat │        Batch status: COMPLETED
            │ loop   │        Export results
            └────────┘        Clean up
```

---

## 2. Multi-App Orchestration Flow

```
┌──────────────────────────────────────────────────────────────┐
│ User Intent: "Extract Q2 sales and email to team"           │
└─────────────────────────────┬────────────────────────────────┘
                              │
                    ┌─────────▼────────────┐
                    │ Ollama parses intent │
                    │ Determines app chain │
                    │ Extracts parameters  │
                    └─────────┬────────────┘
                              │
            ┌─────────────────┼─────────────────┐
            │                 │                 │
    ┌───────▼─────────┐  ┌────▼──────┐  ┌─────▼──────┐
    │ App#1: Excel    │  │ App#2:     │  │ App#3:     │
    │ action: query   │  │ Outlook    │  │ PowerPoint │
    │ input_schema:   │  │ action:    │  │ (optional) │
    │  gorilla/       │  │ send       │  │            │
    │  excel-input/v1 │  │            │  │            │
    └────────┬────────┘  └────┬───────┘  └────────────┘
             │                │
             └─────┬──────────┘
                   │
        ┌──────────▼────────────┐
        │  Start Orchestration  │
        │  State: pending       │
        │  orchestration_id:    │
        │    orch_abc123        │
        └──────────┬────────────┘
                   │
        ┌──────────▼────────────────────────────────────┐
        │              STEP 1: EXCEL (Sequence=1)       │
        │                                               │
        │  ┌──────────────────────────────────────────┐ │
        │  │ Test App Readiness                       │ │
        │  │                                          │ │
        │  │ ✓ Process running? (Get-Process)        │ │
        │  │ ✓ UI responsive? (UIAutomation)         │ │
        │  │ ✓ Ready within 30 sec timeout?          │ │
        │  └──────────────────┬───────────────────────┘ │
        │                     │                         │
        │          ┌──────────▼──────────┐              │
        │          │  Prepare input data │              │
        │          │                     │              │
        │          │  file_path: C:\...  │              │
        │          │  sheet_name: Q2     │              │
        │          │  range: A1:F50      │              │
        │          │  format: json       │              │
        │          └──────────┬──────────┘              │
        │                     │                        │
        │          ┌──────────▼──────────┐             │
        │          │ Invoke Excel action │             │
        │          │ (Pywinauto or API)  │             │
        │          │                     │             │
        │          │ Query sales data    │             │
        │          │ 500 rows returned   │             │
        │          └──────────┬──────────┘             │
        │                     │                        │
        │          ┌──────────▼──────────┐             │
        │          │ Validate output     │             │
        │          │ Schema: gorilla/    │             │
        │          │ excel-output/v1     │             │
        │          │                     │             │
        │          │ ✓ Is JSON valid?    │             │
        │          │ ✓ Matches schema?   │             │
        │          └──────────┬──────────┘             │
        │                     │                        │
        │          ┌──────────▼──────────┐             │
        │          │ Record in state     │             │
        │          │                     │             │
        │          │ state[1] = {        │             │
        │          │  data: [...500 rows │             │
        │          │  timestamp: now()   │             │
        │          │ }                   │             │
        │          └──────────┬──────────┘             │
        │                     │                        │
        │          ┌──────────▼──────────┐             │
        │          │ Step 1 COMPLETED    │             │
        │          │ Status: success     │             │
        │          │ Duration: 45 sec    │             │
        │          └──────────┬──────────┘             │
        │                     │                        │
        └─────────┬───────────┴────────────────────────┘
                  │
        ┌─────────▼──────────────────────────────────────┐
        │          STEP 2: OUTLOOK (Sequence=2)          │
        │                                                │
        │  ┌─────────────────────────────────────────┐   │
        │  │ Test App Readiness                      │   │
        │  │                                         │   │
        │  │ ✓ Process running?                      │   │
        │  │ ✓ Ready? YES                            │   │
        │  └──────────────────┬──────────────────────┘   │
        │                     │                         │
        │          ┌──────────▼──────────┐              │
        │          │ Prepare input data  │              │
        │          │ (from state[1])     │              │
        │          │                     │              │
        │          │ to: email addresses │              │
        │          │ subject: Q2 Results │              │
        │          │ body_data: data[..] │              │
        │          │ from state[1]       │              │
        │          └──────────┬──────────┘              │
        │                     │                        │
        │          ┌──────────▼──────────┐             │
        │          │ Invoke Outlook      │             │
        │          │ action: SEND        │             │
        │          │                     │             │
        │          │ Compose email       │             │
        │          │ Attach CSV of data  │             │
        │          │ Send to recipients  │             │
        │          └──────────┬──────────┘             │
        │                     │                        │
        │          ┌──────────▼──────────┐             │
        │          │ Validate output     │             │
        │          │                     │             │
        │          │ ✓ Email sent?       │             │
        │          │ ✓ Message ID?       │             │
        │          │ ✓ Status: sent      │             │
        │          └──────────┬──────────┘             │
        │                     │                        │
        │          ┌──────────▼──────────┐             │
        │          │ Record in state     │             │
        │          │                     │             │
        │          │ state[2] = {        │             │
        │          │  sent: true         │             │
        │          │  message_id: abc123 │             │
        │          │  recipients: 5      │             │
        │          │ }                   │             │
        │          └──────────┬──────────┘             │
        │                     │                        │
        │          ┌──────────▼──────────┐             │
        │          │ Step 2 COMPLETED    │             │
        │          │ Status: success     │             │
        │          │ Duration: 30 sec    │             │
        │          └──────────┬──────────┘             │
        │                     │                        │
        └─────────┬───────────┴────────────────────────┘
                  │
        ┌─────────▼──────────────────────────────────────┐
        │   Orchestration Complete                       │
        │                                                │
        │   Final State Summary:                         │
        │   ├─ Step 1 (Excel):    SUCCESS ✓             │
        │   ├─ Step 2 (Outlook):  SUCCESS ✓             │
        │   ├─ Total duration:    75 seconds            │
        │   ├─ Errors:            0                     │
        │   └─ Human action needed: NO                  │
        │                                                │
        │   Result: User has their email sent!          │
        └────────────────────────────────────────────────┘
```

---

## 3. Error Recovery Flow (App Crash)

```
Step 2: Outlook ready?
  │
  ├─ Check process: RUNNING ✓
  ├─ Check UI: READY ✓
  │
  Send email command...
  │
  └─ [APP CRASH] Outlook dies mid-send ❌

Error Detection:
  │
  ├─ No response from Outlook (timeout: 30 sec)
  ├─ Process still exists but unresponsive
  │
  └─ Invoke error handler: "retry"

Recovery Attempt 1:
  │
  ├─ Relaunch Outlook (Start-Process)
  ├─ Wait for UI ready (5 sec)
  ├─ Re-send email
  │
  └─ Still fails ❌ (process crashes again)

Recovery Attempt 2:
  │
  ├─ Kill any remaining Outlook instances
  ├─ Wait 2 sec
  ├─ Relaunch
  ├─ Wait for UI
  ├─ Re-send
  │
  └─ Still fails ❌

Recovery Attempt 3 (Last):
  │
  ├─ Final attempt
  ├─ Relaunch, resend
  │
  └─ Fails again ❌

Max Retries Exceeded (3):
  │
  ├─ error_handler is "retry"
  ├─ No fallback_app configured
  │
  ├─ Options:
  │  ├─ "retry" → FAIL (max reached)
  │  ├─ "skip" → Skip step, continue
  │  ├─ "abort" → Stop orchestration
  │  └─ "fallback" → Try alternative (none configured)
  │
  └─ Current: "retry" + no fallback = ABORT

Final State:
  │
  ├─ Orchestration status: FAILED
  ├─ Completed steps: 1 (Excel)
  ├─ Failed step: 2 (Outlook)
  ├─ Error logged: "Outlook crashed after 3 attempts"
  ├─ State preserved: state[1] still has Excel data
  │
  └─ Next action: Manual intervention
     User can:
     ├─ Fix Outlook issue
     ├─ Re-run from checkpoint
     ├─ Use fallback app (Gmail API?)
     └─ Export Excel data and send manually
```

---

## 4. Checkpoint & Recovery

```
Processing 400K items...

Item 1:      [===]
Item 2-99:   [==================]
Item 100:    [=====================]
  
  └─ Checkpoint 1 created
     ├─ ckpt_1
     ├─ last_item: item_100
     ├─ system_state: {memory: 3.2GB, throughput: 34.2 items/min}
     └─ Saved to DB

Item 101-199: [==================]
...
Item 1000:   [=========================]
  
  └─ Checkpoint 2 created
     ├─ ckpt_2
     ├─ last_item: item_1000
     └─ Saved to DB

...continuing...

Item 50000:  [====================================================================]
  
  └─ Checkpoint 50 created
     ├─ ckpt_50
     ├─ last_item: item_50000
     └─ Saved to DB

[SYSTEM CRASH] Power loss, Blue Screen, etc.
  
Processing stops abruptly:
├─ Items 1-50,000: COMPLETED (in DB)
├─ Items 50,001-50,500: processing (locks released)
├─ Items 50,501+: PENDING

Operator restarts processor 2 days later:

  Processor starts:
  ├─ Read last checkpoint: ckpt_50
  ├─ Last completed: item_50000
  │
  ├─ Query for next pending: item_50501
  ├─ Resume processing from item_50501
  │
  ├─ Items 50,001-50,500: Marked RETRY (can re-process)
  ├─ Items 50,501+: Still PENDING
  │
  └─ Continue for remaining 350,000 items

Result:
  ├─ No duplicate processing
  ├─ No data loss
  ├─ No manual intervention needed
  ├─ Complete batch resumes seamlessly
  └─ Total time: ~14 days (unchanged)
```

---

## 5. Schema Validation Pipeline

```
Queue Item Processing:

Input Validation:
  ├─ item.input_schema = "gorilla/embedding-input/v1"
  │
  ├─ Check input_data against schema:
  │  ├─ Required: text, embedding_model
  │  ├─ Optional: batch_size, vector_size
  │  ├─ Type checking: text must be string
  │  ├─ Pattern matching: embedding_model in ['mxbai', 'nomic', ...]
  │  │
  │  ├─ Valid? ✓ → Proceed
  │  └─ Invalid? ✗ → Mark as FAILED

Processing (Ollama):
  ├─ POST to /api/generate
  ├─ {"model": "mxbai-embed-large", "prompt": text, "format": "json"}
  │
  ├─ Response: {"response": "{...embedding vector...}"}
  └─ Latency: ~3 seconds

Output Validation:
  ├─ item.output_schema = "gorilla/embedding-output/v1"
  │
  ├─ Expected structure:
  │  └─ {
  │      embedding: [0.1, 0.2, ..., 0.9],  // 1024 float values
  │      vector_size: 1024,
  │      model: "mxbai-embed-large"
  │    }
  │
  ├─ JSON parse: Valid? ✓
  │  └─ Continue
  │
  ├─ Schema validation:
  │  ├─ Has "embedding"? ✓
  │  ├─ Type is array? ✓
  │  ├─ Length = 1024? ✓
  │  ├─ All floats? ✓
  │  ├─ Has "model"? ✓
  │  │
  │  ├─ All checks pass? ✓ → COMPLETE
  │  └─ Any fail? ✗ → FAILED

Database Update:
  ├─ If COMPLETE:
  │  └─ UPDATE queue_items
  │     SET status='completed',
  │         output_data='{embedding: [...]}',
  │         completed_at=now()
  │
  ├─ If FAILED:
  │  └─ UPDATE queue_items
  │     SET status='failed',
  │         validation_errors=['Missing embedding field'],
  │         retry_count++

Result:
  ├─ Item never reaches next step if schema invalid
  ├─ No cascading failures
  ├─ All validation errors logged
  └─ Batch continues safely
```

---

These diagrams show the complete data flow for all major operations.

