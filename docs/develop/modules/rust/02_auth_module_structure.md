# Auth 模块重构说明

## 重构前后对比

### 重构前（单文件）
```
server/src/
└── auth.rs (约 120 行)
    ├── SmsRequest, SmsResponse
    ├── LoginRequest, LoginResponse
    ├── send_sms()
    └── login()
```

**问题**：
- 所有代码混在一个文件
- 数据模型、业务逻辑、HTTP 处理器耦合
- 难以扩展（如增加密码登录）
- 测试数据硬编码在处理器中

### 重构后（模块化）
```
server/src/auth/
├── mod.rs           # 模块入口（6 行）
├── models.rs        # 数据模型（50 行）
├── service.rs       # 业务逻辑（70 行）
└── handlers.rs      # HTTP 处理器（100 行）
```

**优点**：
- 职责清晰分离
- 易于测试（业务逻辑独立）
- 易于扩展（新增登录方式只需修改 models 和 service）
- 代码复用性高

---

## 模块结构详解

### 1. mod.rs - 模块入口

```rust
mod handlers;
mod models;
mod service;

pub use handlers::{login, send_sms};
```

**职责**：
- 声明子模块
- 重新导出公开 API
- 对外隐藏内部实现细节

**使用方式**：
```rust
// main.rs
mod auth;
use auth::{login, send_sms};  // 直接使用，无需知道内部结构
```

---

### 2. models.rs - 数据模型

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

pub struct LoginResponse { ... }
pub struct SmsRequest { ... }
pub struct SmsResponse { ... }
```

**职责**：
- 定义所有数据结构
- 实现序列化/反序列化
- 定义枚举类型

**设计要点**：
- 使用 `Option<T>` 处理可选字段
- 使用 `#[serde(skip_serializing_if = "Option::is_none")]` 优化 JSON
- 枚举使用 `#[serde(rename_all = "snake_case")]` 统一命名风格

---

### 3. service.rs - 业务逻辑

```rust
pub fn get_test_accounts() -> HashMap<String, String> { ... }
pub fn verify_sms_code(...) -> bool { ... }
pub fn verify_password(...) -> bool { ... }
pub fn find_or_create_user(...) -> (User, bool) { ... }
```

**职责**：
- 纯业务逻辑函数
- 数据验证
- 用户管理
- 测试数据提供

**设计要点**：
- 函数纯粹，无副作用（除了日志）
- 易于单元测试
- 不依赖 HTTP 框架（axum）

---

### 4. handlers.rs - HTTP 处理器

```rust
pub async fn send_sms(
    State(state): State<AppState>,
    Json(body): Json<SmsRequest>,
) -> Json<SmsResponse> { ... }

pub async fn login(
    State(state): State<AppState>,
    Json(body): Json<LoginRequest>,
) -> Result<Json<LoginResponse>, StatusCode> { ... }
```

**职责**：
- 处理 HTTP 请求/响应
- 调用 service 层函数
- 错误处理和状态码返回
- 日志记录

**设计要点**：
- 薄层，只做协议转换
- 业务逻辑委托给 service 层
- 统一错误处理

---

## 新增功能：密码登录

### 1. 登录类型枚举

```rust
#[derive(Debug, Clone, Deserialize, Serialize)]
#[serde(rename_all = "snake_case")]
pub enum LoginType {
    Sms,      // JSON: "sms"
    Password, // JSON: "password"
}
```

### 2. 内置测试账号

```rust
pub fn get_test_accounts() -> HashMap<String, String> {
    let mut accounts = HashMap::new();
    accounts.insert("13800138000".to_string(), "123456".to_string());
    accounts.insert("13800138001".to_string(), "password".to_string());
    accounts.insert("13800138002".to_string(), "abc123".to_string());
    accounts.insert("18888888888".to_string(), "test1234".to_string());
    accounts
}
```

### 3. 登录流程

```rust
match body.login_type {
    LoginType::Sms => {
        // 验证短信验证码
        let code = body.code.ok_or(StatusCode::BAD_REQUEST)?;
        verify_sms_code(&sms_codes, &body.phone, &code)?;
    }
    LoginType::Password => {
        // 验证密码
        let password = body.password.ok_or(StatusCode::BAD_REQUEST)?;
        verify_password(&test_accounts, &body.phone, &password)?;
    }
}
```

---

## 使用示例

### 短信验证码登录

```bash
# 1. 发送验证码
curl -X POST http://127.0.0.1:3000/auth/sms \
  -H "Content-Type: application/json" \
  -d '{"phone":"13800138000"}'

# 2. 登录
curl -X POST http://127.0.0.1:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "login_type":"sms",
    "phone":"13800138000",
    "code":"123456"
  }'
```

### 密码登录

```bash
curl -X POST http://127.0.0.1:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "login_type":"password",
    "phone":"13800138000",
    "password":"123456"
  }'
```

---

## 扩展性示例

### 如何新增第三方登录（如微信）？

**1. 在 models.rs 中添加枚举值**
```rust
pub enum LoginType {
    Sms,
    Password,
    Wechat,  // 新增
}
```

**2. 在 models.rs 中添加字段**
```rust
pub struct LoginRequest {
    pub login_type: LoginType,
    pub phone: String,
    pub code: Option<String>,
    pub password: Option<String>,
    pub wechat_code: Option<String>,  // 新增
}
```

**3. 在 service.rs 中添加验证函数**
```rust
pub fn verify_wechat_code(code: &str) -> Result<String, Error> {
    // 调用微信 API 验证
}
```

**4. 在 handlers.rs 中添加分支**
```rust
match body.login_type {
    LoginType::Sms => { ... }
    LoginType::Password => { ... }
    LoginType::Wechat => {  // 新增
        let code = body.wechat_code.ok_or(StatusCode::BAD_REQUEST)?;
        let openid = verify_wechat_code(&code)?;
        // 使用 openid 查找或创建用户
    }
}
```

**只需修改 4 个地方，不影响现有代码！**

---

## 最佳实践总结

1. **分层清晰**：models → service → handlers
2. **单一职责**：每个文件只做一件事
3. **易于测试**：业务逻辑独立，可单独测试
4. **易于扩展**：新增功能只需修改少量文件
5. **类型安全**：使用枚举而非字符串
6. **错误处理**：使用 `Result` 和 `Option` 明确表达可能失败的操作

---

## 测试建议

### 单元测试（service.rs）
```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_verify_password() {
        let accounts = get_test_accounts();
        assert!(verify_password(&accounts, "13800138000", "123456"));
        assert!(!verify_password(&accounts, "13800138000", "wrong"));
    }
}
```

### 集成测试（handlers.rs）
```rust
#[tokio::test]
async fn test_login_with_password() {
    let state = AppState::new();
    let req = LoginRequest {
        login_type: LoginType::Password,
        phone: "13800138000".to_string(),
        code: None,
        password: Some("123456".to_string()),
    };
    let result = login(State(state), Json(req)).await;
    assert!(result.is_ok());
}
```
