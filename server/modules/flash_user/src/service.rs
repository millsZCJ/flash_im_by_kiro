use sqlx::PgPool;
use flash_core::User;

// ─── 查询 ────────────────────────────────────────────────────────────────────

/// 查询用户资料（包含 signature）
pub async fn get_user_profile(
    pool: &PgPool,
    account_id: i64,
) -> Result<Option<User>, sqlx::Error> {
    let row: Option<(i64, String, String, String, String)> = sqlx::query_as(
        "SELECT a.id, c.identifier, up.nickname, up.avatar, up.signature
         FROM accounts a
         JOIN user_profiles up  ON up.account_id = a.id
         JOIN auth_credentials c ON c.account_id = a.id AND c.auth_type = 'phone'
         WHERE a.id = $1 AND a.status = 0",
    )
    .bind(account_id)
    .fetch_optional(pool)
    .await?;

    Ok(row.map(|(user_id, phone, nickname, avatar, signature)| User {
        user_id,
        phone,
        nickname,
        avatar,
        signature,
    }))
}

/// 查询密码凭据（用于设置密码时检查是否已有密码、修改密码时验证原密码）
pub async fn get_password_credential(
    pool: &PgPool,
    account_id: i64,
) -> Result<Option<Option<String>>, sqlx::Error> {
    let row = sqlx::query_scalar::<_, Option<String>>(
        "SELECT credential FROM auth_credentials
         WHERE account_id = $1 AND auth_type = 'phone'",
    )
    .bind(account_id)
    .fetch_optional(pool)
    .await?;
    Ok(row)
}

// ─── 修改 ────────────────────────────────────────────────────────────────────

/// 更新用户资料（只更新传入的字段）
pub async fn update_nickname(pool: &PgPool, account_id: i64, nickname: &str) -> Result<(), sqlx::Error> {
    sqlx::query("UPDATE user_profiles SET nickname = $1, updated_at = NOW() WHERE account_id = $2")
        .bind(nickname).bind(account_id).execute(pool).await?;
    Ok(())
}

pub async fn update_avatar(pool: &PgPool, account_id: i64, avatar: &str) -> Result<(), sqlx::Error> {
    sqlx::query("UPDATE user_profiles SET avatar = $1, updated_at = NOW() WHERE account_id = $2")
        .bind(avatar).bind(account_id).execute(pool).await?;
    Ok(())
}

pub async fn update_signature(pool: &PgPool, account_id: i64, signature: &str) -> Result<(), sqlx::Error> {
    sqlx::query("UPDATE user_profiles SET signature = $1, updated_at = NOW() WHERE account_id = $2")
        .bind(signature).bind(account_id).execute(pool).await?;
    Ok(())
}

/// 设置密码（首次，写入 credential）
pub async fn set_password(pool: &PgPool, account_id: i64, hash: &str) -> Result<(), sqlx::Error> {
    sqlx::query(
        "UPDATE auth_credentials SET credential = $1, updated_at = NOW()
         WHERE account_id = $2 AND auth_type = 'phone'",
    ).bind(hash).bind(account_id).execute(pool).await?;
    Ok(())
}
