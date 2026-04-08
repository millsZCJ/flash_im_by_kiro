import 'package:flutter/material.dart';

class MainBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const MainBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: const Color(0xFFF7F7F7),
      selectedItemColor: const Color(0xFF07C160),
      unselectedItemColor: const Color(0xFF888888),
      selectedFontSize: 11,
      unselectedFontSize: 11,
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.chat_bubble_outline),
          activeIcon: Icon(Icons.chat_bubble),
          label: '微信',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.contacts_outlined),
          activeIcon: Icon(Icons.contacts),
          label: '通讯录',
        ),
        BottomNavigationBarItem(
          icon: _BadgeIcon(icon: Icons.explore_outlined),
          activeIcon: const Icon(Icons.explore),
          label: '发现',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: '我',
        ),
      ],
    );
  }
}

// 带红点的图标
class _BadgeIcon extends StatelessWidget {
  final IconData icon;

  const _BadgeIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        Positioned(
          top: -2,
          right: -4,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}
