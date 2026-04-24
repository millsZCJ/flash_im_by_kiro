use axum::{extract::State, http::StatusCode, Json};
use rand::Rng;
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::{jwt::generate_token, state::{AppState, User}};

// ─── POST /auth/sms ───────────────────────────────────────────────────────────

#[derive(Deserialize)]
pub struct SmsRequest {
    pub phone: String,
}

#[derive(Serialize)]
pub struct SmsResponse {
    /// playground 阶段直接返回验证码，方便测试
    pub code: String,
    pub message: String,
}

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

#[derive(Deserialize)]
pub struct LoginRequest {
    pub phone: String,
    pub code: String,
}

#[derive(Serialize)]
pub struct LoginResponse {
    pub token: String,
    pub user_id: String,
    pub is_new_user: bool,
}

pub async fn login(
    State(state): State<AppState>,
    Json(body): Json<LoginRequest>,
) -> Result<Json<LoginResponse>, StatusCode> {
    // 1. 验证验证码
    let stored_code = state
        .sms_codes
        .lock()
        .unwrap()
        .get(&body.phone)
        .cloned();

    match stored_code {
        Some(ref c) if c == &body.code => {}
        _ => {
            println!("[AUTH] 验证码错误：phone={}", body.phone);
            return Err(StatusCode::UNAUTHORIZED);
        }
    }

    // 2. 验证通过后删除验证码（一次性）
    state.sms_codes.lock().unwrap().remove(&body.phone);

    // 3. 查找或创建用户（登录即注册）
    let mut users = state.users.lock().unwrap();
    let is_new_user = !users.contains_key(&body.phone);

    let user = users.entry(body.phone.clone()).or_insert_with(|| {
        let user_id = Uuid::new_v4().to_string();
        println!("[AUTH] 新用户注册：phone={}, user_id={}", body.phone, user_id);
        User {
            user_id: user_id.clone(),
            phone: body.phone.clone(),
            nickname: body.phone.clone(), // 默认昵称为手机号
            avatar: format!("https://api.dicebear.com/7.x/thumbs/svg?seed={}", user_id),
        }
    });

    let user_id = user.user_id.clone();
    drop(users); // 释放锁再生成 token

    // 4. 生成 JWT
    let token = generate_token(&user_id, &state.jwt_secret)
        .map_err(|e| {
            println!("[AUTH] JWT 生成失败：{}", e);
            StatusCode::INTERNAL_SERVER_ERROR
        })?;

    println!("[AUTH] 登录成功：user_id={}, is_new={}", user_id, is_new_user);

    Ok(Json(LoginResponse {
        token,
        user_id,
        is_new_user,
    }))
}
