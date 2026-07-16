//! IM WebSocket 模块
//!
//! 当前版本包含 Protobuf 协议定义、WebSocket 升级处理器与帧分发器。
//! 连接管理、消息路由等业务逻辑在后续版本实现。

pub mod dispatcher;
pub mod handler;
pub mod proto;
