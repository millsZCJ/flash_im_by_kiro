# macOS Rust 环境安装指南

---

## 1. 安装 Rust

Rust 官方提供了一键安装脚本 `rustup`，它会同时安装：
- `rustc`：Rust 编译器
- `cargo`：包管理器和构建工具
- `rustup`：工具链版本管理器

打开终端，执行：

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

安装过程中会提示选择安装方式，直接回车选默认（`1) Proceed with standard installation`）即可。

安装完成后，让环境变量生效：

```bash
source $HOME/.cargo/env
```

> 以后每次打开新终端都会自动生效，这一步只需执行一次。

---

## 2. 验证安装

```bash
rustc --version
cargo --version
```

看到版本号输出即表示安装成功，例如：
```
rustc 1.77.0 (aedd173a2 2024-03-17)
cargo 1.77.0 (1865e3433 2024-03-17)
```

---

## 3. 安装 Xcode 命令行工具（macOS 必须）

Rust 编译需要系统链接器，macOS 上由 Xcode 命令行工具提供：

```bash
xcode-select --install
```

弹出安装窗口后点击「安装」，等待完成即可。

---

## 4. 配置国内镜像（网络不好时）

创建或编辑 `~/.cargo/config.toml`：

```bash
cat > ~/.cargo/config.toml << 'EOF'
[source.crates-io]
replace-with = "ustc"

[source.ustc]
registry = "sparse+https://mirrors.ustc.edu.cn/crates.io-index/"
EOF
```

---

## 5. 安装常用工具

```bash
# 代码格式化（官方自带，建议保持更新）
rustup component add rustfmt

# 代码检查 / lint
rustup component add clippy

# cargo-watch：文件变化时自动重新编译（开发时很实用）
cargo install cargo-watch
```

---

## 6. 创建第一个项目

```bash
# 创建新项目
cargo new hello_rust
cd hello_rust

# 运行
cargo run
```

终端输出 `Hello, world!` 说明一切正常。

---

## 7. 安装 VS Code 插件（推荐）

在 VS Code 扩展中搜索并安装：

- `rust-analyzer`：代码补全、跳转定义、内联类型提示，必装
- `Even Better TOML`：`Cargo.toml` 语法高亮

安装后打开任意 `.rs` 文件，`rust-analyzer` 会自动初始化。

---

## 8. 常用命令速查

| 命令 | 说明 |
|------|------|
| `cargo new <name>` | 创建新项目 |
| `cargo run` | 编译并运行 |
| `cargo build` | 仅编译（debug） |
| `cargo build --release` | 编译发布版（优化） |
| `cargo check` | 快速检查语法，不生成二进制 |
| `cargo test` | 运行测试 |
| `cargo add <crate>` | 添加依赖 |
| `cargo fmt` | 格式化代码 |
| `cargo clippy` | 代码检查 |
| `rustup update` | 更新 Rust 到最新版 |
