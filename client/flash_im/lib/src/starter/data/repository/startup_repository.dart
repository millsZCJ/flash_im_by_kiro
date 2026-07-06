import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flash_core/flash_core.dart';

// ─── 启动事件 ─────────────────────────────────────────────────────────────────

sealed class StartupEvent {}

class StartupLoading extends StartupEvent {}

class StartupReady extends StartupEvent {
  final StartupResult result;
  StartupReady(this.result);
}

class StartupFailed extends StartupEvent {
  final String message;
  StartupFailed(this.message);
}

// ─── 启动结果 ─────────────────────────────────────────────────────────────────

class StartupResult {
  final String? token;
  final User? user;
  final bool hasPassword;

  const StartupResult({this.token, this.user, this.hasPassword = false});

  bool get authenticated => token != null;
}

// ─── 启动仓库 ─────────────────────────────────────────────────────────────────

/// 从 SharedPreferences 读取缓存 → Stream 事件流暴露
class StartupRepository {
  final _controller = StreamController<StartupEvent>.broadcast();

  Stream<StartupEvent> get stream => _controller.stream;
  void dispose() => _controller.close();

  /// 初始化：从本地缓存读取认证数据
  Future<void> initialize() async {
    _controller.add(StartupLoading());

    try {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString('auth_token');

      if (token == null) {
        _controller.add(StartupReady(const StartupResult()));
        return;
      }

      final userJson = prefs.getString('user_info');
      final user = userJson != null
          ? User.fromJson(jsonDecode(userJson) as Map<String, dynamic>)
          : null;

      final hasPassword = prefs.getBool('has_password') ?? false;

      _controller.add(StartupReady(StartupResult(
        token: token,
        user: user,
        hasPassword: hasPassword,
      )));
    } catch (e) {
      _controller.add(StartupFailed(e.toString()));
    }
  }
}
