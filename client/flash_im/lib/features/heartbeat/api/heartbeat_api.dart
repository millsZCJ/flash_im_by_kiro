import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../core/network/app_config.dart';
import '../model/heartbeat_state.dart';

/// WebSocket 心跳通信 API
///
/// 负责管理连接生命周期，并通过 Stream 向外暴露状态和消息。
///
/// [channelFactory] 可在测试中注入 mock channel，生产代码使用默认值。
class HeartbeatApi {
  final WebSocketChannel Function(Uri) channelFactory;

  HeartbeatApi({WebSocketChannel Function(Uri)? channelFactory})
      : channelFactory = channelFactory ?? WebSocketChannel.connect;

  WebSocketChannel? _channel;

  // 连接状态流
  final _stateController = StreamController<WsConnectionState>.broadcast();
  Stream<WsConnectionState> get stateStream => _stateController.stream;

  // 消息日志流
  final _logController = StreamController<HeartbeatLog>.broadcast();
  Stream<HeartbeatLog> get logStream => _logController.stream;

  WsConnectionState _state = WsConnectionState.disconnected;
  WsConnectionState get state => _state;

  String get _wsUrl =>
      'ws://${AppConfig.host}:${AppConfig.port}/ws';

  /// 建立 WebSocket 连接
  Future<void> connect() async {
    if (_state != WsConnectionState.disconnected) return;

    _emit(WsConnectionState.connecting);
    _addLog(HeartbeatLogType.info, '正在连接 $_wsUrl ...');

    try {
      _channel = channelFactory(Uri.parse(_wsUrl));

      // 等待握手完成
      await _channel!.ready;

      _emit(WsConnectionState.connected);
      _addLog(HeartbeatLogType.info, '连接成功');

      // 监听服务端消息
      _channel!.stream.listen(
        (data) {
          _addLog(HeartbeatLogType.received, data.toString());
        },
        onError: (e) {
          _addLog(HeartbeatLogType.error, '连接错误：$e');
          _handleClose();
        },
        onDone: () {
          _addLog(HeartbeatLogType.info, '连接已断开');
          _handleClose();
        },
      );
    } catch (e) {
      _addLog(HeartbeatLogType.error, '连接失败：$e');
      _handleClose();
    }
  }

  /// 发送文本消息
  void send(String message) {
    if (_state != WsConnectionState.connected || _channel == null) return;
    _channel!.sink.add(message);
    _addLog(HeartbeatLogType.sent, message);
  }

  /// 主动断开连接
  Future<void> disconnect() async {
    await _channel?.sink.close();
    _handleClose();
  }

  void _handleClose() {
    _channel = null;
    _emit(WsConnectionState.disconnected);
  }

  void _emit(WsConnectionState s) {
    _state = s;
    _stateController.add(s);
  }

  void _addLog(HeartbeatLogType type, String message) {
    _logController.add(HeartbeatLog(type: type, message: message));
  }

  void dispose() {
    _channel?.sink.close();
    _stateController.close();
    _logController.close();
  }
}
