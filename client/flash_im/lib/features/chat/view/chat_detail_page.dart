import 'package:flutter/material.dart';
import '../api/chat_api.dart';
import '../model/chat_message.dart';

/// 聊天详情页
///
/// [conversationId]    会话 ID
/// [title]             AppBar 标题（联系人名 / 群名）
/// [initialMessageIndex] 可选，打开后自动滚动并高亮到该索引的消息（来自搜索跳转）
class ChatDetailPage extends StatefulWidget {
  final String conversationId;
  final String title;
  final int? initialMessageIndex;

  const ChatDetailPage({
    super.key,
    required this.conversationId,
    required this.title,
    this.initialMessageIndex,
  });

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final _api = ChatApi();
  late Future<List<ChatMessage>> _future;

  /// 用于滚动定位
  final _scrollController = ScrollController();

  /// 高亮消息的索引（搜索跳转时使用）
  int? _highlightedIndex;

  @override
  void initState() {
    super.initState();
    _future = _api.getMessages(widget.conversationId);
    _highlightedIndex = widget.initialMessageIndex;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 消息加载完成后，滚动到目标消息
  void _scrollToMessage(int index, int total) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      // 估算每条消息的平均高度（含头像、内容、间距）
      const estimatedItemHeight = 72.0;
      final offset = index * estimatedItemHeight;
      final maxOffset = _scrollController.position.maxScrollExtent;

      _scrollController.animateTo(
        offset.clamp(0.0, maxOffset),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );

      // 高亮 2 秒后取消
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _highlightedIndex = null);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDEDED),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEDEDED),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Color(0xFF1A1A1A)),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return FutureBuilder<List<ChatMessage>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF07C160)),
              strokeWidth: 2,
            ),
          );
        }
        if (snap.hasError || snap.data == null) {
          return Center(
            child: Text(
              '加载失败',
              style: const TextStyle(color: Colors.grey),
            ),
          );
        }

        final messages = snap.data!;

        // 加载完成后，若有目标消息则滚动过去
        if (widget.initialMessageIndex != null) {
          _scrollToMessage(widget.initialMessageIndex!, messages.length);
        }

        if (messages.isEmpty) {
          return const Center(
            child: Text('暂无消息', style: TextStyle(color: Colors.grey)),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final msg = messages[index];
            final isHighlighted = _highlightedIndex == index;
            return _MessageBubble(
              message: msg,
              isHighlighted: isHighlighted,
            );
          },
        );
      },
    );
  }

  Widget _buildInputBar() {
    return Container(
      color: const Color(0xFFF7F7F7),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            const Icon(Icons.keyboard_voice, size: 26, color: Color(0xFF888888)),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFDDDDDD)),
                ),
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: const Text(
                  '',
                  style: TextStyle(fontSize: 15),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.emoji_emotions_outlined, size: 26, color: Color(0xFF888888)),
            const SizedBox(width: 8),
            const Icon(Icons.add_circle_outline, size: 26, color: Color(0xFF888888)),
          ],
        ),
      ),
    );
  }
}

/// 单条消息气泡
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isHighlighted;

  const _MessageBubble({
    required this.message,
    required this.isHighlighted,
  });

  @override
  Widget build(BuildContext context) {
    final isSent = message.direction == MessageDirection.sent;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      color: isHighlighted ? const Color(0xFFD4F5E2) : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisAlignment:
            isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: isSent
            ? [
                _buildContent(isSent),
                const SizedBox(width: 8),
                _buildAvatar(),
              ]
            : [
                _buildAvatar(),
                const SizedBox(width: 8),
                _buildContent(isSent),
              ],
      ),
    );
  }

  Widget _buildAvatar() {
    final color = _avatarColor(message.senderName);
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: Text(
        message.senderName.characters.first,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildContent(bool isSent) {
    return Flexible(
      child: Column(
        crossAxisAlignment:
            isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isSent)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                message.senderName,
                style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSent ? const Color(0xFF95EC69) : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isSent ? 8 : 2),
                topRight: Radius.circular(isSent ? 2 : 8),
                bottomLeft: const Radius.circular(8),
                bottomRight: const Radius.circular(8),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              message.content,
              style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A1A)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              message.time,
              style: const TextStyle(fontSize: 11, color: Color(0xFFAAAAAA)),
            ),
          ),
        ],
      ),
    );
  }

  Color _avatarColor(String name) {
    const colors = [
      Color(0xFF5B9BD5),
      Color(0xFF70AD47),
      Color(0xFFED7D31),
      Color(0xFFFFC000),
      Color(0xFF4472C4),
      Color(0xFF9E480E),
      Color(0xFF636363),
      Color(0xFF997300),
    ];
    return colors[name.codeUnitAt(0) % colors.length];
  }
}
