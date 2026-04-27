/// 登录响应
class LoginResult {
  final String token;
  final String userId;
  final bool isNewUser;

  const LoginResult({
    required this.token,
    required this.userId,
    required this.isNewUser,
  });

  factory LoginResult.fromJson(Map<String, dynamic> json) => LoginResult(
        token: json['token'] as String,
        userId: json['user_id'] as String,
        isNewUser: json['is_new_user'] as bool,
      );
}

/// 用户信息
class UserProfile {
  final String userId;
  final String phone;
  final String nickname;
  final String avatar;

  const UserProfile({
    required this.userId,
    required this.phone,
    required this.nickname,
    required this.avatar,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        userId: json['user_id'] as String,
        phone: json['phone'] as String,
        nickname: json['nickname'] as String,
        avatar: json['avatar'] as String,
      );
}
