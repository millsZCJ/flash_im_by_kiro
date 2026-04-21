/// 消息方向
enum MessageDirection { sent, received }

/// 单条聊天消息
class ChatMessage {
  final String id;
  final String senderName;
  final String content;
  final String time;
  final MessageDirection direction;

  const ChatMessage({
    required this.id,
    required this.senderName,
    required this.content,
    required this.time,
    required this.direction,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'] as String,
    senderName: json['senderName'] as String,
    content: json['content'] as String,
    time: json['time'] as String,
    direction: (json['direction'] as String) == 'sent'
        ? MessageDirection.sent
        : MessageDirection.received,
  );
}
