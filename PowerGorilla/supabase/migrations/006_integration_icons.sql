-- PowerShell Gorilla — Integration Icons Table
-- Stores icon metadata and cache info for integration apps
-- Supports multiple icon sources and fallback chains

CREATE TABLE IF NOT EXISTS integration_icons (
  id                    UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id               UUID         NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- Icon metadata
  source_type           TEXT         NOT NULL
                        CHECK (source_type IN (
                        'simple_icons', 'iconify', 'official_favicon',
                        'tabler_fallback', 'generated_fallback', 'exe_embedded',
                        'user_uploaded'
                        )),
  source_url            TEXT,
  source_slug           TEXT,         -- e.g., 'spotify', 'vscode'
  
  -- Cache info
  cached_data_uri       TEXT,         -- base64 embedded SVG or PNG data URI
  cached_at             TIMESTAMPTZ,
  cache_expires_at      TIMESTAMPTZ,
  file_hash             TEXT,         -- SHA256 of icon for dedup
  
  -- Metadata
  fallback_chain        TEXT[],       -- array of icon strategies tried
  fallback_used         INTEGER,      -- which strategy in chain was successful (0-indexed)
  is_placeholder        BOOLEAN       DEFAULT FALSE,
  
  -- License & source notes
  license_type          TEXT,         -- 'CC0', 'MIT', 'proprietary', etc.
  license_url           TEXT,
  source_notes          TEXT,
  
  -- Stats
  times_used            INTEGER       DEFAULT 0,
  last_used             TIMESTAMPTZ,
  
  created_at            TIMESTAMPTZ   NOT NULL DEFAULT now(),
  updated_at            TIMESTAMPTZ   NOT NULL DEFAULT now(),
  
  -- Constraint: user_id + source_type + source_slug must be unique
  CONSTRAINT unique_user_icon_source UNIQUE (user_id, source_type, source_slug)
);

-- Indexes
CREATE INDEX idx_integration_icons_user_id ON integration_icons(user_id);
CREATE INDEX idx_integration_icons_hash ON integration_icons(file_hash);
CREATE INDEX idx_integration_icons_source ON integration_icons(source_type, source_slug);
CREATE INDEX idx_integration_icons_expires ON integration_icons(cache_expires_at) WHERE cache_expires_at IS NOT NULL;

-- RLS: Users can only see and manage their own icons
ALTER TABLE integration_icons ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own icons"
  ON integration_icons
  FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own icons"
  ON integration_icons
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own icons"
  ON integration_icons
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own icons"
  ON integration_icons
  FOR DELETE
  USING (auth.uid() = user_id);

-- Trigger: auto-update updated_at
CREATE OR REPLACE FUNCTION update_integration_icons_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER integration_icons_timestamp_trigger
  BEFORE UPDATE ON integration_icons
  FOR EACH ROW
  EXECUTE FUNCTION update_integration_icons_timestamp();

-- View: get the best available icon for an app
CREATE OR REPLACE VIEW best_integration_icons AS
SELECT DISTINCT ON (user_id, source_slug)
  id,
  user_id,
  source_slug,
  source_type,
  cached_data_uri,
  is_placeholder,
  created_at
FROM integration_icons
WHERE cached_data_uri IS NOT NULL
ORDER BY user_id, source_slug, is_placeholder ASC, created_at DESC;
