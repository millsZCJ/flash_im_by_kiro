# Implementation Plan: 认证模块（auth）

## Overview

本实现计划将认证模块从内存存储迁移到数据库持久化存储。主要包含数据库迁移、数据层实现、业务逻辑重构、HTTP 层更新和应用集成等任务。

## Tasks

### Phase 1: 基础设施

- [x] 1.1 创建数据库迁移文件 `003_user_auth_update.sql`
  - 添加 `phone` 字段到 users 表
  - 将 `username` 和 `email` 改为可空
  - 创建 `sms_codes` 表
  - 添加必要索引

- [ ] 1.2 更新 `AppState` 结构
  - 移除内存存储字段（`users`, `sms_codes`）
  - 添加数据库连接池 `db: DbPool`
  - 添加配置字段 `sms_code_ttl`, `token_ttl`

- [x] 1.3 添加配置模块 `server/src/config.rs`
  - 定义 `Config` 结构体
  - 实现环境变量读取
  - 支持 `.env` 文件

- [x] 1.4 添加依赖项到 `Cargo.toml`
  - `bcrypt = "0.15"` (密码加密)
  - `dotenvy = "0.15"` (环境变量)

### Phase 2: 数据层

- [-] 2.1 创建 `server/src/auth/errors.rs`
  - 定义 `AuthError` 枚举
  - 实现 `IntoResponse` trait
  - 实现 `From` 转换（DbError, JWT Error）

- [~] 2.2 创建 `server/src/auth/repo.rs` - UserRepo
  - 实现 `UserRepo::find_by_phone`
  - 实现 `UserRepo::create`
  - 实现 `UserRepo::update_password`

- [~] 2.3 实现 `SessionRepo`
  - 实现 `SessionRepo::create`
  - 实现 `SessionRepo::find_by_token`
  - 实现 `SessionRepo::delete_by_token`

- [~] 2.4 实现 `SmsCodeRepo`
  - 实现 `SmsCodeRepo::create`
  - 实现 `SmsCodeRepo::find_and_validate`
  - 实现 `SmsCodeRepo::delete_by_phone`

### Phase 3: 业务逻辑

- [~] 3.1 重构 `server/src/auth/service.rs`
  - 移除内存相关代码
  - 实现 `AuthService::send_sms_code`
  - 实现 `AuthService::login_with_sms`
  - 实现 `AuthService::login_with_password`

- [~] 3.2 实现密码加密
  - 创建 `hash_password` 函数
  - 创建 `verify_password` 函数
  - 使用 bcrypt cost = 12

- [~] 3.3 实现会话管理
  - 登录时创建 session 记录
  - 支持 token 验证时检查 session
  - 清理过期 session 的定时任务（可选）

### Phase 4: HTTP 层

- [~] 4.1 更新 `server/src/auth/handlers.rs`
  - 重构 `send_sms` 使用数据库
  - 重构 `login` 使用 `AuthService`
  - 使用 `AuthError` 统一错误处理

- [~] 4.2 更新 `server/src/auth/models.rs`
  - 添加 `User` 数据库模型
  - 添加 `Session` 数据库模型
  - 添加 `SmsCode` 数据库模型

- [~] 4.3 更新 `server/src/auth/mod.rs`
  - 导出 `errors` 模块
  - 导出 `repo` 模块
  - 更新公开接口

### Phase 5: 应用集成

- [~] 5.1 更新 `server/src/main.rs`
  - 加载配置
  - 初始化数据库连接池
  - 更新 `AppState::new` 签名

- [~] 5.2 创建 `.env.example`
  - `DATABASE_URL` 示例
  - `JWT_SECRET` 说明
  - 其他配置项

- [~] 5.3 更新 `server/src/user.rs`
  - 使用数据库查询用户信息
  - 从 JWT token 获取 user_id
  - 返回数据库中的用户信息

### Phase 6: 测试

- [~] 6.1 密码加密测试
  - 测试 `hash_password` 输出格式
  - 测试 `verify_password` 正确密码
  - 测试 `verify_password` 错误密码

- [~] 6.2 验证码逻辑测试
  - 测试验证码生成
  - 测试验证码过期检查

- [~] 6.3 创建测试辅助模块
  - 测试数据库设置
  - 测试配置
  - 清理函数

- [~] 6.4 登录流程测试
  - 测试短信登录完整流程
  - 测试密码登录完整流程
  - 测试新用户注册

## Notes

- 任务依赖关系见 Task Dependency Graph 章节
- 预估总工作量: 9-13 小时，共 23 个任务
- 测试任务（Phase 6）可在主要功能完成后并行开发

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
