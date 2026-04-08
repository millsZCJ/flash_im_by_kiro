# Windows 安装和配置 Flutter SDK

## 1. 系统要求

- Windows 10/11 64位
- 磁盘空间：至少 2.5 GB
- PowerShell 5.0 或以上
- Git for Windows

---

## 2. 安装 Git

前往 https://git-scm.com/download/win 下载安装，全程默认选项即可。

安装后验证：
```powershell
git --version
```

---

## 3. 下载 Flutter SDK

1. 前往 https://docs.flutter.dev/get-started/install/windows
2. 点击下载最新稳定版 `.zip` 文件
3. 解压到一个**不含中文和空格**的路径，推荐：
   ```
   C:\dev\flutter
   ```
   > 不要放在 `C:\Program Files\` 下，会有权限问题

---

## 4. 配置环境变量

1. 搜索「编辑系统环境变量」→ 点击「环境变量」
2. 在「用户变量」的 `Path` 中，新增：
   ```
   C:\dev\flutter\bin
   ```
3. 点击确定保存

验证（重新打开终端）：
```powershell
flutter --version
```

---

## 5. 配置国内镜像（可选，网络不好时必须）

在系统环境变量中新增两个变量：

| 变量名 | 值 |
|--------|-----|
| `FLUTTER_STORAGE_BASE_URL` | `https://storage.flutter-io.cn` |
| `PUB_HOSTED_URL` | `https://pub.flutter-io.cn` |

---

## 6. 运行环境检测

```powershell
flutter doctor
```

根据输出结果，逐项解决带 `[✗]` 的问题。常见缺失项：
- Android Studio / Android SDK → 参考平台运行教程
- Visual Studio（运行 Windows 桌面应用需要）

---

## 7. 安装 VS Code 插件（推荐编辑器）

在 VS Code 扩展中搜索并安装：
- `Flutter`
- `Dart`

安装后重启 VS Code，即可获得代码补全、热重载等支持。
