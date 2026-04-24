use axum::extract::ws::{Message, WebSocket, WebSocketUpgrade};

pub async fn ws_handler(ws: WebSocketUpgrade) -> impl axum::response::IntoResponse {
    ws.on_upgrade(handle_socket)
}

async fn handle_socket(mut socket: WebSocket) {
    println!("[WS] 客户端已连接");

    if socket
        .send(Message::Text("欢迎连接 Flash IM WebSocket 服务！".into()))
        .await
        .is_err()
    {
        println!("[WS] 发送欢迎消息失败，客户端已断开");
        return;
    }

    loop {
        match socket.recv().await {
            Some(Ok(Message::Text(text))) => {
                println!("[WS] 收到消息：{}", text);
                let reply = format!("echo: {}", text);
                if socket.send(Message::Text(reply.into())).await.is_err() {
                    println!("[WS] 发送回复失败，客户端已断开");
                    break;
                }
            }
            Some(Ok(Message::Close(_))) | None => break,
            Some(Ok(_)) => {}
            Some(Err(e)) => {
                println!("[WS] 连接错误：{}", e);
                break;
            }
        }
    }

    println!("[WS] 客户端已断开");
}
