# 关系型数据库选型调研报告

> 评估日期：2026-06-29
> 背景：Flash IM 后端（Rust + Axum）需要引入关系型数据库，持久化用户信息、认证数据等结构化数据。
> 候选方案：PostgreSQL、MySQL、SQLite

---

## 一、背景与需求

### 当前痛点

认证系统（用户注册、登录、Token）的所有数据存储在进程内存中，服务重启后全部丢失，无法满足生产环境的基本要求。

### 持久化目标

| 数据 | 说明 |
|------|------|
| 用户信息 | user_id、手机号、昵称、头像 |
| 认证凭证 | 密码哈希（密码登录） |
| SMS 验证码 | 带过期时间的一次性验证码 |
| 会话记录 | 后续扩展：消息历史 |

### 技术约束

- 后端语言：**Rust**，异步运行时：**Tokio**
- ORM / 查询层需与 async 生态兼容
- 当前阶段为单机部署，预留水平扩展空间
- 开发体验优先，减少运维负担

---

## 二、候选数据库对比

### 2.1 PostgreSQL

#### 功能

- 完整 SQL 标准支持，包括窗口函数、CTE、递归查询
- 原生 JSON / JSONB 类型，可存储半结构化数据
- 强大的全文检索（tsvector / tsquery）
- 支持数组、范围类型、自定义类型
- LISTEN / NOTIFY 机制，可实现轻量级消息通知
- 丰富的扩展体系：pgvector（向量）、PostGIS（地理）、TimescaleDB（时序）

#### 性能

- 读写均衡，OLTP 场景表现优秀
- 多版本并发控制（MVCC），高并发写入无锁争抢
- 连接开销较大，生产环境必须搭配连接池（PgBouncer / sqlx 内置池）
- 写密集负载下，WAL（预写日志）机制保障数据一致性

#### Rust 生态

```toml
# 主流选择
sqlx = { version = "0.8", features = ["postgres", "runtime-tokio"] }
# 或 ORM
sea-orm = { version = "1.0", features = ["sqlx-postgres"] }
diesel = { version = "2.0", features = ["postgres"] }
```

- **sqlx**：编译期 SQL 验证，完整 async 支持，社区首选
- **sea-orm**：类型安全 ORM，async 原生，适合复杂模型
- **diesel**：成熟 ORM，同步为主（async 支持有限）

#### 适用场景

- 需要复杂查询、事务保障的业务系统
- 数据模型较复杂或有演化需求的项目
- 需要 JSON 字段 + 关系数据混合存储

---

### 2.2 MySQL / MariaDB

#### 功能

- 广泛的 SQL 支持，InnoDB 引擎提供事务和行锁
- JSON 类型支持（5.7+），但功能弱于 PostgreSQL JSONB
- 全文索引支持有限，复杂查询能力不如 PostgreSQL
- MariaDB 在功能上略有增强，兼容性好

#### 性能

- 读多写少场景性能优秀，互联网业务大量使用
- 主从复制成熟，读写分离方案生态完善
- 连接池同样必须（ProxySQL / 内置池）
- 相同负载下，并发写性能略逊于 PostgreSQL

#### Rust 生态

```toml
sqlx = { version = "0.8", features = ["mysql", "runtime-tokio"] }
sea-orm = { version = "1.0", features = ["sqlx-mysql"] }
```

- sqlx / sea-orm 均支持，但维护重心偏向 PostgreSQL
- Diesel 对 MySQL 支持较完整

#### 适用场景

- 已有 MySQL 运维经验的团队
- 读多写少、查询相对简单的 Web 业务
- 需要与 PHP / Java 技术栈共用数据库的场景

---

### 2.3 SQLite

#### 功能

- 无服务进程，嵌入式数据库，文件即数据库
- 支持标准 SQL，事务、索引一应俱全
- 不支持并发写入（写操作全局锁），不适合多进程/多实例场景
- 无用户权限体系，安全边界由应用层负责

#### 性能

- 单线程读写性能极高，延迟极低（无网络开销）
- 并发写入瓶颈明显：WAL 模式下有所缓解，但仍是单写者
- 数据库文件大小无硬性限制，但实践中超过数 GB 后性能下降

#### Rust 生态

```toml
sqlx = { version = "0.8", features = ["sqlite", "runtime-tokio"] }
rusqlite = "0.31"  # 同步接口，轻量
```

- sqlx 支持 SQLite async，开发体验一致
- 适合测试、集成测试、CLI 工具

#### 适用场景

- 本地开发 / 测试环境
- 嵌入式设备、桌面应用
- 单实例、低并发的工具类服务

---

## 三、多维度横向对比

| 维度 | PostgreSQL | MySQL | SQLite |
|------|-----------|-------|--------|
| **SQL 完整性** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |
| **JSON 支持** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐ |
| **事务 / ACID** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **并发写入** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐ |
| **读性能** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Rust 生态** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ |
| **运维难度** | 中 | 中 | 极低 |
| **水平扩展** | 支持（逻辑复制） | 支持（成熟） | 不支持 |
| **扩展插件** | 极丰富 | 一般 | 极少 |
| **开源协议** | PostgreSQL（极宽松） | GPL / 商业双轨 | 公有领域 |

---

## 四、IM 场景专项分析

### 消息存储的特殊需求

IM 系统的消息表写入频率极高，且查询模式固定（按会话 ID + 时间倒序）：

```sql
-- 典型查询
SELECT * FROM messages
WHERE chat_id = $1
ORDER BY created_at DESC
LIMIT 20 OFFSET $2;
```

PostgreSQL 的 BRIN 索引对时序数据尤其友好，配合分区表可支撑亿级消息存储。

### LISTEN / NOTIFY 的潜力

PostgreSQL 原生的 `LISTEN / NOTIFY` 可作为轻量级的消息总线：

```sql
-- 服务端推送新消息通知
NOTIFY new_message, '{"chat_id": "abc", "msg_id": "123"}';
```

这在单机阶段可以替代 Redis Pub/Sub，减少外部依赖。

### 用户数据模型

```sql
CREATE TABLE users (
    user_id   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone     VARCHAR(20) UNIQUE NOT NULL,
    nickname  TEXT NOT NULL,
    avatar    TEXT NOT NULL,
    pwd_hash  TEXT,            -- 密码登录时存哈希
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE sms_codes (
    phone      VARCHAR(20) PRIMARY KEY,
    code       VARCHAR(6) NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL
);
```

---

## 五、结论与建议

### 推荐方案：PostgreSQL

**理由：**

1. **Rust 生态最成熟**：sqlx 对 PostgreSQL 的支持最完善，编译期 SQL 检查是 Rust 项目的重要安全保障
2. **功能储备充足**：JSONB、LISTEN/NOTIFY、分区表，随着 IM 功能扩展不需要换库
3. **事务与并发**：MVCC 在高并发写入（消息、在线状态更新）下表现好于 MySQL
4. **开源协议友好**：PostgreSQL 协议无商业风险，MySQL GPL 在某些场景下有法律顾虑
5. **运维成本可控**：Docker 单命令启动，云厂商均有托管服务（AWS RDS、Supabase 等）

### 各阶段建议

| 阶段 | 建议 |
|------|------|
| **开发 / 测试** | 本机 Docker 跑 PostgreSQL，SQLite 作为集成测试替代 |
| **生产单机** | PostgreSQL + sqlx 连接池（max_connections = 20~50） |
| **生产扩展** | PostgreSQL 主从复制 + PgBouncer 连接池代理 |
| **消息量极大** | 消息表引入分区（按月/按 chat_id hash），或迁移到 Cassandra |

### ORM / 查询层建议

优先选择 **sqlx**，理由：
- 原生 async，与 Tokio 无缝配合
- 宏 `sqlx::query!` 在编译期验证 SQL 正确性，避免运行时错误
- 不引入额外抽象层，SQL 完全可控，便于调优

```toml
# Cargo.toml
[dependencies]
sqlx = { version = "0.8", features = [
    "postgres",
    "runtime-tokio-native-tls",
    "uuid",
    "chrono",
    "migrate",
] }
```

---

## 六、后续行动项

- [ ] 在 `server/` 引入 sqlx，配置连接池
- [ ] 编写数据库 migration（users 表、sms_codes 表）
- [ ] 将 `AppState` 中的内存 HashMap 替换为数据库查询
- [ ] 密码字段使用 `argon2` 哈希存储，替换明文内置账号
- [ ] 配置文件管理数据库连接字符串（`.env` + `dotenvy`）
- [ ] 搭建本地 Docker PostgreSQL 开发环境

---

*Content was rephrased for compliance with licensing restrictions.*
