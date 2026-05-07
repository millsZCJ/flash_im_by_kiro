use axum::{extract::State, http::StatusCode, Json};
use rand::Rng;

use crate::{jwt::generate_token, state::AppState};

use super::{
    models::{LoginRequest, LoginResponse, LoginType, SmsRequest, SmsResponse},
    service::{find_or_create_user, get_test_accounts, verify_password, verify_sms_code},
};

// ─── POST /auth/sms ───────────────────────────────────────────────────────────

pub async fn send_sms(
    State(state): State<AppState>,
    Json(body): Json<SmsRequest>,
) -> Json<SmsResponse> {
    // 生成 6 位随机数字验证码
    let code: String = rand::thread_rng()
        .sample_iter(rand::distributions::Uniform::new(0, 10))
        .take(6)
        .map(|d| d.to_string())
        .collect();

    println!("[SMS] 手机号 {} 的验证码：{}", body.phone, code);

    // 存入内存（覆盖旧验证码）
    state
        .sms_codes
        .lock()
        .unwrap()
        .insert(body.phone.clone(), code.clone());

    Json(SmsResponse {
        code,
        message: "验证码已发送（playground 模式，直接返回）".to_string(),
    })
}

// ─── POST /auth/login ─────────────────────────────────────────────────────────

pub async fn login(
    State(state): State<AppState>,
    Json(body): Json<LoginRequest>,
) -> Result<Json<LoginResponse>, StatusCode> {
    // 1. 根据登录类型验证凭证
    match body.login_type {
        LoginType::Sms => {
            // 短信验证码登录
            let code = body.code.ok_or_else(|| {
                println!("[AUTH] 短信登录缺少验证码：phone={}", body.phone);
                StatusCode::BAD_REQUEST
            })?;

            let sms_codes = state.sms_codes.lock().unwrap();
            if !verify_sms_code(&sms_codes, &body.phone, &code) {
                println!("[AUTH] 验证码错误：phone={}", body.phone);
                return Err(StatusCode::UNAUTHORIZED);
            }
            drop(sms_codes);

            // 验证通过后删除验证码（一次性）
            state.sms_codes.lock().unwrap().remove(&body.phone);
        }

        LoginType::Password => {
            // 密码登录
            let password = body.password.ok_or_else(|| {
                println!("[AUTH] 密码登录缺少密码：phone={}", body.phone);
                StatusCode::BAD_REQUEST
            })?;

            let test_accounts = get_test_accounts();
            if !verify_password(&test_accounts, &body.phone, &password) {
                println!("[AUTH] 密码错误：phone={}", body.phone);
                return Err(StatusCode::UNAUTHORIZED);
            }
        }
    }

    // 2. 查找或创建用户（登录即注册）
    let mut users = state.users.lock().unwrap();
    let (user, is_new_user) = find_or_create_user(&mut users, body.phone.clone());
    let user_id = user.user_id.clone();
    drop(users); // 释放锁再生成 token

    // 3. 生成 JWT
    let token = generate_token(&user_id, &state.jwt_secret).map_err(|e| {
        println!("[AUTH] JWT 生成失败：{}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?;

    println!(
        "[AUTH] 登录成功：user_id={}, is_new={}, type={:?}",
        user_id, is_new_user, body.login_type
    );

    Ok(Json(LoginResponse {
        token,
        user_id,
        is_new_user,
    }))
}
