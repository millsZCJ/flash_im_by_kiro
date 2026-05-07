# 认证登录 API

## 1. 发送短信验证码

**接口**：`POST /auth/sms`

**请求体**：
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

---

## 2. 登录

**接口**：`POST /auth/login`

### 2.1 短信验证码登录

**请求体**：
```json
{
  "login_type": "sms",
  "phone": "13800138000",
  "code": "123456"
}
```

### 2.2 密码登录

**请求体**：
```json
{
  "login_type": "password",
  "phone": "13800138000",
  "password": "123456"
}
```

**响应**（两种方式相同）：
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "is_new_user": false
}
```

---

## 3. 内置测试账号

以下账号可用于密码登录测试：

| 手机号 | 密码 |
|--------|------|
| 13800138000 | 123456 |
| 13800138001 | password |
| 13800138002 | abc123 |
| 18888888888 | test1234 |

---

## 4. 登录类型说明

### LoginType 枚举

```rust
pub enum LoginType {
    /// 短信验证码登录
    Sms,
    /// 密码登录
    Password,
}
```

**JSON 格式**：
- `"sms"` - 短信验证码登录
- `"password"` - 密码登录

---

## 5. 错误码

| HTTP 状态码 | 说明 |
|------------|------|
| 200 | 登录成功 |
| 400 | 请求参数错误（缺少必填字段） |
| 401 | 认证失败（验证码或密码错误） |
| 500 | 服务器内部错误 |

---

## 6. 测试示例

### 6.1 短信验证码登录流程

```bash
# 1. 发送验证码
curl -X POST http://127.0.0.1:3000/auth/sms \
  -H "Content-Type: application/json" \
  -d '{"phone":"13800138000"}'

# 响应：{"code":"123456","message":"..."}

# 2. 使用验证码登录
curl -X POST http://127.0.0.1:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "login_type":"sms",
    "phone":"13800138000",
    "code":"123456"
  }'
```

### 6.2 密码登录流程

```bash
# 直接使用密码登录
curl -X POST http://127.0.0.1:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "login_type":"password",
    "phone":"13800138000",
    "password":"123456"
  }'
```

### 6.3 使用 token 访问受保护接口

```bash
# 获取用户信息
curl -X GET http://127.0.0.1:3000/user/profile \
  -H "Authorization: Bearer <your_token>"
```

---

## 7. 注意事项

1. **验证码一次性**：短信验证码验证成功后会立即删除，不可重复使用
2. **登录即注册**：首次登录会自动创建用户账号
3. **密码登录限制**：目前仅支持内置测试账号，生产环境需要实现密码加密存储
4. **Token 有效期**：JWT token 有效期为 7 天
