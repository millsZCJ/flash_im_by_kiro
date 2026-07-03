use sqlx::PgPool;
use tokio::sync::broadcast;

use crate::chat_room::{new_broadcast, RoomMessage};

/// 用户信息（供 profile 接口返回）
#[derive(Clone, Debug)]
pub struct User {
    pub user_id: i64,
    pub phone: String,
    pub nickname: String,
    pub avatar: String,
}

/// 全局共享状态
#[derive(Clone)]
pub struct AppState {
    /// PostgreSQL 连接池
    pub db: PgPool,
    /// JWT 签名密钥
    pub jwt_secret: String,
    /// 聊天室广播发送端
    pub room_tx: broadcast::Sender<RoomMessage>,
}

/// 创建 AppState，接收 PgPool 和 jwt_secret
pub fn create_app_state(db: PgPool, jwt_secret: String) -> AppState {
    AppState {
        db,
        jwt_secret,
        room_tx: new_broadcast(),
    }
}
