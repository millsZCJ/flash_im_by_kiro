import 'package:flutter/material.dart';
import '../../features/auth/api/auth_api.dart';
import '../../im_playground_app.dart';
import '../pages/chat_room_page.dart';
import '../pages/profile_tab_page.dart';

/// 主界面 Shell：底部导航栏（聊天室 + 我的）
class ImShell extends StatefulWidget {
  final AuthApi authApi;
  const ImShell({super.key, required this.authApi});

  @override
  State<ImShell> createState() => _ImShellState();
}

class _ImShellState extends State<ImShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          ChatRoomPage(authApi: widget.authApi),
          ProfileTabPage(
            authApi: widget.authApi,
            onLogout: _onLogout,
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E5E5), width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.chat_bubble_outline,
                activeIcon: Icons.chat_bubble,
                label: '聊天',
                active: _index == 0,
                onTap: () => setState(() => _index = 0),
              ),
              _NavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: '我',
                active: _index == 1,
                onTap: () => setState(() => _index = 1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onLogout() {
    widget.authApi.logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const ImPlaygroundApp()),
      (_) => false,
    );
  }
}

// ─── 底部导航项 ───────────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF07C160);
    const inactiveColor = Color(0xFF888888);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              active ? activeIcon : icon,
              size: 24,
              color: active ? activeColor : inactiveColor,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: active ? activeColor : inactiveColor,
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
