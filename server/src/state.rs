use std::collections::HashMap;
use std::sync::{Arc, Mutex};

/// 内存中的用户记录
#[derive(Clone, Debug)]
pub struct User {
    pub user_id: String,
    pub phone: String,
    pub nickname: String,
    pub avatar: String,
}

/// 全局共享状态（内存模拟，无数据库）
#[derive(Clone)]
pub struct AppState {
    /// phone → User
    pub users: Arc<Mutex<HashMap<String, User>>>,
    /// phone → 验证码（模拟短信服务）
    pub sms_codes: Arc<Mutex<HashMap<String, String>>>,
    /// JWT 签名密钥
    pub jwt_secret: String,
}

impl AppState {
    pub fn new() -> Self {
        Self {
            users: Arc::new(Mutex::new(HashMap::new())),
            sms_codes: Arc::new(Mutex::new(HashMap::new())),
            jwt_secret: "flash_im_dev_secret_2026".to_string(),
        }
    }
}
