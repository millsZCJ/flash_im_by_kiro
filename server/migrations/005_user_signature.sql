-- ============================================================================
-- 005_user_signature.sql
-- user_profiles 新增 signature 字段（个性签名）
-- ============================================================================

ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS signature VARCHAR(100) NOT NULL DEFAULT '';

COMMENT ON COLUMN user_profiles.signature IS '个性签名，默认空字符串，最长 100 字符';
