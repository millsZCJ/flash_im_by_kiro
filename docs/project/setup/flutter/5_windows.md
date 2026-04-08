# 在 Windows 平台运行 Flutter 项目

---

## 1. 系统要求

- Windows 10/11 64位（版本 1903 及以上）
- 已安装 Visual Studio 2022（不是 VS Code）

---

## 2. 安装 Visual Studio 2022

前往 https://visualstudio.microsoft.com 下载 Community 版（免费）。

安装时，在「工作负载」中勾选：
- **使用 C++ 的桌面开发**

> 这是运行 Windows 桌面应用的必要依赖，不可省略。

---

## 3. 开启 Windows 桌面支持

```powershell
flutter config --enable-windows-desktop
```

---

## 4. 验证环境

```powershell
flutter doctor
```

确认 `Windows Version` 和 `Visual Studio` 两项均为 `[✓]`。

---

## 5. 运行项目

```powershell
flutter run -d windows
```

首次编译较慢（需要几分钟），后续热重载会很快。

---

## 6. 构建发布包

```powershell
flutter build windows
```

产物位于：
```
build\windows\x64\runner\Release\
```

将整个 `Release` 文件夹打包分发即可，无需安装 Flutter 运行时。

---

## 7. 常见问题

| 问题 | 解决方式 |
|------|---------|
| `Visual Studio not installed` | 确认安装了「C++ 桌面开发」工作负载 |
| 编译报 MSBuild 错误 | 以管理员身份运行终端重试 |
| 运行后窗口一闪而过 | 检查 `main()` 是否有未捕获异常 |
