/// 聊天室消息类型
enum RoomMessageType { chat, join, leave }

/// 聊天室消息
class RoomMessage {
  final RoomMessageType type;
  final String sender;
  final String content;
  final String time;

  const RoomMessage({
    required this.type,
    required this.sender,
    required this.content,
    required this.time,
  });

  factory RoomMessage.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String;
    final type = switch (typeStr) {
      'chat' => RoomMessageType.chat,
      'join' => RoomMessageType.join,
      'leave' => RoomMessageType.leave,
      _ => RoomMessageType.chat,
    };
    return RoomMessage(
      type: type,
      sender: json['sender'] as String,
      content: json['content'] as String? ?? '',
      time: json['time'] as String? ?? '',
    );
  }

  bool get isSystem => type == RoomMessageType.join || type == RoomMessageType.leave;

  String get systemText => switch (type) {
        RoomMessageType.join => '$sender 加入了聊天室',
        RoomMessageType.leave => '$sender 离开了聊天室',
        _ => '',
      };
}
