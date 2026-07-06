use thiserror::Error;

#[derive(Error, Debug)]
pub enum DbError {
    #[error("数据库连接失败: {0}")]
    ConnectionError(#[from] sqlx::Error),

    #[error("数据未找到")]
    NotFound,

    #[error("数据已存在")]
    AlreadyExists,

    #[error("无效的数据: {0}")]
    InvalidData(String),

    #[error("迁移失败: {0}")]
    MigrationError(String),
}

impl DbError {
    pub fn from_sqlx(error: sqlx::Error) -> Self {
        match error {
            sqlx::Error::RowNotFound => DbError::NotFound,
            other => DbError::ConnectionError(other),
        }
    }
}
