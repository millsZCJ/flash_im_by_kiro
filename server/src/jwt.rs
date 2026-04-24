use jsonwebtoken::{decode, encode, DecodingKey, EncodingKey, Header, Validation};
use serde::{Deserialize, Serialize};
use std::time::{SystemTime, UNIX_EPOCH};

/// 获取当前 Unix 时间戳（秒）
fn now_secs() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .expect("系统时间早于 UNIX_EPOCH")
        .as_secs()
}

// ─── JWT Payload（Claims）────────────────────────────────────────────────────

/// JWT 标准字段说明：
/// - `sub`  Subject，主体标识，这里存 user_id
/// - `iat`  Issued At，签发时间（Unix 时间戳，秒）
/// - `nbf`  Not Before，生效时间，早于此时间的 token 无效
/// - `exp`  Expiration，过期时间（Unix 时间戳，秒）
#[derive(Debug, Serialize, Deserialize)]
pub struct Claims {
    /// 用户 ID
    pub sub: String,
    /// 签发时间
    pub iat: usize,
    /// 生效时间（与签发时间相同，立即生效）
    pub nbf: usize,
    /// 过期时间
    pub exp: usize,
}

// ─── Token 生成 ───────────────────────────────────────────────────────────────

/// Token 有效期：7 天（秒）
const TOKEN_TTL_SECS: u64 = 7 * 24 * 3600;

/// 生成 JWT Token
///
/// - 签发时间（iat）= 当前时间
/// - 生效时间（nbf）= 当前时间（立即生效）
/// - 过期时间（exp）= 当前时间 + 7 天
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

// ─── Token 验证 ───────────────────────────────────────────────────────────────

/// 验证并解析 JWT Token，返回 Claims
///
/// 校验内容：
/// - 签名是否合法
/// - exp 是否过期
/// - nbf 是否已到生效时间
pub fn verify_token(token: &str, secret: &str) -> Result<Claims, jsonwebtoken::errors::Error> {
    let mut validation = Validation::default();
    // 同时校验 nbf（Not Before）字段
    validation.validate_nbf = true;

    let token_data = decode::<Claims>(
        token,
        &DecodingKey::from_secret(secret.as_bytes()),
        &validation,
    )?;

    Ok(token_data.claims)
}
