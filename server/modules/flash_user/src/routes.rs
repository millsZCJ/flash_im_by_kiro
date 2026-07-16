use axum::routing::{get, post};
use axum::Router;

use crate::handlers::{profile, update_profile, set_password, change_password};
use crate::state::UserState;

/// flash_user 模块的路由集合
///
/// 路由表：
/// - GET  /user/profile   → 查看用户资料
/// - PUT  /user/profile   → 编辑用户资料（昵称、签名、头像）
/// - POST /user/password  → 设置密码（首次，无旧密码）
/// - PUT  /user/password  → 修改密码（需验证旧密码）
pub fn router() -> Router<UserState> {
    Router::new()
        .route("/user/profile", get(profile).put(update_profile))
        .route("/user/password", post(set_password).put(change_password))
}
