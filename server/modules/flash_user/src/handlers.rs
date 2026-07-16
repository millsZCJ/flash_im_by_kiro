use axum::{
    extract::State,
    http::{HeaderMap, StatusCode},
    Json,
};

use flash_core::extract_user_id;

use crate::state::UserState;
use crate::models::{
    ChangePasswordRequest, MessageResponse, SetPasswordRequest,
    UpdateProfileRequest, UserProfileResponse,
};
use crate::service;

// ─── GET /user/profile ────────────────────────────────────────────────────────

pub async fn profile(
    State(state): State<UserState>,
    headers: HeaderMap,
) -> Result<Json<UserProfileResponse>, StatusCode> {
    let account_id = extract_user_id(&headers, &state.jwt_secret)?;

    let user = service::get_user_profile(&state.db, account_id)
        .await
        .map_err(|e| {
            println!("[USER] 查询用户资料失败：{}", e);
            StatusCode::INTERNAL_SERVER_ERROR
        })?;

    match user {
        Some(u) => Ok(Json(UserProfileResponse::from(u))),
        None => {
            println!("[USER] 用户不存在：account_id={}", account_id);
            Err(StatusCode::NOT_FOUND)
        }
    }
}

// ─── PUT /user/profile ──────────────────────────────────────────────────────

pub async fn update_profile(
    State(state): State<UserState>,
    headers: HeaderMap,
    Json(req): Json<UpdateProfileRequest>,
) -> Result<Json<UserProfileResponse>, StatusCode> {
    let account_id = extract_user_id(&headers, &state.jwt_secret)?;

    // 校验字段
    if let Some(ref n) = req.nickname {
        if n.trim().is_empty() || n.len() > 50 {
            return Err(StatusCode::BAD_REQUEST);
        }
    }
    if let Some(ref s) = req.signature {
        if s.len() > 100 {
            return Err(StatusCode::BAD_REQUEST);
        }
    }
    if let Some(ref a) = req.avatar {
        if a.trim().is_empty() {
            return Err(StatusCode::BAD_REQUEST);
        }
    }

    // 更新传入的字段
    if let Some(ref nickname) = req.nickname {
        service::update_nickname(&state.db, account_id, nickname.trim())
            .await.map_err(|e| { println!("[USER] 更新昵称失败：{}", e); StatusCode::INTERNAL_SERVER_ERROR })?;
    }
    if let Some(ref avatar) = req.avatar {
        service::update_avatar(&state.db, account_id, avatar.trim())
            .await.map_err(|e| { println!("[USER] 更新头像失败：{}", e); StatusCode::INTERNAL_SERVER_ERROR })?;
    }
    if let Some(ref signature) = req.signature {
        service::update_signature(&state.db, account_id, signature.trim())
            .await.map_err(|e| { println!("[USER] 更新签名失败：{}", e); StatusCode::INTERNAL_SERVER_ERROR })?;
    }

    // 返回完整用户信息
    let user = service::get_user_profile(&state.db, account_id)
        .await.map_err(|e| { println!("[USER] 查询更新后资料失败：{}", e); StatusCode::INTERNAL_SERVER_ERROR })?;

    match user {
        Some(u) => {
            println!("[USER] 资料更新成功：account_id={}", account_id);
            Ok(Json(UserProfileResponse::from(u)))
        }
        None => Err(StatusCode::NOT_FOUND),
    }
}

// ─── POST /user/password — 设置密码（首次）────────────────────────────────────

pub async fn set_password(
    State(state): State<UserState>,
    headers: HeaderMap,
    Json(req): Json<SetPasswordRequest>,
) -> Result<Json<MessageResponse>, StatusCode> {
    let account_id = extract_user_id(&headers, &state.jwt_secret)?;

    if req.new_password.len() < 6 {
        println!("[USER] 密码长度不足：account_id={}", account_id);
        return Err(StatusCode::BAD_REQUEST);
    }

    // 检查是否已有密码
    let credential_row = service::get_password_credential(&state.db, account_id)
        .await.map_err(|e| { println!("[USER] 查询凭据失败：{}", e); StatusCode::INTERNAL_SERVER_ERROR })?;

    match credential_row {
        None => {
            println!("[USER] 用户不存在：account_id={}", account_id);
            return Err(StatusCode::NOT_FOUND);
        }
        Some(None) => {} // 未设密码，允许设置
        Some(Some(_)) => {
            println!("[USER] 已有密码，拒绝重复设置：account_id={}", account_id);
            return Err(StatusCode::CONFLICT); // 409 已设置过密码
        }
    }

    let hash = bcrypt::hash(&req.new_password, 10).map_err(|e| {
        println!("[USER] 密码哈希失败：{}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?;

    service::set_password(&state.db, account_id, &hash)
        .await.map_err(|e| { println!("[USER] 设置密码失败：{}", e); StatusCode::INTERNAL_SERVER_ERROR })?;

    println!("[USER] 密码设置成功：account_id={}", account_id);
    Ok(Json(MessageResponse { message: "密码设置成功".to_string() }))
}

// ─── PUT /user/password — 修改密码（需旧密码）───────────────────────────────────

pub async fn change_password(
    State(state): State<UserState>,
    headers: HeaderMap,
    Json(req): Json<ChangePasswordRequest>,
) -> Result<Json<MessageResponse>, StatusCode> {
    let account_id = extract_user_id(&headers, &state.jwt_secret)?;

    if req.new_password.len() < 6 {
        println!("[USER] 新密码长度不足：account_id={}", account_id);
        return Err(StatusCode::BAD_REQUEST);
    }

    // 查询当前密码凭据
    let credential_row = service::get_password_credential(&state.db, account_id)
        .await.map_err(|e| { println!("[USER] 查询凭据失败：{}", e); StatusCode::INTERNAL_SERVER_ERROR })?;

    let current_hash = match credential_row {
        None => {
            println!("[USER] 用户不存在：account_id={}", account_id);
            return Err(StatusCode::NOT_FOUND);
        }
        Some(None) => {
            println!("[USER] 未设置密码，应使用设置密码接口：account_id={}", account_id);
            return Err(StatusCode::NOT_FOUND); // 404 未设过密码
        }
        Some(Some(h)) => h,
    };

    // 验证旧密码
    let valid = bcrypt::verify(&req.old_password, &current_hash).map_err(|e| {
        println!("[USER] bcrypt 验证失败：{}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?;

    if !valid {
        println!("[USER] 原密码错误：account_id={}", account_id);
        return Err(StatusCode::UNAUTHORIZED);
    }

    // 哈希新密码并更新
    let new_hash = bcrypt::hash(&req.new_password, 10).map_err(|e| {
        println!("[USER] 密码哈希失败：{}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?;

    service::set_password(&state.db, account_id, &new_hash)
        .await.map_err(|e| { println!("[USER] 修改密码失败：{}", e); StatusCode::INTERNAL_SERVER_ERROR })?;

    println!("[USER] 密码修改成功：account_id={}", account_id);
    Ok(Json(MessageResponse { message: "密码修改成功".to_string() }))
}
