# POST /auth/login — 验证码登录

## 接口说明

使用手机号 + 验证码登录。验证通过后返回 JWT Token 和用户 ID。
若手机号不存在则自动注册（登录即注册），默认昵称为手机号。

---

## 请求

| 项目 | 内容 |
|---|---|
| 方法 | `POST` |
| 路径 | `/auth/login` |
| Content-Type | `application/json` |

### 请求体

```json
{
  "phone": "13800138000",
  "code": "026895"
}
```

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| phone | string | ✅ | 手机号 |
| code | string | ✅ | 验证码（由 `/auth/sms` 获取） |

---

## curl 命令

```bash
curl -s -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"phone":"13800138000","code":"026895"}'
```

---

## 响应

### 成功 200

```json
{
  "token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiI5YzVlODM2ZC0wZjE4LTRiZjctOTkxMS1mYTZkZjgzN2ZjNzEiLCJpYXQiOjE3NzY5OTYwNDUsIm5iZiI6MTc3Njk5NjA0NSwiZXhwIjoxNzc3NjAwODQ1fQ.CWscfrH5qo38fNqxT8_DB4YTYFzQZd13smAcIiJ85pE",
  "user_id": "9c5e836d-0f18-4bf7-9911-fa6df837fc71",
  "is_new_user": false
}
```

| 字段 | 类型 | 说明 |
|---|---|---|
| token | string | JWT Token，有效期 7 天 |
| user_id | string | 用户唯一 ID（UUID v4） |
| is_new_user | bool | `true` 表示本次自动注册，`false` 表示已有账号 |

### JWT Payload 解码

Token 的 Payload 部分解码后内容：

```json
{
  "sub": "9c5e836d-0f18-4bf7-9911-fa6df837fc71",
  "iat": 1776996045,
  "nbf": 1776996045,
  "exp": 1777600845
}
```

| 字段 | 说明 |
|---|---|
| sub | 用户 ID |
| iat | 签发时间（Unix 时间戳） |
| nbf | 生效时间（与 iat 相同，立即生效） |
| exp | 过期时间（iat + 7 天） |

### 失败 401 — 验证码错误或已过期

```
HTTP 401 Unauthorized
```

---

## 测试结果

| 测试项 | 结果 |
|---|---|
| 验证码正确，返回 JWT Token | ✅ |
| JWT 包含 sub / iat / nbf / exp 字段 | ✅ |
| 手机号已存在，`is_new_user` 为 false | ✅ |
| 手机号不存在，自动注册，`is_new_user` 为 true | ✅ |
| 验证码错误，返回 401 | ✅ |
| 验证码使用后删除（一次性） | ✅ |

### 实际响应记录

```
请求时间：2026-04-24
手机号：13800138000
验证码：026895
user_id：9c5e836d-0f18-4bf7-9911-fa6df837fc71
is_new_user：false（该用户之前已注册）
```

---

## 备注

- Token 有效期 7 天，过期后需重新登录
- 同一手机号多次登录返回相同的 `user_id`
- 验证码一次性，登录成功后立即从内存中删除
