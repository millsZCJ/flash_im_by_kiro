# GET /user/profile — 获取用户信息

## 接口说明

从请求头中读取 JWT Token，解析出 `user_id`，返回对应的用户信息。
Token 无效或缺失时返回 401。

---

## 请求

| 项目 | 内容 |
|---|---|
| 方法 | `GET` |
| 路径 | `/user/profile` |
| 认证方式 | Bearer Token（Authorization Header） |

### 请求头

```
Authorization: Bearer <token>
```

---

## curl 命令

### 正常请求（携带有效 Token）

```bash
curl -s http://localhost:3000/user/profile \
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiI5YzVlODM2ZC0wZjE4LTRiZjctOTkxMS1mYTZkZjgzN2ZjNzEiLCJpYXQiOjE3NzY5OTYwNDUsIm5iZiI6MTc3Njk5NjA0NSwiZXhwIjoxNzc3NjAwODQ1fQ.CWscfrH5qo38fNqxT8_DB4YTYFzQZd13smAcIiJ85pE"
```

### 无 Token（验证 401）

```bash
curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/user/profile
```

### 无效 Token（验证 401）

```bash
curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/user/profile \
  -H "Authorization: Bearer invalid.token.here"
```

---

## 响应

### 成功 200

```json
{
  "user_id": "9c5e836d-0f18-4bf7-9911-fa6df837fc71",
  "phone": "13800138000",
  "nickname": "13800138000",
  "avatar": "https://api.dicebear.com/7.x/thumbs/svg?seed=9c5e836d-0f18-4bf7-9911-fa6df837fc71"
}
```

| 字段 | 类型 | 说明 |
|---|---|---|
| user_id | string | 用户唯一 ID |
| phone | string | 手机号 |
| nickname | string | 昵称（默认为手机号） |
| avatar | string | 头像 URL（DiceBear 生成，以 user_id 为种子） |

### 失败 401 — Token 缺失或无效

```
HTTP 401 Unauthorized
```

触发场景：
- 未携带 `Authorization` Header
- Token 格式错误
- Token 签名不合法
- Token 已过期（exp 超时）
- Token 尚未生效（早于 nbf）

---

## 测试结果

| 测试项 | 结果 |
|---|---|
| 携带有效 Token，返回用户信息 | ✅ |
| user_id 与登录返回一致 | ✅ |
| 头像 URL 以 user_id 为种子生成 | ✅ |
| 无 Token，返回 401 | ✅ |
| 无效 Token，返回 401 | ✅ |

### 实际响应记录

```
请求时间：2026-04-24

--- 正常请求 ---
{
  "user_id": "9c5e836d-0f18-4bf7-9911-fa6df837fc71",
  "phone": "13800138000",
  "nickname": "13800138000",
  "avatar": "https://api.dicebear.com/7.x/thumbs/svg?seed=9c5e836d-0f18-4bf7-9911-fa6df837fc71"
}

--- 无 Token ---
HTTP 401
```

---

## 备注

- 头像使用 [DiceBear Thumbs](https://www.dicebear.com/) 风格，以 `user_id` 为随机种子，同一用户头像固定不变
- 生产环境中昵称和头像应支持用户自定义修改
- Token 通过 `Authorization: Bearer <token>` 传递，这是 HTTP API 的标准方式
