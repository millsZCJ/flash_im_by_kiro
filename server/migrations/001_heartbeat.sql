-- ============================================================================
-- 001_heartbeat.sql
-- 心跳功能模块的数据库表
-- ============================================================================

-- 创建心跳记录表
CREATE TABLE IF NOT EXISTS heartbeat_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    client_timestamp BIGINT NOT NULL,
    server_timestamp BIGINT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_heartbeat_records_user_id ON heartbeat_records(user_id);
CREATE INDEX IF NOT EXISTS idx_heartbeat_records_created_at ON heartbeat_records(created_at);

-- 添加注释
COMMENT ON TABLE heartbeat_records IS '心跳记录表';
COMMENT ON COLUMN heartbeat_records.user_id IS '用户ID';
COMMENT ON COLUMN heartbeat_records.client_timestamp IS '客户端时间戳（毫秒）';
COMMENT ON COLUMN heartbeat_records.server_timestamp IS '服务器时间戳（毫秒）';
COMMENT ON COLUMN heartbeat_records.created_at IS '记录创建时间';
