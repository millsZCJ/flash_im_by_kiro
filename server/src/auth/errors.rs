// ============================================================================
// auth/errors.rs
// 认证模块错误类型定义
// ============================================================================

use axum::{
    http::StatusCode,
    response::{IntoResponse, Response},
    Json,
};
use serde_json::json;
use thiserror::Error;

#[derive(Error, Debug)]
pub enum AuthError {
    #[error("验证码错误或已过期")]
    InvalidSmsCode,

    #[error("密码错误")]
    InvalidPassword,

    #[error("用户不存在")]
    UserNotFound,

    #[error("用户已存在")]
    UserAlreadyExists,

    #[error("Token 无效或已过期")]
    InvalidToken,

    #[error("缺少必填字段: {0}")]
    MissingField(&'static str),

    #[error("数据库错误: {0}")]
    Database(String),

    #[error("JWT 错误: {0}")]
    Jwt(String),

    #[error("密码哈希错误: {0}")]
    PasswordHash(String),
}

impl From<sqlx::Error> for AuthError {
    fn from(error: sqlx::Error) -> Self {
        match error {
            sqlx::Error::RowNotFound => AuthError::UserNotFound,
            _ => AuthError::Database(error.to_string()),
        }
    }
}

impl From<jsonwebtoken::errors::Error> for AuthError {
    fn from(error: jsonwebtoken::errors::Error) -> Self {
        AuthError::Jwt(error.to_string())
    }
}

impl IntoResponse for AuthError {
    fn into_response(self) -> Response {
        let status = match &self {
            AuthError::InvalidSmsCode | AuthError::InvalidPassword => StatusCode::UNAUTHORIZED,
            AuthError::MissingField(_) => StatusCode::BAD_REQUEST,
            AuthError::UserNotFound => StatusCode::NOT_FOUND,
            AuthError::UserAlreadyExists => StatusCode::CONFLICT,
            _ => StatusCode::INTERNAL_SERVER_ERROR,
        };

        let body = Json(json!({
            "error": self.to_string(),
            "code": status.as_u16(),
        }));

        (status, body).into_response()
    }
}
