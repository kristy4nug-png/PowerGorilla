-- Phat Gorrilla local/free-tier policy
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
