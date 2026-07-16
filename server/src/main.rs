use axum::extract::FromRef;
use sqlx::PgPool;

use flash_core::Config;
use flash_auth::AuthState;
use flash_user::UserState;

// ─── AppState ─────────────────────────────────────────────────────────────────

/// 全局共享状态
#[derive(Clone)]
struct AppState {
    db: PgPool,
    jwt_secret: String,
}

/// AuthState 自动从 AppState 提取 —— auth 模块无需了解完整 AppState 结构
impl FromRef<AppState> for AuthState {
    fn from_ref(state: &AppState) -> AuthState {
        AuthState {
            db: state.db.clone(),
            jwt_secret: state.jwt_secret.clone(),
        }
    }
}

/// UserState 自动从 AppState 提取 —— user 模块无需了解完整 AppState 结构
impl FromRef<AppState> for UserState {
    fn from_ref(state: &AppState) -> UserState {
        UserState {
            db: state.db.clone(),
            jwt_secret: state.jwt_secret.clone(),
        }
    }
}

// ─── 现有接口 ─────────────────────────────────────────────────────────────────

use axum::{
    response::Html,
    routing::{get, post},
    Json, Router,
};
use local_ip_address::local_ip;
use serde::Serialize;

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
    dotenvy::dotenv().ok();

    let config = Config::from_env().expect("加载配置失败");
    let port = config.server_port;

    println!("正在连接数据库：{}", config.database_url);
    let db = sqlx::postgres::PgPoolOptions::new()
        .max_connections(config.db_pool_size)
        .connect(&config.database_url)
        .await
        .expect("数据库连接失败");

    sqlx::migrate!("./migrations").run(&db).await.expect("数据库迁移失败");
    println!("Database connected ✓");

    let state = AppState {
        db,
        jwt_secret: config.jwt_secret.clone(),
    };

    let cors = tower_http::cors::CorsLayer::new()
        .allow_origin(tower_http::cors::Any)
        .allow_methods(tower_http::cors::Any)
        .allow_headers(tower_http::cors::Any);

    let app = Router::new()
        .route("/v", get(version))
        .route("/conversation", get(conversations))
        .route("/ws/im", get(im_ws::handler::ws_handler))
        .route("/playground", get(playground))
        // auth 路由
        .route("/auth/sms", post(flash_auth::send_sms))
        .route("/auth/login", post(flash_auth::login))
        // user 路由（按 design.md 规范注册）
        .route("/user/profile", get(flash_user::handlers::profile).put(flash_user::handlers::update_profile))
        .route("/user/password", post(flash_user::handlers::set_password).put(flash_user::handlers::change_password))
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
    println!("─────────────────────────────────────");
    println!("发送验证码   → POST http://127.0.0.1:{}/auth/sms", port);
    println!("登录        → POST http://127.0.0.1:{}/auth/login", port);
    println!("用户信息    → GET  http://127.0.0.1:{}/user/profile", port);
    println!("编辑资料    → PUT  http://127.0.0.1:{}/user/profile", port);
    println!("设置密码    → POST http://127.0.0.1:{}/user/password", port);
    println!("修改密码    → PUT  http://127.0.0.1:{}/user/password", port);
    println!("IM WebSocket → WS   ws://127.0.0.1:{}/ws/im", port);

    axum::serve(listener, app).await.expect("服务启动失败");
}
