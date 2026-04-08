import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flash_im/features/conversation/api/conversation_api.dart';
import 'package:flash_im/features/conversation/model/conversation.dart';

void main() {
  group('ConversationApi', () {
    test('getList 返回非空列表且字段正确', () async {
      // 直接指向真实服务，可按需改 baseUrl
      final dio = Dio(BaseOptions(baseUrl: 'http://192.168.122.208:3000'));
      final api = ConversationApi(dio: dio);

      final list = await api.getList();

      expect(list, isNotEmpty);
      expect(list.length, 20);

      final first = list.first;
      expect(first.title, isNotEmpty);
      expect(first.lastMsg, isNotEmpty);
      expect(first.time, isNotEmpty);
    });

    test('Conversation.fromJson 解析正确', () {
      final json = {
        'title': '张伟',
        'lastMsg': '好的，明天见',
        'time': '2026-04-07 09:01',
      };
      final c = Conversation.fromJson(json);
      expect(c.title, '张伟');
      expect(c.lastMsg, '好的，明天见');
      expect(c.time, '2026-04-07 09:01');
    });
  });
}
