use prost::Message as ProstMessage;

use crate::proto::{WsFrame, WsFrameType};

/// 处理收到的帧，返回需要回复的帧（如果有）
pub async fn handle_frame(frame: WsFrame) -> Option<Vec<u8>> {
    let frame_type = WsFrameType::try_from(frame.r#type).ok()?;

    match frame_type {
        WsFrameType::Ping => {
            let reply = WsFrame {
                r#type: WsFrameType::Pong as i32,
                payload: Vec::new(),
            };
            Some(reply.encode_to_vec())
        }
        other => {
            println!("[im-ws] 未处理的帧类型: {:?}", other);
            None
        }
    }
}
