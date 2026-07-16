/// 用户模型 — 本地缓存 + 接口共用
class User {
  final String userId;
  final String phone;
  final String nickname;
  final String avatar;
  final String signature; // 新增，默认空字符串

  const User({
    required this.userId,
    required this.phone,
    required this.nickname,
    required this.avatar,
    this.signature = '',
  });

  /// 是否使用自定义头像（非 identicon）
  bool get hasCustomAvatar => !avatar.startsWith('identicon:');

  /// identicon seed：从 avatar 中提取 seed 部分
  String get identiconSeed => avatar.startsWith('identicon:')
      ? avatar.substring('identicon:'.length)
      : userId;

  factory User.fromJson(Map<String, dynamic> json) => User(
        userId: json['user_id'] as String,
        phone: json['phone'] as String,
        nickname: json['nickname'] as String,
        avatar: json['avatar'] as String,
        // signature 兼容 null（旧缓存无此字段）
        signature: (json['signature'] as String?) ?? '',
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'phone': phone,
        'nickname': nickname,
        'avatar': avatar,
        'signature': signature,
      };
}
