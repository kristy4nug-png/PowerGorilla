-- PowerShell Gorilla — Integration Actions Table
-- Stores user-defined and default actions for integration apps
-- Supports open, search, pin, favourite, remove, and custom actions

CREATE TABLE IF NOT EXISTS integration_actions (
  id                    UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id               UUID         NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  integration_app_id    UUID         NOT NULL REFERENCES integration_apps(id) ON DELETE CASCADE,
  
  -- Action metadata
  action_id             TEXT         NOT NULL,  -- 'open', 'search', 'pin', 'favourite', 'remove', etc.
  label                 TEXT         NOT NULL,  -- Display label for button/menu
  description           TEXT,        -- Tooltip or help text
  
  -- Action type
  action_type           TEXT         NOT NULL
                        CHECK (action_type IN (
                        'open_url', 'open_url_template', 'open_app',
                        'search_online', 'update_preference', 'copy_text',
                        'custom_command'
                        )),
  
  -- Target/Config
  target                TEXT,        -- URL, command, preference key, etc.
  params                JSONB,       -- Additional config: timeout, retry, sandbox_level
  
  -- UI & Display
  icon_emoji            TEXT,        -- 🔵, 🔍, 📌, ⭐, ❌
  button_color          TEXT         DEFAULT 'primary',
  button_size           TEXT         DEFAULT 'medium',
  is_destructive        BOOLEAN      DEFAULT FALSE,
  is_default            BOOLEAN      DEFAULT FALSE,
  confirm_before_action BOOLEAN      DEFAULT FALSE,
  
  -- Validation & Safety
  requires_review       BOOLEAN      DEFAULT FALSE,
  requires_auth         BOOLEAN      DEFAULT FALSE,
  max_executions_per_day INTEGER,
  
  -- Metadata
  order_index           INTEGER      NOT NULL DEFAULT 0,
  is_enabled            BOOLEAN      NOT NULL DEFAULT TRUE,
  times_executed        INTEGER      DEFAULT 0,
  last_executed         TIMESTAMPTZ,
  
  created_at            TIMESTAMPTZ  NOT NULL DEFAULT now(),
  updated_at            TIMESTAMPTZ  NOT NULL DEFAULT now(),
  
  -- Constraint: user_id + integration_app_id + action_id must be unique
  CONSTRAINT unique_user_app_action UNIQUE (user_id, integration_app_id, action_id)
);

-- Indexes
CREATE INDEX idx_integration_actions_user_id ON integration_actions(user_id);
CREATE INDEX idx_integration_actions_app_id ON integration_actions(user_id, integration_app_id);
CREATE INDEX idx_integration_actions_type ON integration_actions(action_type);
CREATE INDEX idx_integration_actions_enabled ON integration_actions(user_id, is_enabled, order_index);

-- RLS: Users can only see and manage their own actions
ALTER TABLE integration_actions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own actions"
  ON integration_actions
  FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own actions"
  ON integration_actions
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own actions"
  ON integration_actions
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own actions"
  ON integration_actions
  FOR DELETE
  USING (auth.uid() = user_id);

-- Trigger: auto-update updated_at
CREATE OR REPLACE FUNCTION update_integration_actions_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER integration_actions_timestamp_trigger
  BEFORE UPDATE ON integration_actions
  FOR EACH ROW
  EXECUTE FUNCTION update_integration_actions_timestamp();

-- Trigger: log action executions
CREATE OR REPLACE FUNCTION log_integration_action_execution()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'UPDATE' AND NEW.last_executed IS DISTINCT FROM OLD.last_executed THEN
    INSERT INTO audit_log (type, message, actor, data)
    VALUES (
      'integration_action_executed',
      'Action executed',
      'integration-system',
      jsonb_build_object(
        'user_id', NEW.user_id,
        'integration_app_id', NEW.integration_app_id,
        'action_id', NEW.action_id,
        'times_executed', NEW.times_executed,
        'timestamp', NEW.last_executed
      )
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER log_integration_action_execution_trigger
  AFTER UPDATE ON integration_actions
  FOR EACH ROW
  EXECUTE FUNCTION log_integration_action_execution();

-- View: get enabled actions for an integration, sorted by order
CREATE OR REPLACE VIEW integration_app_actions_enabled AS
SELECT
  ia.id,
  ia.user_id,
  ia.integration_app_id,
  ia.action_id,
  ia.label,
  ia.action_type,
  ia.target,
  ia.icon_emoji,
  ia.button_color,
  ia.order_index
FROM integration_actions ia
WHERE ia.is_enabled = TRUE
ORDER BY ia.order_index ASC;
