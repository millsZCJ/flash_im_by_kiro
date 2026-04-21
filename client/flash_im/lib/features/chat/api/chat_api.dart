import 'package:dio/dio.dart';
import '../../../core/network/http_client.dart';
import '../model/chat_message.dart';

/// 聊天消息 API
class ChatApi {
  final Dio _dio;

  ChatApi({Dio? dio}) : _dio = dio ?? HttpClient.instance;

  /// 获取指定会话的消息列表
  Future<List<ChatMessage>> getMessages(String conversationId) async {
    try {
      final resp = await _dio.get('/chat/$conversationId/messages');
      final data = resp.data as List<dynamic>;
      return data.map((e) => ChatMessage.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException {
      // 后端接口暂未实现时，使用本地 mock 数据
      return _mockMessages(conversationId);
    }
  }

  /// 本地 mock 数据
  List<ChatMessage> _mockMessages(String conversationId) {
    // 根据不同的 conversationId 返回不同的消息列表
    if (conversationId == 'conv_zhangsan') {
      return [
        const ChatMessage(
          id: 'msg_1',
          senderName: '张三',
          content: '在吗？',
          time: '10:30',
          direction: MessageDirection.received,
        ),
        const ChatMessage(
          id: 'msg_2',
          senderName: '我',
          content: '在的，什么事？',
          time: '10:31',
          direction: MessageDirection.sent,
        ),
        const ChatMessage(
          id: 'msg_3',
          senderName: '张三',
          content: '明天有空吗？一起吃个饭',
          time: '10:32',
          direction: MessageDirection.received,
        ),
        const ChatMessage(
          id: 'msg_4',
          senderName: '我',
          content: '可以啊',
          time: '10:33',
          direction: MessageDirection.sent,
        ),
        const ChatMessage(
          id: 'msg_5',
          senderName: '张三',
          content: '那就这么定了',
          time: '10:34',
          direction: MessageDirection.received,
        ),
        const ChatMessage(
          id: 'msg_6',
          senderName: '我',
          content: '好的，明天见！',
          time: '10:35',
          direction: MessageDirection.sent,
        ),
      ];
    } else if (conversationId == 'conv_group_rd') {
      return [
        const ChatMessage(
          id: 'msg_1',
          senderName: '产品经理',
          content: '大家看一下这个新需求',
          time: '09:00',
          direction: MessageDirection.received,
        ),
        const ChatMessage(
          id: 'msg_2',
          senderName: '我',
          content: '收到',
          time: '09:01',
          direction: MessageDirection.sent,
        ),
        const ChatMessage(
          id: 'msg_3',
          senderName: '张三',
          content: '我看看',
          time: '09:02',
          direction: MessageDirection.received,
        ),
        const ChatMessage(
          id: 'msg_4',
          senderName: '李四',
          content: '这个需求可以做',
          time: '09:05',
          direction: MessageDirection.received,
        ),
        const ChatMessage(
          id: 'msg_5',
          senderName: '我',
          content: '技术上没问题',
          time: '09:06',
          direction: MessageDirection.sent,
        ),
      ];
    } else if (conversationId == 'conv_lisi') {
      return [
        const ChatMessage(
          id: 'msg_1',
          senderName: '李四',
          content: '周末去爬山吗？',
          time: '昨天',
          direction: MessageDirection.received,
        ),
        const ChatMessage(
          id: 'msg_2',
          senderName: '我',
          content: '好啊',
          time: '昨天',
          direction: MessageDirection.sent,
        ),
        const ChatMessage(
          id: 'msg_3',
          senderName: '李四',
          content: '[图片]',
          time: '昨天',
          direction: MessageDirection.received,
        ),
        const ChatMessage(
          id: 'msg_4',
          senderName: '我',
          content: '这个地方不错',
          time: '昨天',
          direction: MessageDirection.sent,
        ),
      ];
    } else if (conversationId == 'conv_group_family') {
      return [
        const ChatMessage(
          id: 'msg_1',
          senderName: '爸爸',
          content: '今天天气不错',
          time: '上周',
          direction: MessageDirection.received,
        ),
        const ChatMessage(
          id: 'msg_2',
          senderName: '妈妈',
          content: '记得回家吃饭',
          time: '上周',
          direction: MessageDirection.received,
        ),
        const ChatMessage(
          id: 'msg_3',
          senderName: '我',
          content: '好的',
          time: '上周',
          direction: MessageDirection.sent,
        ),
      ];
    }

    // 默认返回空列表
    return [];
  }
}
