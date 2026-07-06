// flash_auth — 闪讯认证模块 crate
// 提供登录认证 HTTP handlers + 业务逻辑 + 数据模型
// 通过 AuthState（FromRef）与主 APP 的 AppState 解耦

pub mod handlers;
pub mod models;
pub mod service;
pub mod errors;
pub mod state;

pub use handlers::{login, profile, send_sms, set_password, is_valid_phone};
pub use state::AuthState;
pub use errors::AuthError;
