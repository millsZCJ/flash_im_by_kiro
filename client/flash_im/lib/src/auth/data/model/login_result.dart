/// 登录响应数据模型 — 对应服务端 /auth/login
class LoginResult {
  final String token;
  final String userId;
  final bool isNewUser;
  final bool hasPassword;

  const LoginResult({
    required this.token,
    required this.userId,
    required this.isNewUser,
    required this.hasPassword,
  });

  factory LoginResult.fromJson(Map<String, dynamic> json) => LoginResult(
        token: json['token'] as String,
        userId: json['user_id'] as String,
        isNewUser: json['is_new_user'] as bool,
        hasPassword: json['has_password'] as bool,
      );
}
