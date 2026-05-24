-- PowerShell Gorilla â€” Supabase Migration 001
-- Run this in the Supabase SQL Editor at: https://app.supabase.com
-- Project: powershell-gorrilla

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- Enable pgvector
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
CREATE EXTENSION IF NOT EXISTS vector;

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- APPS TABLE
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
CREATE TABLE IF NOT EXISTS apps (
  id                TEXT        PRIMARY KEY,
  name              TEXT        NOT NULL,
  normalized_name   TEXT,
  category          TEXT        NOT NULL DEFAULT 'Unknown',
  licence_mode      TEXT        NOT NULL DEFAULT 'Unknown'
                    CHECK (licence_mode IN ('Open-source','Free','Free-tier','Built-in','Paid or trial','Unknown')),
  is_open_source    BOOLEAN     NOT NULL DEFAULT FALSE,
  is_free           BOOLEAN     NOT NULL DEFAULT FALSE,
  sign_in_mode      TEXT        NOT NULL DEFAULT 'Unknown',
  local_mode        TEXT        NOT NULL DEFAULT 'Unknown',
  status            TEXT        NOT NULL DEFAULT 'Missing'
                    CHECK (status IN ('Installed','Missing','Portable','Store app','Shortcut only')),
  installed         BOOLEAN     NOT NULL DEFAULT FALSE,
  install_path      TEXT,
  executable_path   TEXT,
  shortcut_path     TEXT,
  icon_url          TEXT,
  publisher         TEXT,
  version           TEXT,
  source            TEXT        NOT NULL DEFAULT 'Unknown',
  detected_source   TEXT,
  seen_in_workflows INTEGER,
  ollama_enriched   BOOLEAN     NOT NULL DEFAULT FALSE,
  embedding_model   TEXT,
  last_scanned      TIMESTAMPTZ NOT NULL DEFAULT now(),
  embedding         vector(768),
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS apps_embedding_idx ON apps USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);
CREATE INDEX IF NOT EXISTS apps_category_idx ON apps (category);
CREATE INDEX IF NOT EXISTS apps_installed_idx ON apps (installed);
CREATE INDEX IF NOT EXISTS apps_name_idx ON apps USING gin (to_tsvector('english', name));

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- WORKFLOWS TABLE
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
CREATE TABLE IF NOT EXISTS workflows (
  id                    TEXT        PRIMARY KEY,
  workflow_name         TEXT        NOT NULL,
  description           TEXT        NOT NULL DEFAULT '',
  category              TEXT        NOT NULL DEFAULT 'Unknown',
  app_names             TEXT[]      NOT NULL,
  combination_size      INTEGER     NOT NULL CHECK (combination_size BETWEEN 2 AND 4),
  difficulty            TEXT        NOT NULL DEFAULT 'Unknown'
                        CHECK (difficulty IN ('Easy','Medium','Hard','Unknown')),
  risk_level            TEXT        NOT NULL DEFAULT 'Low'
                        CHECK (risk_level IN ('Low','Medium','High')),
  automation_readiness  TEXT        NOT NULL DEFAULT 'Unknown',
  free_open_source      TEXT        NOT NULL DEFAULT 'Unknown',
  rank_score            NUMERIC(5,2) NOT NULL DEFAULT 50 CHECK (rank_score BETWEEN 0 AND 100),
  sign_in_requirement   TEXT        NOT NULL DEFAULT 'Unknown',
  powershell_plan       TEXT[]      NOT NULL DEFAULT '{}',
  ollama_enriched       BOOLEAN     NOT NULL DEFAULT FALSE,
  embedding_model       TEXT,
  embedding             vector(768),
  created_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS workflows_embedding_idx ON workflows USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);
CREATE INDEX IF NOT EXISTS workflows_combination_size_idx ON workflows (combination_size);
CREATE INDEX IF NOT EXISTS workflows_rank_idx ON workflows (rank_score DESC);
CREATE INDEX IF NOT EXISTS workflows_app_names_idx ON workflows USING gin (app_names);
CREATE INDEX IF NOT EXISTS workflows_fts_idx ON workflows USING gin (to_tsvector('english', workflow_name || ' ' || description));

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- OLLAMA EXTRACTIONS TABLE
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
CREATE TABLE IF NOT EXISTS ollama_extractions (
  extraction_id     TEXT        PRIMARY KEY,
  source_type       TEXT        NOT NULL
                    CHECK (source_type IN ('app-row','workflow-row','csv-chunk','freetext')),
  source_ref        TEXT        NOT NULL,
  extracted_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  model             TEXT        NOT NULL,
  prompt            TEXT,
  result            JSONB       NOT NULL DEFAULT '{}',
  target_schema     TEXT        CHECK (target_schema IN ('gorilla/app/v1','gorilla/workflow/v1')),
  confidence        NUMERIC(4,3) NOT NULL DEFAULT 1.0 CHECK (confidence BETWEEN 0 AND 1),
  schema_valid      BOOLEAN     NOT NULL DEFAULT FALSE,
  validation_errors TEXT[]      NOT NULL DEFAULT '{}'
);

CREATE INDEX IF NOT EXISTS extractions_source_type_idx ON ollama_extractions (source_type);
CREATE INDEX IF NOT EXISTS extractions_model_idx ON ollama_extractions (model);
CREATE INDEX IF NOT EXISTS extractions_valid_idx ON ollama_extractions (schema_valid);

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- AUDIT LOG (append-only ledger, mirrors gorledger)
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
CREATE TABLE IF NOT EXISTS audit_log (
  id         BIGINT      GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  ts         TIMESTAMPTZ NOT NULL DEFAULT now(),
  type       TEXT        NOT NULL,
  message    TEXT        NOT NULL,
  actor      TEXT        NOT NULL DEFAULT 'powershell-gorilla',
  data       JSONB
);

CREATE INDEX IF NOT EXISTS audit_log_ts_idx ON audit_log (ts DESC);
CREATE INDEX IF NOT EXISTS audit_log_type_idx ON audit_log (type);

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- VECTOR SEARCH FUNCTIONS
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
CREATE OR REPLACE FUNCTION search_apps(
  query_embedding vector(768),
  match_count     INT DEFAULT 20,
  filter_installed BOOLEAN DEFAULT NULL
)
RETURNS TABLE (
  id          TEXT,
  name        TEXT,
  category    TEXT,
  status      TEXT,
  installed   BOOLEAN,
  licence_mode TEXT,
  icon_url    TEXT,
  similarity  FLOAT
)
LANGUAGE SQL STABLE AS $$
  SELECT
    id, name, category, status, installed, licence_mode, icon_url,
    1 - (embedding <=> query_embedding) AS similarity
  FROM apps
  WHERE
    embedding IS NOT NULL
    AND (filter_installed IS NULL OR installed = filter_installed)
  ORDER BY embedding <=> query_embedding
  LIMIT match_count;
$$;

CREATE OR REPLACE FUNCTION search_workflows(
  query_embedding   vector(768),
  match_count       INT DEFAULT 20,
  filter_combo_size INT DEFAULT NULL
)
RETURNS TABLE (
  id               TEXT,
  workflow_name    TEXT,
  description      TEXT,
  category         TEXT,
  app_names        TEXT[],
  combination_size INTEGER,
  risk_level       TEXT,
  rank_score       NUMERIC,
  similarity       FLOAT
)
LANGUAGE SQL STABLE AS $$
  SELECT
    id, workflow_name, description, category, app_names,
    combination_size, risk_level, rank_score,
    1 - (embedding <=> query_embedding) AS similarity
  FROM workflows
  WHERE
    embedding IS NOT NULL
    AND (filter_combo_size IS NULL OR combination_size = filter_combo_size)
  ORDER BY embedding <=> query_embedding
  LIMIT match_count;
$$;

-- Bad Gorrilla frontend performance
-- Free-tier friendly indexes and small views for the Expo/Supabase UI.

CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- App inventory screen: public/free-only rows, sorted by name with common filters.
CREATE INDEX IF NOT EXISTS apps_public_name_idx
  ON apps (name)
  WHERE cost_allowed = TRUE AND licence_mode <> 'Paid or trial';

CREATE INDEX IF NOT EXISTS apps_public_category_name_idx
  ON apps (category, name)
  WHERE cost_allowed = TRUE AND licence_mode <> 'Paid or trial';

CREATE INDEX IF NOT EXISTS apps_public_installed_name_idx
  ON apps (installed, name)
  WHERE cost_allowed = TRUE AND licence_mode <> 'Paid or trial';

CREATE INDEX IF NOT EXISTS apps_public_open_source_name_idx
  ON apps (is_open_source, name)
  WHERE cost_allowed = TRUE AND licence_mode <> 'Paid or trial';

CREATE INDEX IF NOT EXISTS apps_public_name_trgm_idx
  ON apps USING gin (name gin_trgm_ops)
  WHERE cost_allowed = TRUE AND licence_mode <> 'Paid or trial';

-- Workflow screen: top-ranked free workflows and filter combinations.
CREATE INDEX IF NOT EXISTS workflows_public_rank_idx
  ON workflows (rank_score DESC)
  WHERE cost_allowed = TRUE;

CREATE INDEX IF NOT EXISTS workflows_public_size_rank_idx
  ON workflows (combination_size, rank_score DESC)
  WHERE cost_allowed = TRUE;

CREATE INDEX IF NOT EXISTS workflows_public_category_rank_idx
  ON workflows (category, rank_score DESC)
  WHERE cost_allowed = TRUE;

CREATE INDEX IF NOT EXISTS workflows_public_risk_rank_idx
  ON workflows (risk_level, rank_score DESC)
  WHERE cost_allowed = TRUE;

CREATE INDEX IF NOT EXISTS workflows_public_name_trgm_idx
  ON workflows USING gin (workflow_name gin_trgm_ops)
  WHERE cost_allowed = TRUE;

CREATE INDEX IF NOT EXISTS audit_log_recent_idx
  ON audit_log (ts DESC, id DESC);

-- Tiny filter-chip views. The frontend falls back to base tables if these
-- views have not been applied yet, but these are the preferred production path.
CREATE OR REPLACE VIEW app_categories AS
SELECT
  category,
  COUNT(*)::INT AS app_count
FROM apps
WHERE
  cost_allowed = TRUE
  AND licence_mode <> 'Paid or trial'
  AND NULLIF(category, '') IS NOT NULL
GROUP BY category
ORDER BY category;

CREATE OR REPLACE VIEW workflow_categories AS
SELECT
  category,
  COUNT(*)::INT AS workflow_count
FROM workflows
WHERE
  cost_allowed = TRUE
  AND NULLIF(category, '') IS NOT NULL
GROUP BY category
ORDER BY category;

GRANT SELECT ON dashboard_stats, app_categories, workflow_categories TO anon, authenticated;

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- ROW LEVEL SECURITY
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
ALTER TABLE apps              ENABLE ROW LEVEL SECURITY;
ALTER TABLE workflows         ENABLE ROW LEVEL SECURITY;
ALTER TABLE ollama_extractions ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_log         ENABLE ROW LEVEL SECURITY;

-- Public read (the Expo web app reads without auth)
CREATE POLICY "Public read apps"       ON apps              FOR SELECT USING (true);
CREATE POLICY "Public read workflows"  ON workflows         FOR SELECT USING (true);
CREATE POLICY "Public read audit"      ON audit_log         FOR SELECT USING (true);

-- Service role write (PowerShell uses the service_role key)
-- These policies allow the service_role to insert/update/delete
CREATE POLICY "Service write apps"     ON apps
  FOR ALL USING (auth.role() = 'service_role');
CREATE POLICY "Service write workflows" ON workflows
  FOR ALL USING (auth.role() = 'service_role');
CREATE POLICY "Service write extractions" ON ollama_extractions
  FOR ALL USING (auth.role() = 'service_role');
CREATE POLICY "Service write audit"    ON audit_log
  FOR ALL USING (auth.role() = 'service_role');

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- AUTO-UPDATED updated_at for apps
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
CREATE OR REPLACE FUNCTION touch_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END;
$$;

CREATE TRIGGER apps_updated_at
  BEFORE UPDATE ON apps
  FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- STATS VIEW (used by Dashboard screen)
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
CREATE OR REPLACE VIEW dashboard_stats AS
SELECT
  (SELECT COUNT(*) FROM apps)                           AS total_apps,
  (SELECT COUNT(*) FROM apps WHERE installed = TRUE)    AS installed_apps,
  (SELECT COUNT(*) FROM apps WHERE installed = FALSE)   AS missing_apps,
  (SELECT COUNT(*) FROM apps WHERE is_open_source)      AS open_source_apps,
  (SELECT COUNT(*) FROM workflows)                      AS total_workflows,
  (SELECT COUNT(*) FROM workflows WHERE combination_size = 2) AS two_app_workflows,
  (SELECT COUNT(*) FROM workflows WHERE combination_size = 3) AS three_app_workflows,
  (SELECT COUNT(*) FROM workflows WHERE combination_size = 4) AS four_app_workflows,
  (SELECT COUNT(*) FROM apps WHERE embedding IS NOT NULL)     AS apps_embedded,
  (SELECT COUNT(*) FROM workflows WHERE embedding IS NOT NULL) AS workflows_embedded,
  (SELECT COUNT(*) FROM ollama_extractions WHERE schema_valid) AS valid_extractions,
  now()                                                  AS generated_at;

-- PowerShell Gorilla â€” Checkpoint Queue System
-- Handles async batch processing of up to 400,000+ prompts
-- Provides transaction-ledger state tracking for resilience

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- BATCH JOBS TABLE
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- QUEUE ITEMS TABLE (transaction ledger)
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- BATCH CHECKPOINT TABLE (Resume-ability)
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- OLLAMA HEALTH & METRICS TABLE
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- FUNCTIONS: State Transitions
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- FUNCTION: Restart / Resume Batch recovery
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

-- Power Gorilla local/free-tier policy
-- Enforces the product rule: local-first, no paid subscriptions, free-tier only when needed.

ALTER TABLE apps
  ADD COLUMN IF NOT EXISTS cost_allowed BOOLEAN NOT NULL DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS cost_policy TEXT NOT NULL DEFAULT 'Local-first; no paid subscriptions; free-tier only when a cloud service is unavoidable.';

ALTER TABLE workflows
  ADD COLUMN IF NOT EXISTS cost_allowed BOOLEAN NOT NULL DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS cost_policy TEXT NOT NULL DEFAULT 'Local-first; no paid subscriptions; free-tier only when a cloud service is unavoidable.';

UPDATE apps
SET
  cost_allowed = FALSE,
  cost_policy = 'Blocked: paid, trial, commercial, premium, or subscription signal detected.'
WHERE
  licence_mode = 'Paid or trial'
  OR lower(coalesce(name, '') || ' ' || coalesce(category, '') || ' ' || coalesce(source, '') || ' ' || coalesce(sign_in_mode, ''))
     ~ '(paid|subscription|commercial|premium|pro plan|enterprise plan|adobe creative cloud|microsoft 365|office 365)';

UPDATE apps
SET cost_policy = 'Allowed: free, open-source, built-in, local, or free-tier.'
WHERE cost_allowed = TRUE;

UPDATE workflows
SET
  cost_allowed = FALSE,
  cost_policy = 'Blocked because one or more workflow apps are paid, trial, commercial, premium, or subscription-based.'
WHERE EXISTS (
  SELECT 1
  FROM unnest(workflows.app_names) AS workflow_app(name)
  JOIN apps ON lower(apps.name) = lower(workflow_app.name)
  WHERE apps.cost_allowed = FALSE
);

UPDATE workflows
SET cost_policy = 'Allowed: local-first, free, open-source, built-in, or free-tier.'
WHERE cost_allowed = TRUE;

CREATE INDEX IF NOT EXISTS apps_cost_allowed_idx ON apps (cost_allowed);
CREATE INDEX IF NOT EXISTS workflows_cost_allowed_idx ON workflows (cost_allowed);

CREATE OR REPLACE VIEW dashboard_stats AS
SELECT
  (SELECT COUNT(*) FROM apps WHERE cost_allowed = TRUE)                           AS total_apps,
  (SELECT COUNT(*) FROM apps WHERE installed = TRUE AND cost_allowed = TRUE)       AS installed_apps,
  (SELECT COUNT(*) FROM apps WHERE installed = FALSE AND cost_allowed = TRUE)      AS missing_apps,
  (SELECT COUNT(*) FROM apps WHERE is_open_source AND cost_allowed = TRUE)         AS open_source_apps,
  (SELECT COUNT(*) FROM workflows WHERE cost_allowed = TRUE)                      AS total_workflows,
  (SELECT COUNT(*) FROM workflows WHERE combination_size = 2 AND cost_allowed = TRUE) AS two_app_workflows,
  (SELECT COUNT(*) FROM workflows WHERE combination_size = 3 AND cost_allowed = TRUE) AS three_app_workflows,
  (SELECT COUNT(*) FROM workflows WHERE combination_size = 4 AND cost_allowed = TRUE) AS four_app_workflows,
  (SELECT COUNT(*) FROM apps WHERE embedding IS NOT NULL AND cost_allowed = TRUE)      AS apps_embedded,
  (SELECT COUNT(*) FROM workflows WHERE embedding IS NOT NULL AND cost_allowed = TRUE) AS workflows_embedded,
  (SELECT COUNT(*) FROM ollama_extractions WHERE schema_valid)                    AS valid_extractions,
  now()                                                                          AS generated_at;

CREATE OR REPLACE FUNCTION search_apps(
  query_embedding vector(768),
  match_count     INT DEFAULT 20,
  filter_installed BOOLEAN DEFAULT NULL
)
RETURNS TABLE (
  id          TEXT,
  name        TEXT,
  category    TEXT,
  status      TEXT,
  installed   BOOLEAN,
  licence_mode TEXT,
  icon_url    TEXT,
  similarity  FLOAT
)
LANGUAGE SQL STABLE AS $$
  SELECT
    id, name, category, status, installed, licence_mode, icon_url,
    1 - (embedding <=> query_embedding) AS similarity
  FROM apps
  WHERE
    embedding IS NOT NULL
    AND cost_allowed = TRUE
    AND (filter_installed IS NULL OR installed = filter_installed)
  ORDER BY embedding <=> query_embedding
  LIMIT match_count;
$$;

CREATE OR REPLACE FUNCTION search_workflows(
  query_embedding   vector(768),
  match_count       INT DEFAULT 20,
  filter_combo_size INT DEFAULT NULL
)
RETURNS TABLE (
  id               TEXT,
  workflow_name    TEXT,
  description      TEXT,
  category         TEXT,
  app_names        TEXT[],
  combination_size INTEGER,
  risk_level       TEXT,
  rank_score       NUMERIC,
  similarity       FLOAT
)
LANGUAGE SQL STABLE AS $$
  SELECT
    id, workflow_name, description, category, app_names,
    combination_size, risk_level, rank_score,
    1 - (embedding <=> query_embedding) AS similarity
  FROM workflows
  WHERE
    embedding IS NOT NULL
    AND cost_allowed = TRUE
    AND (filter_combo_size IS NULL OR combination_size = filter_combo_size)
  ORDER BY embedding <=> query_embedding
  LIMIT match_count;
$$;


