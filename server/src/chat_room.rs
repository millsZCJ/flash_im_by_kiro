use axum::{
    extract::{
        ws::{Message, WebSocket, WebSocketUpgrade},
        Query, State,
    },
    http::StatusCode,
    response::IntoResponse,
};
use serde::{Deserialize, Serialize};
use tokio::sync::broadcast;

use crate::{jwt::verify_token, state::AppState};

// ─── 聊天室广播频道（全局单例，挂在 AppState 上）────────────────────────────

/// 聊天室消息（JSON 格式广播给所有在线用户）
#[derive(Clone, Serialize)]
pub struct RoomMessage {
    /// 消息类型：chat | join | leave
    #[serde(rename = "type")]
    pub msg_type: String,
    /// 发送者昵称
    pub sender: String,
    /// 消息内容（join/leave 时为空）
    pub content: String,
    /// 时间戳（HH:mm:ss）
    pub time: String,
}

/// 广播频道容量
const CHANNEL_CAPACITY: usize = 128;

/// 创建广播发送端，存入 AppState
pub fn new_broadcast() -> broadcast::Sender<RoomMessage> {
    broadcast::channel(CHANNEL_CAPACITY).0
}

// ─── URL 参数 ─────────────────────────────────────────────────────────────────

#[derive(Deserialize)]
pub struct ChatRoomParams {
    pub token: Option<String>,
}

// ─── Handler ─────────────────────────────────────────────────────────────────

/// GET /chat_room?token=<jwt>
///
/// 1. 从 URL 参数提取并验证 JWT
/// 2. 升级为 WebSocket
/// 3. 加入广播频道，广播"进入聊天室"事件
/// 4. 转发消息给所有在线用户
/// 5. 断开时广播"离开聊天室"事件
pub async fn chat_room_handler(
    ws: WebSocketUpgrade,
    Query(params): Query<ChatRoomParams>,
    State(state): State<AppState>,
) -> impl IntoResponse {
    // 验证 token
    let token = match params.token {
        Some(t) if !t.is_empty() => t,
        _ => {
            println!("[ROOM] 拒绝连接：缺少 token");
            return StatusCode::UNAUTHORIZED.into_response();
        }
    };

    let claims = match verify_token(&token, &state.jwt_secret) {
        Ok(c) => c,
        Err(e) => {
            println!("[ROOM] 拒绝连接：token 无效 - {}", e);
            return StatusCode::UNAUTHORIZED.into_response();
        }
    };

    let user_id = claims.sub.clone();

    // 从内存中查找用户昵称
    let nickname = {
        let users = state.users.lock().unwrap();
        users
            .values()
            .find(|u| u.user_id == user_id)
            .map(|u| u.nickname.clone())
            .unwrap_or_else(|| user_id.clone())
    };

    println!("[ROOM] 用户 {} ({}) 连接", nickname, user_id);

    let tx = state.room_tx.clone();
    ws.on_upgrade(move |socket| handle_room(socket, nickname, tx))
}

// ─── 连接处理 ─────────────────────────────────────────────────────────────────

async fn handle_room(
    mut socket: WebSocket,
    nickname: String,
    tx: broadcast::Sender<RoomMessage>,
) {
    let mut rx = tx.subscribe();

    // 广播"进入聊天室"
    let join_msg = RoomMessage {
        msg_type: "join".to_string(),
        sender: nickname.clone(),
        content: String::new(),
        time: current_time(),
    };
    let _ = tx.send(join_msg);

    loop {
        tokio::select! {
            // 收到客户端消息 → 广播给所有人
            msg = socket.recv() => {
                match msg {
                    Some(Ok(Message::Text(text))) => {
                        let text = text.trim().to_string();
                        if text.is_empty() { continue; }

                        println!("[ROOM] {} 发送：{}", nickname, text);

                        let chat_msg = RoomMessage {
                            msg_type: "chat".to_string(),
                            sender: nickname.clone(),
                            content: text,
                            time: current_time(),
                        };
                        let _ = tx.send(chat_msg);
                    }
                    Some(Ok(Message::Close(_))) | None => break,
                    Some(Ok(_)) => {}
                    Some(Err(e)) => {
                        println!("[ROOM] {} 连接错误：{}", nickname, e);
                        break;
                    }
                }
            }

            // 收到广播消息 → 推送给当前客户端
            broadcast = rx.recv() => {
                match broadcast {
                    Ok(room_msg) => {
                        if let Ok(json) = serde_json::to_string(&room_msg) {
                            if socket.send(Message::Text(json.into())).await.is_err() {
                                break;
                            }
                        }
                    }
                    Err(_) => break,
                }
            }
        }
    }

    // 广播"离开聊天室"
    println!("[ROOM] 用户 {} 断开", nickname);
    let leave_msg = RoomMessage {
        msg_type: "leave".to_string(),
        sender: nickname.clone(),
        content: String::new(),
        time: current_time(),
    };
    let _ = tx.send(leave_msg);
}

// ─── 工具函数 ─────────────────────────────────────────────────────────────────

fn current_time() -> String {
    use std::time::{SystemTime, UNIX_EPOCH};
    let secs = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap()
        .as_secs();
    let h = (secs % 86400) / 3600;
    let m = (secs % 3600) / 60;
    let s = secs % 60;
    format!("{:02}:{:02}:{:02}", h, m, s)
}
