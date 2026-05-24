-- PowerShell Gorilla — Supabase Migration 001
-- Run this in the Supabase SQL Editor at: https://app.supabase.com
-- Project: powershell-gorrilla

-- ─────────────────────────────────────────────────────────────
-- Enable pgvector
-- ─────────────────────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS vector;

-- ─────────────────────────────────────────────────────────────
-- APPS TABLE
-- ─────────────────────────────────────────────────────────────
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

-- ─────────────────────────────────────────────────────────────
-- WORKFLOWS TABLE
-- ─────────────────────────────────────────────────────────────
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

-- ─────────────────────────────────────────────────────────────
-- OLLAMA EXTRACTIONS TABLE
-- ─────────────────────────────────────────────────────────────
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

-- ─────────────────────────────────────────────────────────────
-- AUDIT LOG (append-only ledger, mirrors gorledger)
-- ─────────────────────────────────────────────────────────────
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

-- ─────────────────────────────────────────────────────────────
-- VECTOR SEARCH FUNCTIONS
-- ─────────────────────────────────────────────────────────────
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

-- ─────────────────────────────────────────────────────────────
-- ROW LEVEL SECURITY
-- ─────────────────────────────────────────────────────────────
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

-- ─────────────────────────────────────────────────────────────
-- AUTO-UPDATED updated_at for apps
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION touch_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END;
$$;

CREATE TRIGGER apps_updated_at
  BEFORE UPDATE ON apps
  FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

-- ─────────────────────────────────────────────────────────────
-- STATS VIEW (used by Dashboard screen)
-- ─────────────────────────────────────────────────────────────
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
