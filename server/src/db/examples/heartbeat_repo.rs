// ============================================================================
// db/examples/heartbeat_repo.rs
// 心跳记录数据库操作示例
// ============================================================================

use anyhow::Result;
use sqlx::PgPool;
use uuid::Uuid;
use chrono::{DateTime, Utc};

/// 心跳记录
#[derive(Debug, Clone, sqlx::FromRow)]
pub struct HeartbeatRecord {
    pub id: Uuid,
    pub user_id: Uuid,
    pub client_timestamp: i64,
    pub server_timestamp: i64,
    pub created_at: DateTime<Utc>,
}

/// 创建心跳记录
pub async fn create_heartbeat(
    pool: &PgPool,
    user_id: Uuid,
    client_timestamp: i64,
    server_timestamp: i64,
) -> Result<HeartbeatRecord> {
    let record = sqlx::query_as::<_, HeartbeatRecord>(
        r#"
        INSERT INTO heartbeat_records (user_id, client_timestamp, server_timestamp)
        VALUES ($1, $2, $3)
        RETURNING *
        "#,
    )
    .bind(user_id)
    .bind(client_timestamp)
    .bind(server_timestamp)
    .fetch_one(pool)
    .await?;

    Ok(record)
}

/// 获取用户的心跳记录
pub async fn get_user_heartbeats(
    pool: &PgPool,
    user_id: Uuid,
    limit: i64,
) -> Result<Vec<HeartbeatRecord>> {
    let records = sqlx::query_as::<_, HeartbeatRecord>(
        r#"
        SELECT * FROM heartbeat_records
        WHERE user_id = $1
        ORDER BY created_at DESC
        LIMIT $2
        "#,
    )
    .bind(user_id)
    .bind(limit)
    .fetch_all(pool)
    .await?;

    Ok(records)
}

/// 清理过期的记录（保留最近 N 天）
pub async fn cleanup_old_records(pool: &PgPool, days_to_keep: i32) -> Result<u64> {
    let result = sqlx::query(
        r#"
        DELETE FROM heartbeat_records
        WHERE created_at < NOW() - INTERVAL '1 day' * $1
        "#,
    )
    .bind(days_to_keep)
    .execute(pool)
    .await?;

    Ok(result.rows_affected())
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::db::create_test_pool;

    #[tokio::test]
    async fn test_heartbeat_crud() {
        let database_url = std::env::var("DATABASE_URL")
            .unwrap_or_else(|_| "postgres://postgres@localhost:5432/flash_im".to_string());
        
        let pool = create_test_pool(&database_url)
            .await
            .expect("Failed to create pool");

        let user_id = Uuid::new_v4();
        let client_ts = chrono::Utc::now().timestamp_millis();
        let server_ts = client_ts + 10;

        // 创建
        let record = create_heartbeat(&pool, user_id, client_ts, server_ts)
            .await
            .expect("Failed to create heartbeat");
        
        assert_eq!(record.user_id, user_id);
        assert_eq!(record.client_timestamp, client_ts);

        // 查询
        let records = get_user_heartbeats(&pool, user_id, 10)
            .await
            .expect("Failed to get heartbeats");
        
        assert!(!records.is_empty());

        // 清理
        let deleted = cleanup_old_records(&pool, 0)
            .await
            .expect("Failed to cleanup");
        
        assert!(deleted > 0);
    }
}
