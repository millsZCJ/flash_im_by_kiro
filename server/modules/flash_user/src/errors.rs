use axum::{
    http::StatusCode,
    response::{IntoResponse, Response},
    Json,
};
use serde_json::json;
use thiserror::Error;

#[derive(Error, Debug)]
pub enum UserError {
    #[error("原密码错误")]
    WrongOldPassword,

    #[error("用户不存在")]
    UserNotFound,

    #[error("Token 无效或已过期")]
    InvalidToken,

    #[error("缺少必填字段: {0}")]
    MissingField(&'static str),

    #[error("昵称过长（最多20个字符）")]
    NicknameTooLong,

    #[error("数据库错误: {0}")]
    Database(String),

    #[error("JWT 错误: {0}")]
    Jwt(String),

    #[error("密码哈希错误: {0}")]
    PasswordHash(String),
}

impl From<sqlx::Error> for UserError {
    fn from(error: sqlx::Error) -> Self {
        match error {
            sqlx::Error::RowNotFound => UserError::UserNotFound,
            _ => UserError::Database(error.to_string()),
        }
    }
}

impl From<jsonwebtoken::errors::Error> for UserError {
    fn from(error: jsonwebtoken::errors::Error) -> Self {
        UserError::Jwt(error.to_string())
    }
}

impl IntoResponse for UserError {
    fn into_response(self) -> Response {
        let status = match &self {
            UserError::WrongOldPassword => StatusCode::UNAUTHORIZED,
            UserError::UserNotFound => StatusCode::NOT_FOUND,
            UserError::InvalidToken => StatusCode::UNAUTHORIZED,
            UserError::MissingField(_) => StatusCode::BAD_REQUEST,
            UserError::NicknameTooLong => StatusCode::BAD_REQUEST,
            _ => StatusCode::INTERNAL_SERVER_ERROR,
        };

        let body = Json(json!({
            "error": self.to_string(),
            "code": status.as_u16(),
        }));

        (status, body).into_response()
    }
}
