use flash_core::{generate_token, verify_token, Claims};

#[test]
fn test_generate_and_verify_token() {
    let secret = "test_secret_key_for_jwt";
    let user_id = "42";

    // 生成 token
    let token = generate_token(user_id, secret).expect("token generation failed");

    // 验证 token
    let claims = verify_token(&token, secret).expect("token verification failed");
    assert_eq!(claims.sub, user_id);
}

#[test]
fn test_verify_token_with_wrong_secret() {
    let secret = "correct_secret";
    let wrong_secret = "wrong_secret";
    let user_id = "42";

    let token = generate_token(user_id, secret).expect("token generation failed");

    // 用错误的 secret 验证应失败
    let result = verify_token(&token, wrong_secret);
    assert!(result.is_err());
}

#[test]
fn test_verify_expired_token() {
    // 构造一个已过期的 Claims（exp = 0）
    use jsonwebtoken::{encode, EncodingKey, Header};
    use std::time::{SystemTime, UNIX_EPOCH};

    let now = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .expect("time")
        .as_secs() as usize;

    let expired_claims = Claims {
        sub: "42".to_string(),
        iat: now - 200,
        nbf: now - 200,
        exp: now - 100, // 已过期
    };

    let secret = "test_secret";
    let token = encode(
        &Header::default(),
        &expired_claims,
        &EncodingKey::from_secret(secret.as_bytes()),
    ).expect("encode failed");

    let result = verify_token(&token, secret);
    assert!(result.is_err());
}

#[test]
fn test_token_contains_expected_fields() {
    let secret = "test_secret";
    let user_id = "12345";

    let token = generate_token(user_id, secret).expect("token generation failed");
    let claims = verify_token(&token, secret).expect("verification failed");

    assert_eq!(claims.sub, "12345");
    assert!(claims.iat > 0);
    assert!(claims.exp > claims.iat);
    assert!(claims.nbf > 0);
}
