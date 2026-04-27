import 'dart:async';
import 'package:flutter/material.dart';
import '../../features/auth/api/auth_api.dart';
import '../../features/chat_room/api/chat_room_api.dart';
import '../../features/chat_room/model/room_message.dart';

/// 聊天室页面（微信风格）
class ChatRoomPage extends StatefulWidget {
  final AuthApi authApi;
  const ChatRoomPage({super.key, required this.authApi});

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage>
    with AutomaticKeepAliveClientMixin {
  late final ChatRoomApi _roomApi;
  final _messages = <RoomMessage>[];
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  bool _connected = false;
  bool _connecting = false;

  // 自己的昵称（通过第一条 join 消息推断）
  String? _selfNickname;

  late final StreamSubscription<RoomMessage> _msgSub;
  late final StreamSubscription<bool> _connSub;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _roomApi = ChatRoomApi(token: widget.authApi.token ?? '');

    _connSub = _roomApi.connectedStream.listen((c) {
      setState(() => _connected = c);
    });

    _msgSub = _roomApi.messageStream.listen((msg) {
      setState(() => _messages.add(msg));
      _scrollToBottom();
    });

    _connect();
  }

  @override
  void dispose() {
    _msgSub.cancel();
    _connSub.cancel();
    _roomApi.dispose();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    if (_connecting || _connected) return;
    setState(() => _connecting = true);
    try {
      await _roomApi.connect();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('连接失败：$e'),
          backgroundColor: const Color(0xFFE53935),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
        ));
      }
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  void _send() {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || !_connected) return;
    _roomApi.send(text);
    _inputCtrl.clear();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  bool _isSelf(String sender) {
    if (_selfNickname == null) {
      final joinMsg = _messages
          .where((m) => m.type == RoomMessageType.join)
          .firstOrNull;
      if (joinMsg != null) _selfNickname = joinMsg.sender;
    }
    return sender == _selfNickname;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: const Color(0xFFEDEDED),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildInputBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFEDEDED),
      elevation: 0,
      centerTitle: true,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('聊天室',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A))),
          const SizedBox(width: 8),
          _StatusDot(connected: _connected, connecting: _connecting),
        ],
      ),
      actions: [
        if (!_connected && !_connecting)
          TextButton(
            onPressed: _connect,
            child: const Text('重连',
                style: TextStyle(color: Color(0xFF07C160))),
          ),
      ],
    );
  }

  Widget _buildMessageList() {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chat_bubble_outline, size: 48,
                color: Color(0xFFCCCCCC)),
            const SizedBox(height: 12),
            Text(
              _connecting ? '正在连接聊天室...' : '暂无消息',
              style: const TextStyle(fontSize: 14, color: Color(0xFF999999)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: _messages.length,
      itemBuilder: (_, i) {
        final msg = _messages[i];
        if (msg.isSystem) return _SystemBubble(msg: msg);
        return _ChatBubble(msg: msg, isSelf: _isSelf(msg.sender));
      },
    );
  }

  Widget _buildInputBar() {
    return Container(
      color: const Color(0xFFF7F7F7),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFDDDDDD)),
                ),
                child: TextField(
                  controller: _inputCtrl,
                  enabled: _connected,
                  onSubmitted: (_) => _send(),
                  style: const TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: _connected ? '输入消息...' : '连接中...',
                    hintStyle: const TextStyle(
                        color: Color(0xFFBBBBBB), fontSize: 15),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    isDense: true,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _connected ? _send : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: _connected
                      ? const Color(0xFF07C160)
                      : const Color(0xFFCCCCCC),
                  borderRadius: BorderRadius.circular(4),
                ),
                alignment: Alignment.center,
                child: const Text('发送',
                    style: TextStyle(color: Colors.white, fontSize: 15,
                        fontWeight: FontWeight.w500)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 连接状态指示点 ───────────────────────────────────────────────────────────

class _StatusDot extends StatelessWidget {
  final bool connected;
  final bool connecting;
  const _StatusDot({required this.connected, required this.connecting});

  @override
  Widget build(BuildContext context) {
    final color = connected
        ? const Color(0xFF07C160)
        : connecting
            ? const Color(0xFFE6A817)
            : const Color(0xFFCCCCCC);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

// ─── 系统消息气泡 ─────────────────────────────────────────────────────────────

class _SystemBubble extends StatelessWidget {
  final RoomMessage msg;
  const _SystemBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFD9D9D9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(msg.systemText,
              style: const TextStyle(fontSize: 12, color: Color(0xFF666666))),
        ),
      ),
    );
  }
}

// ─── 聊天气泡 ─────────────────────────────────────────────────────────────────

class _ChatBubble extends StatelessWidget {
  final RoomMessage msg;
  final bool isSelf;
  const _ChatBubble({required this.msg, required this.isSelf});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment:
            isSelf ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: isSelf
            ? [_buildContent(), const SizedBox(width: 8), _buildAvatar()]
            : [_buildAvatar(), const SizedBox(width: 8), _buildContent()],
      ),
    );
  }

  Widget _buildAvatar() {
    final color = _avatarColor(msg.sender);
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: Text(
        msg.sender.isNotEmpty ? msg.sender[0] : '?',
        style: const TextStyle(color: Colors.white, fontSize: 16,
            fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildContent() {
    return Flexible(
      child: Column(
        crossAxisAlignment:
            isSelf ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isSelf)
            Padding(
              padding: const EdgeInsets.only(bottom: 4, left: 2),
              child: Text(msg.sender,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF888888))),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelf ? const Color(0xFF95EC69) : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isSelf ? 8 : 2),
                topRight: Radius.circular(isSelf ? 2 : 8),
                bottomLeft: const Radius.circular(8),
                bottomRight: const Radius.circular(8),
              ),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 2,
                    offset: const Offset(0, 1)),
              ],
            ),
            child: Text(msg.content,
                style: const TextStyle(
                    fontSize: 15, color: Color(0xFF1A1A1A))),
          ),
        ],
      ),
    );
  }

  Color _avatarColor(String name) {
    const colors = [
      Color(0xFF5B9BD5), Color(0xFF70AD47), Color(0xFFED7D31),
      Color(0xFFFFC000), Color(0xFF4472C4), Color(0xFF9E480E),
      Color(0xFF636363), Color(0xFF997300),
    ];
    if (name.isEmpty) return colors[0];
    return colors[name.codeUnitAt(0) % colors.length];
  }
}
