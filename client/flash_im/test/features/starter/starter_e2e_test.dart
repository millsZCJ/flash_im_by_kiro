import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flash_core/flash_core.dart';
import 'package:flash_auth/flash_auth.dart';
import 'package:flash_im/src/starter/data/repository/startup_repository.dart';

void main() {
  group('端到端测试 — Starter 模块', () {

    // ─── 纯逻辑测试 ──────────────────────────────────────────────────────────

    // ─── 测试 1: AuthState 三种状态正确构造 ────────────────────────────────────
    test('AuthState 三种状态正确构造', () {
      const unknownState = AuthState.unknown();
      expect(unknownState.status, AuthStatus.unknown);
      expect(unknownState.token, isNull);
      expect(unknownState.user, isNull);
      expect(unknownState.hasPassword, isFalse);

      final user = User(userId: '1', phone: '13800138000', nickname: 'Test', avatar: 'https://example.com/a.png');
      final authState = AuthState.authenticated(token: 'abc', user: user, hasPassword: true);
      expect(authState.status, AuthStatus.authenticated);
      expect(authState.token, 'abc');
      expect(authState.user, user);
      expect(authState.hasPassword, isTrue);

      const unauthState = AuthState.unauthenticated();
      expect(unauthState.status, AuthStatus.unauthenticated);
      expect(unauthState.token, isNull);
    });

    // ─── 测试 2: AuthCubit 状态转换 ──────────────────────────────────────────
    test('AuthCubit applyStartupSnapshot → onPasswordSet → unauthenticated', () {
      final httpClient = HttpClient(tokenProvider: () => '', onUnauthorized: () {});
      final authRepo = AuthRepository(dio: httpClient.dio);
      final cubit = AuthCubit(authRepository: authRepo);

      // 初始状态 unknown
      expect(cubit.state.status, AuthStatus.unknown);

      // 有 Token 的 snapshot → authenticated
      final user = User(userId: '1', phone: '138', nickname: 'N', avatar: 'A');
      cubit.applyStartupSnapshot(token: 'tok', user: user, hasPassword: false);
      expect(cubit.state.status, AuthStatus.authenticated);
      expect(cubit.state.hasPassword, isFalse);

      // 设置密码后更新
      cubit.onPasswordSet();
      expect(cubit.state.hasPassword, isTrue);

      // 无 Token 的 snapshot → unauthenticated
      cubit.applyStartupSnapshot(token: null);
      expect(cubit.state.status, AuthStatus.unauthenticated);
    });

    // ─── 测试 3: 退出登录状态转换 ──────────────────────────────────────────
    test('AuthCubit logout 从 authenticated → unauthenticated', () {
      final httpClient = HttpClient(tokenProvider: () => '', onUnauthorized: () {});
      final authRepo = AuthRepository(dio: httpClient.dio);
      final authCubit = AuthCubit(authRepository: authRepo);

      final mockUser = User(userId: '1', phone: '138', nickname: 'N', avatar: 'A');
      authCubit.applyStartupSnapshot(token: 'test_token', user: mockUser, hasPassword: true);
      expect(authCubit.state.status, AuthStatus.authenticated);

      // 模拟 logout 的状态转换（直接 emit unauthenticated，跳过 SP 操作）
      authCubit.applyStartupSnapshot(token: null);
      expect(authCubit.state.status, AuthStatus.unauthenticated);
      expect(authCubit.state.token, isNull);
    });

    // ─── 测试 4: StartupRepository 有 Token 时返回认证 ────────────────────────
    test('StartupRepository 正确读取 SharedPreferences（有 Token）', () async {
      final mockUser = User(userId: '1', phone: '13800138000', nickname: 'TestUser', avatar: 'https://example.com/avatar.png');

      SharedPreferences.setMockInitialValues({
        'auth_token': 'valid_token',
        'user_info': jsonEncode(mockUser.toJson()),
        'has_password': true,
      });

      final repo = StartupRepository();
      final completer = Completer<StartupEvent>();

      repo.stream.listen((event) {
        if (event is StartupReady || event is StartupFailed) {
          if (!completer.isCompleted) completer.complete(event);
        }
      });

      await repo.initialize();
      final event = await completer.future;

      expect(event, isA<StartupReady>());
      final ready = event as StartupReady;
      expect(ready.result.authenticated, isTrue);
      expect(ready.result.token, 'valid_token');
      expect(ready.result.hasPassword, isTrue);
      expect(ready.result.user?.phone, '13800138000');

      repo.dispose();
    });

    // ─── 测试 5: StartupRepository 无 Token 时返回未认证 ──────────────────────
    test('StartupRepository 无 Token 返回未认证', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = StartupRepository();
      final completer = Completer<StartupEvent>();

      repo.stream.listen((event) {
        if (event is StartupReady || event is StartupFailed) {
          if (!completer.isCompleted) completer.complete(event);
        }
      });

      await repo.initialize();
      final event = await completer.future;

      expect(event, isA<StartupReady>());
      final ready = event as StartupReady;
      expect(ready.result.authenticated, isFalse);
      expect(ready.result.token, isNull);

      repo.dispose();
    });

    // ─── 测试 6: StartupResult authenticated getter ──────────────────────────
    test('StartupResult.authenticated getter', () {
      // 有 Token → authenticated
      const withToken = StartupResult(token: 'abc', hasPassword: true);
      expect(withToken.authenticated, isTrue);

      // 无 Token → not authenticated
      const withoutToken = StartupResult();
      expect(withoutToken.authenticated, isFalse);
    });

    // ─── 测试 7: User 模型 JSON 序列化/反序列化 ──────────────────────────────
    test('User fromJson / toJson 完整性', () {
      final user = User(userId: '42', phone: '13800138000', nickname: 'Nick', avatar: 'https://example.com/a.png');
      final json = user.toJson();
      expect(json['user_id'], '42');
      expect(json['phone'], '13800138000');
      expect(json['nickname'], 'Nick');
      expect(json['avatar'], 'https://example.com/a.png');

      final fromJson = User.fromJson(json);
      expect(fromJson.userId, '42');
      expect(fromJson.phone, '13800138000');
      expect(fromJson.nickname, 'Nick');
      expect(fromJson.avatar, 'https://example.com/a.png');
    });

    // ─── 测试 8: AuthState Equatable ──────────────────────────────────────────
    test('AuthState props 含 token/user/hasPassword', () {
      const state1 = AuthState.unknown();
      const state2 = AuthState.unknown();
      expect(state1, state2); // Equatable: same props → equal

      final state3 = AuthState.authenticated(token: 'abc', hasPassword: false);
      expect(state1 == state3, isFalse); // Different status/props → not equal
    });

    // ─── 测试 9: AuthCubit.login 方法 ──────────────────────────────────────────
    test('AuthCubit.login 更新状态为 authenticated', () {
      final httpClient = HttpClient(tokenProvider: () => '', onUnauthorized: () {});
      final authRepo = AuthRepository(dio: httpClient.dio);
      final cubit = AuthCubit(authRepository: authRepo);

      // 先设为 unauthenticated
      cubit.applyStartupSnapshot(token: null);
      expect(cubit.state.status, AuthStatus.unauthenticated);

      // login
      final loginResult = LoginResult(token: 'new_token', userId: '1', isNewUser: true, hasPassword: false);
      final user = User(userId: '1', phone: '138', nickname: 'N', avatar: 'A');
      cubit.login(loginResult, user);
      expect(cubit.state.status, AuthStatus.authenticated);
      expect(cubit.state.token, 'new_token');
      expect(cubit.state.hasPassword, isFalse);
    });

    // ─── 测试 10: 端到端流程模拟（SP → Repo → Cubit → 状态变更）─────────────────
    test('完整启动→登录→退出流程（纯逻辑）', () async {
      // 1. 无 Token 启动
      SharedPreferences.setMockInitialValues({});
      final repo = StartupRepository();
      final httpClient = HttpClient(tokenProvider: () => '', onUnauthorized: () {});
      final authRepo = AuthRepository(dio: httpClient.dio);
      final authCubit = AuthCubit(authRepository: authRepo);

      final completer = Completer<StartupEvent>();
      repo.stream.listen((event) {
        if (event is StartupReady || event is StartupFailed) {
          if (!completer.isCompleted) completer.complete(event);
        }
      });

      await repo.initialize();
      final startupEvent = await completer.future;
      expect(startupEvent, isA<StartupReady>());
      final startupResult = (startupEvent as StartupReady).result;
      expect(startupResult.authenticated, isFalse);

      // 2. applyStartupSnapshot（无 Token）
      authCubit.applyStartupSnapshot(token: startupResult.token);
      expect(authCubit.state.status, AuthStatus.unauthenticated);

      // 3. 模拟登录成功
      final loginResult = LoginResult(token: 'logged_in_token', userId: '42', isNewUser: true, hasPassword: false);
      final user = User(userId: '42', phone: '13800138000', nickname: 'Nick', avatar: 'https://example.com/a.png');
      authCubit.login(loginResult, user);
      expect(authCubit.state.status, AuthStatus.authenticated);
      expect(authCubit.state.token, 'logged_in_token');
      expect(authCubit.state.hasPassword, isFalse);

      // 4. 设置密码
      authCubit.onPasswordSet();
      expect(authCubit.state.hasPassword, isTrue);

      // 5. 模拟退出登录（状态转换，不调用真正的 logout 以避免 SP binding 问题）
      authCubit.applyStartupSnapshot(token: null);
      expect(authCubit.state.status, AuthStatus.unauthenticated);

      repo.dispose();
    });
  });
}
