import 'package:flutter/material.dart';
import '../../features/auth/api/auth_api.dart';
import '../../features/auth/model/auth_model.dart';

/// "我的" Tab 页（微信风格）
class ProfileTabPage extends StatefulWidget {
  final AuthApi authApi;
  final VoidCallback onLogout;

  const ProfileTabPage({
    super.key,
    required this.authApi,
    required this.onLogout,
  });

  @override
  State<ProfileTabPage> createState() => _ProfileTabPageState();
}

class _ProfileTabPageState extends State<ProfileTabPage>
    with AutomaticKeepAliveClientMixin {
  late Future<UserProfile> _profileFuture;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _profileFuture = widget.authApi.getProfile();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: const Color(0xFFEDEDED),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEDEDED),
        elevation: 0,
        centerTitle: true,
        title: const Text('我',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A))),
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
          if (snap.hasError || snap.data == null) {
            return Center(
              child: Text('加载失败',
                  style: const TextStyle(color: Color(0xFF999999))),
            );
          }
          return _buildContent(snap.data!);
        },
      ),
    );
  }

  Widget _buildContent(UserProfile profile) {
    final token = widget.authApi.token ?? '';
    final tokenPreview = token.length > 20
        ? '${token.substring(0, 20)}...-V...'
        : token;

    return ListView(
      children: [
        // 顶部用户卡片
        _buildUserCard(profile),
        const SizedBox(height: 12),
        // 信息列表
        _buildInfoSection(profile, tokenPreview),
        const SizedBox(height: 24),
        // 退出登录
        _buildLogoutButton(),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildUserCard(UserProfile profile) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          // 头像
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: const Color(0xFFE8F5E9),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                profile.avatar,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                  child: Text(
                    profile.nickname.isNotEmpty ? profile.nickname[0] : '?',
                    style: const TextStyle(fontSize: 28,
                        fontWeight: FontWeight.w600, color: Color(0xFF07C160)),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // 昵称 + ID
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.nickname,
                    style: const TextStyle(fontSize: 18,
                        fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
                const SizedBox(height: 4),
                Text('ID: ${profile.userId.substring(0, 8)}',
                    style: const TextStyle(fontSize: 13,
                        color: Color(0xFF888888))),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFFCCCCCC)),
        ],
      ),
    );
  }

  Widget _buildInfoSection(UserProfile profile, String tokenPreview) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.phone_outlined,
            iconColor: const Color(0xFF07C160),
            label: '手机号',
            value: profile.phone,
          ),
          const Divider(height: 1, indent: 56, color: Color(0xFFF0F0F0)),
          _InfoRow(
            icon: Icons.vpn_key_outlined,
            iconColor: const Color(0xFF07C160),
            label: 'Token',
            value: tokenPreview,
            valueStyle: const TextStyle(fontSize: 12,
                color: Color(0xFF888888), fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: widget.onLogout,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        alignment: Alignment.center,
        child: const Text(
          '退出登录',
          style: TextStyle(fontSize: 16, color: Color(0xFFE53935)),
        ),
      ),
    );
  }
}

// ─── 信息行 ───────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const _InfoRow({
    required this.icon,
    required this.iconColor,
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
          Icon(icon, size: 22, color: iconColor),
          const SizedBox(width: 16),
          SizedBox(
            width: 56,
            child: Text(label,
                style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A1A))),
          ),
          Expanded(
            child: Text(
              value,
              style: valueStyle ??
                  const TextStyle(fontSize: 15, color: Color(0xFF888888)),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
