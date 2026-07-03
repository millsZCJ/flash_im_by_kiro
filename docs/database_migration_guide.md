# 数据库管理指南

本项目使用 sqlx 进行数据库迁移和管理。

## 快速开始

### 1. 初始化数据库

```bash
# 一键初始化：安装工具、创建数据库、运行迁移
./scripts/database/db_manager.sh init
```

这个命令会：
- 检测并安装 sqlx-cli（如果未安装）
- 启动 PostgreSQL（如果未运行）
- 创建数据库 `flash_im`
- 运行所有迁移脚本

### 2. 常用命令

```bash
# 查看帮助
./scripts/database/db_manager.sh help

# 查看迁移状态
./scripts/database/db_manager.sh status

# 创建新的迁移文件（以功能模块命名）
./scripts/database/db_manager.sh new <功能模块名>

# 示例：创建消息模块的迁移
./scripts/database/db_manager.sh new message

# 运行迁移
./scripts/database/db_manager.sh migrate

# 回滚最后一次迁移
./scripts/database/db_manager.sh rollback

# 重置数据库（删除并重新创建）
./scripts/database/db_manager.sh reset

# 删除数据库
./scripts/database/db_manager.sh drop
```

## 迁移文件命名规范

迁移文件位于 `server/migrations/` 目录，以功能模块命名：

```
server/migrations/
├── 001_heartbeat.sql      # 心跳功能模块
├── 002_user_auth.sql      # 用户认证模块
├── 003_message.sql        # 消息功能模块
├── 004_chat_room.sql      # 聊天室功能模块
└── ...
```

### 命名规则

- 格式：`{序号}_{功能模块名}.sql`
- 序号：3位数字，从 001 开始递增
- 功能模块名：小写字母 + 下划线，简洁明了

### 迁移文件内容规范

```sql
-- ============================================================================
-- {序号}_{功能模块名}.sql
-- {功能模块}的数据库表
-- ============================================================================

-- 创建表
CREATE TABLE IF NOT EXISTS table_name (
    -- 字段定义
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_table_name_field ON table_name(field);

-- 添加注释
COMMENT ON TABLE table_name IS '表注释';
COMMENT ON COLUMN table_name.field IS '字段注释';
```

## Rust 代码中使用数据库

### 1. 添加依赖

```toml
[dependencies]
sqlx = { version = "0.7", features = ["runtime-tokio", "tls-native-tls", "postgres", "uuid", "chrono", "migrate"] }
```

### 2. 创建连接池

```rust
use server::db::{create_pool, DbPool};

#[tokio::main]
async fn main() -> Result<()> {
    let database_url = "postgres://postgres@localhost:5432/flash_im";
    let pool = create_pool(database_url, 10).await?;
    
    // 使用连接池
    let row: (i64,) = sqlx::query_as("SELECT 1")
        .fetch_one(&pool)
        .await?;
    
    Ok(())
}
```

### 3. 定义数据模型

```rust
use sqlx::FromRow;
use uuid::Uuid;
use chrono::{DateTime, Utc};

#[derive(Debug, Clone, FromRow)]
pub struct User {
    pub id: Uuid,
    pub username: String,
    pub email: String,
    pub created_at: DateTime<Utc>,
}
```

### 4. 数据库操作

```rust
use sqlx::PgPool;

// 查询
pub async fn get_user_by_id(pool: &PgPool, user_id: Uuid) -> Result<Option<User>> {
    let user = sqlx::query_as::<_, User>(
        "SELECT * FROM users WHERE id = $1"
    )
    .bind(user_id)
    .fetch_optional(pool)
    .await?;
    
    Ok(user)
}

// 插入
pub async fn create_user(pool: &PgPool, username: &str, email: &str) -> Result<User> {
    let user = sqlx::query_as::<_, User>(
        r#"
        INSERT INTO users (username, email)
        VALUES ($1, $2)
        RETURNING *
        "#
    )
    .bind(username)
    .bind(email)
    .fetch_one(pool)
    .await?;
    
    Ok(user)
}

// 更新
pub async fn update_user_email(pool: &PgPool, user_id: Uuid, new_email: &str) -> Result<User> {
    let user = sqlx::query_as::<_, User>(
        r#"
        UPDATE users
        SET email = $1, updated_at = NOW()
        WHERE id = $2
        RETURNING *
        "#
    )
    .bind(new_email)
    .bind(user_id)
    .fetch_one(pool)
    .await?;
    
    Ok(user)
}

// 删除
pub async fn delete_user(pool: &PgPool, user_id: Uuid) -> Result<()> {
    sqlx::query("DELETE FROM users WHERE id = $1")
        .bind(user_id)
        .execute(pool)
        .await?;
    
    Ok(())
}
```

## 开发工作流

### 添加新功能模块

1. 创建迁移文件：
```bash
./scripts/database/db_manager.sh new <功能模块名>
```

2. 编辑生成的迁移文件（`server/migrations/{序号}_{功能模块名}.sql`）

3. 运行迁移：
```bash
./scripts/database/db_manager.sh migrate
```

4. 在 `server/src/` 下创建对应的模块

5. 编写数据访问层代码

### 测试

```bash
# 运行测试（需要数据库运行）
cd server
cargo test
```

## 环境变量

创建 `server/.env` 文件（参考 `.env.example`）：

```bash
DATABASE_URL=postgres://postgres@localhost:5432/flash_im
```

## 注意事项

1. **迁移文件不可修改**：已运行的迁移文件不要修改，应该创建新的迁移
2. **使用事务**：复杂操作使用事务确保数据一致性
3. **索引优化**：根据查询模式创建适当的索引
4. **清理数据**：定期清理不需要的历史数据
5. **备份**：生产环境定期备份数据库

## 常见问题

### Q: sqlx-cli 安装失败？

A: 确保已安装 Rust 和 cargo：
```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

### Q: 数据库连接失败？

A: 检查：
1. PostgreSQL 是否运行：`./scripts/database/start_postgres.sh`
2. 数据库是否存在：`./scripts/database/db_manager.sh create`
3. 连接字符串是否正确

### Q: 迁移失败？

A. 检查：
1. SQL 语法是否正确
2. 表/字段是否已存在
3. 使用 `./scripts/database/db_manager.sh status` 查看状态

## 参考资源

- [sqlx 文档](https://docs.rs/sqlx/)
- [sqlx-cli GitHub](https://github.com/launchbadge/sqlx/tree/main/sqlx-cli)
- [PostgreSQL 文档](https://www.postgresql.org/docs/)
