use jsonwebtoken::{decode, encode, DecodingKey, EncodingKey, Header, Validation};
use serde::{Deserialize, Serialize};
use std::time::{SystemTime, UNIX_EPOCH};
use axum::http::{HeaderMap, StatusCode};

/// 获取当前 Unix 时间戳（秒）
fn now_secs() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .expect("系统时间早于 UNIX_EPOCH")
        .as_secs()
}

/// JWT Payload（Claims）
#[derive(Debug, Serialize, Deserialize)]
pub struct Claims {
    /// 用户 ID
    pub sub: String,
    /// 签发时间
    pub iat: usize,
    /// 生效时间
    pub nbf: usize,
    /// 过期时间
    pub exp: usize,
}

/// Token 有效期：7 天（秒）
const TOKEN_TTL_SECS: u64 = 7 * 24 * 3600;

/// 生成 JWT Token
pub fn generate_token(user_id: &str, secret: &str) -> Result<String, jsonwebtoken::errors::Error> {
    let now = now_secs() as usize;
    let exp = (now_secs() + TOKEN_TTL_SECS) as usize;

    let claims = Claims {
        sub: user_id.to_string(),
        iat: now,
        nbf: now,
        exp,
    };

    encode(
        &Header::default(),
        &claims,
        &EncodingKey::from_secret(secret.as_bytes()),
    )
}

/// 验证并解析 JWT Token，返回 Claims
pub fn verify_token(token: &str, secret: &str) -> Result<Claims, jsonwebtoken::errors::Error> {
    let mut validation = Validation::default();
    validation.validate_nbf = true;

    let token_data = decode::<Claims>(
        token,
        &DecodingKey::from_secret(secret.as_bytes()),
        &validation,
    )?;

    Ok(token_data.claims)
}

/// 从 Authorization header 解析 Token，返回 account_id
///
/// 供 flash_auth、flash_user 等模块共用，消除重复实现。
/// jwt_secret 由调用方传入（各模块的 State 中持有）。
pub fn extract_user_id(headers: &HeaderMap, jwt_secret: &str) -> Result<i64, StatusCode> {
    let token = headers
        .get("Authorization")
        .or_else(|| headers.get("authorization"))
        .and_then(|v| v.to_str().ok())
        .and_then(|v| v.strip_prefix("Bearer "))
        .ok_or(StatusCode::UNAUTHORIZED)?;

    let claims = verify_token(token, jwt_secret).map_err(|_| StatusCode::UNAUTHORIZED)?;
    claims.sub.parse::<i64>().map_err(|_| StatusCode::UNAUTHORIZED)
}
