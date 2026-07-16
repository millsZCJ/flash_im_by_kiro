use serde::{Deserialize, Serialize};

/// 登录类型
#[derive(Debug, Clone, Deserialize, Serialize)]
#[serde(rename_all = "snake_case")]
pub enum LoginType {
    Sms,
    Password,
}

/// SMS 发送请求
#[derive(Deserialize)]
pub struct SmsRequest {
    pub phone: String,
}

/// SMS 响应
#[derive(Serialize)]
pub struct SmsResponse {
    pub code: String,
    pub message: String,
}

/// 登录请求
#[derive(Deserialize)]
pub struct LoginRequest {
    pub login_type: LoginType,
    pub phone: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub code: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub password: Option<String>,
}

/// 登录响应
#[derive(Serialize)]
pub struct LoginResponse {
    pub token: String,
    pub user_id: String,
    pub is_new_user: bool,
    pub has_password: bool,
}
// 注：PasswordRequest、MessageResponse 已迁至 flash_user
