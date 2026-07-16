import 'dart:async';
import 'dart:math' as math;

import 'package:web_socket_channel/web_socket_channel.dart';

import '../data/im_config.dart';
import '../data/proto/ws.pb.dart';

/// 连接状态
enum WsConnectionState {
  disconnected,
  connecting,
  authenticating,
  authenticated,
}

/// Token 提供者
typedef TokenProvider = String? Function();

/// WebSocket 管理器
///
/// 负责连接、认证、心跳保活、断线重连以及帧收发。
class WsClient {
  final ImConfig _config;
  final TokenProvider _tokenProvider;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;

  int _reconnectAttempts = 0;
  int _missedPongs = 0;
  bool _intentionalDisconnect = false;
  WsConnectionState _state = WsConnectionState.disconnected;

  // 连接状态流
  final _stateController = StreamController<WsConnectionState>.broadcast();
  Stream<WsConnectionState> get stateStream => _stateController.stream;
  WsConnectionState get state => _state;

  // 帧流
  final _frameController = StreamController<WsFrame>.broadcast();
  Stream<WsFrame> get frameStream => _frameController.stream;

  WsClient({required ImConfig config, required TokenProvider tokenProvider})
      : _config = config,
        _tokenProvider = tokenProvider;

  void _setState(WsConnectionState value) {
    _state = value;
    _stateController.add(value);
  }

  /// 建立连接并发送 AUTH 帧
  Future<void> connect() async {
    if (_state == WsConnectionState.connecting ||
        _state == WsConnectionState.authenticating ||
        _state == WsConnectionState.authenticated) {
      return;
    }

    _intentionalDisconnect = false;
    _stopReconnect();
    _setState(WsConnectionState.connecting);

    try {
      _channel = WebSocketChannel.connect(Uri.parse(_config.wsUrl));
    } catch (e) {
      print('[WsClient] 连接创建失败: $e');
      _setState(WsConnectionState.disconnected);
      _scheduleReconnect();
      return;
    }

    _setState(WsConnectionState.authenticating);

    final token = _tokenProvider() ?? '';
    final authFrame = WsFrame(
      type: WsFrameType.AUTH,
      payload: AuthRequest(token: token).writeToBuffer(),
    );
    _channel!.sink.add(authFrame.writeToBuffer());

    _subscription = _channel!.stream.listen(
      _onMessage,
      onDone: _onDisconnected,
      onError: (Object e) {
        print('[WsClient] 连接错误: $e');
        _onDisconnected();
      },
    );
  }

  /// 主动断开连接
  void disconnect() {
    _intentionalDisconnect = true;
    _stopReconnect();
    _stopHeartbeat();
    _cleanupChannel();
    _setState(WsConnectionState.disconnected);
  }

  /// 发送帧
  void sendFrame(WsFrame frame) {
    if (_channel == null) return;
    _channel!.sink.add(frame.writeToBuffer());
  }

  /// 释放资源
  void dispose() {
    disconnect();
    _stateController.close();
    _frameController.close();
  }

  void _onMessage(dynamic message) {
    if (message is! List<int>) {
      print('[WsClient] 收到非二进制消息，忽略');
      return;
    }

    try {
      final frame = WsFrame.fromBuffer(message);

      if (_state == WsConnectionState.authenticating) {
        _handleAuthFrame(frame);
        return;
      }

      if (frame.type == WsFrameType.PONG) {
        _missedPongs = 0;
        return;
      }

      _frameController.add(frame);
    } catch (e) {
      print('[WsClient] 帧解码失败: $e');
    }
  }

  void _handleAuthFrame(WsFrame frame) {
    if (frame.type != WsFrameType.AUTH_RESULT) {
      print('[WsClient] 认证阶段收到非 AUTH_RESULT 帧');
      _setState(WsConnectionState.disconnected);
      _cleanupChannel();
      return;
    }

    try {
      final result = AuthResult.fromBuffer(frame.payload);
      if (result.success) {
        _setState(WsConnectionState.authenticated);
        _reconnectAttempts = 0;
        _startHeartbeat();
      } else {
        print('[WsClient] 认证失败: ${result.message}');
        _setState(WsConnectionState.disconnected);
        _cleanupChannel();
      }
    } catch (e) {
      print('[WsClient] AUTH_RESULT 解码失败: $e');
      _setState(WsConnectionState.disconnected);
      _cleanupChannel();
    }
  }

  void _startHeartbeat() {
    _stopHeartbeat();
    _missedPongs = 0;

    _heartbeatTimer = Timer.periodic(_config.heartbeatInterval, (_) {
      if (_state != WsConnectionState.authenticated) return;

      _missedPongs++;
      final ping = WsFrame(type: WsFrameType.PING);
      sendFrame(ping);

      if (_missedPongs >= _config.heartbeatTimeout) {
        print('[WsClient] 心跳超时，判定断线');
        _onDisconnected();
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _onDisconnected() {
    _stopHeartbeat();
    _cleanupChannel();

    if (_intentionalDisconnect) {
      _setState(WsConnectionState.disconnected);
      return;
    }

    _setState(WsConnectionState.disconnected);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_intentionalDisconnect) return;

    final delayMs = math.min(
      _config.reconnectBaseDelay.inMilliseconds * math.pow(2, _reconnectAttempts).toInt(),
      _config.reconnectMaxDelay.inMilliseconds,
    );
    final delay = Duration(milliseconds: delayMs);
    _reconnectAttempts++;

    print('[WsClient] 第 ${_reconnectAttempts + 1} 次重连，延迟 ${delay.inSeconds}s');
    _reconnectTimer = Timer(delay, connect);
  }

  void _stopReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  void _cleanupChannel() {
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
  }
}
