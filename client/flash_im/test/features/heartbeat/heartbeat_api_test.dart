import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flash_im/features/heartbeat/api/heartbeat_api.dart';
import 'package:flash_im/features/heartbeat/model/heartbeat_state.dart';

// ─── Mock WebSocketSink ───────────────────────────────────────────────────────

class _MockSink implements WebSocketSink {
  final List<dynamic> sent = [];
  bool closed = false;
  final _closeCompleter = Completer<void>();

  @override
  void add(dynamic data) => sent.add(data);

  @override
  Future<void> close([int? code, String? reason]) {
    closed = true;
    if (!_closeCompleter.isCompleted) _closeCompleter.complete();
    return _closeCompleter.future;
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<void> addStream(Stream stream) async {
    await for (final data in stream) {
      add(data);
    }
  }

  @override
  Future get done => _closeCompleter.future;
}

// ─── Mock WebSocketChannel ────────────────────────────────────────────────────
//
// 用 StreamChannelMixin 满足接口要求，只需实现 stream 和 sink 两个核心属性。

class _MockChannel extends StreamChannelMixin implements WebSocketChannel {
  final StreamController<dynamic> _controller;
  final _MockSink _mockSink;
  final bool failReady;

  _MockChannel({this.failReady = false})
      : _controller = StreamController<dynamic>(),
        _mockSink = _MockSink();

  /// 模拟服务端推送消息给客户端
  void pushFromServer(String message) => _controller.add(message);

  /// 模拟服务端关闭连接
  void closeFromServer() => _controller.close();

  /// 读取客户端发出的消息
  List<dynamic> get sentMessages => _mockSink.sent;

  @override
  Stream get stream => _controller.stream;

  @override
  WebSocketSink get sink => _mockSink;

  @override
  Future<void> get ready =>
      failReady ? Future.error(Exception('连接被拒绝')) : Future.value();

  @override
  int? get closeCode => null;

  @override
  String? get closeReason => null;

  @override
  String? get protocol => null;
}

// ─── 测试 ─────────────────────────────────────────────────────────────────────

void main() {
  group('HeartbeatApi', () {
    late _MockChannel mockChannel;
    late HeartbeatApi api;

    setUp(() {
      mockChannel = _MockChannel();
      api = HeartbeatApi(
        channelFactory: (_) => mockChannel,
      );
    });

    tearDown(() => api.dispose());

    // ── 1. 初始状态 ────────────────────────────────────────────────────────────
    test('初始状态为 disconnected', () {
      expect(api.state, WsConnectionState.disconnected);
    });

    // ── 2. 连接流程 ────────────────────────────────────────────────────────────
    test('connect() 后状态变为 connected', () async {
      await api.connect();
      expect(api.state, WsConnectionState.connected);
    });

    test('connect() 过程中状态经历 connecting → connected', () async {
      final states = <WsConnectionState>[];
      final sub = api.stateStream.listen(states.add);

      await api.connect();
      await Future.delayed(Duration.zero); // 等待 stream 事件冲刷
      await sub.cancel();

      expect(states, [
        WsConnectionState.connecting,
        WsConnectionState.connected,
      ]);
    });

    test('connect() 成功后日志包含"连接成功"', () async {
      final logs = <HeartbeatLog>[];
      final sub = api.logStream.listen(logs.add);

      await api.connect();
      await Future.delayed(Duration.zero);
      await sub.cancel();

      expect(
        logs.any((l) => l.message.contains('连接成功')),
        isTrue,
      );
    });

    // ── 3. 重复连接保护 ────────────────────────────────────────────────────────
    test('已连接时再次调用 connect() 不会重复建立连接', () async {
      final states = <WsConnectionState>[];
      api.stateStream.listen(states.add);

      await api.connect();
      await api.connect(); // 第二次应被忽略

      // 只应有一次 connecting + connected
      expect(states.where((s) => s == WsConnectionState.connecting).length, 1);
      expect(states.where((s) => s == WsConnectionState.connected).length, 1);
    });

    // ── 4. 发送消息 ────────────────────────────────────────────────────────────
    test('send() 将消息写入 channel sink', () async {
      await api.connect();
      api.send('你好，服务器！');

      expect(mockChannel.sentMessages, contains('你好，服务器！'));
    });

    test('send() 同时记录 sent 类型日志', () async {
      final logs = <HeartbeatLog>[];
      final sub = api.logStream.listen(logs.add);

      await api.connect();
      await Future.delayed(Duration.zero);
      api.send('测试消息');
      await Future.delayed(Duration.zero);
      await sub.cancel();

      final sentLog = logs.firstWhere(
        (l) => l.type == HeartbeatLogType.sent,
        orElse: () => throw StateError('未找到 sent 日志'),
      );
      expect(sentLog.message, '测试消息');
    });

    test('未连接时 send() 不发送任何消息', () {
      api.send('不应该发出去');
      expect(mockChannel.sentMessages, isEmpty);
    });

    // ── 5. 接收消息 ────────────────────────────────────────────────────────────
    test('服务端推送消息后，logStream 收到 received 类型日志', () async {
      final logs = <HeartbeatLog>[];
      api.logStream.listen(logs.add);

      await api.connect();
      mockChannel.pushFromServer('echo: 你好');

      // 等待 Stream 事件传播
      await Future.delayed(Duration.zero);

      final recvLog = logs.firstWhere(
        (l) => l.type == HeartbeatLogType.received,
        orElse: () => throw StateError('未找到 received 日志'),
      );
      expect(recvLog.message, 'echo: 你好');
    });

    test('服务端连续推送多条消息，全部记录到日志', () async {
      final logs = <HeartbeatLog>[];
      api.logStream.listen(logs.add);

      await api.connect();
      mockChannel.pushFromServer('消息 1');
      mockChannel.pushFromServer('消息 2');
      mockChannel.pushFromServer('消息 3');

      await Future.delayed(Duration.zero);

      final received = logs.where((l) => l.type == HeartbeatLogType.received);
      expect(received.length, 3);
    });

    // ── 6. 断开连接 ────────────────────────────────────────────────────────────
    test('disconnect() 后状态变为 disconnected', () async {
      await api.connect();
      await api.disconnect();

      expect(api.state, WsConnectionState.disconnected);
    });

    test('disconnect() 后 sink 被关闭', () async {
      await api.connect();
      await api.disconnect();

      expect((mockChannel.sink as _MockSink).closed, isTrue);
    });

    // ── 7. 服务端主动关闭 ──────────────────────────────────────────────────────
    test('服务端关闭连接后，状态变为 disconnected', () async {
      final states = <WsConnectionState>[];
      api.stateStream.listen(states.add);

      await api.connect();
      mockChannel.closeFromServer();

      await Future.delayed(Duration.zero);

      expect(api.state, WsConnectionState.disconnected);
    });

    // ── 8. 连接失败 ────────────────────────────────────────────────────────────
    test('channel.ready 抛出异常时，状态回到 disconnected 并记录 error 日志', () async {
      final failChannel = _MockChannel(failReady: true);
      final failApi = HeartbeatApi(channelFactory: (_) => failChannel);
      final logs = <HeartbeatLog>[];
      final sub = failApi.logStream.listen(logs.add);

      await failApi.connect();
      await Future.delayed(Duration.zero);
      await sub.cancel();

      expect(failApi.state, WsConnectionState.disconnected);
      expect(
        logs.any((l) => l.type == HeartbeatLogType.error),
        isTrue,
      );

      failApi.dispose();
    });
  });

  // ─── HeartbeatLog 模型测试 ──────────────────────────────────────────────────
  group('HeartbeatLog', () {
    test('timeLabel 格式为 HH:mm:ss', () {
      final log = HeartbeatLog(
        type: HeartbeatLogType.info,
        message: '测试',
        time: DateTime(2026, 4, 23, 9, 5, 3),
      );
      expect(log.timeLabel, '09:05:03');
    });

    test('未传 time 时自动使用当前时间', () {
      final before = DateTime.now();
      final log = HeartbeatLog(type: HeartbeatLogType.info, message: '');
      final after = DateTime.now();

      expect(log.time.isAfter(before) || log.time.isAtSameMomentAs(before), isTrue);
      expect(log.time.isBefore(after) || log.time.isAtSameMomentAs(after), isTrue);
    });
  });
}
