use serde::{Deserialize, Serialize};

// ─── 登录类型 ─────────────────────────────────────────────────────────────────

#[derive(Debug, Clone, Deserialize, Serialize)]
#[serde(rename_all = "snake_case")]
pub enum LoginType {
    /// 短信验证码登录
    Sms,
    /// 密码登录
    Password,
}

// ─── SMS 相关 ─────────────────────────────────────────────────────────────────

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

// ─── 登录相关 ─────────────────────────────────────────────────────────────────

#[derive(Deserialize)]
pub struct LoginRequest {
    /// 登录类型
    pub login_type: LoginType,
    /// 手机号
    pub phone: String,
    /// 短信验证码（login_type = sms 时必填）
    #[serde(skip_serializing_if = "Option::is_none")]
    pub code: Option<String>,
    /// 密码（login_type = password 时必填）
    #[serde(skip_serializing_if = "Option::is_none")]
    pub password: Option<String>,
}

#[derive(Serialize)]
pub struct LoginResponse {
    pub token: String,
    pub user_id: String,
    pub is_new_user: bool,
}
