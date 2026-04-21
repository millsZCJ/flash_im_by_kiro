import 'dart:async';
import 'package:flutter/material.dart';
import '../api/search_api.dart';
import '../model/search_result.dart';
import '../widget/search_section.dart';
import '../../chat/view/chat_detail_page.dart';

/// 全局搜索页面（仿微信风格）
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _api = SearchApi();

  String _keyword = '';
  List<SearchResult> _results = [];
  bool _loading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // 页面打开后自动弹出键盘
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    setState(() {
      _keyword = value;
      if (value.trim().isEmpty) {
        _results = [];
        _loading = false;
      } else {
        _loading = true;
      }
    });

    if (value.trim().isEmpty) return;

    // 防抖 300ms，避免每次击键都请求
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final results = await _api.search(value);
      if (!mounted) return;
      setState(() {
        _results = results;
        _loading = false;
      });
    });
  }

  void _onResultTap(SearchResult result) {
    if (result.type == SearchResultType.chatHistory) {
      // 跳转到聊天记录所在位置
      _navigateToChatHistory(result);
    } else {
      // 跳转到对应会话
      _navigateToConversation(result);
    }
  }

  void _navigateToConversation(SearchResult result) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatDetailPage(
          conversationId: result.conversationId,
          title: result.title,
        ),
      ),
    );
  }

  void _navigateToChatHistory(SearchResult result) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatDetailPage(
          conversationId: result.conversationId,
          title: result.title,
          initialMessageIndex: result.messageIndex,
        ),
      ),
    );
  }

  // 按类型过滤结果
  List<SearchResult> _byType(SearchResultType type) =>
      _results.where((r) => r.type == type).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDEDED),
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFEDEDED),
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Row(
        children: [
          const SizedBox(width: 8),
          // 搜索输入框
          Expanded(
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                onChanged: _onChanged,
                textInputAction: TextInputAction.search,
                style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A1A)),
                decoration: InputDecoration(
                  hintText: '搜索',
                  hintStyle: const TextStyle(fontSize: 15, color: Color(0xFFAAAAAA)),
                  prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFFAAAAAA)),
                  suffixIcon: _keyword.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _controller.clear();
                            _onChanged('');
                          },
                          child: const Icon(Icons.cancel, size: 18, color: Color(0xFFAAAAAA)),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  isDense: true,
                ),
              ),
            ),
          ),
          // 取消按钮
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF1A1A1A),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: const Text('取消', style: TextStyle(fontSize: 15)),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    // 空状态：未输入关键词
    if (_keyword.trim().isEmpty) {
      return const _EmptyHint();
    }

    // 加载中
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF07C160)),
          strokeWidth: 2,
        ),
      );
    }

    // 无结果
    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 48, color: Color(0xFFCCCCCC)),
            const SizedBox(height: 12),
            Text(
              '没有找到"$_keyword"的相关结果',
              style: const TextStyle(fontSize: 14, color: Color(0xFF999999)),
            ),
          ],
        ),
      );
    }

    // 搜索结果列表
    return ListView(
      children: [
        SearchSection(
          title: '联系人',
          results: _byType(SearchResultType.contact),
          keyword: _keyword,
          onTap: _onResultTap,
        ),
        SearchSection(
          title: '群聊',
          results: _byType(SearchResultType.group),
          keyword: _keyword,
          onTap: _onResultTap,
        ),
        SearchSection(
          title: '聊天记录',
          results: _byType(SearchResultType.chatHistory),
          keyword: _keyword,
          onTap: _onResultTap,
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

/// 未输入关键词时的提示区域
class _EmptyHint extends StatelessWidget {
  const _EmptyHint();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 16),
        _HintTile(icon: Icons.person_outline, label: '搜索联系人'),
        const Divider(height: 1, indent: 56, color: Color(0xFFE5E5E5)),
        _HintTile(icon: Icons.group_outlined, label: '搜索群聊'),
        const Divider(height: 1, indent: 56, color: Color(0xFFE5E5E5)),
        _HintTile(icon: Icons.chat_bubble_outline, label: '搜索聊天记录'),
      ],
    );
  }
}

class _HintTile extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HintTile({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 22, color: const Color(0xFF888888)),
          const SizedBox(width: 18),
          Text(label, style: const TextStyle(fontSize: 15, color: Color(0xFF888888))),
        ],
      ),
    );
  }
}
