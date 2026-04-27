import 'package:flutter/material.dart';
import '../api/auth_api.dart';
import '../model/auth_model.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  final AuthApi api;
  final bool isNewUser;

  const ProfilePage({
    super.key,
    required this.api,
    this.isNewUser = false,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<UserProfile> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = widget.api.getProfile();

    // 新用户注册时提示
    if (widget.isNewUser) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('🎉 注册成功，欢迎加入 Flash IM！'),
            backgroundColor: const Color(0xFF07C160),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            margin: const EdgeInsets.all(16),
          ));
        }
      });
    }
  }

  void _logout() {
    widget.api.logout();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => LoginPage(api: widget.api),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FA),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '个人信息',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<UserProfile>(
        future: _profileFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Color(0xFF07C160)),
                strokeWidth: 2,
              ),
            );
          }
          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Color(0xFFCCCCCC)),
                  const SizedBox(height: 12),
                  Text(
                    '加载失败：${snap.error}',
                    style: const TextStyle(color: Color(0xFF999999), fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final profile = snap.data!;
          return _buildProfile(profile);
        },
      ),
    );
  }

  Widget _buildProfile(UserProfile profile) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 32),
          // 头像
          _buildAvatar(profile),
          const SizedBox(height: 16),
          // 昵称
          Text(
            profile.nickname,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'ID: ${profile.userId.substring(0, 8)}...',
            style: const TextStyle(fontSize: 12, color: Color(0xFFAAAAAA)),
          ),
          const SizedBox(height: 32),
          // 信息卡片
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildInfoCard(profile),
          ),
          const SizedBox(height: 24),
          // Token 信息
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildTokenCard(),
          ),
          const SizedBox(height: 40),
          // 退出登录
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildLogoutButton(),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildAvatar(UserProfile profile) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFE8F5E9),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.network(
          profile.avatar,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Center(
            child: Text(
              profile.nickname.isNotEmpty ? profile.nickname[0] : '?',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w600,
                color: Color(0xFF07C160),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(UserProfile profile) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.phone_outlined,
            label: '手机号',
            value: profile.phone,
          ),
          const Divider(height: 1, indent: 56, color: Color(0xFFF0F0F0)),
          _InfoRow(
            icon: Icons.person_outline,
            label: '昵称',
            value: profile.nickname,
          ),
          const Divider(height: 1, indent: 56, color: Color(0xFFF0F0F0)),
          _InfoRow(
            icon: Icons.fingerprint,
            label: '用户 ID',
            value: profile.userId,
            valueStyle: const TextStyle(
              fontSize: 12,
              color: Color(0xFF999999),
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTokenCard() {
    final token = widget.api.token ?? '';
    final preview = token.length > 20
        ? '${token.substring(0, 20)}...'
        : token;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FFF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFB2DFDB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user_outlined,
                  size: 16, color: Color(0xFF07C160)),
              const SizedBox(width: 6),
              const Text(
                'JWT Token（已登录）',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            preview,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF555555),
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: _logout,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFE53935),
          side: const BorderSide(color: Color(0xFFFFCDD2)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          '退出登录',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

// ── 信息行组件 ────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF888888)),
          const SizedBox(width: 12),
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: Color(0xFF888888)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: valueStyle ??
                  const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A1A1A),
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
