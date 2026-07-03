// ============================================================================
// config.rs
// 应用配置管理
// ============================================================================

use anyhow::Result;

/// 应用配置
#[derive(Debug, Clone)]
pub struct Config {
    /// 数据库连接字符串
    pub database_url: String,
    /// JWT 签名密钥
    pub jwt_secret: String,
    /// 验证码有效期（秒）
    pub sms_code_ttl: u64,
    /// Token 有效期（秒）
    pub token_ttl: u64,
    /// 数据库连接池大小
    pub db_pool_size: u32,
    /// 服务器端口
    pub server_port: u16,
}

impl Config {
    /// 从环境变量加载配置
    pub fn from_env() -> Result<Self> {
        Ok(Self {
            database_url: std::env::var("DATABASE_URL")
                .unwrap_or_else(|_| "postgres://zcj@localhost:5432/flash_im".to_string()),
            jwt_secret: std::env::var("JWT_SECRET")
                .unwrap_or_else(|_| "flash_im_dev_secret_2026".to_string()),
            sms_code_ttl: std::env::var("SMS_CODE_TTL")
                .unwrap_or_else(|_| "300".to_string())
                .parse()?,
            token_ttl: std::env::var("TOKEN_TTL")
                .unwrap_or_else(|_| "604800".to_string()) // 7 天
                .parse()?,
            db_pool_size: std::env::var("DB_POOL_SIZE")
                .unwrap_or_else(|_| "10".to_string())
                .parse()?,
            server_port: std::env::var("SERVER_PORT")
                .unwrap_or_else(|_| "3000".to_string())
                .parse()?,
        })
    }
}

impl Default for Config {
    fn default() -> Self {
        Self {
            database_url: "postgres://zcj@localhost:5432/flash_im".to_string(),
            jwt_secret: "flash_im_dev_secret_2026".to_string(),
            sms_code_ttl: 300,
            token_ttl: 604800,
            db_pool_size: 10,
            server_port: 3000,
        }
    }
}
