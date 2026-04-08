# 在 iOS / macOS 平台运行 Flutter 项目

> 必须在 macOS 系统上操作，Windows/Linux 无法构建 iOS/macOS 应用。

---

## 一、iOS

### 1. 安装 Xcode

在 App Store 搜索 `Xcode` 安装（约 10 GB），安装后运行一次完成初始化。

```bash
# 配置命令行工具
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
```

### 2. 安装 CocoaPods

```bash
sudo gem install cocoapods
```

> 如果 gem 速度慢，可换国内源：
> ```bash
> gem sources --add https://gems.ruby-china.com/ --remove https://rubygems.org/
> ```

### 3. 运行到 iOS 模拟器

```bash
# 打开模拟器
open -a Simulator

# 运行项目
flutter run
```

### 4. 运行到 iOS 真机

1. 用 USB 连接 iPhone
2. 在 Xcode 中打开项目的 `ios/Runner.xcworkspace`
3. 选择你的开发者账号（需要 Apple ID，免费账号即可）：
   `Signing & Capabilities` → `Team` → 选择账号
4. 信任设备：iPhone 上「设置 → 通用 → VPN与设备管理」→ 信任证书
5. 回到终端运行：
   ```bash
   flutter run
   ```

---

## 二、macOS 桌面

### 1. 开启 macOS 桌面支持

```bash
flutter config --enable-macos-desktop
```

### 2. 运行

```bash
flutter run -d macos
```

### 3. 常见问题

| 问题 | 解决方式 |
|------|---------|
| `CocoaPods not installed` | 执行 `sudo gem install cocoapods` |
| 签名错误 | 在 Xcode 中重新选择 Team |
| 模拟器版本不匹配 | 在 Xcode → Preferences → Components 中下载对应版本 |
