-- ============================================================
-- SIPELOR Security Hardening — Required DB Migrations
-- Run these in your Supabase SQL Editor (in order)
-- ============================================================

-- 1. Rate Limit Log (used by Edge Function: supabase/functions/rate-limit/)
CREATE TABLE IF NOT EXISTS rate_limit_log (
  id           BIGSERIAL PRIMARY KEY,
  key          TEXT        NOT NULL,
  action       TEXT        NOT NULL,
  attempted_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_rate_limit_key_action_time
  ON rate_limit_log (key, action, attempted_at);

-- 2. Moderation Logs (used by ContentModerationService.logBlockedAttempt)
CREATE TABLE IF NOT EXISTS moderation_logs (
  id              BIGSERIAL PRIMARY KEY,
  user_id         UUID        REFERENCES auth.users(id) ON DELETE SET NULL,
  blocked_content TEXT,
  context         TEXT        DEFAULT 'chat',
  attempted_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_moderation_user ON moderation_logs (user_id, attempted_at);

-- 3. Audit Logs (used by AuditService — already exists, ensure schema is correct)
CREATE TABLE IF NOT EXISTS audit_logs (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID        REFERENCES auth.users(id) ON DELETE SET NULL,
  user_name   TEXT,
  action      TEXT        NOT NULL,
  entity_type TEXT        NOT NULL,
  entity_id   TEXT,
  changes     JSONB,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_audit_logs_user  ON audit_logs (user_id, created_at);
CREATE INDEX IF NOT EXISTS idx_audit_logs_entity ON audit_logs (entity_type, entity_id);

-- 4. RLS Policies (restrict access to service_role only for security tables)
ALTER TABLE rate_limit_log  ENABLE ROW LEVEL SECURITY;
ALTER TABLE moderation_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs      ENABLE ROW LEVEL SECURITY;

-- Only service_role (Edge Function / server) can read/write these tables
CREATE POLICY "service_role_only_rate_limit"
  ON rate_limit_log FOR ALL TO service_role USING (true);

CREATE POLICY "service_role_only_moderation"
  ON moderation_logs FOR ALL TO service_role USING (true);

CREATE POLICY "admin_read_audit_logs"
  ON audit_logs FOR SELECT
  USING (auth.jwt() ->> 'role' IN ('admin', 'super_admin'));

CREATE POLICY "service_role_write_audit"
  ON audit_logs FOR INSERT TO service_role WITH CHECK (true);
