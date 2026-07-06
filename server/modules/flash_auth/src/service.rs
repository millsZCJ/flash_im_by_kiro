use sqlx::PgPool;
use chrono::{DateTime, Utc};
use flash_core::User;

/// 短信验证码查询结果
pub struct SmsCodeRow {
    pub code: String,
    pub expires_at: DateTime<Utc>,
}

/// 查询短信验证码
pub async fn get_sms_code(pool: &PgPool, phone: &str) -> Result<Option<SmsCodeRow>, sqlx::Error> {
    let row: Option<(String, DateTime<Utc>)> = sqlx::query_as(
        "SELECT code, expires_at FROM sms_codes WHERE phone = $1",
    )
    .bind(phone)
    .fetch_optional(pool)
    .await?;

    Ok(row.map(|(code, expires_at)| SmsCodeRow { code, expires_at }))
}

/// 插入或更新短信验证码（UPSERT）
pub async fn upsert_sms_code(
    pool: &PgPool,
    phone: &str,
    code: &str,
    expires_at: DateTime<Utc>,
) -> Result<(), sqlx::Error> {
    sqlx::query(
        "INSERT INTO sms_codes (phone, code, expires_at) VALUES ($1, $2, $3)
         ON CONFLICT (phone) DO UPDATE SET code = $2, expires_at = $3, created_at = NOW()",
    )
    .bind(phone)
    .bind(code)
    .bind(expires_at)
    .execute(pool)
    .await?;
    Ok(())
}

/// 删除短信验证码（防止重放）
pub async fn delete_sms_code(pool: &PgPool, phone: &str) -> Result<(), sqlx::Error> {
    sqlx::query("DELETE FROM sms_codes WHERE phone = $1")
        .bind(phone)
        .execute(pool)
        .await?;
    Ok(())
}

/// find_or_create_user 的返回值
pub struct FindOrCreateResult {
    pub account_id: i64,
    pub is_new_user: bool,
    pub has_password: bool,
}

/// 查找或创建用户（登录即注册）
pub async fn find_or_create_user(
    pool: &PgPool,
    phone: &str,
) -> Result<FindOrCreateResult, sqlx::Error> {
    let existing: Option<(i64, Option<String>)> = sqlx::query_as(
        "SELECT a.id, c.credential
         FROM accounts a
         JOIN auth_credentials c ON c.account_id = a.id AND c.auth_type = 'phone'
         WHERE c.identifier = $1 AND a.status = 0",
    )
    .bind(phone)
    .fetch_optional(pool)
    .await?;

    if let Some((account_id, credential)) = existing {
        return Ok(FindOrCreateResult {
            account_id,
            is_new_user: false,
            has_password: credential.is_some(),
        });
    }

    let mut tx = pool.begin().await?;

    let account_id: i64 = sqlx::query_scalar(
        "INSERT INTO accounts (status) VALUES (0) RETURNING id",
    )
    .fetch_one(&mut *tx)
    .await?;

    let nickname = phone.to_string();
    let avatar = format!("https://api.dicebear.com/7.x/thumbs/svg?seed={}", account_id);
    sqlx::query(
        "INSERT INTO user_profiles (account_id, nickname, avatar) VALUES ($1, $2, $3)",
    )
    .bind(account_id)
    .bind(&nickname)
    .bind(&avatar)
    .execute(&mut *tx)
    .await?;

    sqlx::query(
        "INSERT INTO auth_credentials (account_id, auth_type, identifier, credential)
         VALUES ($1, 'phone', $2, NULL)",
    )
    .bind(account_id)
    .bind(phone)
    .execute(&mut *tx)
    .await?;

    tx.commit().await?;

    Ok(FindOrCreateResult {
        account_id,
        is_new_user: true,
        has_password: false,
    })
}

/// 密码登录查询结果
pub struct PasswordLoginRow {
    pub account_id: i64,
    pub credential: String,
}

/// 根据 phone 查询密码凭据
pub async fn get_password_credential(
    pool: &PgPool,
    phone: &str,
) -> Result<Option<PasswordLoginRow>, sqlx::Error> {
    let row: Option<(i64, Option<String>)> = sqlx::query_as(
        "SELECT a.id, c.credential
         FROM accounts a
         JOIN auth_credentials c ON c.account_id = a.id AND c.auth_type = 'phone'
         WHERE c.identifier = $1 AND a.status = 0",
    )
    .bind(phone)
    .fetch_optional(pool)
    .await?;

    Ok(row.and_then(|(account_id, cred)| {
        cred.map(|credential| PasswordLoginRow { account_id, credential })
    }))
}

/// 更新密码凭据
pub async fn update_password(
    pool: &PgPool,
    account_id: i64,
    hash: &str,
) -> Result<(), sqlx::Error> {
    sqlx::query(
        "UPDATE auth_credentials SET credential = $1, updated_at = NOW()
         WHERE account_id = $2 AND auth_type = 'phone'",
    )
    .bind(hash)
    .bind(account_id)
    .execute(pool)
    .await?;
    Ok(())
}

/// 查询用户资料
pub async fn get_user_profile(
    pool: &PgPool,
    account_id: i64,
) -> Result<Option<User>, sqlx::Error> {
    let row: Option<(i64, String, String, String)> = sqlx::query_as(
        "SELECT a.id, c.identifier, up.nickname, up.avatar
         FROM accounts a
         JOIN user_profiles up  ON up.account_id = a.id
         JOIN auth_credentials c ON c.account_id = a.id AND c.auth_type = 'phone'
         WHERE a.id = $1 AND a.status = 0",
    )
    .bind(account_id)
    .fetch_optional(pool)
    .await?;

    Ok(row.map(|(user_id, phone, nickname, avatar)| User {
        user_id,
        phone,
        nickname,
        avatar,
    }))
}
