# Conversation 功能开发汇报

> 全程通过 AI 对话驱动，从 0 到 1 完成会话模块的完整闭环。

---

## 一、服务端：模拟数据接口

**技术栈**：Rust + Axum

在 `server/src/main.rs` 中新增 `/conversation` 接口，返回 20 条模拟会话数据，每项包含三个字段：

| 字段 | 类型 | 说明 |
|------|------|------|
| title | String | 会话标题（联系人/群名） |
| lastMsg | String | 最后一条消息 |
| time | String | 消息时间 |

**关键点**：后续发现 Flutter Web 无法请求接口，原因是浏览器的同源策略限制。通过引入 `tower-http` 的 `CorsLayer` 并设置 `allow_origin(Any)` 解决跨域问题。

---

## 二、数据留存：接口响应快照

通过 `curl` 请求真实接口，将响应数据保存至：

```
docs/data/playground/conversation/list.json
```

作为离线参考数据，方便后续开发和对照。

---

## 三、客户端分层架构

**技术栈**：Flutter + Dio

按职责将代码拆分为四层：

```
lib/
├── core/network/
│   ├── app_config.dart       # IP/端口集中配置
│   └── http_client.dart      # Dio 单例
└── features/conversation/
    ├── model/conversation.dart     # 实体类
    ├── api/conversation_api.dart   # 请求层
    ├── view/conversation_page.dart # 页面
    └── widget/conversation_item.dart # 单条 item
```

**关键设计**：
- IP 地址集中在 `AppConfig` 管理，变化时只改一处
- `ConversationApi` 支持注入自定义 `Dio` 实例，便于测试时替换
- 视图层只负责展示，不直接依赖网络细节

---

## 四、游乐场机制

正式产品入口（`main.dart`）与游乐场入口（`lib/playground/main_playground.dart`）完全隔离，打包时互不影响。

```bash
# 运行游乐场
flutter run -d chrome -t lib/playground/main_playground.dart

# 运行正式产品
flutter run -d chrome
```

新增案例只需两步：在 `playground/cases/` 下建文件，在 `_cases` 列表注册一行。

---

## 五、接口测试

测试文件位于 `test/features/conversation/conversation_api_test.dart`，覆盖两个场景：

1. **集成测试**：请求真实服务，验证返回列表非空、数量为 20
2. **单元测试**：验证 `Conversation.fromJson` 字段解析正确

```bash
flutter test test/features/conversation/conversation_api_test.dart
```

---

## 六、UI 还原

参考微信会话列表截图，实现以下细节：

- 头像根据名字首字生成固定色块（无需图片资源）
- 分隔线从头像右侧起始（`indent: 72`），与微信一致
- 底部导航栏四 tab，「发现」带红点角标
- 主壳使用 `IndexedStack` 保持各 tab 状态

---

## 总结

| 阶段 | 产出 |
|------|------|
| 服务端接口 | `/conversation` REST 接口 + CORS 支持 |
| 数据快照 | `docs/data/playground/conversation/list.json` |
| 网络层 | AppConfig + HttpClient + ConversationApi |
| 视图层 | ConversationPage + ConversationItem + MainShell |
| 测试 | 集成测试 + 实体解析单元测试 |
| 游乐场 | 独立入口，不影响正式打包 |
