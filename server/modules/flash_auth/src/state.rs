use sqlx::PgPool;

/// Auth 模块所需的状态子集
///
/// 通过 axum 的 FromRef 机制，从主 APP 的 AppState 自动提取。
/// auth handlers 使用 `State(state): State<AuthState>` 即可，
/// 不需要知道主 APP 的完整状态结构。
#[derive(Clone)]
pub struct AuthState {
    pub db: PgPool,
    pub jwt_secret: String,
}
