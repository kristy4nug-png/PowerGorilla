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
