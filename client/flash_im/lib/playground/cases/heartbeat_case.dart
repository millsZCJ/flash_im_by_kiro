import 'package:flutter/material.dart';
import '../../features/heartbeat/view/heartbeat_page.dart';

/// Playground 入口：心跳通信
class HeartbeatCase extends StatelessWidget {
  const HeartbeatCase({super.key});

  static const String title = '💓 心跳通信（WebSocket）';

  @override
  Widget build(BuildContext context) => const HeartbeatPage();
}
