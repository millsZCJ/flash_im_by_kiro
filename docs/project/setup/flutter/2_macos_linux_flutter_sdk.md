# macOS / Linux 安装和配置 Flutter SDK

---

## macOS

### 1. 系统要求

- macOS 12 (Monterey) 及以上
- 磁盘空间：至少 2.8 GB
- 已安装 Xcode（运行 iOS/macOS 应用需要）

### 2. 推荐方式：使用 Homebrew 安装

```bash
# 安装 Homebrew（已有可跳过）
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 安装 Flutter
brew install --cask flutter
```

### 3. 手动安装方式

1. 前往 https://docs.flutter.dev/get-started/install/macos 下载 `.zip`
2. 解压到目标目录：
   ```bash
   cd ~/development
   unzip ~/Downloads/flutter_macos_*.zip
   ```
3. 添加到 PATH（写入 `~/.zshrc` 或 `~/.bash_profile`）：
   ```bash
   export PATH="$HOME/development/flutter/bin:$PATH"
   ```
4. 使配置生效：
   ```bash
   source ~/.zshrc
   ```

### 4. 验证安装

```bash
flutter --version
flutter doctor
```

---

## Linux

### 1. 系统要求

- 64 位 Linux，推荐 Ubuntu 20.04+
- 依赖工具：`bash curl git unzip xz-utils zip`

### 2. 安装依赖

```bash
sudo apt-get update
sudo apt-get install -y curl git unzip xz-utils zip libglu1-mesa
```

### 3. 下载并配置 SDK

```bash
cd ~/development
wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_*.tar.xz
tar xf flutter_linux_*.tar.xz
```

添加到 PATH（写入 `~/.bashrc`）：
```bash
export PATH="$HOME/development/flutter/bin:$PATH"
source ~/.bashrc
```

### 4. 配置国内镜像（网络不好时）

```bash
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
export PUB_HOSTED_URL=https://pub.flutter-io.cn
```

建议写入 `~/.bashrc` 或 `~/.zshrc` 永久生效。

### 5. 验证安装

```bash
flutter --version
flutter doctor
```
