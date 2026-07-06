# Implementation Plan: 认证模块（auth）

## Overview

本实现计划将认证模块从内存存储迁移到数据库持久化存储，并最终模块化为独立 crate。
主要包含数据库迁移、数据层实现、业务逻辑重构、HTTP 层更新、应用集成和模块化拆分等任务。

> **注**: Phase 1-5 已完成并模块化到 `server/modules/flash_core` + `server/modules/flash_auth`。
> 原始单 crate 下的文件路径已不存在，实际代码在独立 crate 中。

## Tasks

### Phase 1: 基础设施 ✅

- [x] 1.1 创建数据库迁移文件
  - 创建 `accounts`、`user_profiles`、`auth_credentials`、`sms_codes` 四张表
  - 添加必要索引

- [x] 1.2 更新 `AppState` → `AuthState` 结构（已迁到 `server/modules/flash_auth/src/state.rs`）
  - 使用 `AuthState { db: PgPool, jwt_secret: String }`
  - 通过 `FromRef<AppState> for AuthState` 从主 APP 自动提取
  - 移除内存存储字段

- [x] 1.3 添加配置模块（已迁到 `server/modules/flash_core/src/config.rs`）
  - 定义 `Config` 结构体
  - 实现环境变量读取
  - 支持 `.env` 文件

- [x] 1.4 添加依赖项
  - `bcrypt = "0.15"`、`dotenvy = "0.15"`、`sqlx`、`chrono` 等

### Phase 2: 数据层 ✅

- [x] 2.1 创建 `errors.rs`（`server/modules/flash_auth/src/errors.rs`）
  - 定义 `AuthError` 枚举
  - 实现 `IntoResponse` trait
  - 实现 `From` 转换（sqlx::Error, jsonwebtoken::errors::Error）

- [x] 2.2 创建 `service.rs` — 数据库查询函数（`server/modules/flash_auth/src/service.rs`）
  - 实现 `find_or_create_user`（登录即注册）
  - 实现 `get_password_credential` / `update_password`
  - 实现 `get_user_profile`

- [x] 2.3 SMS 验证码数据层（合并到 `service.rs`）
  - 实现 `upsert_sms_code` / `get_sms_code` / `delete_sms_code`

- [x] 2.4 SessionRepo → 改为 JWT 方案，不再使用数据库 session

### Phase 3: 业务逻辑 ✅

- [x] 3.1 重构 handlers（`server/modules/flash_auth/src/handlers.rs`）
  - 实现 `send_sms`、`login`、`login_with_sms`、`login_with_password`
  - 实现 `set_password`、`profile`、`extract_user_id`

- [x] 3.2 实现密码加密（bcrypt，cost=10）
  - 使用 `bcrypt::hash` 和 `bcrypt::verify`

- [x] 3.3 会话管理 → 使用 JWT token，无需数据库 session

### Phase 4: HTTP 层 ✅

- [x] 4.1 handlers.rs — 6 个 HTTP handler + extract_user_id 工具函数

- [x] 4.2 models.rs（`server/modules/flash_auth/src/models.rs`）
  - LoginType、SmsRequest/SmsResponse、LoginRequest/LoginResponse
  - PasswordRequest、MessageResponse

- [x] 4.3 lib.rs — 模块导出（handlers、models、service、errors、state）

### Phase 5: 应用集成 ✅

- [x] 5.1 更新 `server/src/main.rs`
  - Cargo workspace 格式，依赖 flash_core + flash_auth
  - 启动时连接数据库、构建 AppState

- [x] 5.2 创建 `.env.example`

- [x] 5.3 用户资料 → handlers.rs 中的 `profile` handler

### Phase 6: 测试 ✅

- [x] 6.1 JWT token 生成/验证测试（4 tests in `flash_core/tests/jwt_test.rs`）
- [x] 6.2 密码哈希测试（bcrypt）（4 tests in `flash_auth/tests/bcrypt_test.rs`）
- [x] 6.3 验证码逻辑测试（手机号校验 3 tests in `flash_auth/tests/handlers_test.rs`）
- [x] 6.4 模型序列化测试（9 tests in `flash_auth/tests/models_test.rs`）+ AuthError 测试（3 tests）
    - 注：集成测试（需数据库）暂未实现，纯逻辑测试已覆盖

## Notes

- Phase 1-5 已完成，代码已迁到 workspace 模块化结构
- `cargo build` 通过，接口测试通过
- Phase 6 测试待完成

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1", "1.3", "1.4"] },
    { "id": 1, "tasks": ["1.2", "2.1"] },
    { "id": 2, "tasks": ["2.2", "2.3", "2.4"] },
    { "id": 3, "tasks": ["3.1", "3.2", "3.3", "4.2"] },
    { "id": 4, "tasks": ["4.1", "4.3", "5.1", "5.2"] },
    { "id": 5, "tasks": ["5.3"] },
    { "id": 6, "tasks": ["6.1", "6.2", "6.3", "6.4"] }
  ]
}
```
