use std::collections::HashMap;
use uuid::Uuid;

use crate::state::User;

// ─── 内存数据：用户密码 ───────────────────────────────────────────────────────

/// 内置测试账号（手机号 -> 密码）
pub fn get_test_accounts() -> HashMap<String, String> {
    let mut accounts = HashMap::new();
    accounts.insert("13800138000".to_string(), "123456".to_string());
    accounts.insert("13800138001".to_string(), "password".to_string());
    accounts.insert("13800138002".to_string(), "abc123".to_string());
    accounts.insert("18888888888".to_string(), "test1234".to_string());
    accounts
}

// ─── 业务逻辑 ─────────────────────────────────────────────────────────────────

/// 验证短信验证码
pub fn verify_sms_code(
    sms_codes: &HashMap<String, String>,
    phone: &str,
    code: &str,
) -> bool {
    sms_codes.get(phone).map(|c| c == code).unwrap_or(false)
}

/// 验证密码
pub fn verify_password(
    test_accounts: &HashMap<String, String>,
    phone: &str,
    password: &str,
) -> bool {
    test_accounts
        .get(phone)
        .map(|p| p == password)
        .unwrap_or(false)
}

/// 查找或创建用户（登录即注册）
pub fn find_or_create_user(
    users: &mut HashMap<String, User>,
    phone: String,
) -> (User, bool) {
    let is_new_user = !users.contains_key(&phone);

    let user = users
        .entry(phone.clone())
        .or_insert_with(|| {
            let user_id = Uuid::new_v4().to_string();
            println!(
                "[AUTH] 新用户注册：phone={}, user_id={}",
                phone, user_id
            );
            User {
                user_id: user_id.clone(),
                phone: phone.clone(),
                nickname: phone.clone(), // 默认昵称为手机号
                avatar: format!(
                    "https://api.dicebear.com/7.x/thumbs/svg?seed={}",
                    user_id
                ),
            }
        })
        .clone();

    (user, is_new_user)
}
