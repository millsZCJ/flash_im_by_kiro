use bcrypt::{hash, verify};

#[test]
fn test_bcrypt_hash_and_verify_correct_password() {
    let password = "my_secret_password";
    let hashed = hash(password, 10).expect("hashing failed");

    // 哈希值应以 $2b$ 或 $2y$ 开头
    assert!(hashed.starts_with("$2b$") || hashed.starts_with("$2y$"));

    // 正确密码应验证通过
    let valid = verify(password, &hashed).expect("verification failed");
    assert!(valid);
}

#[test]
fn test_bcrypt_verify_wrong_password() {
    let password = "correct_password";
    let hashed = hash(password, 10).expect("hashing failed");

    // 错误密码应验证失败
    let valid = verify("wrong_password", &hashed).expect("verification failed");
    assert!(!valid);
}

#[test]
fn test_bcrypt_hash_is_different_each_time() {
    let password = "same_password";
    let hash1 = hash(password, 10).expect("hashing failed");
    let hash2 = hash(password, 10).expect("hashing failed");

    // 同一密码两次哈希应不同（因为 salt 不同）
    assert_ne!(hash1, hash2);
}

#[test]
fn test_bcrypt_short_password() {
    let password = "123456"; // 最短密码（6位）
    let hashed = hash(password, 10).expect("hashing failed");
    let valid = verify(password, &hashed).expect("verification failed");
    assert!(valid);
}
