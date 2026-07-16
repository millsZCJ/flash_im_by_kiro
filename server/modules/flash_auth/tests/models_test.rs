use flash_auth::models::*;

#[test]
fn test_login_type_serialization() {
    // SMS
    let sms_json = serde_json::to_string(&LoginType::Sms).expect("serialize failed");
    assert_eq!(sms_json, "\"sms\"");

    // Password
    let pwd_json = serde_json::to_string(&LoginType::Password).expect("serialize failed");
    assert_eq!(pwd_json, "\"password\"");
}

#[test]
fn test_login_type_deserialization() {
    let sms: LoginType = serde_json::from_str("\"sms\"").expect("deserialize failed");
    assert!(matches!(sms, LoginType::Sms));

    let pwd: LoginType = serde_json::from_str("\"password\"").expect("deserialize failed");
    assert!(matches!(pwd, LoginType::Password));
}

#[test]
fn test_sms_request_deserialization() {
    let json = "{\"phone\":\"13800138000\"}";
    let req: SmsRequest = serde_json::from_str(json).expect("deserialize failed");
    assert_eq!(req.phone, "13800138000");
}

#[test]
fn test_sms_response_serialization() {
    let resp = SmsResponse {
        code: "123456".to_string(),
        message: "验证码已发送".to_string(),
    };
    let json = serde_json::to_string(&resp).expect("serialize failed");
    assert!(json.contains("123456"));
    assert!(json.contains("验证码已发送"));
}

#[test]
fn test_login_request_deserialization_sms() {
    let json = "{\"login_type\":\"sms\",\"phone\":\"13800138000\",\"code\":\"123456\"}";
    let req: LoginRequest = serde_json::from_str(json).expect("deserialize failed");
    assert!(matches!(req.login_type, LoginType::Sms));
    assert_eq!(req.phone, "13800138000");
    assert_eq!(req.code, Some("123456".to_string()));
    assert_eq!(req.password, None);
}

#[test]
fn test_login_request_deserialization_password() {
    let json = "{\"login_type\":\"password\",\"phone\":\"13800138000\",\"password\":\"mypass123\"}";
    let req: LoginRequest = serde_json::from_str(json).expect("deserialize failed");
    assert!(matches!(req.login_type, LoginType::Password));
    assert_eq!(req.phone, "13800138000");
    assert_eq!(req.code, None);
    assert_eq!(req.password, Some("mypass123".to_string()));
}

#[test]
fn test_login_response_serialization() {
    let resp = LoginResponse {
        token: "jwt_token_here".to_string(),
        user_id: "42".to_string(),
        is_new_user: true,
        has_password: false,
    };
    let json = serde_json::to_string(&resp).expect("serialize failed");
    assert!(json.contains("jwt_token_here"));
    assert!(json.contains("\"is_new_user\":true"));
    assert!(json.contains("\"has_password\":false"));
}
// 注：PasswordRequest 和 MessageResponse 测试已迁至 flash_user
