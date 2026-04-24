# 用户认证系统概览

> 为 Flash IM 即时通信产品梳理认证的基本概念和流程

---

## 一句话理解认证

**认证（Authentication）** 回答的是："你是谁？"
**授权（Authorization）** 回答的是："你能做什么？"

两者经常被混淆，但本质不同。本文聚焦认证。

---

## 1. 为什么 IM 产品需要认证

没有认证的 IM 就像一栋没有门锁的楼——任何人都能进来，冒充任何人发消息。

认证解决三个核心问题：

| 问题 | 没有认证 | 有认证 |
|---|---|---|
| 身份确认 | 任何人都能发消息 | 只有本人能操作自己的账号 |
| 会话隔离 | 所有人看到所有消息 | 只能看到自己的会话 |
| WebSocket 安全 | 任何人都能建立连接 | 只有登录用户才能连接 |

---

## 2. 认证的核心流程

### 2.1 注册

用户第一次创建账号的过程。

```mermaid
sequenceDiagram
    participant 用户
    participant 客户端
    participant 服务器
    participant 数据库

    用户->>客户端: 填写用户名 + 密码
    客户端->>服务器: POST /register { username, password }
    服务器->>服务器: 对密码进行哈希处理（bcrypt）
    服务器->>数据库: 存储 { username, password_hash }
    数据库-->>服务器: 存储成功
    服务器-->>客户端: 201 Created { user_id }
    客户端-->>用户: 注册成功，请登录
```

> ⚠️ 密码永远不能明文存储，必须经过哈希处理。

---

### 2.2 登录与 Token 颁发

用户证明身份，服务器颁发"通行证"（Token）。

```mermaid
sequenceDiagram
    participant 用户
    participant 客户端
    participant 服务器
    participant 数据库

    用户->>客户端: 输入用户名 + 密码
    客户端->>服务器: POST /login { username, password }
    服务器->>数据库: 查询用户记录
    数据库-->>服务器: 返回 { password_hash, user_id }
    服务器->>服务器: 验证密码哈希是否匹配
    
    alt 密码正确
        服务器->>服务器: 生成 JWT Token（含 user_id、过期时间）
        服务器-->>客户端: 200 OK { access_token, refresh_token }
        客户端->>客户端: 本地存储 Token
        客户端-->>用户: 登录成功
    else 密码错误
        服务器-->>客户端: 401 Unauthorized
        客户端-->>用户: 用户名或密码错误
    end
```

---

### 2.3 携带 Token 访问受保护资源

登录后，每次请求都带上 Token，服务器验证后才响应。

```mermaid
sequenceDiagram
    participant 客户端
    participant 服务器

    客户端->>服务器: GET /conversations\nAuthorization: Bearer <token>
    服务器->>服务器: 解析并验证 Token 签名
    服务器->>服务器: 检查 Token 是否过期

    alt Token 有效
        服务器->>服务器: 从 Token 中取出 user_id
        服务器-->>客户端: 200 OK { 会话列表 }
    else Token 无效或过期
        服务器-->>客户端: 401 Unauthorized
        客户端->>客户端: 跳转到登录页
    end
```

---

### 2.4 WebSocket 连接认证

IM 产品的核心场景：建立 WebSocket 连接时也需要验证身份。

```mermaid
sequenceDiagram
    participant 客户端
    participant 服务器

    Note over 客户端: 已持有登录后的 Token

    客户端->>服务器: WebSocket 握手\nws://host/ws?token=<jwt>
    服务器->>服务器: 从 URL 参数中取出 Token
    服务器->>服务器: 验证 Token 有效性

    alt Token 有效
        服务器-->>客户端: 101 Switching Protocols（握手成功）
        Note over 客户端,服务器: 连接建立，开始实时通信
    else Token 无效
        服务器-->>客户端: 401 关闭连接
        Note over 客户端: 跳转登录页重新认证
    end
```

> WebSocket 不支持自定义 Header，所以 Token 通常通过 URL 参数或握手阶段的子协议传递。

---

## 3. JWT 是什么

JWT（JSON Web Token）是目前最主流的 Token 格式，适合无状态的分布式系统。

### 结构

JWT 由三段 Base64 编码的字符串组成，用 `.` 分隔：

```
eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoxMjMsImV4cCI6MTc0NTAwMH0.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c
    Header（算法）          Payload（数据）                    Signature（签名）
```

- **Header**：声明签名算法（如 HS256）
- **Payload**：存放数据，如 `user_id`、`exp`（过期时间）
- **Signature**：用服务器密钥对前两段签名，防止篡改

### 验证原理

```mermaid
flowchart LR
    A["客户端发来 Token"] --> B["拆分三段"]
    B --> C["用服务器密钥\n重新计算签名"]
    C --> D{签名一致？}
    D -->|是| E["检查是否过期"]
    D -->|否| F["❌ 拒绝，Token 被篡改"]
    E --> G{已过期？}
    G -->|否| H["✅ 认证通过，取出 user_id"]
    G -->|是| I["❌ 拒绝，要求重新登录"]
```

### JWT 的优势

- **无状态**：服务器不需要存储 Session，Token 本身携带所有信息
- **可扩展**：多台服务器都能验证同一个 Token，天然支持水平扩展
- **跨平台**：App、Web、WebSocket 都能用同一套 Token

---

## 4. Access Token 与 Refresh Token

Token 有过期时间，过期后需要重新获取。两种 Token 分工不同：

| | Access Token | Refresh Token |
|---|---|---|
| 用途 | 访问 API、建立 WebSocket | 换取新的 Access Token |
| 有效期 | 短（15 分钟 ~ 2 小时） | 长（7 天 ~ 30 天） |
| 存储位置 | 内存 / 安全存储 | 安全存储（Keychain / SecureStorage） |
| 泄露风险 | 较高（频繁传输） | 较低（很少使用） |

### 无感刷新流程

```mermaid
sequenceDiagram
    participant 客户端
    participant 服务器

    客户端->>服务器: 请求 API（Access Token 已过期）
    服务器-->>客户端: 401 Token 过期

    Note over 客户端: 自动用 Refresh Token 换新 Token

    客户端->>服务器: POST /refresh { refresh_token }
    服务器->>服务器: 验证 Refresh Token
    服务器-->>客户端: 200 OK { 新 access_token }

    客户端->>服务器: 重试原请求（新 Access Token）
    服务器-->>客户端: 200 OK { 数据 }

    Note over 客户端: 用户无感知，体验流畅
```

---

## 5. 密码安全：为什么不能明文存储

假设数据库被拖库，明文密码会直接暴露所有用户账号。哈希处理后，即使数据库泄露，攻击者也无法还原原始密码。

```mermaid
flowchart TD
    A["用户密码：abc123"] --> B["bcrypt 哈希"]
    B --> C["$2b$12$K8Hv...（存入数据库）"]

    D["登录时输入：abc123"] --> E["bcrypt 验证"]
    C --> E
    E --> F{匹配？}
    F -->|是| G["✅ 登录成功"]
    F -->|否| H["❌ 密码错误"]
```

**bcrypt 的特点：**
- 同一个密码每次哈希结果不同（加盐），防止彩虹表攻击
- 计算速度故意设计得慢，暴力破解成本极高
- 业界标准，Rust 有成熟的 `bcrypt` crate

---

## 6. Flash IM 认证方案总结

基于以上概念，Flash IM 的认证方案设计如下：

```mermaid
flowchart TD
    A["用户打开 App"] --> B{本地有 Token？}
    B -->|否| C["显示登录页"]
    B -->|是| D["验证 Token 是否过期"]
    D -->|未过期| E["直接进入主界面"]
    D -->|已过期| F["用 Refresh Token 静默刷新"]
    F -->|成功| E
    F -->|失败| C

    C --> G["用户登录"]
    G --> H["服务器颁发 Access Token + Refresh Token"]
    H --> I["本地安全存储 Token"]
    I --> E

    E --> J["HTTP 请求携带 Access Token"]
    E --> K["WebSocket 连接携带 Access Token"]
```

### 技术选型

| 模块 | 方案 |
|---|---|
| Token 格式 | JWT（HS256 签名） |
| 密码哈希 | bcrypt |
| 服务端（Rust） | `jsonwebtoken` + `bcrypt` crate |
| 客户端存储（Flutter） | `flutter_secure_storage` |
| Token 刷新 | Dio Interceptor 自动处理 401 |

---

## 7. 下一步

认证系统的实现分为三个阶段：

1. **后端**：注册 / 登录接口，JWT 颁发与验证，WebSocket 握手认证
2. **前端**：登录页 UI，Token 本地存储，Dio 拦截器自动刷新
3. **集成**：WebSocket 连接携带 Token，受保护接口统一鉴权
