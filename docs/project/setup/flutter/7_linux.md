# 在 Linux 平台运行 Flutter 项目

---

## 1. 系统要求

- 64 位 Linux，推荐 Ubuntu 20.04+
- 已完成 Flutter SDK 安装（参考第 2 篇）

---

## 2. 安装系统依赖

```bash
sudo apt-get install -y \
  clang cmake ninja-build pkg-config \
  libgtk-3-dev liblzma-dev libstdc++-12-dev
```

---

## 3. 开启 Linux 桌面支持

```bash
flutter config --enable-linux-desktop
```

---

## 4. 验证环境

```bash
flutter doctor
```

确认 `Linux toolchain` 一项为 `[✓]`。

---

## 5. 运行项目

```bash
flutter run -d linux
```

---

## 6. 构建发布包

```bash
flutter build linux
```

产物位于：
```
build/linux/x64/release/bundle/
```

将整个 `bundle` 目录打包分发即可。

---

## 7. 常见问题

| 问题 | 解决方式 |
|------|---------|
| `clang not found` | `sudo apt-get install clang` |
| `cmake not found` | `sudo apt-get install cmake` |
| GTK 相关编译错误 | `sudo apt-get install libgtk-3-dev` |
| 运行后无窗口 | 确认当前环境有图形界面（不支持纯 SSH 终端） |
