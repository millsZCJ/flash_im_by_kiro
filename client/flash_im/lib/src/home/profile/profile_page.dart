import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:flash_im/src/auth/logic/auth/auth_cubit.dart';
import 'package:flash_im/src/auth/logic/auth/auth_state.dart';
import 'package:flash_im/src/home/profile/set_password_page.dart';

/// "我的"页面 — 微信风格列表布局
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDEDED),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEDEDED), elevation: 0, centerTitle: true,
        title: const Text('我', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
      ),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state.status != AuthStatus.authenticated || state.user == null) {
            return const Center(child: Text('未登录', style: TextStyle(color: Color(0xFF999999))));
          }
          return _buildContent(context, state);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, AuthState state) {
    final user = state.user!;
    return ListView(
      children: [
        _buildUserCard(user),
        const SizedBox(height: 12),
        _buildInfoSection(user, state.hasPassword, context),
        const SizedBox(height: 24),
        _buildLogoutButton(context),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildUserCard(dynamic user) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Container(width: 64, height: 64, decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: const Color(0xFFE8F5E9)),
            child: ClipRRect(borderRadius: BorderRadius.circular(8),
              child: Image.network(user.avatar, fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Center(child: Text(user.nickname.isNotEmpty ? user.nickname[0] : '?', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: Color(0xFF07C160))))))),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(user.nickname, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
            const SizedBox(height: 4),
            Text('ID: ${user.userId.substring(0, 8)}', style: const TextStyle(fontSize: 13, color: Color(0xFF888888))),
          ])),
          const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFFCCCCCC)),
        ],
      ),
    );
  }

  Widget _buildInfoSection(dynamic user, bool hasPassword, BuildContext context) {
    return Container(color: Colors.white, child: Column(children: [
      _InfoRow(icon: Icons.phone_outlined, iconColor: const Color(0xFF07C160), label: '手机号', value: user.phone),
      const Divider(height: 1, indent: 56, color: Color(0xFFF0F0F0)),
      _InfoRow(icon: Icons.lock_outline, iconColor: const Color(0xFF07C160), label: hasPassword ? '修改密码' : '设置密码', value: '',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SetPasswordPage()))),
    ]));
  }

  Widget _buildLogoutButton(BuildContext context) {
    return GestureDetector(
      onTap: () async { await context.read<AuthCubit>().logout(); if (context.mounted) context.go('/login'); },
      child: Container(color: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), alignment: Alignment.center,
        child: const Text('退出登录', style: TextStyle(fontSize: 16, color: Color(0xFFE53935))),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon; final Color iconColor; final String label; final String value; final VoidCallback? onTap;
  const _InfoRow({required this.icon, required this.iconColor, required this.label, required this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque,
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Icon(icon, size: 22, color: iconColor), const SizedBox(width: 16),
          SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A1A)))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 15, color: Color(0xFF888888)), textAlign: TextAlign.right, overflow: TextOverflow.ellipsis)),
          if (onTap != null) const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFFCCCCCC)),
        ]),
      ),
    );
  }
}
