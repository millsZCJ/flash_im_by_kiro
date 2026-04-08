# 在 Web 平台运行 Flutter 项目

---

## 1. 前提条件

- Flutter SDK 已安装（Web 支持从 Flutter 2.0 起内置，无需额外安装）
- 已安装 Google Chrome

---

## 2. 开启 Web 支持

```bash
flutter config --enable-web
```

验证 Web 设备已识别：
```bash
flutter devices
# 应看到 Chrome 和 Edge 等浏览器设备
```

---

## 3. 运行到 Chrome

```bash
flutter run -d chrome
```

支持热重载，修改代码后按 `r` 即可刷新。

---

## 4. 指定端口（可选）

```bash
flutter run -d chrome --web-port=8080
```

---

## 5. 构建发布包

```bash
flutter build web
```

产物位于 `build/web/`，是标准的静态文件，可直接部署到任意 Web 服务器或 CDN。

```bash
# 本地预览构建结果（需要 Python）
cd build/web
python3 -m http.server 8000
```

---

## 6. 渲染模式说明

Flutter Web 有两种渲染器：

| 模式 | 说明 | 适用场景 |
|------|------|---------|
| `canvaskit`（默认） | 基于 WebAssembly，像素级还原 | 图形要求高的应用 |
| `html` | 使用 HTML/CSS 渲染，包体更小 | 内容型应用 |

指定渲染模式：
```bash
flutter run -d chrome --web-renderer html
flutter build web --web-renderer canvaskit
```

---

## 7. 常见问题

| 问题 | 解决方式 |
|------|---------|
| 请求接口报 CORS 错误 | 服务端添加 `Access-Control-Allow-Origin: *` 响应头 |
| 字体加载慢 | 使用本地字体资源，避免依赖 Google Fonts |
| 热重载不生效 | 按 `R`（大写）做热重启 |
