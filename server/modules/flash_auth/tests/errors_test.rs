use flash_auth::errors::AuthError;

#[test]
fn test_auth_error_display_messages() {
    assert_eq!(AuthError::InvalidSmsCode.to_string(), "验证码错误或已过期");
    assert_eq!(AuthError::InvalidPassword.to_string(), "密码错误");
    assert_eq!(AuthError::UserNotFound.to_string(), "用户不存在");
    assert_eq!(AuthError::UserAlreadyExists.to_string(), "用户已存在");
    assert_eq!(AuthError::InvalidToken.to_string(), "Token 无效或已过期");
}

#[test]
fn test_auth_error_from_sqlx_row_not_found() {
    let sqlx_err = sqlx::Error::RowNotFound;
    let auth_err: AuthError = sqlx_err.into();
    assert!(matches!(auth_err, AuthError::UserNotFound));
}

#[test]
fn test_auth_error_into_response_status_codes() {
    use axum::http::StatusCode;
    use axum::response::IntoResponse;

    // 验证各错误对应的 HTTP 状态码
    let response = AuthError::InvalidSmsCode.into_response();
    assert_eq!(response.status(), StatusCode::UNAUTHORIZED);

    let response = AuthError::InvalidPassword.into_response();
    assert_eq!(response.status(), StatusCode::UNAUTHORIZED);

    let response = AuthError::UserNotFound.into_response();
    assert_eq!(response.status(), StatusCode::NOT_FOUND);

    let response = AuthError::MissingField("phone").into_response();
    assert_eq!(response.status(), StatusCode::BAD_REQUEST);

    let response = AuthError::UserAlreadyExists.into_response();
    assert_eq!(response.status(), StatusCode::CONFLICT);

    let response = AuthError::Database("some error".to_string()).into_response();
    assert_eq!(response.status(), StatusCode::INTERNAL_SERVER_ERROR);

    let response = AuthError::InvalidToken.into_response();
    assert_eq!(response.status(), StatusCode::INTERNAL_SERVER_ERROR);
}
