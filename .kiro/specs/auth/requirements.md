# 认证模块（auth）需求文档

## 1. 功能概述

基于 `docs/api/auth_login.md` 的设计，实现完整的用户认证系统，支持短信验证码登录、密码登录、JWT token 管理以及用户注册（首次登录自动创建账号）。

## 2. 用户场景

### 2.1 短信验证码登录

**作为** 用户  
**我想要** 通过手机号和短信验证码登录  
**以便于** 无需记忆密码即可快速访问系统

**验收标准：**
- AC-2.1.1: 用户提交手机号后，系统生成 6 位数字验证码
- AC-2.1.2: 验证码在 playground 模式下直接返回给客户端（生产环境需接入短信服务）
- AC-2.1.3: 验证码验证成功后立即删除，不可重复使用
- AC-2.1.4: 验证码登录成功后返回 JWT token 和用户信息

### 2.2 密码登录

**作为** 用户  
**我想要** 通过手机号和密码登录  
**以便于** 使用已注册的凭据访问系统

**验收标准：**
- AC-2.2.1: 密码使用 bcrypt 进行加密存储
- AC-2.2.2: 密码验证失败时返回 401 错误
- AC-2.2.3: 密码登录成功后返回 JWT token 和用户信息

### 2.3 用户注册（登录即注册）

**作为** 新用户  
**我想要** 首次登录时自动创建账号  
**以便于** 无需单独注册流程即可使用系统

**验收标准：**
- AC-2.3.1: 首次登录的用户自动在数据库中创建记录
- AC-2.3.2: 新用户的手机号作为默认昵称
- AC-2.3.3: 返回 `is_new_user` 标识，告知客户端是否为新用户

### 2.4 JWT Token 管理

**作为** 系统  
**我想要** 生成和验证 JWT token  
**以便于** 实现无状态的用户认证

**验收标准：**
- AC-2.4.1: Token 有效期为 7 天
- AC-2.4.2: Token 包含 user_id（sub）、签发时间（iat）、生效时间（nbf）、过期时间（exp）
- AC-2.4.3: Token 验证时检查签名、过期时间和生效时间

### 2.5 服务端会话管理

**作为** 系统  
**我想要** 在服务端记录用户会话  
**以便于** 支持主动登出和会话管理

**验收标准：**
- AC-2.5.1: 登录成功后将 token 存入 sessions 表
- AC-2.5.2: 会话记录包含 user_id、token、过期时间
- AC-2.5.3: 支持通过删除 session 实现登出功能

## 3. 技术约束

### 3.1 技术栈

- **服务端框架**：Rust + Axum
- **数据库**：PostgreSQL + sqlx
- **认证**：JWT（已有 `server/src/jwt.rs`）
- **密码加密**：bcrypt

### 3.2 数据库表结构

**users 表（调整后）：**
| 字段 | 类型 | 说明 |
|------|------|------|
| id | UUID | 主键 |
| phone | VARCHAR(20) | 手机号，唯一，非空 |
| username | VARCHAR(50) | 用户名，唯一，可为空 |
| email | VARCHAR(100) | 邮箱，唯一，可为空 |
| password_hash | VARCHAR(255) | 密码哈希，可为空（短信登录用户） |
| created_at | TIMESTAMPTZ | 创建时间 |
| updated_at | TIMESTAMPTZ | 更新时间 |

**sessions 表：**
| 字段 | 类型 | 说明 |
|------|------|------|
| id | UUID | 主键 |
| user_id | UUID | 外键，关联 users.id |
| token | VARCHAR(255) | JWT token |
| expires_at | TIMESTAMPTZ | 过期时间 |
| created_at | TIMESTAMPTZ | 创建时间 |

**sms_codes 表（新增）：**
| 字段 | 类型 | 说明 |
|------|------|------|
| id | UUID | 主键 |
| phone | VARCHAR(20) | 手机号 |
| code | VARCHAR(6) | 验证码 |
| expires_at | TIMESTAMPTZ | 过期时间 |
| created_at | TIMESTAMPTZ | 创建时间 |

## 4. API 接口

### 4.1 发送短信验证码

**请求**：`POST /auth/sms`
```json
{
  "phone": "13800138000"
}
```

**响应**：
```json
{
  "code": "123456",
  "message": "验证码已发送（playground 模式，直接返回）"
}
```

### 4.2 登录

**请求**：`POST /auth/login`

短信验证码登录：
```json
{
  "login_type": "sms",
  "phone": "13800138000",
  "code": "123456"
}
```

密码登录：
```json
{
  "login_type": "password",
  "phone": "13800138000",
  "password": "123456"
}
```

**响应**：
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "is_new_user": false
}
```

### 4.3 错误响应

| HTTP 状态码 | 说明 |
|------------|------|
| 200 | 成功 |
| 400 | 请求参数错误 |
| 401 | 认证失败 |
| 500 | 服务器内部错误 |

## 5. 非功能性需求

### 5.1 安全性

- NFR-5.1.1: 密码必须使用 bcrypt 加密存储，cost factor ≥ 10
- NFR-5.1.2: JWT secret 从环境变量读取，不硬编码
- NFR-5.1.3: 验证码有效期不超过 5 分钟

### 5.2 性能

- NFR-5.2.1: 登录接口响应时间 < 500ms（正常负载）
- NFR-5.2.2: 数据库连接池最大连接数可配置

### 5.3 可维护性

- NFR-5.3.1: 代码分层：handlers（HTTP 层）、service（业务逻辑）、models（数据结构）
- NFR-5.3.2: 错误处理统一使用 thiserror 定义错误类型
- NFR-5.3.3: 所有公开函数有文档注释

## 6. 迁移计划

### 6.1 数据库迁移

1. 创建新的迁移文件调整 users 表结构
2. 创建 sms_codes 表
3. 保留原有 sessions 表

### 6.2 代码迁移

1. 将内存存储替换为数据库操作
2. 保持现有 API 接口不变
3. 更新 AppState 以包含数据库连接池
