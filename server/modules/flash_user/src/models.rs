use serde::{Deserialize, Serialize};
use flash_core::User;

/// 编辑用户信息请求（字段均为可选，只传需要修改的）
#[derive(Deserialize)]
pub struct UpdateProfileRequest {
    pub nickname: Option<String>,
    pub avatar: Option<String>,
    pub signature: Option<String>,
}

/// 设置密码请求（首次）
#[derive(Deserialize)]
pub struct SetPasswordRequest {
    pub new_password: String,
}

/// 修改密码请求（需验证旧密码）
#[derive(Deserialize)]
pub struct ChangePasswordRequest {
    pub old_password: String,
    pub new_password: String,
}

/// 通用消息响应
#[derive(Serialize)]
pub struct MessageResponse {
    pub message: String,
}

/// 用户信息响应（复用 flash_core::User，额外序列化 user_id 为 String）
#[derive(Serialize)]
pub struct UserProfileResponse {
    pub user_id: String,
    pub phone: String,
    pub nickname: String,
    pub avatar: String,
    pub signature: String,
}

impl From<User> for UserProfileResponse {
    fn from(u: User) -> Self {
        Self {
            user_id: u.user_id.to_string(),
            phone: u.phone,
            nickname: u.nickname,
            avatar: u.avatar,
            signature: u.signature,
        }
    }
}
