-- PowerShell Gorilla — Integration Apps Table
-- Stores discovered and integrated apps (online + desktop)
-- User-owned, RLS enabled, additive to existing app catalog

CREATE TABLE IF NOT EXISTS integration_apps (
  id                    UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id               UUID         NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name                  TEXT         NOT NULL,
  slug                  TEXT         NOT NULL,
  app_type              TEXT         NOT NULL
                        CHECK (app_type IN ('online', 'desktop', 'hybrid')),
  category              TEXT         NOT NULL DEFAULT 'Uncategorized',
  
  -- Online app fields
  official_url          TEXT,
  launch_url            TEXT,
  requires_login        BOOLEAN      DEFAULT FALSE,
  requires_payment      BOOLEAN      DEFAULT FALSE,
  free_tier_available   BOOLEAN      DEFAULT TRUE,
  
  -- Desktop app fields
  exe_path              TEXT,
  shortcut_path         TEXT,
  launch_command        TEXT,
  publisher             TEXT,
  
  -- Common fields
  icon_id               UUID         REFERENCES integration_icons(id) ON DELETE SET NULL,
  icon_source           TEXT         CHECK (icon_source IN (
                        'user_selected', 'simple_icons', 'iconify', 'official_favicon',
                        'tabler_fallback', 'generated_fallback', 'exe_embedded'
                        )),
  
  -- Metadata
  confidence            NUMERIC(3,2) NOT NULL DEFAULT 0.95
                        CHECK (confidence BETWEEN 0 AND 1),
  safe_to_launch        BOOLEAN      NOT NULL DEFAULT TRUE,
  needs_review          BOOLEAN      NOT NULL DEFAULT FALSE,
  review_notes          TEXT,
  
  -- UI state
  is_pinned             BOOLEAN      NOT NULL DEFAULT FALSE,
  is_hidden             BOOLEAN      NOT NULL DEFAULT FALSE,
  custom_label          TEXT,
  
  -- Timestamps
  created_at            TIMESTAMPTZ  NOT NULL DEFAULT now(),
  updated_at            TIMESTAMPTZ  NOT NULL DEFAULT now(),
  last_launched         TIMESTAMPTZ,
  
  -- Constraint: user_id + slug must be unique per user
  CONSTRAINT unique_user_app_slug UNIQUE (user_id, slug)
);

-- Indexes for common queries
CREATE INDEX idx_integration_apps_user_id ON integration_apps(user_id);
CREATE INDEX idx_integration_apps_user_category ON integration_apps(user_id, category);
CREATE INDEX idx_integration_apps_user_pinned ON integration_apps(user_id, is_pinned);
CREATE INDEX idx_integration_apps_app_type ON integration_apps(user_id, app_type);
CREATE INDEX idx_integration_apps_created ON integration_apps(user_id, created_at DESC);

-- FTS index for name search
CREATE INDEX idx_integration_apps_search ON integration_apps USING gin(to_tsvector('english', name));

-- RLS: Users can only see and modify their own integrations
ALTER TABLE integration_apps ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own integrations"
  ON integration_apps
  FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own integrations"
  ON integration_apps
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own integrations"
  ON integration_apps
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own integrations"
  ON integration_apps
  FOR DELETE
  USING (auth.uid() = user_id);

-- Trigger: auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_integration_apps_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER integration_apps_timestamp_trigger
  BEFORE UPDATE ON integration_apps
  FOR EACH ROW
  EXECUTE FUNCTION update_integration_apps_timestamp();

-- Audit logging: log app integrations
CREATE OR REPLACE FUNCTION audit_integration_app_change()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO audit_log (type, message, actor, data)
  VALUES (
    'integration_app_' || TG_OP,
    COALESCE(NEW.name, OLD.name) || ' (' || COALESCE(NEW.app_type, OLD.app_type) || ')',
    'integration-system',
    jsonb_build_object(
      'user_id', COALESCE(NEW.user_id, OLD.user_id),
      'app_id', COALESCE(NEW.id, OLD.id),
      'app_type', COALESCE(NEW.app_type, OLD.app_type),
      'operation', TG_OP
    )
  );
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER audit_integration_app_trigger
  AFTER INSERT OR UPDATE OR DELETE ON integration_apps
  FOR EACH ROW
  EXECUTE FUNCTION audit_integration_app_change();
