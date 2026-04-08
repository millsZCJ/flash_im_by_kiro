# 在 HarmonyOS 平台运行 Flutter 项目

> HarmonyOS 的 Flutter 支持由华为与社区共同维护，使用独立的 Flutter 分支（flutter-ohos），与官方 Flutter 并行存在。

---

## 1. 前提条件

- macOS 或 Windows 开发机
- 已安装官方 Flutter SDK
- 华为开发者账号（https://developer.huawei.com）

---

## 2. 安装 DevEco Studio

前往 https://developer.huawei.com/consumer/cn/deveco-studio 下载安装。

DevEco Studio 是 HarmonyOS 的官方 IDE，相当于 Android Studio 的角色。

安装后完成 SDK 初始化，下载：
- HarmonyOS SDK
- Node.js（DevEco 内置，按提示安装）

---

## 3. 获取 flutter-ohos 分支

```bash
git clone https://gitee.com/openharmony-sig/flutter_flutter.git -b dev flutter-ohos
```

配置环境变量，将 `flutter-ohos/bin` 加入 PATH：

```bash
# macOS/Linux，写入 ~/.zshrc 或 ~/.bashrc
export PATH="$HOME/flutter-ohos/bin:$PATH"
```

> 注意：`flutter-ohos` 和官方 `flutter` 命令需要分开管理，建议用不同的 shell alias 区分。

---

## 4. 安装 ohpm（鸿蒙包管理器）

```bash
# ohpm 随 DevEco Studio 一起安装，配置路径即可
export PATH="$DEVECO_HOME/tools/ohpm/bin:$PATH"
```

---

## 5. 配置签名

1. 在 DevEco Studio 中创建项目
2. `File` → `Project Structure` → `Signing Configs`
3. 勾选「Automatically generate signature」，登录华为开发者账号完成签名

---

## 6. 运行到 HarmonyOS 模拟器

1. 在 DevEco Studio 中打开 `Device Manager`，创建并启动模拟器
2. 在终端使用 flutter-ohos 运行：

```bash
flutter-ohos run -d <device-id>
```

查看设备列表：
```bash
flutter-ohos devices
```

---

## 7. 运行到真机

1. 手机开启「开发者模式」（设置 → 关于手机 → 版本号连点 7 次）
2. 开启「USB 调试」
3. 连接电脑后：

```bash
flutter-ohos run
```

---

## 8. 构建发布包

```bash
flutter-ohos build hap
```

产物为 `.hap` 文件，可通过 DevEco Studio 上传至华为应用市场。

---

## 9. 参考资源

- flutter-ohos 仓库：https://gitee.com/openharmony-sig/flutter_flutter
- HarmonyOS 开发者文档：https://developer.huawei.com/consumer/cn/doc/
- 社区适配进度：https://gitee.com/openharmony-sig/flutter_samples
