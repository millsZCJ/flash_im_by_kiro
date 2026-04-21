/// 搜索结果的类型
enum SearchResultType { contact, group, chatHistory }

/// 单条搜索结果
class SearchResult {
  final SearchResultType type;

  /// 标题（联系人名 / 群名 / 发送者名）
  final String title;

  /// 副标题（联系人备注 / 群成员数 / 消息内容）
  final String subtitle;

  /// 时间（聊天记录专用）
  final String? time;

  /// 关联的会话 ID，用于跳转
  final String conversationId;

  /// 聊天记录专用：消息在会话中的索引，用于定位
  final int? messageIndex;

  const SearchResult({
    required this.type,
    required this.title,
    required this.subtitle,
    this.time,
    required this.conversationId,
    this.messageIndex,
  });
}
