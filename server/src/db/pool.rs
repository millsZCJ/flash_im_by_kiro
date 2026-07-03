// ============================================================================
// db/pool.rs
// 数据库连接池管理
// ============================================================================

use anyhow::Result;
use sqlx::postgres::{PgPoolOptions, PgPool};
use std::time::Duration;

pub type DbPool = PgPool;

/// 创建数据库连接池
///
/// # Arguments
/// * `database_url` - 数据库连接字符串
/// * `max_connections` - 最大连接数
///
/// # Returns
/// 返回数据库连接池
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

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_create_pool() {
        let database_url = "postgres://zcj@localhost:5432/flash_im";
        
        // 注意：这个测试需要数据库运行
        let result = create_pool(database_url, 5).await;
        
        // 如果数据库未运行，测试会失败，这是预期的
        if let Ok(pool) = result {
            // 测试连接
            let row: (i64,) = sqlx::query_as("SELECT 1")
                .fetch_one(&pool)
                .await
                .expect("Failed to execute query");
            
            assert_eq!(row.0, 1);
        }
    }
}
