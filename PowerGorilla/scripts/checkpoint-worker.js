#!/usr/bin/env node
/**
 * PowerShell Gorilla — Node.js Checkpoint Queue Worker
 * Sequential, crash-resilient queue processor for local Ollama models.
 * 
 * Supports:
 * - Local-First Mode: Reads/Writes to data/queue/[BatchId].queue.json
 * - Supabase Mode: Integrates with PostgreSQL checkpoint_queue schema via native RPC endpoints
 */

const fs = require('fs');
const path = require('path');

// ============================================================================
// CONFIGURATION & ENVIRONMENT SETUP
// ============================================================================

const args = parseArgs();
const projectRoot = path.resolve(__dirname, '..');

// Attempt to load environment variables from .env or frontend/.env.local
loadEnvFiles();

const BATCH_ID = args.batchId;
const OLLAMA_ENDPOINT = args.ollamaEndpoint || process.env.OLLAMA_ENDPOINT || 'http://localhost:11434';
const WORKER_ID = args.workerId || `worker-node-${process.pid}`;
const CHECKPOINT_INTERVAL = parseInt(args.checkpointInterval || '100', 10);
const MAX_RETRIES = parseInt(args.maxRetries || '3', 10);

const SUPABASE_URL = process.env.SUPABASE_URL || process.env.GORILLA_SUPABASE_URL || process.env.EXPO_PUBLIC_SUPABASE_URL || '';
const SUPABASE_KEY = process.env.SUPABASE_SERVICE_KEY || process.env.GORILLA_SUPABASE_SERVICE_KEY || process.env.SUPABASE_ANON_KEY || process.env.GORILLA_SUPABASE_ANON_KEY || process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY || '';

const isLocalOnly = args.localOnly || !SUPABASE_URL || !SUPABASE_KEY;
const localQueuePath = args.localQueuePath || path.join(projectRoot, 'data', 'queue', `${BATCH_ID}.queue.json`);

// Simple logging helper
function log(message, level = 'INFO') {
  const ts = new Date().toISOString().replace('T', ' ').substring(0, 19);
  const logLine = `[${ts}] [${level}] ${message}`;
  console.log(logLine);
  
  // Write to log file under logs/batch/
  try {
    const logDir = path.join(projectRoot, 'logs', 'batch');
    if (!fs.existsSync(logDir)) {
      fs.mkdirSync(logDir, { recursive: true });
    }
    const logFile = path.join(logDir, `batch_${BATCH_ID}_node.log`);
    fs.appendFileSync(logFile, logLine + '\n', 'utf8');
  } catch (err) {
    // Ignore logging write errors
  }
}

// Ensure batchId is provided
if (!BATCH_ID) {
  console.error('Error: --batchId is a mandatory parameter.');
  console.log('\nUsage: node checkpoint-worker.js --batchId <id> [--localOnly] [--checkpointInterval 100] [--ollamaEndpoint http://localhost:11434]');
  process.exit(1);
}

log(`Starting Node.js batch processor for Batch ID: ${BATCH_ID}`);
log(`Worker ID: ${WORKER_ID}`);
log(`Mode: ${isLocalOnly ? 'Local-First (JSON files)' : 'Optional Supabase Free-Tier'}`);

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

function parseArgs() {
  const parsed = {};
  for (let i = 2; i < process.argv.length; i++) {
    const arg = process.argv[i];
    if (arg.startsWith('--')) {
      const key = arg.substring(2);
      const val = process.argv[i + 1];
      if (val && !val.startsWith('--')) {
        parsed[key] = val;
        i++;
      } else {
        parsed[key] = true;
      }
    }
  }
  return parsed;
}

function loadEnvFiles() {
  const envPaths = [
    path.join(projectRoot, 'frontend', '.env.local'),
    path.join(projectRoot, 'frontend', '.env'),
    path.join(projectRoot, '.env')
  ];

  for (const envPath of envPaths) {
    if (fs.existsSync(envPath)) {
      try {
        const content = fs.readFileSync(envPath, 'utf8');
        content.split('\n').forEach(line => {
          const match = line.match(/^\s*([\w.\-]+)\s*=\s*(.*)?\s*$/);
          if (match) {
            const key = match[1];
            let value = match[2] || '';
            // Remove quotes if any
            if (value.startsWith('"') && value.endsWith('"')) value = value.slice(1, -1);
            if (value.startsWith("'") && value.endsWith("'")) value = value.slice(1, -1);
            process.env[key] = value;
          }
        });
        log(`Loaded environment from: ${path.basename(envPath)}`);
        break; // Only load the first matching env file
      } catch (err) {
        log(`Failed to parse env file at ${envPath}: ${err.message}`, 'WARN');
      }
    }
  }
}

// Native fetch helper for PostgREST RPC
async function invokeSupabaseRpc(functionName, params) {
  const url = `${SUPABASE_URL.replace(/\/$/, '')}/rest/v1/rpc/${functionName}`;
  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'apikey': SUPABASE_KEY,
      'Authorization': `Bearer ${SUPABASE_KEY}`,
      'Content-Type': 'application/json',
      'Prefer': 'params=singleobject'
    },
    body: JSON.stringify(params)
  });

  if (!response.ok) {
    const errText = await response.text();
    throw new Error(`Supabase RPC ${functionName} failed (${response.status}): ${errText}`);
  }

  const text = await response.text();
  return text ? JSON.parse(text) : null;
}

// Native fetch helper for local Ollama API
async function invokeOllamaPrompt(prompt, model, jsonSchema) {
  const url = `${OLLAMA_ENDPOINT.replace(/\/$/, '')}/api/generate`;
  const body = {
    model: model,
    prompt: prompt,
    stream: false,
    format: jsonSchema ? jsonSchema : 'text'
  };

  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 300 * 1000); // 5 min timeout

  try {
    const response = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
      signal: controller.signal
    });

    clearTimeout(timeoutId);

    if (!response.ok) {
      throw new Error(`Ollama request failed with status ${response.status}`);
    }

    const result = await response.json();
    const responseText = result.response;

    if (jsonSchema) {
      try {
        const parsedJson = JSON.parse(responseText);
        return {
          success: true,
          data: parsedJson,
          raw: responseText,
          duration_ms: result.eval_duration ? result.eval_duration / 1000000 : 0
        };
      } catch (jsonErr) {
        log(`Ollama response failed JSON schema parse validation.`, 'WARN');
        return {
          success: false,
          error: `JSON Validation Error: ${jsonErr.message}`,
          raw: responseText
        };
      }
    }

    return {
      success: true,
      data: responseText,
      raw: responseText,
      duration_ms: result.eval_duration ? result.eval_duration / 1000000 : 0
    };

  } catch (err) {
    clearTimeout(timeoutId);
    log(`Ollama prompt execution failed: ${err.message}`, 'ERROR');
    return {
      success: false,
      error: err.message
    };
  }
}

// ============================================================================
// SCHEMA LOADING
// ============================================================================

const appSchemaPath = path.join(projectRoot, 'schema', 'app.schema.json');
const workflowSchemaPath = path.join(projectRoot, 'schema', 'workflow.schema.json');

let appSchema = null;
let workflowSchema = null;

try {
  if (fs.existsSync(appSchemaPath)) {
    appSchema = JSON.parse(fs.readFileSync(appSchemaPath, 'utf8'));
  }
  if (fs.existsSync(workflowSchemaPath)) {
    workflowSchema = JSON.parse(fs.readFileSync(workflowSchemaPath, 'utf8'));
  }
} catch (err) {
  log(`Warning: Failed to pre-load JSON schemas: ${err.message}`, 'WARN');
}

// ============================================================================
// MAIN RUNNERS
// ============================================================================

async function runLocalQueue() {
  log(`Initializing local queue processing...`);
  if (!fs.existsSync(localQueuePath)) {
    const queueDir = path.dirname(localQueuePath);
    if (!fs.existsSync(queueDir)) {
      fs.mkdirSync(queueDir, { recursive: true });
    }
    fs.writeFileSync(localQueuePath, '[]', 'utf8');
    log(`Created empty local queue file at: ${localQueuePath}. Please add items and run again.`, 'WARN');
    return;
  }

  let queue;
  try {
    let rawContent = fs.readFileSync(localQueuePath, 'utf8');
    if (rawContent.charCodeAt(0) === 0xFEFF) {
      rawContent = rawContent.slice(1);
    }
    const parsed = JSON.parse(rawContent);
    queue = Array.isArray(parsed) ? parsed : [parsed];
  } catch (err) {
    log(`Failed to parse local queue JSON: ${err.message}`, 'ERROR');
    process.exit(1);
  }

  let totalProcessed = 0;
  let totalFailed = 0;
  const batchStartTime = Date.now();

  const saveQueue = () => {
    fs.writeFileSync(localQueuePath, JSON.stringify(queue, null, 2), 'utf8');
  };

  for (const item of queue) {
    if (!item.status) item.status = 'pending';
    if (item.status !== 'pending' && item.status !== 'retry') continue;

    item.status = 'processing';
    item.worker_id = WORKER_ID;
    item.started_at = new Date().toISOString();
    saveQueue();

    const itemId = item.item_id || Math.random().toString(36).substring(2);
    item.item_id = itemId;
    log(`Processing local item: ${itemId}`);

    const inputData = item.input_data || {};
    const itemType = item.item_type || 'prompt';
    const model = inputData.model || inputData.embedding_model || 'llama3.2';

    let result;
    if (itemType === 'prompt' || itemType === 'workflow' || itemType === 'app-analysis' || itemType === 'extraction') {
      const promptText = inputData.prompt_text || '';
      let schemaObj = null;
      if (itemType === 'workflow') schemaObj = workflowSchema;
      else if (itemType === 'app-analysis') schemaObj = appSchema;
      
      result = await invokeOllamaPrompt(promptText, model, schemaObj);
    } else if (itemType === 'embedding') {
      result = await invokeOllamaPrompt(inputData.text || '', model);
    } else {
      result = { success: false, error: `Unknown item type: ${itemType}` };
    }

    if (result.success) {
      item.status = 'completed';
      item.output_data = result.data;
      item.completed_at = new Date().toISOString();
      item.duration_ms = result.duration_ms;
      totalProcessed++;
      log(`Completed local item: ${itemId}`);
    } else {
      item.status = 'failed';
      item.error_message = result.error;
      item.completed_at = new Date().toISOString();
      totalFailed++;
      log(`Failed local item: ${itemId} - ${result.error}`, 'WARN');
    }

    saveQueue();

    if (totalProcessed > 0 && totalProcessed % CHECKPOINT_INTERVAL === 0) {
      log(`Local Checkpoint reached. Total Processed: ${totalProcessed} | Total Failed: ${totalFailed}`);
    }
  }

  const elapsed = ((Date.now() - batchStartTime) / 1000).toFixed(2);
  log(`Local batch processing complete. Processed: ${totalProcessed}, Failed: ${totalFailed}, Time: ${elapsed}s`);
}

async function runSupabaseQueue() {
  log(`Initializing Supabase active queue processing...`);
  
  // Verify Ollama connection first
  try {
    const testRes = await fetch(`${OLLAMA_ENDPOINT.replace(/\/$/, '')}/api/tags`);
    if (!testRes.ok) throw new Error(`Ollama returned status ${testRes.status}`);
    log(`Connected to Ollama engine successfully.`);
  } catch (err) {
    log(`ERROR: Cannot reach local Ollama engine at ${OLLAMA_ENDPOINT} : ${err.message}`, 'ERROR');
    process.exit(1);
  }

  let totalProcessed = 0;
  let totalFailed = 0;
  const batchStartTime = Date.now();

  while (true) {
    try {
      // 1. Claim next pending item atomically via RPC
      const claimed = await invokeSupabaseRpc('claim_next_queue_item', {
        p_batch_id: BATCH_ID,
        p_worker_id: WORKER_ID
      });

      if (!claimed || claimed.length === 0) {
        log(`No more pending items in queue. Batch ${BATCH_ID} processing complete.`);
        break;
      }

      const item = claimed[0];
      const itemId = item.item_id;
      const sequenceNum = item.sequence_number;

      log(`Processing queue item [Seq #${sequenceNum}] [ID: ${itemId}]`);

      const inputData = item.input_data || {};
      const itemType = item.item_type || 'prompt';
      const model = inputData.model || inputData.embedding_model || 'llama3.2';

      // 2. Invoke local Ollama
      let result;
      if (itemType === 'prompt' || itemType === 'workflow' || itemType === 'app-analysis' || itemType === 'extraction') {
        const promptText = inputData.prompt_text || '';
        let schemaObj = null;
        if (itemType === 'workflow') schemaObj = workflowSchema;
        else if (itemType === 'app-analysis') schemaObj = appSchema;
        
        result = await invokeOllamaPrompt(promptText, model, schemaObj);
      } else if (itemType === 'embedding') {
        result = await invokeOllamaPrompt(inputData.text || '', model);
      } else {
        result = { success: false, error: `Unknown item type: ${itemType}` };
      }

      // 3. Update result state atomically via RPC
      if (result.success) {
        await invokeSupabaseRpc('complete_queue_item', {
          p_item_id: itemId,
          p_output_data: result.data,
          p_output_schema: itemType
        });
        log(`Completed item ID: ${itemId}`);
        totalProcessed++;
      } else {
        await invokeSupabaseRpc('fail_queue_item', {
          p_item_id: itemId,
          p_error_message: result.error
        });
        log(`Failed item ID: ${itemId} - Error: ${result.error}`, 'WARN');
        totalFailed++;
      }

      // 4. Create database checkpoint every N items
      if (totalProcessed > 0 && totalProcessed % CHECKPOINT_INTERVAL === 0) {
        const memoryUsage = Math.round(process.memoryUsage().heapUsed / 1024 / 1024 * 100) / 100;
        const systemState = {
          memory_used_mb: memoryUsage,
          total_processed: totalProcessed,
          total_failed: totalFailed,
          items_per_sec: parseFloat((totalProcessed / ((Date.now() - batchStartTime) / 1000)).toFixed(2))
        };

        const checkpointId = await invokeSupabaseRpc('create_batch_checkpoint', {
          p_batch_id: BATCH_ID,
          p_system_state: systemState
        });

        log(`Saved Checkpoint: ${checkpointId} | Processed: ${totalProcessed} | Failed: ${totalFailed}`, 'INFO');
      }

    } catch (err) {
      log(`ERROR in main processing loop: ${err.message}`, 'ERROR');
      // Cooldown wait before retrying to prevent rapid error spinning
      await new Promise(resolve => setTimeout(resolve, 5000));
    }
  }

  const elapsed = ((Date.now() - batchStartTime) / 1000).toFixed(2);
  log(`Batch processing finished. Total Processed: ${totalProcessed}, Failed: ${totalFailed}, Duration: ${elapsed}s`);
}

// Launch the chosen worker loop
if (isLocalOnly) {
  runLocalQueue().catch(err => {
    log(`Fatal Error in Local Queue: ${err.message}`, 'ERROR');
    process.exit(1);
  });
} else {
  runSupabaseQueue().catch(err => {
    log(`Fatal Error in Supabase Queue: ${err.message}`, 'ERROR');
    process.exit(1);
  });
}
