# 项目长期记忆

## IM 协议 v0.0.1

- 已完成：proto/ws.proto、server/modules/im-ws、scripts/proto/gen.ps1、client/modules/flash_im_core。
- `server/modules/im-ws/build.rs` 中 proto 路径应使用 `../../../proto/`（crate 根 → 项目根），因为 workspace 根目录是 `server/`。
- 客户端主工程 pubspec 路径是 `client/flash_im/pubspec.yaml`，不是 `client/pubspec.yaml`。

## 本地工具

- 当前环境未安装系统级 `protoc` 时，可将 protobuf 官方 release 下载到 `.tools/protoc` 并将 `.tools/protoc/bin` 加入 PATH。
- `protoc-gen-dart` 可通过 `protoc_plugin` 包提供，实际可执行名为 `protoc_plugin`；可用 `.tools/bin/protoc-gen-dart` 包装器执行 `dart run protoc_plugin:protoc_plugin`。

## IM Core v0.0.1

- 客户端主入口为 `client/flash_im/lib/main.dart`（不是 `client/lib/main.dart`）。
- `flash_im_core` 通过 `RepositoryProvider` 向子树提供 `WsClient`；`AuthCubit` 的 `BlocListener` 负责在 authenticated/unauthenticated 时连接/断开 WebSocket。
- `im-ws` crate 使用直接依赖而非 `workspace = true`（因为 `server/Cargo.toml` 未定义 `[workspace.dependencies]`）。
- 旧 `server/src/ws.rs` 与 `server/src/chat_room.rs` 已被删除，`/ws` 与 `/chat_room` 路由移除，统一由 `/ws/im` 提供新协议。
