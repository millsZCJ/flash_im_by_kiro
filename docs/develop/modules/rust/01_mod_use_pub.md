# Rust 模块系统：mod、use、pub

## 概述

Rust 使用模块系统来组织代码，主要涉及三个关键字：
- `mod`：声明模块
- `use`：导入模块或项
- `pub`：控制可见性

## 一、mod - 模块声明

### 1.1 内联模块

```rust
// 在同一文件中定义模块
mod math {
    pub fn add(a: i32, b: i32) -> i32 {
        a + b
    }
}

fn main() {
    let result = math::add(1, 2);
}
```

### 1.2 文件模块

**方式一：单文件模块**

```
src/
├── main.rs
└── math.rs
```

```rust
// main.rs
mod math;  // 声明模块，Rust 会查找 math.rs

fn main() {
    math::add(1, 2);
}
```

```rust
// math.rs
pub fn add(a: i32, b: i32) -> i32 {
    a + b
}
```

**方式二：目录模块（推荐）**

```
src/
├── main.rs
└── math/
    ├── mod.rs      # 模块入口
    ├── add.rs
    └── subtract.rs
```

```rust
// main.rs
mod math;

fn main() {
    math::add(1, 2);
}
```

```rust
// math/mod.rs
pub mod add;        // 声明子模块
pub mod subtract;

// 可以在这里重新导出
pub use add::add;
pub use subtract::subtract;
```

```rust
// math/add.rs
pub fn add(a: i32, b: i32) -> i32 {
    a + b
}
```

### 1.3 模块路径规则

| 声明位置 | 模块声明 | Rust 查找的文件 |
|---------|---------|----------------|
| `src/main.rs` | `mod foo;` | `src/foo.rs` 或 `src/foo/mod.rs` |
| `src/lib.rs` | `mod foo;` | `src/foo.rs` 或 `src/foo/mod.rs` |
| `src/foo/mod.rs` | `mod bar;` | `src/foo/bar.rs` 或 `src/foo/bar/mod.rs` |

## 二、pub - 可见性控制

### 2.1 默认私有

```rust
// math.rs
fn private_fn() {}      // 私有，只能在 math 模块内使用
pub fn public_fn() {}   // 公开，可以被外部使用
```

### 2.2 pub 的使用场景

```rust
// 公开函数
pub fn add() {}

// 公开结构体
pub struct Point {
    pub x: i32,     // 公开字段
    y: i32,         // 私有字段
}

// 公开枚举（所有变体自动公开）
pub enum Color {
    Red,
    Green,
}

// 公开 trait
pub trait Drawable {
    fn draw(&self);
}

// 公开常量
pub const MAX_SIZE: usize = 100;

// 公开类型别名
pub type Result<T> = std::result::Result<T, Error>;
```

### 2.3 pub(crate) - 限制可见性

```rust
pub(crate) fn internal_api() {}  // 仅在当前 crate 内可见
pub(super) fn parent_only() {}   // 仅父模块可见
pub(in crate::foo) fn foo_only() {}  // 仅在 foo 模块内可见
```

## 三、use - 导入路径

### 3.1 基本导入

```rust
// 导入模块
use std::collections::HashMap;

// 导入多个项
use std::io::{self, Read, Write};

// 导入所有公开项（不推荐）
use std::collections::*;
```

### 3.2 路径类型

```rust
// 绝对路径（从 crate 根开始）
use crate::math::add;

// 相对路径
use super::parent_module;  // 父模块
use self::child_module;    // 当前模块

// 外部 crate
use axum::Router;
```

### 3.3 重命名

```rust
use std::io::Result as IoResult;
use std::fmt::Result as FmtResult;

fn foo() -> IoResult<()> { Ok(()) }
fn bar() -> FmtResult { Ok(()) }
```

### 3.4 重新导出（Re-export）

```rust
// math/mod.rs
mod add;
mod subtract;

// 重新导出，让外部可以直接使用
pub use add::add;
pub use subtract::subtract;

// 使用者可以这样用：
// use math::add;  而不是 use math::add::add;
```

## 四、实战示例：Web 项目结构

### 4.1 项目结构

```
server/src/
├── main.rs
├── config.rs
├── router.rs
├── state.rs
├── handlers/
│   ├── mod.rs
│   ├── version.rs
│   └── conversation.rs
├── auth/
│   ├── mod.rs
│   ├── login.rs
│   └── sms.rs
└── models/
    ├── mod.rs
    └── user.rs
```

### 4.2 main.rs

```rust
// 声明顶层模块
mod config;
mod router;
mod state;
mod handlers;
mod auth;
mod models;

// 导入需要的项
use config::ServerConfig;
use router::create_router;
use state::AppState;

#[tokio::main]
async fn main() {
    let config = ServerConfig::new();
    let state = AppState::new();
    let app = create_router(state);
    
    // 启动服务器...
}
```

### 4.3 handlers/mod.rs

```rust
// 声明子模块
pub mod version;
pub mod conversation;

// 重新导出常用项
pub use version::handler as version_handler;
pub use conversation::handler as conversation_handler;
```

### 4.4 handlers/version.rs

```rust
use axum::Json;
use serde::Serialize;

#[derive(Serialize)]
pub struct VersionInfo {
    pub name: &'static str,
    pub version: &'static str,
}

pub async fn handler() -> Json<VersionInfo> {
    Json(VersionInfo {
        name: "IM Server",
        version: env!("CARGO_PKG_VERSION"),
    })
}
```

### 4.5 router.rs

```rust
use axum::{routing::get, Router};
use crate::handlers;
use crate::state::AppState;

pub fn create_router(state: AppState) -> Router {
    Router::new()
        .route("/v", get(handlers::version::handler))
        .route("/conversation", get(handlers::conversation::handler))
        .with_state(state)
}
```

## 五、最佳实践

### 5.1 模块组织原则

1. **按功能分模块**：auth、user、chat 等
2. **使用 mod.rs 作为模块入口**：统一管理子模块
3. **合理使用 pub**：只公开必要的 API
4. **重新导出简化路径**：让使用者更方便

### 5.2 导入顺序（约定俗成）

```rust
// 1. 标准库
use std::collections::HashMap;

// 2. 外部 crate
use axum::Router;
use serde::Serialize;

// 3. 当前 crate
use crate::config::ServerConfig;
use crate::handlers;

// 4. 相对导入
use super::parent_fn;
```

### 5.3 避免循环依赖

```rust
// ❌ 错误：循环依赖
// a.rs
use crate::b::B;
pub struct A { b: B }

// b.rs
use crate::a::A;
pub struct B { a: A }

// ✅ 正确：使用 trait 或提取公共模块
// common.rs
pub trait Common {}

// a.rs
use crate::common::Common;
pub struct A;
impl Common for A {}

// b.rs
use crate::common::Common;
pub struct B;
impl Common for B {}
```

## 六、常见问题

### 6.1 模块未找到

```rust
// 错误：mod foo; 但没有 foo.rs 或 foo/mod.rs
mod foo;  // error: file not found for module `foo`

// 解决：创建对应文件
// src/foo.rs 或 src/foo/mod.rs
```

### 6.2 私有项访问

```rust
// math.rs
fn private() {}  // 私有

// main.rs
mod math;
fn main() {
    math::private();  // error: function `private` is private
}

// 解决：添加 pub
pub fn private() {}
```

### 6.3 use 和 mod 的区别

```rust
// mod：声明模块（告诉编译器这个模块存在）
mod math;  // 声明 math 模块

// use：导入路径（简化访问）
use math::add;  // 导入 add 函数

// 可以只 mod 不 use
mod math;
fn main() {
    math::add(1, 2);  // 使用完整路径
}

// 也可以 mod + use
mod math;
use math::add;
fn main() {
    add(1, 2);  // 直接使用
}
```

## 七、总结

| 关键字 | 作用 | 示例 |
|-------|------|------|
| `mod` | 声明模块 | `mod math;` |
| `pub` | 公开项 | `pub fn add() {}` |
| `use` | 导入路径 | `use std::collections::HashMap;` |
| `pub use` | 重新导出 | `pub use math::add;` |
| `crate` | 当前 crate 根 | `use crate::math;` |
| `super` | 父模块 | `use super::parent;` |
| `self` | 当前模块 | `use self::child;` |

**核心理念**：
- `mod` 定义结构
- `pub` 控制边界
- `use` 简化访问
