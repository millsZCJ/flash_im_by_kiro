import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flash_im/src/auth/logic/auth/auth_cubit.dart';
import 'package:flash_im/src/auth/logic/auth/auth_state.dart';
import 'package:flash_im/src/home/profile/profile_page.dart';
import 'package:flash_im/src/home/profile/set_password_page.dart';

/// 三 Tab 主 Shell — 消息 / 通讯录 / 我的
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  bool _hasShownPasswordHint = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkPasswordHint());
  }

  void _checkPasswordHint() {
    if (_hasShownPasswordHint) return;
    final state = context.read<AuthCubit>().state;
    if (state.status == AuthStatus.authenticated && !state.hasPassword) {
      _hasShownPasswordHint = true;
      _showPasswordHintDialog();
    }
  }

  void _showPasswordHintDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [Icon(Icons.lock_outline, size: 28, color: Color(0xFF07C160)), SizedBox(width: 12), Text('建议设置密码', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600))]),
        content: const Text('方便下次快速登录，提升账号安全性', style: TextStyle(fontSize: 14, color: Color(0xFF666666))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('跳过', style: TextStyle(color: Color(0xFF999999)))),
          ElevatedButton(
            onPressed: () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => const SetPasswordPage())); },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF07C160), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('去设置'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const Center(child: Text('暂无消息', style: TextStyle(fontSize: 16, color: Color(0xFF999999)))),
          const Center(child: Text('暂无联系人', style: TextStyle(fontSize: 16, color: Color(0xFF999999)))),
          const ProfilePage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), activeIcon: Icon(Icons.chat_bubble), label: '消息'),
          BottomNavigationBarItem(icon: Icon(Icons.contacts_outlined), activeIcon: Icon(Icons.contacts), label: '通讯录'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: '我的'),
        ],
        selectedItemColor: const Color(0xFF07C160),
        unselectedItemColor: const Color(0xFF999999),
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
