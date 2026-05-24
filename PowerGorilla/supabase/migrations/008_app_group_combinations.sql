-- supabase/migrations/008_app_group_combinations.sql
-- Support for user-created app groups/combinations (2-4 apps per group)
-- Enables custom themed sections like "Shopping", "Music", "Dev Tools"

CREATE TABLE IF NOT EXISTS app_group_combinations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  icon_emoji TEXT NOT NULL DEFAULT '⭐',
  color TEXT NOT NULL DEFAULT '#6366F1',
  app_ids UUID[] NOT NULL,
  description TEXT,
  order_index INT DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  
  CONSTRAINT valid_app_count CHECK (array_length(app_ids, 1) >= 2 AND array_length(app_ids, 1) <= 4),
  CONSTRAINT unique_user_group_name UNIQUE (user_id, name),
  CONSTRAINT valid_emoji CHECK (emoji ~ '^[^\x00-\x1F]*$'),
  CONSTRAINT valid_color CHECK (color ~ '^#[0-9A-Fa-f]{6}$')
);

-- Row-Level Security: Only users can see/modify their own groups
ALTER TABLE app_group_combinations ENABLE ROW LEVEL SECURITY;

CREATE POLICY app_group_select
  ON app_group_combinations FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY app_group_insert
  ON app_group_combinations FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY app_group_update
  ON app_group_combinations FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY app_group_delete
  ON app_group_combinations FOR DELETE
  USING (auth.uid() = user_id);

-- Auto-update timestamp
CREATE TRIGGER update_app_group_combinations_timestamp
  BEFORE UPDATE ON app_group_combinations
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Index for faster lookups
CREATE INDEX idx_app_groups_user_id ON app_group_combinations(user_id);
CREATE INDEX idx_app_groups_order ON app_group_combinations(user_id, order_index);

-- Audit logging for group operations
CREATE TRIGGER audit_app_group_combinations_insert
  AFTER INSERT ON app_group_combinations
  FOR EACH ROW
  EXECUTE FUNCTION audit_log_insert();

CREATE TRIGGER audit_app_group_combinations_update
  AFTER UPDATE ON app_group_combinations
  FOR EACH ROW
  EXECUTE FUNCTION audit_log_update();

CREATE TRIGGER audit_app_group_combinations_delete
  AFTER DELETE ON app_group_combinations
  FOR EACH ROW
  EXECUTE FUNCTION audit_log_delete();
