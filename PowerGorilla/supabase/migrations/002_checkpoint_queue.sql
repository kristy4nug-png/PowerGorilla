-- PowerShell Gorilla — Checkpoint Queue System
-- Handles async batch processing of up to 400,000+ prompts
-- Provides transaction-ledger state tracking for resilience

-- ─────────────────────────────────────────────────────────────
-- BATCH JOBS TABLE
-- ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS batch_jobs (
  batch_id          TEXT        PRIMARY KEY,
  batch_name        TEXT        NOT NULL,
  description       TEXT,
  status            TEXT        NOT NULL DEFAULT 'pending'
                    CHECK (status IN ('pending','running','paused','completed','failed','cancelled')),
  total_items       INTEGER     NOT NULL DEFAULT 0,
  processed_items   INTEGER     NOT NULL DEFAULT 0,
  failed_items      INTEGER     NOT NULL DEFAULT 0,
  skipped_items     INTEGER     NOT NULL DEFAULT 0,
  target_model      TEXT        NOT NULL DEFAULT 'llama2',
  batch_start_time  TIMESTAMPTZ,
  batch_end_time    TIMESTAMPTZ,
  estimated_time_ms BIGINT      DEFAULT NULL,
  actual_time_ms    BIGINT      DEFAULT NULL,
  checkpoint_index  INTEGER     NOT NULL DEFAULT 0,
  last_checkpoint   TIMESTAMPTZ NOT NULL DEFAULT now(),
  priority          INTEGER     NOT NULL DEFAULT 50 CHECK (priority BETWEEN 0 AND 100),
  config_json       JSONB       NOT NULL DEFAULT '{}',
  error_log         TEXT        DEFAULT NULL,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS batch_jobs_status_idx ON batch_jobs (status);
CREATE INDEX IF NOT EXISTS batch_jobs_created_idx ON batch_jobs (created_at DESC);
CREATE INDEX IF NOT EXISTS batch_jobs_priority_idx ON batch_jobs (priority DESC);

-- ─────────────────────────────────────────────────────────────
-- QUEUE ITEMS TABLE (transaction ledger)
-- ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS queue_items (
  item_id           TEXT        PRIMARY KEY,
  batch_id          TEXT        NOT NULL REFERENCES batch_jobs(batch_id) ON DELETE CASCADE,
  sequence_number   INTEGER     NOT NULL,
  item_type         TEXT        NOT NULL
                    CHECK (item_type IN ('prompt','embedding','extraction','workflow','app-analysis')),
  status            TEXT        NOT NULL DEFAULT 'pending'
                    CHECK (status IN ('pending','processing','completed','failed','skipped','retry')),
  
  -- Input payload
  input_data        JSONB       NOT NULL,
  input_schema      TEXT,
  
  -- Output payload
  output_data       JSONB,
  output_schema     TEXT,
  
  -- Validation & schema enforcement
  schema_valid      BOOLEAN     NOT NULL DEFAULT FALSE,
  validation_errors TEXT[]      NOT NULL DEFAULT '{}',
  
  -- Timing & metrics
  queued_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  started_at        TIMESTAMPTZ,
  completed_at      TIMESTAMPTZ,
  duration_ms       BIGINT,
  retry_count       INTEGER     NOT NULL DEFAULT 0,
  max_retries       INTEGER     NOT NULL DEFAULT 3,
  
  -- State
  locked_by         TEXT,
  locked_at         TIMESTAMPTZ,
  worker_id         TEXT,
  
  -- Metadata
  priority          INTEGER     NOT NULL DEFAULT 50,
  tags              TEXT[]      DEFAULT '{}',
  parent_item_id    TEXT,
  
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS queue_items_batch_idx ON queue_items (batch_id);
CREATE INDEX IF NOT EXISTS queue_items_status_idx ON queue_items (status);
CREATE INDEX IF NOT EXISTS queue_items_sequence_idx ON queue_items (batch_id, sequence_number);
CREATE INDEX IF NOT EXISTS queue_items_locked_idx ON queue_items (locked_by, locked_at);
CREATE INDEX IF NOT EXISTS queue_items_completed_idx ON queue_items (completed_at DESC) WHERE status = 'completed';
CREATE INDEX IF NOT EXISTS queue_items_failed_idx ON queue_items (status) WHERE status IN ('failed', 'retry');

-- ─────────────────────────────────────────────────────────────
-- BATCH CHECKPOINT TABLE (Resume-ability)
-- ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS batch_checkpoints (
  checkpoint_id     TEXT        PRIMARY KEY,
  batch_id          TEXT        NOT NULL REFERENCES batch_jobs(batch_id) ON DELETE CASCADE,
  checkpoint_number INTEGER     NOT NULL,
  last_completed_id TEXT        NOT NULL,
  items_processed   INTEGER     NOT NULL,
  checkpoint_time   TIMESTAMPTZ NOT NULL DEFAULT now(),
  system_state      JSONB       NOT NULL DEFAULT '{}',
  
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON COLUMN batch_checkpoints.system_state IS 'Captures memory usage, queue depth, and Ollama status';

CREATE INDEX IF NOT EXISTS batch_checkpoints_batch_idx ON batch_checkpoints (batch_id);
CREATE INDEX IF NOT EXISTS batch_checkpoints_time_idx ON batch_checkpoints (checkpoint_time DESC);

-- ─────────────────────────────────────────────────────────────
-- OLLAMA HEALTH & METRICS TABLE
-- ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS ollama_metrics (
  metric_id         TEXT        PRIMARY KEY,
  timestamp         TIMESTAMPTZ NOT NULL DEFAULT now(),
  model_name        TEXT        NOT NULL,
  
  -- Model state
  model_loaded      BOOLEAN     NOT NULL,
  memory_used_mb    BIGINT,
  context_size      INTEGER,
  
  -- Request metrics
  avg_response_ms   NUMERIC(10,2),
  p99_response_ms   NUMERIC(10,2),
  requests_per_min  NUMERIC(8,2),
  error_rate        NUMERIC(5,2),
  
  -- Hardware
  total_memory_mb   BIGINT,
  free_memory_mb    BIGINT,
  
  health_status     TEXT        DEFAULT 'healthy'
                    CHECK (health_status IN ('healthy','degraded','offline')),
  
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS ollama_metrics_model_idx ON ollama_metrics (model_name);
CREATE INDEX IF NOT EXISTS ollama_metrics_timestamp_idx ON ollama_metrics (timestamp DESC);

-- ─────────────────────────────────────────────────────────────
-- FUNCTIONS: State Transitions
-- ─────────────────────────────────────────────────────────────

-- Atomically claim next pending item (unambiguous qualified references)
CREATE OR REPLACE FUNCTION claim_next_queue_item(
  p_batch_id TEXT,
  p_worker_id TEXT
)
RETURNS TABLE (
  item_id TEXT,
  sequence_number INTEGER,
  input_data JSONB,
  item_type TEXT
)
LANGUAGE SQL AS $$
  UPDATE queue_items qi
  SET
    status = 'processing',
    locked_by = p_worker_id,
    locked_at = now(),
    started_at = now(),
    updated_at = now()
  WHERE
    qi.item_id = (
      SELECT sub.item_id FROM queue_items sub
      WHERE sub.batch_id = p_batch_id
        AND sub.status = 'pending'
        AND (sub.locked_by IS NULL OR sub.locked_at < now() - interval '5 minutes')
      ORDER BY sub.priority DESC, sub.sequence_number ASC
      LIMIT 1
      FOR UPDATE SKIP LOCKED
    )
  RETURNING qi.item_id, qi.sequence_number, qi.input_data, qi.item_type;
$$;

-- Mark item as completed
CREATE OR REPLACE FUNCTION complete_queue_item(
  p_item_id TEXT,
  p_output_data JSONB,
  p_output_schema TEXT
)
RETURNS void
LANGUAGE SQL AS $$
  UPDATE queue_items
  SET
    status = 'completed',
    output_data = p_output_data,
    output_schema = p_output_schema,
    completed_at = now(),
    duration_ms = EXTRACT(EPOCH FROM (now() - started_at)) * 1000,
    locked_by = NULL,
    locked_at = NULL,
    updated_at = now()
  WHERE item_id = p_item_id;
$$;

-- Mark item as failed with retry logic
CREATE OR REPLACE FUNCTION fail_queue_item(
  p_item_id TEXT,
  p_error_message TEXT
)
RETURNS void
LANGUAGE PLPGSQL AS $$
DECLARE
  v_retry_count INTEGER;
  v_max_retries INTEGER;
BEGIN
  SELECT retry_count, max_retries INTO v_retry_count, v_max_retries
  FROM queue_items WHERE item_id = p_item_id;

  IF v_retry_count < v_max_retries THEN
    UPDATE queue_items
    SET
      status = 'retry',
      retry_count = retry_count + 1,
      validation_errors = array_append(validation_errors, p_error_message),
      locked_by = NULL,
      locked_at = NULL,
      updated_at = now()
    WHERE item_id = p_item_id;
  ELSE
    UPDATE queue_items
    SET
      status = 'failed',
      validation_errors = array_append(validation_errors, p_error_message),
      locked_by = NULL,
      locked_at = NULL,
      updated_at = now()
    WHERE item_id = p_item_id;
  END IF;
END;
$$;

-- Get batch progress
CREATE OR REPLACE FUNCTION get_batch_progress(p_batch_id TEXT)
RETURNS TABLE (
  total_items INTEGER,
  processed_items INTEGER,
  failed_items INTEGER,
  pending_items INTEGER,
  retry_items INTEGER,
  percent_complete NUMERIC,
  time_elapsed_ms BIGINT,
  est_time_remaining_ms BIGINT
)
LANGUAGE SQL STABLE AS $$
  WITH batch_stats AS (
    SELECT
      COUNT(*) FILTER (WHERE status != 'skipped') as total_not_skipped,
      COUNT(*) FILTER (WHERE status = 'completed') as completed,
      COUNT(*) FILTER (WHERE status = 'failed') as failed,
      COUNT(*) FILTER (WHERE status = 'pending') as pending,
      COUNT(*) FILTER (WHERE status = 'retry') as retrying,
      MIN(queued_at) as start_time
    FROM queue_items
    WHERE batch_id = p_batch_id
  )
  SELECT
    batch_stats.total_not_skipped::INTEGER,
    batch_stats.completed::INTEGER,
    batch_stats.failed::INTEGER,
    batch_stats.pending::INTEGER,
    batch_stats.retrying::INTEGER,
    ROUND((batch_stats.completed::NUMERIC / NULLIF(batch_stats.total_not_skipped, 0)) * 100, 2),
    (EXTRACT(EPOCH FROM (now() - batch_stats.start_time)) * 1000)::BIGINT,
    CASE
      WHEN batch_stats.completed > 0 THEN
        (EXTRACT(EPOCH FROM (now() - batch_stats.start_time)) / batch_stats.completed *
         (batch_stats.total_not_skipped - batch_stats.completed) * 1000)::BIGINT
      ELSE NULL
    END
  FROM batch_stats;
$$;

-- Cleanup stale locks
CREATE OR REPLACE FUNCTION release_stale_locks(p_timeout_minutes INT DEFAULT 5)
RETURNS TABLE (released_count INT)
LANGUAGE SQL AS $$
  WITH released AS (
    UPDATE queue_items
    SET
      status = 'retry',
      locked_by = NULL,
      locked_at = NULL,
      retry_count = retry_count + 1,
      updated_at = now()
    WHERE
      locked_by IS NOT NULL
      AND locked_at < now() - (p_timeout_minutes || ' minutes')::INTERVAL
      AND status = 'processing'
    RETURNING item_id
  )
  SELECT COUNT(*)::INT FROM released;
$$;

-- Create checkpoint
CREATE OR REPLACE FUNCTION create_batch_checkpoint(
  p_batch_id TEXT,
  p_system_state JSONB
)
RETURNS TEXT
LANGUAGE PLPGSQL AS $$
DECLARE
  v_checkpoint_id TEXT;
  v_last_completed_id TEXT;
  v_items_processed INTEGER;
  v_checkpoint_number INTEGER;
BEGIN
  SELECT COALESCE(MAX(checkpoint_number), 0) + 1
  INTO v_checkpoint_number
  FROM batch_checkpoints
  WHERE batch_id = p_batch_id;

  SELECT item_id, COUNT(*)
  INTO v_last_completed_id, v_items_processed
  FROM queue_items
  WHERE batch_id = p_batch_id AND status = 'completed'
  GROUP BY item_id, completed_at
  ORDER BY completed_at DESC
  LIMIT 1;

  v_checkpoint_id := p_batch_id || '_ckpt_' || v_checkpoint_number;

  INSERT INTO batch_checkpoints (
    checkpoint_id, batch_id, checkpoint_number,
    last_completed_id, items_processed, system_state
  )
  VALUES (
    v_checkpoint_id, p_batch_id, v_checkpoint_number,
    COALESCE(v_last_completed_id, ''), COALESCE(v_items_processed, 0), p_system_state
  );

  UPDATE batch_jobs
  SET
    checkpoint_index = v_checkpoint_number,
    last_checkpoint = now()
  WHERE batch_id = p_batch_id;

  RETURN v_checkpoint_id;
END;
$$;

-- ─────────────────────────────────────────────────────────────
-- FUNCTION: Restart / Resume Batch recovery
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION restart_batch_from_checkpoint(
  p_batch_id TEXT,
  p_last_completed_id TEXT
)
RETURNS void
LANGUAGE PLPGSQL AS $$
DECLARE
  v_last_seq INTEGER;
BEGIN
  -- Find sequence number of the last completed item
  SELECT sequence_number INTO v_last_seq
  FROM queue_items
  WHERE item_id = p_last_completed_id;

  -- Default to 0 if not found, so we reset everything
  IF v_last_seq IS NULL THEN
    v_last_seq := 0;
  END IF;

  -- Reset all items after the last completed sequence
  UPDATE queue_items
  SET
    status = 'pending',
    output_data = NULL,
    output_schema = NULL,
    locked_by = NULL,
    locked_at = NULL,
    started_at = NULL,
    completed_at = NULL,
    duration_ms = NULL,
    updated_at = now()
  WHERE batch_id = p_batch_id
    AND sequence_number > v_last_seq;
    
  -- Set batch job status back to pending
  UPDATE batch_jobs
  SET status = 'pending'
  WHERE batch_id = p_batch_id;
END;
$$;
