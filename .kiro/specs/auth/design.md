# 认证模块（auth）设计文档

## 1. 架构概述

认证模块采用分层架构，将 HTTP 处理、业务逻辑和数据访问分离：

```
┌─────────────────────────────────────────────────────┐
│                   HTTP Layer                        │
│  handlers.rs - Axum route handlers                 │
└─────────────────────┬───────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────┐
│                Service Layer                        │
│  service.rs - Business logic, validation           │
└─────────────────────┬───────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────┐
│               Repository Layer                      │
│  repo.rs - Database operations via sqlx            │
└─────────────────────┬───────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────┐
│                Database                             │
│  PostgreSQL - users, sessions, sms_codes           │
└─────────────────────────────────────────────────────┘
```

## 2. 模块结构

```
server/src/auth/
├── mod.rs           # 模块导出
├── handlers.rs      # HTTP 路由处理（Axum handlers）
├── models.rs        # 请求/响应数据结构
├── service.rs       # 业务逻辑层
├── repo.rs          # 数据库访问层（新增）
└── errors.rs        # 错误类型定义（新增）
```

## 3. 数据模型

### 3.1 数据库表

#### users 表

```sql
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone VARCHAR(20) NOT NULL UNIQUE,
    username VARCHAR(50) UNIQUE,
    email VARCHAR(100) UNIQUE,
    password_hash VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

#### sessions 表

```sql
CREATE TABLE IF NOT EXISTS sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token VARCHAR(255) NOT NULL UNIQUE,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

#### sms_codes 表

```sql
CREATE TABLE IF NOT EXISTS sms_codes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone VARCHAR(20) NOT NULL,
    code VARCHAR(6) NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sms_codes_phone ON sms_codes(phone);
CREATE INDEX IF NOT EXISTS idx_sms_codes_expires_at ON sms_codes(expires_at);
```

### 3.2 Rust 数据结构

#### 领域模型

```rust
/// 用户实体
pub struct User {
    pub id: Uuid,
    pub phone: String,
    pub username: Option<String>,
    pub email: Option<String>,
    pub password_hash: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

/// 会话实体
pub struct Session {
    pub id: Uuid,
    pub user_id: Uuid,
    pub token: String,
    pub expires_at: DateTime<Utc>,
    pub created_at: DateTime<Utc>,
}

/// 短信验证码实体
pub struct SmsCode {
    pub id: Uuid,
    pub phone: String,
    pub code: String,
    pub expires_at: DateTime<Utc>,
    pub created_at: DateTime<Utc>,
}
```

#### API 模型（现有，保持不变）

```rust
pub enum LoginType {
    Sms,
    Password,
}

pub struct LoginRequest {
    pub login_type: LoginType,
    pub phone: String,
    pub code: Option<String>,
    pub password: Option<String>,
}

pub struct LoginResponse {
    pub token: String,
    pub user_id: String,
    pub is_new_user: bool,
}

pub struct SmsRequest {
    pub phone: String,
}

pub struct SmsResponse {
    pub code: String,
    pub message: String,
}
```

## 4. 核心流程

### 4.1 短信验证码登录流程

```
┌──────────┐    POST /auth/sms    ┌───────────┐
│  Client  │ ──────────────────► │  Handler  │
└──────────┘                      └─────┬─────┘
                                        │
                                        ▼
┌──────────────────────────────────────────────────────┐
│  1. 生成 6 位随机验证码                              │
│  2. 计算过期时间（5 分钟后）                         │
│  3. 存入 sms_codes 表                                │
│  4. 返回验证码（playground 模式）                    │
└──────────────────────────────────────────────────────┘

┌──────────┐    POST /auth/login   ┌───────────┐
│  Client  │ ──────────────────► │  Handler  │
└──────────┘                      └─────┬─────┘
                                        │
                                        ▼
┌──────────────────────────────────────────────────────┐
│  1. 从 sms_codes 表查询验证码                        │
│  2. 验证是否匹配且未过期                             │
│  3. 删除已使用的验证码                               │
│  4. 查找或创建用户                                   │
│  5. 生成 JWT token                                   │
│  6. 存入 sessions 表                                 │
│  7. 返回 token 和用户信息                            │
└──────────────────────────────────────────────────────┘
```

### 4.2 密码登录流程

```
┌──────────┐    POST /auth/login   ┌───────────┐
│  Client  │ ──────────────────► │  Handler  │
└──────────┘    login_type=       └─────┬─────┘
                password                │
                                        ▼
┌──────────────────────────────────────────────────────┐
│  1. 根据 phone 查询用户                              │
│  2. 验证密码（bcrypt::verify）                       │
│  3. 生成 JWT token                                   │
│  4. 存入 sessions 表                                 │
│  5. 返回 token 和用户信息                            │
└──────────────────────────────────────────────────────┘
```

### 4.3 新用户注册流程

```
┌──────────────────────────────────────────────────────┐
│  登录时用户不存在                                    │
│  1. 创建新用户记录                                   │
│     - phone: 登录手机号                              │
│     - username: None                                 │
│     - email: None                                    │
│     - password_hash: None（短信登录）或加密密码       │
│  2. 设置 is_new_user = true                          │
│  3. 继续正常登录流程                                 │
└──────────────────────────────────────────────────────┘
```

## 5. 组件设计

### 5.1 数据库访问层（repo.rs）

```rust
/// 用户仓储
pub struct UserRepo;

impl UserRepo {
    /// 根据 phone 查找用户
    pub async fn find_by_phone(pool: &DbPool, phone: &str) -> Result<Option<User>, DbError>;
    
    /// 创建新用户
    pub async fn create(pool: &DbPool, phone: &str, password_hash: Option<&str>) -> Result<User, DbError>;
    
    /// 更新密码
    pub async fn update_password(pool: &DbPool, user_id: Uuid, password_hash: &str) -> Result<(), DbError>;
}

/// 会话仓储
pub struct SessionRepo;

impl SessionRepo {
    /// 创建会话
    pub async fn create(pool: &DbPool, user_id: Uuid, token: &str, expires_at: DateTime<Utc>) -> Result<Session, DbError>;
    
    /// 根据 token 查找会话
    pub async fn find_by_token(pool: &DbPool, token: &str) -> Result<Option<Session>, DbError>;
    
    /// 删除会话（登出）
    pub async fn delete_by_token(pool: &DbPool, token: &str) -> Result<(), DbError>;
    
    /// 清理过期会话
    pub async fn delete_expired(pool: &DbPool) -> Result<u64, DbError>;
}

/// 验证码仓储
pub struct SmsCodeRepo;

impl SmsCodeRepo {
    /// 创建验证码
    pub async fn create(pool: &DbPool, phone: &str, code: &str, expires_at: DateTime<Utc>) -> Result<SmsCode, DbError>;
    
    /// 查找并验证
    pub async fn find_and_validate(pool: &DbPool, phone: &str, code: &str) -> Result<bool, DbError>;
    
    /// 删除验证码
    pub async fn delete_by_phone(pool: &DbPool, phone: &str) -> Result<(), DbError>;
}
```

### 5.2 业务逻辑层（service.rs）

```rust
/// 认证服务
pub struct AuthService;

impl AuthService {
    /// 发送验证码
    pub async fn send_sms_code(
        pool: &DbPool,
        phone: &str,
    ) -> Result<String, AuthError>;
    
    /// 短信验证码登录
    pub async fn login_with_sms(
        pool: &DbPool,
        jwt_secret: &str,
        phone: &str,
        code: &str,
    ) -> Result<LoginResult, AuthError>;
    
    /// 密码登录
    pub async fn login_with_password(
        pool: &DbPool,
        jwt_secret: &str,
        phone: &str,
        password: &str,
    ) -> Result<LoginResult, AuthError>;
    
    /// 设置密码（用于密码登录用户）
    pub async fn set_password(
        pool: &DbPool,
        user_id: Uuid,
        password: &str,
    ) -> Result<(), AuthError>;
    
    /// 验证 token
    pub async fn verify_token(
        pool: &DbPool,
        jwt_secret: &str,
        token: &str,
    ) -> Result<Claims, AuthError>;
    
    /// 登出
    pub async fn logout(
        pool: &DbPool,
        token: &str,
    ) -> Result<(), AuthError>;
}

/// 登录结果
pub struct LoginResult {
    pub user: User,
    pub token: String,
    pub is_new_user: bool,
}
```

### 5.3 错误处理（errors.rs）

```rust
#[derive(Error, Debug)]
pub enum AuthError {
    #[error("验证码错误或已过期")]
    InvalidSmsCode,
    
    #[error("密码错误")]
    InvalidPassword,
    
    #[error("用户不存在")]
    UserNotFound,
    
    #[error("用户已存在")]
    UserAlreadyExists,
    
    #[error("Token 无效或已过期")]
    InvalidToken,
    
    #[error("缺少必填字段: {0}")]
    MissingField(&'static str),
    
    #[error("数据库错误: {0}")]
    Database(#[from] DbError),
    
    #[error("JWT 错误: {0}")]
    Jwt(#[from] jsonwebtoken::errors::Error),
    
    #[error("密码哈希错误: {0}")]
    PasswordHash(String),
}

impl IntoResponse for AuthError {
    fn into_response(self) -> Response {
        let status = match &self {
            AuthError::InvalidSmsCode | AuthError::InvalidPassword => StatusCode::UNAUTHORIZED,
            AuthError::MissingField(_) => StatusCode::BAD_REQUEST,
            AuthError::UserNotFound => StatusCode::NOT_FOUND,
            AuthError::UserAlreadyExists => StatusCode::CONFLICT,
            _ => StatusCode::INTERNAL_SERVER_ERROR,
        };
        (status, Json(ErrorResponse::from(self))).into_response()
    }
}
```

## 6. 配置管理

### 6.1 环境变量

```rust
/// 应用配置
pub struct Config {
    /// 数据库连接字符串
    pub database_url: String,
    /// JWT 签名密钥
    pub jwt_secret: String,
    /// 验证码有效期（秒）
    pub sms_code_ttl: u64,
    /// Token 有效期（秒）
    pub token_ttl: u64,
    /// 数据库连接池大小
    pub db_pool_size: u32,
}

impl Config {
    pub fn from_env() -> Result<Self, anyhow::Error> {
        Ok(Self {
            database_url: env::var("DATABASE_URL")?,
            jwt_secret: env::var("JWT_SECRET")
                .unwrap_or_else(|_| "flash_im_dev_secret_2026".to_string()),
            sms_code_ttl: env::var("SMS_CODE_TTL")
                .unwrap_or_else(|_| "300".to_string())
                .parse()?,
            token_ttl: env::var("TOKEN_TTL")
                .unwrap_or_else(|_| "604800".to_string()) // 7 天
                .parse()?,
            db_pool_size: env::var("DB_POOL_SIZE")
                .unwrap_or_else(|_| "10".to_string())
                .parse()?,
        })
    }
}
```

## 7. 状态管理更新

### 7.1 AppState 改造

```rust
/// 应用全局状态
#[derive(Clone)]
pub struct AppState {
    /// 数据库连接池
    pub db: DbPool,
    /// JWT 签名密钥
    pub jwt_secret: String,
    /// 验证码有效期（秒）
    pub sms_code_ttl: u64,
    /// Token 有效期（秒）
    pub token_ttl: u64,
    /// 聊天室广播发送端
    pub room_tx: broadcast::Sender<RoomMessage>,
}

impl AppState {
    pub async fn new(config: Config) -> Result<Self, anyhow::Error> {
        let db = create_pool(&config.database_url, config.db_pool_size).await?;
        
        Ok(Self {
            db,
            jwt_secret: config.jwt_secret,
            sms_code_ttl: config.sms_code_ttl,
            token_ttl: config.token_ttl,
            room_tx: new_broadcast(),
        })
    }
}
```

## 8. 依赖项

需要添加到 `Cargo.toml` 的依赖：

```toml
bcrypt = "0.15"  # 密码加密
dotenvy = "0.15" # 环境变量加载
```

## 9. 测试策略

### 9.1 单元测试

- 密码哈希和验证
- JWT 生成和验证
- 验证码生成和过期逻辑

### 9.2 集成测试

- 短信登录完整流程
- 密码登录完整流程
- 新用户注册流程
- Token 验证和登出

### 9.3 测试工具

- 使用 `sqlx::testing` 进行数据库测试
- 使用内存数据库或测试数据库
- Mock 短信服务（playground 模式）
