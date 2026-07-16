/// 用户信息（供 profile 接口返回）
#[derive(Clone, Debug, serde::Serialize)]
pub struct User {
    pub user_id: i64,
    pub phone: String,
    pub nickname: String,
    pub avatar: String,
    pub signature: String,
}
