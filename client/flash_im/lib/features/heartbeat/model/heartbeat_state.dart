/// WebSocket 连接状态
enum WsConnectionState {
  disconnected, // 未连接 / 已断开
  connecting,   // 连接中
  connected,    // 已连接
}

/// 单条心跳日志
class HeartbeatLog {
  final HeartbeatLogType type;
  final String message;
  final DateTime time;

  HeartbeatLog({
    required this.type,
    required this.message,
    DateTime? time,
  }) : time = time ?? DateTime.now();

  String get timeLabel {
    final t = time;
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    final s = t.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

enum HeartbeatLogType {
  info,     // 系统提示（灰）
  received, // 收到消息（绿）
  sent,     // 发送消息（蓝）
  error,    // 错误（红）
}
