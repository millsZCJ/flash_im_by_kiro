// flash_user — 闪讯用户模块 crate
// 提供用户资料查看/编辑、密码管理等 HTTP handlers
// 通过 UserState（FromRef）与主 APP 的 AppState 解耦
// 公开 API：pub fn router() → Router<UserState>

pub mod handlers;
pub mod models;
pub mod service;
pub mod errors;
pub mod state;
pub mod routes;

pub use routes::router;
pub use state::UserState;
pub use errors::UserError;
