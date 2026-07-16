use axum::{
    extract::State,
    http::StatusCode,
    Json,
};
use rand::Rng;

use flash_core::generate_token;

use crate::state::AuthState;
use crate::models::{
    LoginRequest, LoginResponse, LoginType, SmsRequest,
    SmsResponse,
};
use crate::service;

// ─── 工具函数 ─────────────────────────────────────────────────────────────────

/// 校验手机号格式
pub fn is_valid_phone(phone: &str) -> bool {
    phone.len() == 11 && phone.starts_with('1') && phone.chars().all(|c| c.is_ascii_digit())
}

// ─── POST /auth/sms ───────────────────────────────────────────────────────────

pub async fn send_sms(
    State(state): State<AuthState>,
    Json(body): Json<SmsRequest>,
) -> Result<Json<SmsResponse>, StatusCode> {
    if !is_valid_phone(&body.phone) {
        println!("[SMS] 手机号格式不合法：{}", body.phone);
        return Err(StatusCode::BAD_REQUEST);
    }

    let code: String = rand::thread_rng()
        .sample_iter(rand::distributions::Uniform::new(0, 10))
        .take(6)
        .map(|d| d.to_string())
        .collect();

    let expires_at = chrono::Utc::now() + chrono::Duration::minutes(5);

    if let Err(e) = service::upsert_sms_code(&state.db, &body.phone, &code, expires_at).await {
        println!("[SMS] 写入验证码失败：{}", e);
        return Err(StatusCode::INTERNAL_SERVER_ERROR);
    }

    println!("[SMS] 手机号 {} 的验证码：{}", body.phone, code);

    Ok(Json(SmsResponse {
        code,
        message: "验证码已发送（playground 模式，直接返回）".to_string(),
    }))
}

// ─── POST /auth/login ─────────────────────────────────────────────────────────

pub async fn login(
    State(state): State<AuthState>,
    Json(body): Json<LoginRequest>,
) -> Result<Json<LoginResponse>, StatusCode> {
    match body.login_type {
        LoginType::Sms => login_with_sms(&state, body).await,
        LoginType::Password => login_with_password(&state, body).await,
    }
}

async fn login_with_sms(
    state: &AuthState,
    body: LoginRequest,
) -> Result<Json<LoginResponse>, StatusCode> {
    let phone = &body.phone;
    let code = body.code.as_deref().ok_or_else(|| {
        println!("[AUTH] 短信登录缺少验证码：phone={}", phone);
        StatusCode::BAD_REQUEST
    })?;

    let sms_row = service::get_sms_code(&state.db, phone).await.map_err(|e| {
        println!("[AUTH] 查询验证码失败：{}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?;

    match sms_row {
        None => {
            println!("[AUTH] 验证码不存在：phone={}", phone);
            return Err(StatusCode::UNAUTHORIZED);
        }
        Some(row) => {
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

    if let Err(e) = service::delete_sms_code(&state.db, phone).await {
        println!("[AUTH] 删除验证码失败：{}", e);
        return Err(StatusCode::INTERNAL_SERVER_ERROR);
    }

    let result = service::find_or_create_user(&state.db, phone).await.map_err(|e| {
        println!("[AUTH] 创建用户失败：{}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?;

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

async fn login_with_password(
    state: &AuthState,
    body: LoginRequest,
) -> Result<Json<LoginResponse>, StatusCode> {
    let phone = &body.phone;
    let password = body.password.as_deref().ok_or_else(|| {
        println!("[AUTH] 密码登录缺少密码：phone={}", phone);
        StatusCode::BAD_REQUEST
    })?;

    let row = service::get_password_credential(&state.db, phone).await.map_err(|e| {
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

    let valid = bcrypt::verify(password, &cred_row.credential).map_err(|e| {
        println!("[AUTH] bcrypt 验证失败：{}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?;

    if !valid {
        println!("[AUTH] 密码错误：phone={}", phone);
        return Err(StatusCode::UNAUTHORIZED);
    }

    let user_id_str = cred_row.account_id.to_string();
    let token = generate_token(&user_id_str, &state.jwt_secret).map_err(|e| {
        println!("[AUTH] JWT 生成失败：{}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?;

    println!("[AUTH] 密码登录成功：account_id={}", cred_row.account_id);

    Ok(Json(LoginResponse {
        token,
        user_id: user_id_str,
        is_new_user: false,
        has_password: true,
    }))
}
