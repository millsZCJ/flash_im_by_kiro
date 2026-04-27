mod auth;
mod chat_room;
mod jwt;
mod state;
mod user;
mod ws;

use axum::{
    response::Html,
    routing::{get, post},
    Json, Router,
};
use local_ip_address::local_ip;
use serde::Serialize;
use state::AppState;
use tower_http::cors::{Any, CorsLayer};

// ─── 现有接口 ─────────────────────────────────────────────────────────────────

#[derive(Serialize)]
struct VersionInfo {
    name: &'static str,
    version: &'static str,
}

async fn version() -> Json<VersionInfo> {
    Json(VersionInfo {
        name: "IM Server",
        version: env!("CARGO_PKG_VERSION"),
    })
}

#[derive(Serialize)]
struct Conversation {
    title: &'static str,
    #[serde(rename = "lastMsg")]
    last_msg: &'static str,
    time: &'static str,
}

async fn conversations() -> Json<Vec<Conversation>> {
    Json(vec![
        Conversation { title: "张伟", last_msg: "好的，明天见", time: "2026-04-07 09:01" },
        Conversation { title: "李娜", last_msg: "文件已发送", time: "2026-04-07 09:15" },
        Conversation { title: "王芳", last_msg: "收到，谢谢", time: "2026-04-07 09:30" },
        Conversation { title: "刘洋", last_msg: "会议推迟到下午", time: "2026-04-07 09:45" },
        Conversation { title: "陈静", last_msg: "好的没问题", time: "2026-04-07 10:00" },
        Conversation { title: "赵磊", last_msg: "代码已提交", time: "2026-04-07 10:20" },
        Conversation { title: "孙丽", last_msg: "需求文档看了吗", time: "2026-04-07 10:35" },
        Conversation { title: "周强", last_msg: "下午有空吗", time: "2026-04-07 10:50" },
        Conversation { title: "吴敏", last_msg: "Bug 已修复", time: "2026-04-07 11:05" },
        Conversation { title: "郑浩", last_msg: "测试通过了", time: "2026-04-07 11:20" },
        Conversation { title: "技术群", last_msg: "新版本上线了", time: "2026-04-07 11:35" },
        Conversation { title: "产品讨论", last_msg: "原型图更新了", time: "2026-04-07 11:50" },
        Conversation { title: "设计组", last_msg: "切图已上传", time: "2026-04-07 12:10" },
        Conversation { title: "运营团队", last_msg: "活动方案确认", time: "2026-04-07 12:30" },
        Conversation { title: "客服反馈", last_msg: "用户投诉已处理", time: "2026-04-07 13:00" },
        Conversation { title: "林晓", last_msg: "周报发你了", time: "2026-04-07 13:20" },
        Conversation { title: "黄鑫", last_msg: "接口文档更新", time: "2026-04-07 13:45" },
        Conversation { title: "徐梅", last_msg: "好的我看看", time: "2026-04-07 14:00" },
        Conversation { title: "马超", last_msg: "部署完成", time: "2026-04-07 14:20" },
        Conversation { title: "朱婷", last_msg: "下班一起走？", time: "2026-04-07 14:35" },
    ])
}

async fn playground() -> Html<&'static str> {
    Html(include_str!("ws_playground.html"))
}

// ─── 启动 ─────────────────────────────────────────────────────────────────────

#[tokio::main]
async fn main() {
    let port = 3000;
    let state = AppState::new();

    let cors = CorsLayer::new()
        .allow_origin(Any)
        .allow_methods(Any)
        .allow_headers(Any);

    let app = Router::new()
        // 基础接口
        .route("/v", get(version))
        .route("/conversation", get(conversations))
        // WebSocket
        .route("/ws", get(ws::ws_handler))
        .route("/playground", get(playground))
        // 认证接口
        .route("/auth/sms", post(auth::send_sms))
        .route("/auth/login", post(auth::login))
        // 用户接口
        .route("/user/profile", get(user::get_profile))
        // 聊天室 WebSocket（JWT 认证）
        .route("/chat_room", get(chat_room::chat_room_handler))
        .with_state(state)
        .layer(cors);

    let listener = tokio::net::TcpListener::bind(format!("0.0.0.0:{port}"))
        .await
        .expect("端口绑定失败");

    match local_ip() {
        Ok(ip) => println!("服务已启动 → http://{}:{}", ip, port),
        Err(_) => println!("服务已启动 → http://127.0.0.1:{}", port),
    }
    println!("本机访问  → http://127.0.0.1:{}", port);
    println!("会话接口  → http://127.0.0.1:{}/conversation", port);
    println!("WebSocket → ws://127.0.0.1:{}/ws", port);
    println!("WS 测试台 → http://127.0.0.1:{}/playground", port);
    println!("─────────────────────────────────────");
    println!("发送验证码 → POST http://127.0.0.1:{}/auth/sms", port);
    println!("登录      → POST http://127.0.0.1:{}/auth/login", port);
    println!("用户信息  → GET  http://127.0.0.1:{}/user/profile", port);
    println!("聊天室    → WS   ws://127.0.0.1:{}/chat_room?token=<jwt>", port);

    axum::serve(listener, app).await.expect("服务启动失败");
}
