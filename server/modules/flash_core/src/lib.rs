// flash_core — 共享基础设施 crate
// 提供 Config、User、JWT、DbPool 等基础能力

pub mod config;
pub mod jwt;
pub mod model;
pub mod db;

pub use config::Config;
pub use model::User;
pub use jwt::{Claims, generate_token, verify_token};
pub use db::{DbPool, DbError, create_pool};
