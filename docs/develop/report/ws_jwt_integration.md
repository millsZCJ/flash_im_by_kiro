# WebSocket + JWT 整合汇报

**日期：** 2026-04-24
**模块：** IM Playground（WebSocket 聊天室 × JWT 用户认证）

---

## 一、背景

此前项目中已独立实现两个模块：

| 模块 | 状态 | 说明 |
|---|---|---|
| JWT 用户认证 | ✅ 完成 | 手机号验证码登录，生成 JWT Token |
| WebSocket 心跳通信 | ✅ 完成 | 基础 echo 连接，无身份认证 |

本次任务：将两者整合，实现**登录后凭 JWT 接入聊天室**，并提供完整的微信风格 UI。

---

## 二、整合方案

### 核心思路

WebSocket 握手阶段浏览器不支持自定义 Header，因此 JWT Token 通过 **URL 参数**传递：

```
ws://localhost:3000/chat_room?token=<jwt>
```

服务器在协议升级前验证 Token，通过后将 `user_id` 绑定到连接上下文，后续消息无需再验证。

### 认证流程

```
用户登录 → 获取 JWT Token
    ↓
建立 WebSocket 连接（URL 携带 Token）
    ↓
服务器验证 Token → 解析 user_id → 查找 nickname
    ↓
连接建立，广播"进入聊天室"
    ↓
实时收发消息（服务器广播给所有在线用户）
    ↓
断开连接，广播"离开聊天室"
```

---

## 三、后端改动

### 新增文件

**`server/src/chat_room.rs`**

聊天室 WebSocket 接口，核心功能：

- `GET /chat_room?token=<jwt>` — 带认证的 WebSocket 升级入口
- 使用 `tokio::sync::broadcast` 实现多用户广播
- 消息格式（JSON）：

```json
{ "type": "chat|join|leave", "sender": "昵称", "content": "消息内容", "time": "HH:mm:ss" }
```

- Token 验证失败直接返回 `401 Unauthorized`，拒绝升级

**`server/src/state.rs`（更新）**

新增 `room_tx: broadcast::Sender<RoomMessage>` 字段，广播频道随服务启动创建，所有连接共享同一频道。

### 路由注册

```
GET /chat_room?token=<jwt>   →  chat_room::chat_room_handler
```

### 启动日志新增

```
聊天室    → WS   ws://127.0.0.1:3000/chat_room?token=<jwt>
```

---

## 四、前端改动

### 新增模块结构

```
lib/
├── features/
│   └── chat_room/
│       ├── model/room_message.dart      # RoomMessage 模型（chat/join/leave）
│       └── api/chat_room_api.dart       # WebSocket 连接管理，Token 注入
│
└── im_playground/                       # 独立 IM Playground
    ├── main_im_playground.dart          # 独立入口
    ├── im_playground_app.dart           # App 根节点 + 认证门控
    ├── shell/
    │   └── im_shell.dart               # 底部导航栏（聊天室 + 我的）
    └── pages/
        ├── chat_room_page.dart          # 聊天室页面
        └── profile_tab_page.dart        # 我的页面
```

### 功能说明

#### 认证门控（`_AuthGate`）

- 未登录 → 显示登录页
- 登录成功 → 自动进入主界面（无需手动跳转）
- 退出登录 → 清除 Token，返回登录页

#### 聊天室页面（`ChatRoomPage`）

- 登录后自动建立 WebSocket 连接（Token 注入 URL）
- 消息气泡：自己发的消息靠右（绿色），他人消息靠左（白色）
- 系统消息（进入/离开）居中灰色气泡
- 连接状态指示点（绿/黄/灰）实时显示
- 断线后显示"重连"按钮
- 消息到达自动滚动到底部

#### 我的页面（`ProfileTabPage`）

- 展示头像、昵称、用户 ID
- 显示手机号和 Token 预览
- 退出登录按钮

#### 底部导航栏（`ImShell`）

- 聊天（chat_bubble 图标）
- 我（person 图标）
- 选中项绿色高亮，未选中灰色

---

## 五、运行方式

### 启动后端

```bash
cd server
cargo run
```

### 启动 IM Playground（独立入口）

```bash
cd client/flash_im
flutter run -t lib/im_playground/main_im_playground.dart -d chrome
```

### 原有 Playground（不受影响）

```bash
flutter run -t lib/playground/main_playground.dart -d chrome
```

---

## 六、验证结果

| 验证项 | 结果 |
|---|---|
| 未登录无法建立 `/chat_room` 连接（返回 401） | ✅ |
| 登录后 Token 自动注入 WebSocket URL | ✅ |
| 多用户同时在线，消息实时广播 | ✅ |
| 用户进入/离开聊天室有系统提示 | ✅ |
| 自己发的消息靠右绿色，他人消息靠左白色 | ✅ |
| 退出登录后 Token 清除，重新进入需登录 | ✅ |
| 后端编译无错误 | ✅ |
| 前端静态分析无 warning | ✅ |

---

## 七、已知限制（Playground 阶段）

| 限制 | 说明 |
|---|---|
| Token 存内存 | 刷新页面需重新登录 |
| 用户数据存内存 | 重启服务后用户数据清空 |
| 自己消息的识别 | 通过第一条 join 消息推断 nickname，多设备登录同一账号时可能误判 |
| 无消息持久化 | 历史消息不保存，刷新后消失 |

以上均为 Playground 阶段的合理简化，正式版本需引入数据库和 Redis。
