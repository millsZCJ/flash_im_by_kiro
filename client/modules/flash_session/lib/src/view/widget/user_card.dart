import 'package:flutter/material.dart';
import 'package:flash_core/flash_core.dart';
import 'package:flash_session/src/view/widget/identicon_avatar.dart';

/// UserAvatar — 根据 User 状态自动渲染 identicon / 网络图片 / 灰色占位
class UserAvatar extends StatelessWidget {
  final User? user;
  final double size;
  final double borderRadius;

  const UserAvatar({
    super.key,
    this.user,
    this.size = 64,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      // 灰色占位
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          color: const Color(0xFFE0E0E0),
        ),
        child: Center(
          child: Text(
            '?',
            style: TextStyle(
              fontSize: size * 0.4,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF999999),
            ),
          ),
        ),
      );
    }

    if (user!.hasCustomAvatar) {
      // 网络图片
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.network(
          user!.avatar,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildFallback(user!),
        ),
      );
    }

    // identicon 本地渲染
    return IdenticonAvatar(
      seed: user!.identiconSeed,
      size: size,
      borderRadius: borderRadius,
    );
  }

  Widget _buildFallback(User user) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: const Color(0xFFE8F5E9),
      ),
      child: Center(
        child: Text(
          user.nickname.isNotEmpty ? user.nickname[0] : '?',
          style: TextStyle(
            fontSize: size * 0.4,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF07C160),
          ),
        ),
      ),
    );
  }
}

/// UserCard — 微信风格用户卡片（头像 + 昵称 + 闪讯号 + 签名 + 右箭头）
class UserCard extends StatelessWidget {
  final User user;
  final VoidCallback? onTap;

  const UserCard({
    super.key,
    required this.user,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final userIdShort = user.userId.length > 8 ? user.userId.substring(0, 8) : user.userId;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            UserAvatar(user: user, size: 64, borderRadius: 8),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.nickname,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '闪讯号: $userIdShort',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF888888)),
                  ),
                  if (user.signature.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      user.signature,
                      style: const TextStyle(fontSize: 12, color: Color(0xFFAAAAAA)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFFCCCCCC)),
          ],
        ),
      ),
    );
  }
}
