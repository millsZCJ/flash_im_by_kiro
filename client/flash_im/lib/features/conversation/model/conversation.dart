class Conversation {
  final String title;
  final String lastMsg;
  final String time;

  const Conversation({
    required this.title,
    required this.lastMsg,
    required this.time,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
    title: json['title'] as String,
    lastMsg: json['lastMsg'] as String,
    time: json['time'] as String,
  );

  @override
  String toString() =>
      'Conversation(title: $title, lastMsg: $lastMsg, time: $time)';
}
