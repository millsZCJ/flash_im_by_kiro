import 'package:flutter/material.dart';

import '../logic/ws_client.dart';

/// WebSocket 连接状态指示器
///
/// - authenticated：完全隐藏（不占空间）
/// - disconnected：红色横条，可点击手动重连
/// - connecting / authenticating：橙色横条
class WsStatusIndicator extends StatelessWidget {
  final Stream<WsConnectionState> stateStream;
  final WsConnectionState initialState;
  final VoidCallback? onTapReconnect;

  const WsStatusIndicator({
    super.key,
    required this.stateStream,
    required this.initialState,
    this.onTapReconnect,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<WsConnectionState>(
      initialData: initialState,
      stream: stateStream,
      builder: (context, snapshot) {
        final state = snapshot.data ?? WsConnectionState.disconnected;

        if (state == WsConnectionState.authenticated) {
          return const SizedBox.shrink();
        }

        final (backgroundColor, text, showTapHint) = switch (state) {
          WsConnectionState.connecting =>
            (const Color(0xFFFFA726), '正在连接...', false),
          WsConnectionState.authenticating =>
            (const Color(0xFFFFA726), '正在认证...', false),
          _ => (const Color(0xFFEF5350), '连接已断开', true),
        };

        return GestureDetector(
          onTap: onTapReconnect,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: double.infinity,
            height: 32,
            color: backgroundColor,
            alignment: Alignment.center,
            child: Text(
              showTapHint && onTapReconnect != null ? '$text，点击重连' : text,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      },
    );
  }
}
