use axum::{
    extract::State,
    http::{HeaderMap, StatusCode},
    Json,
};
use serde::Serialize;

use crate::{jwt::verify_token, state::AppState};

// ─── GET /user/profile ────────────────────────────────────────────────────────

#[derive(Serialize)]
pub struct ProfileResponse {
    pub user_id: String,
    pub phone: String,
    pub nickname: String,
    pub avatar: String,
}

pub async fn get_profile(
    State(state): State<AppState>,
    headers: HeaderMap,
) -> Result<Json<ProfileResponse>, StatusCode> {
    // 1. 从 Authorization header 中提取 token
    let auth_header = headers
        .get("authorization")
        .and_then(|v| v.to_str().ok())
        .ok_or(StatusCode::UNAUTHORIZED)?;

    let token = auth_header
        .strip_prefix("Bearer ")
        .ok_or(StatusCode::UNAUTHORIZED)?;

    // 2. 验证 JWT 并提取 user_id
    let claims = verify_token(token, &state.jwt_secret).map_err(|e| {
        println!("[USER] Token 验证失败：{}", e);
        StatusCode::UNAUTHORIZED
    })?;

    let user_id = claims.sub;

    // 3. 从内存中查找用户
    let users = state.users.lock().unwrap();
    let user = users
        .values()
        .find(|u| u.user_id == user_id)
        .ok_or_else(|| {
            println!("[USER] 用户不存在：user_id={}", user_id);
            StatusCode::NOT_FOUND
        })?;

    Ok(Json(ProfileResponse {
        user_id: user.user_id.clone(),
        phone: user.phone.clone(),
        nickname: user.nickname.clone(),
        avatar: user.avatar.clone(),
    }))
}
