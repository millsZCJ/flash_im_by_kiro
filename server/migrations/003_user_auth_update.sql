-- ============================================================================
-- 003_user_auth_update.sql
-- 认证模块数据库表更新
-- ============================================================================

-- 1. 修改 users 表
-- 添加 phone 字段
ALTER TABLE users ADD COLUMN IF NOT EXISTS phone VARCHAR(20);

-- 将 username 和 email 改为可空
ALTER TABLE users ALTER COLUMN username DROP NOT NULL;
ALTER TABLE users ALTER COLUMN email DROP NOT NULL;

-- 设置 phone 为唯一约束
ALTER TABLE users ADD CONSTRAINT users_phone_key UNIQUE (phone);

-- 添加索引
CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone);

-- 添加注释
COMMENT ON COLUMN users.phone IS '手机号';
COMMENT ON COLUMN users.username IS '用户名（可空）';
COMMENT ON COLUMN users.email IS '邮箱（可空）';

-- 2. 创建 sms_codes 表
CREATE TABLE IF NOT EXISTS sms_codes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone VARCHAR(20) NOT NULL,
    code VARCHAR(6) NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_sms_codes_phone ON sms_codes(phone);
CREATE INDEX IF NOT EXISTS idx_sms_codes_expires_at ON sms_codes(expires_at);

-- 添加注释
COMMENT ON TABLE sms_codes IS '短信验证码表';
COMMENT ON COLUMN sms_codes.phone IS '手机号';
COMMENT ON COLUMN sms_codes.code IS '验证码（6位数字）';
COMMENT ON COLUMN sms_codes.expires_at IS '过期时间';
COMMENT ON COLUMN sms_codes.created_at IS '创建时间';
