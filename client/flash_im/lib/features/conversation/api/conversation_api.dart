import 'package:dio/dio.dart';
import '../../../core/network/http_client.dart';
import '../model/conversation.dart';

class ConversationApi {
  final Dio _dio;

  ConversationApi({Dio? dio}) : _dio = dio ?? HttpClient.instance;

  Future<List<Conversation>> getList() async {
    try {
      final response = await _dio.get('/conversation');
      final list = response.data as List<dynamic>;
      return list
          .map((e) => Conversation.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException {
      // 后端不可用时降级到本地 mock 数据
      return _mockList();
    }
  }

  static List<Conversation> _mockList() => [
    const Conversation(title: '张三', lastMsg: '好的，明天见！', time: '昨天'),
    const Conversation(title: '产品研发群', lastMsg: '李四：这个需求可以做', time: '周一'),
    const Conversation(title: '李四', lastMsg: '[图片]', time: '3天前'),
    const Conversation(title: '家庭群', lastMsg: '妈妈：记得回家吃饭', time: '上周'),
    const Conversation(title: '王五', lastMsg: '好的收到', time: '上周'),
    const Conversation(title: '大学同学群', lastMsg: '周末聚一聚？', time: '2周前'),
  ];
}
