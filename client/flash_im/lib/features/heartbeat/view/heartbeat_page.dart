import 'dart:async';
import 'package:flutter/material.dart';
import '../api/heartbeat_api.dart';
import '../model/heartbeat_state.dart';

/// 心跳通信测试页
class HeartbeatPage extends StatefulWidget {
  const HeartbeatPage({super.key});

  @override
  State<HeartbeatPage> createState() => _HeartbeatPageState();
}

class _HeartbeatPageState extends State<HeartbeatPage> {
  final _api = HeartbeatApi();
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _logs = <HeartbeatLog>[];

  WsConnectionState _connState = WsConnectionState.disconnected;

  late final StreamSubscription<WsConnectionState> _stateSub;
  late final StreamSubscription<HeartbeatLog> _logSub;

  @override
  void initState() {
    super.initState();
    _stateSub = _api.stateStream.listen((s) {
      setState(() => _connState = s);
    });
    _logSub = _api.logStream.listen((log) {
      setState(() => _logs.add(log));
      // 新消息到来时滚动到底部
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _stateSub.cancel();
    _logSub.cancel();
    _api.dispose();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    _api.send(text);
    _inputController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF07C160),
        foregroundColor: Colors.white,
        title: const Text(
          '💓 心跳通信',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _ConnectionBadge(state: _connState),
          ),
        ],
      ),
      body: Column(
        children: [
          // 端点信息栏
          _EndpointBar(state: _connState),
          // 消息日志
          Expanded(child: _LogList(logs: _logs, scrollController: _scrollController)),
          // 输入 + 操作区
          _BottomBar(
            connState: _connState,
            inputController: _inputController,
            onConnect: _api.connect,
            onDisconnect: _api.disconnect,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

// ─── 连接状态徽章 ────────────────────────────────────────────────────────────

class _ConnectionBadge extends StatelessWidget {
  final WsConnectionState state;
  const _ConnectionBadge({required this.state});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (state) {
      WsConnectionState.connected    => ('已连接', const Color(0xFFD4F5E2)),
      WsConnectionState.connecting   => ('连接中', const Color(0xFFFFF3CD)),
      WsConnectionState.disconnected => ('未连接', const Color(0xFFEEEEEE)),
    };
    final textColor = switch (state) {
      WsConnectionState.connected    => const Color(0xFF07C160),
      WsConnectionState.connecting   => const Color(0xFFE6A817),
      WsConnectionState.disconnected => const Color(0xFF999999),
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 状态指示点
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: textColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 端点信息栏 ──────────────────────────────────────────────────────────────

class _EndpointBar extends StatelessWidget {
  final WsConnectionState state;
  const _EndpointBar({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF7F7F7),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.link, size: 14, color: Color(0xFFAAAAAA)),
          const SizedBox(width: 6),
          Text(
            'ws://127.0.0.1:3000/ws',
            style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
          ),
        ],
      ),
    );
  }
}

// ─── 消息日志列表 ─────────────────────────────────────────────────────────────

class _LogList extends StatelessWidget {
  final List<HeartbeatLog> logs;
  final ScrollController scrollController;

  const _LogList({required this.logs, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline, size: 40, color: Color(0xFFCCCCCC)),
            SizedBox(height: 10),
            Text(
              '点击「连接」开始测试',
              style: TextStyle(fontSize: 13, color: Color(0xFFBBBBBB)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      itemCount: logs.length,
      itemBuilder: (_, i) => _LogItem(log: logs[i]),
    );
  }
}

class _LogItem extends StatelessWidget {
  final HeartbeatLog log;
  const _LogItem({required this.log});

  @override
  Widget build(BuildContext context) {
    final (tag, tagBg, tagFg) = switch (log.type) {
      HeartbeatLogType.received => ('收到', const Color(0xFFE6F9EE), const Color(0xFF07C160)),
      HeartbeatLogType.sent     => ('发送', const Color(0xFFE8F0FE), const Color(0xFF1A73E8)),
      HeartbeatLogType.error    => ('ERROR', const Color(0xFFFDECEA), const Color(0xFFE53935)),
      HeartbeatLogType.info     => ('INFO', const Color(0xFFF3F3F3), const Color(0xFF888888)),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 时间
          SizedBox(
            width: 60,
            child: Text(
              log.timeLabel,
              style: const TextStyle(fontSize: 11, color: Color(0xFFBBBBBB)),
            ),
          ),
          const SizedBox(width: 6),
          // 标签
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: tagBg,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              tag,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: tagFg,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 消息内容
          Expanded(
            child: Text(
              log.message,
              style: const TextStyle(fontSize: 13, color: Color(0xFF333333)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 底部输入 + 操作栏 ────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final WsConnectionState connState;
  final TextEditingController inputController;
  final VoidCallback onConnect;
  final Future<void> Function() onDisconnect;
  final VoidCallback onSend;

  const _BottomBar({
    required this.connState,
    required this.inputController,
    required this.onConnect,
    required this.onDisconnect,
    required this.onSend,
  });

  bool get _isConnected => connState == WsConnectionState.connected;
  bool get _isConnecting => connState == WsConnectionState.connecting;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 消息输入行
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: inputController,
                      enabled: _isConnected,
                      onSubmitted: (_) => onSend(),
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: _isConnected ? '输入消息，按 Enter 发送' : '请先连接服务器',
                        hintStyle: const TextStyle(fontSize: 14, color: Color(0xFFAAAAAA)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(color: Color(0xFF07C160)),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
                        ),
                        filled: !_isConnected,
                        fillColor: const Color(0xFFF5F5F5),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _ActionButton(
                    label: '发送',
                    color: const Color(0xFF07C160),
                    enabled: _isConnected,
                    onTap: onSend,
                  ),
                ],
              ),
            ),
            // 连接 / 断开行
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      label: _isConnecting ? '连接中...' : '连接',
                      color: const Color(0xFF07C160),
                      enabled: !_isConnected && !_isConnecting,
                      onTap: onConnect,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionButton(
                      label: '断开',
                      color: const Color(0xFFF5F5F5),
                      textColor: const Color(0xFF555555),
                      enabled: _isConnected || _isConnecting,
                      onTap: onDisconnect,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color? textColor;
  final bool enabled;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    this.textColor,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: enabled ? 1.0 : 0.4,
      duration: const Duration(milliseconds: 200),
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          height: 38,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: textColor ?? Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
