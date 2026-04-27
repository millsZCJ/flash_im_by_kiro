import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../core/network/app_config.dart';
import '../model/room_message.dart';

/// 聊天室 WebSocket API（带 JWT 认证）
class ChatRoomApi {
  final WebSocketChannel Function(Uri) channelFactory;
  final String token;

  ChatRoomApi({
    required this.token,
    WebSocketChannel Function(Uri)? channelFactory,
  }) : channelFactory = channelFactory ?? WebSocketChannel.connect;

  WebSocketChannel? _channel;

  // 消息流
  final _messageController = StreamController<RoomMessage>.broadcast();
  Stream<RoomMessage> get messageStream => _messageController.stream;

  // 连接状态流
  final _connectedController = StreamController<bool>.broadcast();
  Stream<bool> get connectedStream => _connectedController.stream;

  bool _connected = false;
  bool get connected => _connected;

  String get _wsUrl =>
      'ws://${AppConfig.host}:${AppConfig.port}/chat_room?token=$token';

  /// 建立连接
  Future<void> connect() async {
    if (_connected) return;

    try {
      _channel = channelFactory(Uri.parse(_wsUrl));
      await _channel!.ready;

      _connected = true;
      _connectedController.add(true);

      _channel!.stream.listen(
        (data) {
          try {
            final json = jsonDecode(data as String) as Map<String, dynamic>;
            final msg = RoomMessage.fromJson(json);
            _messageController.add(msg);
          } catch (e) {
            print('[ROOM] 消息解析失败：$e');
          }
        },
        onError: (_) => _handleClose(),
        onDone: _handleClose,
      );
    } catch (e) {
      print('[ROOM] 连接失败：$e');
      _handleClose();
      rethrow;
    }
  }

  /// 发送消息
  void send(String content) {
    if (!_connected || _channel == null) return;
    _channel!.sink.add(content);
  }

  /// 断开连接
  Future<void> disconnect() async {
    await _channel?.sink.close();
    _handleClose();
  }

  void _handleClose() {
    _channel = null;
    _connected = false;
    _connectedController.add(false);
  }

  void dispose() {
    _channel?.sink.close();
    _messageController.close();
    _connectedController.close();
  }
}
