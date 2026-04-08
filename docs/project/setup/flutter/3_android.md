# 在 Android 平台运行 Flutter 项目

---

## 1. 安装 Android Studio

前往 https://developer.android.com/studio 下载安装。

安装时勾选：
- Android SDK
- Android SDK Platform-Tools
- Android Virtual Device（模拟器）

---

## 2. 配置 Android SDK

打开 Android Studio → `Settings` → `Languages & Frameworks` → `Android SDK`

确认已安装：
- SDK Platforms：Android 14（或最新版）
- SDK Tools：Android SDK Build-Tools、Android Emulator、Platform-Tools

---

## 3. 接受 Android 许可证

```bash
flutter doctor --android-licenses
```

全部输入 `y` 确认。

---

## 4. 运行到模拟器

**创建模拟器**：Android Studio → `Device Manager` → `Create Device`，选择设备型号和系统镜像，完成后启动。

**运行项目**：
```bash
flutter run
```

Flutter 会自动检测到运行中的模拟器并部署。

---

## 5. 运行到真机

1. 手机开启「开发者选项」（连续点击「关于手机」中的版本号 7 次）
2. 开启「USB 调试」
3. 用数据线连接电脑，手机上选择「允许调试」
4. 验证设备已识别：
   ```bash
   flutter devices
   ```
5. 运行：
   ```bash
   flutter run
   ```

---

## 6. 常见问题

| 问题 | 解决方式 |
|------|---------|
| `flutter doctor` 提示 Android SDK 未找到 | 在 Android Studio 中确认 SDK 路径，或手动设置 `ANDROID_HOME` 环境变量 |
| 模拟器启动慢 | 在 BIOS 中开启 Intel VT-x / AMD-V 虚拟化 |
| 真机无法识别 | 更换数据线，或安装对应品牌的 USB 驱动 |
