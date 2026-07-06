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

use flash_core::verify_token;

use crate::AppState;

// ─── 聊天室广播频道 ────────────────────────────────────────────────────────────

#[derive(Clone, Serialize)]
pub struct RoomMessage {
    #[serde(rename = "type")]
    pub msg_type: String,
    pub sender: String,
    pub content: String,
    pub time: String,
}

const CHANNEL_CAPACITY: usize = 128;

pub fn new_broadcast() -> broadcast::Sender<RoomMessage> {
    broadcast::channel(CHANNEL_CAPACITY).0
}

#[derive(Deserialize)]
pub struct ChatRoomParams {
    pub token: Option<String>,
}

// ─── Handler ─────────────────────────────────────────────────────────────────

pub async fn chat_room_handler(
    ws: WebSocketUpgrade,
    Query(params): Query<ChatRoomParams>,
    State(state): State<AppState>,
) -> impl IntoResponse {
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

    let user_id_str = claims.sub.clone();

    let account_id: i64 = match user_id_str.parse() {
        Ok(id) => id,
        Err(_) => {
            println!("[ROOM] 拒绝连接：account_id 解析失败 - {}", user_id_str);
            return StatusCode::UNAUTHORIZED.into_response();
        }
    };

    let nickname = match sqlx::query_scalar::<_, String>(
        "SELECT nickname FROM user_profiles WHERE account_id = $1",
    )
    .bind(account_id)
    .fetch_optional(&state.db)
    .await
    {
        Ok(Some(n)) => n,
        Ok(None) => {
            println!("[ROOM] 用户不存在：account_id={}", account_id);
            return StatusCode::UNAUTHORIZED.into_response();
        }
        Err(e) => {
            println!("[ROOM] 查询用户昵称失败：{}", e);
            return StatusCode::INTERNAL_SERVER_ERROR.into_response();
        }
    };

    println!("[ROOM] 用户 {} ({}) 连接", nickname, account_id);

    let tx = state.room_tx.clone();
    ws.on_upgrade(move |socket| handle_room(socket, nickname, tx))
}

async fn handle_room(
    mut socket: WebSocket,
    nickname: String,
    tx: broadcast::Sender<RoomMessage>,
) {
    let mut rx = tx.subscribe();

    let join_msg = RoomMessage {
        msg_type: "join".to_string(),
        sender: nickname.clone(),
        content: String::new(),
        time: current_time(),
    };
    let _ = tx.send(join_msg);

    loop {
        tokio::select! {
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

    println!("[ROOM] 用户 {} 断开", nickname);
    let leave_msg = RoomMessage {
        msg_type: "leave".to_string(),
        sender: nickname.clone(),
        content: String::new(),
        time: current_time(),
    };
    let _ = tx.send(leave_msg);
}

fn current_time() -> String {
    use std::time::{SystemTime, UNIX_EPOCH};
    let secs = SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_secs();
    let h = (secs % 86400) / 3600;
    let m = (secs % 3600) / 60;
    let s = secs % 60;
    format!("{:02}:{:02}:{:02}", h, m, s)
}
