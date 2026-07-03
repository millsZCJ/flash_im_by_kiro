mod auth;
mod chat_room;
mod config;
mod db;
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
use sqlx::postgres::PgPoolOptions;
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
    // 1. 加载 .env 环境变量
    dotenvy::dotenv().ok();

    // 2. 加载配置
    let config = config::Config::from_env().expect("加载配置失败");
    let port = config.server_port;

    // 3. 创建数据库连接池
    println!("正在连接数据库：{}", config.database_url);
    let db = PgPoolOptions::new()
        .max_connections(config.db_pool_size)
        .connect(&config.database_url)
        .await
        .expect("数据库连接失败，请检查 PostgreSQL 是否启动及 DATABASE_URL 配置");

    // 4. 运行数据库迁移
    sqlx::migrate!("./migrations")
        .run(&db)
        .await
        .expect("数据库迁移失败");

    println!("Database connected ✓");

    // 5. 创建 AppState
    let state = AppState {
        db,
        jwt_secret: config.jwt_secret.clone(),
        room_tx: chat_room::new_broadcast(),
    };

    // 6. CORS
    let cors = CorsLayer::new()
        .allow_origin(Any)
        .allow_methods(Any)
        .allow_headers(Any);

    // 7. 路由
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
        .route("/auth/password", post(auth::set_password))
        // 用户接口
        .route("/user/profile", get(auth::profile))
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
    println!("设置密码  → POST http://127.0.0.1:{}/auth/password", port);
    println!("用户信息  → GET  http://127.0.0.1:{}/user/profile", port);
    println!("聊天室    → WS   ws://127.0.0.1:{}/chat_room?token=<jwt>", port);

    axum::serve(listener, app).await.expect("服务启动失败");
}
