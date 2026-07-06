use anyhow::Result;
use sqlx::postgres::{PgPoolOptions, PgPool};
use std::time::Duration;

pub type DbPool = PgPool;

/// 创建数据库连接池
pub async fn create_pool(database_url: &str, max_connections: u32) -> Result<DbPool> {
    let pool = PgPoolOptions::new()
        .max_connections(max_connections)
        .acquire_timeout(Duration::from_secs(5))
        .connect(database_url)
        .await?;

    Ok(pool)
}

/// 创建测试用的数据库连接池
pub async fn create_test_pool(database_url: &str) -> Result<DbPool> {
    create_pool(database_url, 5).await
}
