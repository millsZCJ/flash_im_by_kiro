use flash_auth::handlers::is_valid_phone;

// ─── 手机号格式校验测试 ──────────────────────────────────────────────────────

#[test]
fn test_valid_phone_numbers() {
    assert!(is_valid_phone("13800138000")); // 标准中国手机号
    assert!(is_valid_phone("15012345678")); // 15开头
    assert!(is_valid_phone("18600001111")); // 18开头
    assert!(is_valid_phone("19900001111")); // 19开头
    assert!(is_valid_phone("17000001111")); // 17开头
}

#[test]
fn test_invalid_phone_numbers() {
    // 长度不对
    assert!(!is_valid_phone("1380013800"));  // 10位
    assert!(!is_valid_phone("138001380001")); // 12位

    // 不以1开头
    assert!(!is_valid_phone("23800138000"));
    assert!(!is_valid_phone("03800138000"));

    // 包含非数字字符
    assert!(!is_valid_phone("1380013800a"));
    assert!(!is_valid_phone("138-00138000"));

    // 空字符串
    assert!(!is_valid_phone(""));
}

#[test]
fn test_phone_validation_edge_cases() {
    // 格式校验只检查1开头+11位数字，不验证号段真实性
    assert!(is_valid_phone("10000000000")); // 1开头+11位数字，格式合法
    assert!(is_valid_phone("11111111111")); // 全1，格式合法
}
