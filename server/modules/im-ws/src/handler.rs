use std::sync::LazyLock;
use std::time::Duration;

use axum::{
    extract::ws::{Message, WebSocket, WebSocketUpgrade},
    response::IntoResponse,
};
use futures::{SinkExt, StreamExt};
use prost::Message as ProstMessage;
use tokio::time::timeout;

use crate::dispatcher;
use crate::proto::{AuthRequest, AuthResult, WsFrame, WsFrameType};

/// JWT secret，启动时从环境变量加载一次
static JWT_SECRET: LazyLock<String> = LazyLock::new(|| {
    flash_core::Config::from_env()
        .map(|c| c.jwt_secret)
        .unwrap_or_else(|_| flash_core::Config::default().jwt_secret)
});

/// GET /ws/im — WebSocket 升级端点
pub async fn ws_handler(ws: WebSocketUpgrade) -> impl IntoResponse {
    ws.on_upgrade(handle_socket)
}

/// 处理单个 WebSocket 连接
async fn handle_socket(socket: WebSocket) {
    let (mut sender, mut receiver) = socket.split();

    // 1. 等待认证，10 秒超时
    let user_id = match timeout(Duration::from_secs(10), wait_for_auth(&mut receiver)).await {
        Ok(Some(id)) => id,
        _ => {
            println!("[im-ws] 认证失败或超时");
            let _ = send_auth_result(&mut sender, false, "认证失败").await;
            let _ = sender.close().await;
            return;
        }
    };

    // 2. 认证成功，发送结果
    if send_auth_result(&mut sender, true, "ok").await.is_err() {
        println!("[im-ws] 向用户 {} 发送认证结果失败", user_id);
        let _ = sender.close().await;
        return;
    }

    println!("[im-ws] ✅ 用户 {} 已连接", user_id);

    // 3. 消息循环
    while let Some(Ok(msg)) = receiver.next().await {
        match msg {
            Message::Binary(data) => {
                match WsFrame::decode(&data[..]) {
                    Ok(frame) => {
                        if let Some(reply) = dispatcher::handle_frame(frame).await {
                            if sender.send(Message::Binary(reply.into())).await.is_err() {
                                break;
                            }
                        }
                    }
                    Err(e) => println!("[im-ws] 帧解码失败: {}", e),
                }
            }
            Message::Close(_) => break,
            _ => {}
        }
    }

    println!("[im-ws] ❌ 用户 {} 已断开", user_id);
}

/// 等待客户端发送 AUTH 帧，返回 user_id
async fn wait_for_auth(receiver: &mut futures::stream::SplitStream<WebSocket>) -> Option<i64> {
    let msg = receiver.next().await?.ok()?;
    let data = match msg {
        Message::Binary(d) => d,
        _ => {
            println!("[im-ws] 认证消息类型错误");
            return None;
        }
    };

    let frame = WsFrame::decode(&data[..]).ok()?;
    if frame.r#type != WsFrameType::Auth as i32 {
        println!("[im-ws] 首帧不是 AUTH");
        return None;
    }

    let req = AuthRequest::decode(&frame.payload[..]).ok()?;
    let claims = flash_core::verify_token(&req.token, &JWT_SECRET).ok()?;
    claims.sub.parse::<i64>().ok()
}

/// 发送 AUTH_RESULT 帧
async fn send_auth_result(
    sender: &mut futures::stream::SplitSink<WebSocket, Message>,
    success: bool,
    message: &str,
) -> Result<(), axum::Error> {
    let result = AuthResult {
        success,
        message: message.to_string(),
    };
    let frame = WsFrame {
        r#type: WsFrameType::AuthResult as i32,
        payload: result.encode_to_vec(),
    };
    sender.send(Message::Binary(frame.encode_to_vec().into())).await
}
