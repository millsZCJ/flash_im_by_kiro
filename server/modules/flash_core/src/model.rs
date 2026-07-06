/// 用户信息（供 profile 接口返回）
#[derive(Clone, Debug)]
pub struct User {
    pub user_id: i64,
    pub phone: String,
    pub nickname: String,
    pub avatar: String,
}
