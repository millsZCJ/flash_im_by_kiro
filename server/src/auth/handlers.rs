// ============================================================================
// auth/handlers.rs
// 认证 HTTP 处理器 — 全部接入 PostgreSQL
// ============================================================================

use axum::{
    extract::State,
    http::{HeaderMap, StatusCode},
    Json,
};
use rand::Rng;

use crate::{jwt::generate_token, jwt::verify_token, state::AppState};

use super::models::{
    LoginRequest, LoginResponse, LoginType, MessageResponse, PasswordRequest, SmsRequest,
    SmsResponse,
};
use super::service;

// ─── 工具函数 ─────────────────────────────────────────────────────────────────

/// 校验手机号格式（11 位，1 开头）
fn is_valid_phone(phone: &str) -> bool {
    phone.len() == 11 && phone.starts_with('1') && phone.chars().all(|c| c.is_ascii_digit())
}

/// 从 Authorization header 解析 Token，返回 account_id
fn extract_user_id(
    headers: &HeaderMap,
    jwt_secret: &str,
) -> Result<i64, StatusCode> {
    let token = headers
        .get("Authorization")
        .or_else(|| headers.get("authorization"))
        .and_then(|v| v.to_str().ok())
        .and_then(|v| v.strip_prefix("Bearer "))
        .ok_or(StatusCode::UNAUTHORIZED)?;

    let claims = verify_token(token, jwt_secret).map_err(|_| StatusCode::UNAUTHORIZED)?;

    claims.sub.parse::<i64>().map_err(|_| StatusCode::UNAUTHORIZED)
}

// ─── POST /auth/sms — 发送验证码 ──────────────────────────────────────────────

pub async fn send_sms(
    State(state): State<AppState>,
    Json(body): Json<SmsRequest>,
) -> Result<Json<SmsResponse>, StatusCode> {
    // 1. 校验手机号格式
    if !is_valid_phone(&body.phone) {
        println!("[SMS] 手机号格式不合法：{}", body.phone);
        return Err(StatusCode::BAD_REQUEST);
    }

    // 2. 生成 6 位随机数字验证码
    let code: String = rand::thread_rng()
        .sample_iter(rand::distributions::Uniform::new(0, 10))
        .take(6)
        .map(|d| d.to_string())
        .collect();

    // 3. 过期时间 5 分钟后
    let expires_at = chrono::Utc::now() + chrono::Duration::minutes(5);

    // 4. 写入数据库（UPSERT 覆盖旧验证码）
    if let Err(e) = service::upsert_sms_code(&state.db, &body.phone, &code, expires_at).await {
        println!("[SMS] 写入验证码失败：{}", e);
        return Err(StatusCode::INTERNAL_SERVER_ERROR);
    }

    println!("[SMS] 手机号 {} 的验证码：{}", body.phone, code);

    // 5. 返回验证码（测试阶段直接返回，生产环境改为发短信）
    Ok(Json(SmsResponse {
        code,
        message: "验证码已发送（playground 模式，直接返回）".to_string(),
    }))
}

// ─── POST /auth/login — 统一登录入口 ──────────────────────────────────────────

pub async fn login(
    State(state): State<AppState>,
    Json(body): Json<LoginRequest>,
) -> Result<Json<LoginResponse>, StatusCode> {
    match body.login_type {
        LoginType::Sms => login_with_sms(&state, body).await,
        LoginType::Password => login_with_password(&state, body).await,
    }
}

/// 短信验证码登录（登录即注册）
async fn login_with_sms(
    state: &AppState,
    body: LoginRequest,
) -> Result<Json<LoginResponse>, StatusCode> {
    let phone = &body.phone;
    let code = body.code.as_deref().ok_or_else(|| {
        println!("[AUTH] 短信登录缺少验证码：phone={}", phone);
        StatusCode::BAD_REQUEST
    })?;

    // 1. 查 sms_codes 表
    let sms_row = service::get_sms_code(&state.db, phone)
        .await
        .map_err(|e| {
            println!("[AUTH] 查询验证码失败：{}", e);
            StatusCode::INTERNAL_SERVER_ERROR
        })?;

    match sms_row {
        None => {
            println!("[AUTH] 验证码不存在：phone={}", phone);
            return Err(StatusCode::UNAUTHORIZED);
        }
        Some(row) => {
            // 校验验证码和过期时间
            if row.code != code {
                println!("[AUTH] 验证码错误：phone={}", phone);
                return Err(StatusCode::UNAUTHORIZED);
            }
            if row.expires_at < chrono::Utc::now() {
                println!("[AUTH] 验证码已过期：phone={}", phone);
                return Err(StatusCode::UNAUTHORIZED);
            }
        }
    }

    // 2. 验证通过后删除验证码（防止重放）
    if let Err(e) = service::delete_sms_code(&state.db, phone).await {
        println!("[AUTH] 删除验证码失败：{}", e);
        return Err(StatusCode::INTERNAL_SERVER_ERROR);
    }

    // 3. 查找或创建用户
    let result = service::find_or_create_user(&state.db, phone)
        .await
        .map_err(|e| {
            println!("[AUTH] 创建用户失败：{}", e);
            StatusCode::INTERNAL_SERVER_ERROR
        })?;

    // 4. 生成 JWT
    let user_id_str = result.account_id.to_string();
    let token = generate_token(&user_id_str, &state.jwt_secret).map_err(|e| {
        println!("[AUTH] JWT 生成失败：{}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?;

    println!(
        "[AUTH] 短信登录成功：account_id={}, is_new={}, has_password={}",
        result.account_id, result.is_new_user, result.has_password
    );

    Ok(Json(LoginResponse {
        token,
        user_id: user_id_str,
        is_new_user: result.is_new_user,
        has_password: result.has_password,
    }))
}

/// 密码登录
async fn login_with_password(
    state: &AppState,
    body: LoginRequest,
) -> Result<Json<LoginResponse>, StatusCode> {
    let phone = &body.phone;
    let password = body.password.as_deref().ok_or_else(|| {
        println!("[AUTH] 密码登录缺少密码：phone={}", phone);
        StatusCode::BAD_REQUEST
    })?;

    // 1. 查 auth_credentials 表获取 credential
    let row = service::get_password_credential(&state.db, phone)
        .await
        .map_err(|e| {
            println!("[AUTH] 查询密码凭据失败：{}", e);
            StatusCode::INTERNAL_SERVER_ERROR
        })?;

    let cred_row = match row {
        None => {
            println!("[AUTH] 用户不存在或未设置密码：phone={}", phone);
            return Err(StatusCode::UNAUTHORIZED);
        }
        Some(r) => r,
    };

    // 2. 验证密码（bcrypt）
    let valid = bcrypt::verify(password, &cred_row.credential).map_err(|e| {
        println!("[AUTH] bcrypt 验证失败：{}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?;

    if !valid {
        println!("[AUTH] 密码错误：phone={}", phone);
        return Err(StatusCode::UNAUTHORIZED);
    }

    // 3. 生成 JWT，has_password 固定为 true
    let user_id_str = cred_row.account_id.to_string();
    let token = generate_token(&user_id_str, &state.jwt_secret).map_err(|e| {
        println!("[AUTH] JWT 生成失败：{}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?;

    println!(
        "[AUTH] 密码登录成功：account_id={}",
        cred_row.account_id
    );

    Ok(Json(LoginResponse {
        token,
        user_id: user_id_str,
        is_new_user: false,
        has_password: true,
    }))
}

// ─── POST /auth/password — 设置密码（需 Token）─────────────────────────────────

pub async fn set_password(
    State(state): State<AppState>,
    headers: HeaderMap,
    Json(req): Json<PasswordRequest>,
) -> Result<Json<MessageResponse>, StatusCode> {
    // 1. 从 Token 解析 account_id
    let account_id = extract_user_id(&headers, &state.jwt_secret)?;

    // 2. 校验密码长度 ≥ 6
    if req.new_password.len() < 6 {
        println!("[AUTH] 密码长度不足：account_id={}", account_id);
        return Err(StatusCode::BAD_REQUEST);
    }

    // 3. bcrypt hash
    let hash = bcrypt::hash(&req.new_password, 10).map_err(|e| {
        println!("[AUTH] 密码哈希失败：{}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?;

    // 4. UPDATE auth_credentials
    let result = service::update_password(&state.db, account_id, &hash).await;
    match result {
        Ok(()) => {
            println!("[AUTH] 密码设置成功：account_id={}", account_id);
            Ok(Json(MessageResponse {
                message: "密码设置成功".to_string(),
            }))
        }
        Err(e) => {
            println!("[AUTH] 更新密码失败：{}", e);
            Err(StatusCode::INTERNAL_SERVER_ERROR)
        }
    }
}

// ─── GET /user/profile — 获取用户信息（需 Token）──────────────────────────────

pub async fn profile(
    State(state): State<AppState>,
    headers: HeaderMap,
) -> Result<Json<serde_json::Value>, StatusCode> {
    // 1. 从 Token 解析 account_id
    let account_id = extract_user_id(&headers, &state.jwt_secret)?;

    // 2. 查询用户资料
    let user = service::get_user_profile(&state.db, account_id)
        .await
        .map_err(|e| {
            println!("[USER] 查询用户资料失败：{}", e);
            StatusCode::INTERNAL_SERVER_ERROR
        })?;

    match user {
        Some(u) => Ok(Json(serde_json::json!({
            "user_id": u.user_id.to_string(),
            "phone": u.phone,
            "nickname": u.nickname,
            "avatar": u.avatar,
        }))),
        None => {
            println!("[USER] 用户不存在：account_id={}", account_id);
            Err(StatusCode::NOT_FOUND)
        }
    }
}
