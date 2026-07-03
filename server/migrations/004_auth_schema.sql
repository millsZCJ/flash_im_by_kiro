-- ============================================================================
-- 004_auth_schema.sql
-- Auth 模块 — 按 design.md 重新设计认证表结构
-- 4 张表：accounts / user_profiles / auth_credentials / sms_codes
-- ============================================================================

-- 清理旧表（002/003 迁移创建的旧 schema）
DROP TABLE IF EXISTS sms_codes;
DROP TABLE IF EXISTS sessions;
DROP TABLE IF EXISTS users;

-- ─── accounts：账户主体 ───────────────────────────────────────────────────────
-- BIGSERIAL 主键，status 预留封禁/注销
CREATE TABLE IF NOT EXISTS accounts (
    id         BIGSERIAL PRIMARY KEY,
    status     SMALLINT      NOT NULL DEFAULT 0,   -- 0=正常, 1=封禁, 2=注销
    created_at TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

-- ─── user_profiles：用户资料（1:1 accounts）──────────────────────────────────
CREATE TABLE IF NOT EXISTS user_profiles (
    account_id BIGINT        PRIMARY KEY REFERENCES accounts(id) ON DELETE CASCADE,
    nickname   VARCHAR(100)  NOT NULL,
    avatar     TEXT          NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

-- ─── auth_credentials：认证凭据（1:N accounts）───────────────────────────────
-- UNIQUE(auth_type, identifier) 确保同一类型下标识符唯一
CREATE TABLE IF NOT EXISTS auth_credentials (
    id         BIGSERIAL     PRIMARY KEY,
    account_id BIGINT        NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    auth_type  VARCHAR(20)   NOT NULL,              -- 'phone', 'email' ...
    identifier VARCHAR(100)  NOT NULL,              -- 手机号 / 邮箱
    credential TEXT,                                -- 密码哈希，NULL = 未设置密码
    created_at TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    UNIQUE(auth_type, identifier)
);

-- ─── sms_codes：短信验证码（phone 主键，带过期时间）──────────────────────────
CREATE TABLE IF NOT EXISTS sms_codes (
    phone      VARCHAR(20)   PRIMARY KEY,
    code       VARCHAR(6)    NOT NULL,
    expires_at TIMESTAMPTZ   NOT NULL,
    created_at TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

-- ─── 索引 ─────────────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_auth_credentials_account_id ON auth_credentials(account_id);
CREATE INDEX IF NOT EXISTS idx_user_profiles_nickname      ON user_profiles(nickname);

-- ─── 注释 ─────────────────────────────────────────────────────────────────────
COMMENT ON TABLE accounts IS '账户主体表';
COMMENT ON COLUMN accounts.status IS '0=正常, 1=封禁, 2=注销';

COMMENT ON TABLE user_profiles IS '用户资料表（1:1 accounts）';

COMMENT ON TABLE auth_credentials IS '认证凭据表（1:N accounts）';
COMMENT ON COLUMN auth_credentials.auth_type   IS '认证类型: phone, email';
COMMENT ON COLUMN auth_credentials.identifier  IS '标识符: 手机号/邮箱';
COMMENT ON COLUMN auth_credentials.credential  IS '密码哈希，NULL 表示未设置密码';

COMMENT ON TABLE sms_codes IS '短信验证码表';
COMMENT ON COLUMN sms_codes.expires_at IS '过期时间';
