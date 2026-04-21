import 'package:dio/dio.dart';
import '../../../core/network/http_client.dart';
import '../model/search_result.dart';

/// 搜索 API
/// 当后端搜索接口就绪后，替换 _mockSearch 中的逻辑即可。
class SearchApi {
  final Dio _dio;

  SearchApi({Dio? dio}) : _dio = dio ?? HttpClient.instance;

  /// 全局搜索，返回按类型分组的结果列表
  Future<List<SearchResult>> search(String keyword) async {
    if (keyword.trim().isEmpty) return [];

    // 尝试调用后端搜索接口；若接口不存在则降级到本地 mock
    try {
      final resp = await _dio.get(
        '/search',
        queryParameters: {'q': keyword},
      );
      return _parseResponse(resp.data as List<dynamic>);
    } on DioException {
      // 后端接口暂未实现时，使用本地 mock 数据演示
      return _mockSearch(keyword);
    }
  }

  List<SearchResult> _parseResponse(List<dynamic> data) {
    return data.map((e) {
      final map = e as Map<String, dynamic>;
      return SearchResult(
        type: SearchResultType.values.firstWhere(
          (t) => t.name == map['type'],
          orElse: () => SearchResultType.chatHistory,
        ),
        title: map['title'] as String,
        subtitle: map['subtitle'] as String,
        time: map['time'] as String?,
        conversationId: map['conversationId'] as String,
        messageIndex: map['messageIndex'] as int?,
      );
    }).toList();
  }

  /// 本地 mock 数据，用于在后端接口就绪前演示搜索效果
  List<SearchResult> _mockSearch(String keyword) {
    final kw = keyword.toLowerCase();
    final all = _mockData();
    return all
        .where(
          (r) =>
              r.title.toLowerCase().contains(kw) ||
              r.subtitle.toLowerCase().contains(kw),
        )
        .toList();
  }

  static List<SearchResult> _mockData() => [
    // 联系人
    const SearchResult(
      type: SearchResultType.contact,
      title: '张三',
      subtitle: '备注：小张',
      conversationId: 'conv_zhangsan',
    ),
    const SearchResult(
      type: SearchResultType.contact,
      title: '李四',
      subtitle: '备注：老李',
      conversationId: 'conv_lisi',
    ),
    const SearchResult(
      type: SearchResultType.contact,
      title: '王五',
      subtitle: '备注：王总',
      conversationId: 'conv_wangwu',
    ),
    // 群聊
    const SearchResult(
      type: SearchResultType.group,
      title: '产品研发群',
      subtitle: '12人',
      conversationId: 'conv_group_rd',
    ),
    const SearchResult(
      type: SearchResultType.group,
      title: '家庭群',
      subtitle: '5人',
      conversationId: 'conv_group_family',
    ),
    const SearchResult(
      type: SearchResultType.group,
      title: '大学同学群',
      subtitle: '38人',
      conversationId: 'conv_group_college',
    ),
    // 聊天记录
    const SearchResult(
      type: SearchResultType.chatHistory,
      title: '张三',
      subtitle: '好的，明天见！',
      time: '昨天',
      conversationId: 'conv_zhangsan',
      messageIndex: 5,
    ),
    const SearchResult(
      type: SearchResultType.chatHistory,
      title: '产品研发群',
      subtitle: '李四：这个需求可以做',
      time: '周一',
      conversationId: 'conv_group_rd',
      messageIndex: 12,
    ),
    const SearchResult(
      type: SearchResultType.chatHistory,
      title: '李四',
      subtitle: '发来了一张图片',
      time: '3天前',
      conversationId: 'conv_lisi',
      messageIndex: 3,
    ),
    const SearchResult(
      type: SearchResultType.chatHistory,
      title: '家庭群',
      subtitle: '妈妈：记得回家吃饭',
      time: '上周',
      conversationId: 'conv_group_family',
      messageIndex: 8,
    ),
  ];
}
