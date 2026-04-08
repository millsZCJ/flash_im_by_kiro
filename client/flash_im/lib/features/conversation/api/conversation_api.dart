import 'package:dio/dio.dart';
import '../../../core/network/http_client.dart';
import '../model/conversation.dart';

class ConversationApi {
  final Dio _dio;

  ConversationApi({Dio? dio}) : _dio = dio ?? HttpClient.instance;

  Future<List<Conversation>> getList() async {
    final response = await _dio.get('/conversation');
    final list = response.data as List<dynamic>;
    return list
        .map((e) => Conversation.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
