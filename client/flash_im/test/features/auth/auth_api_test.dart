import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flash_im/features/auth/api/auth_api.dart';
import 'package:flash_im/features/auth/model/auth_model.dart';

// ─── Mock HTTP Adapter ────────────────────────────────────────────────────────
//
// 拦截 Dio 的底层请求，按 path + method 返回预设响应，无需真实网络。

typedef _Handler = Map<String, dynamic> Function(RequestOptions);

class _MockAdapter implements HttpClientAdapter {
  final Map<String, _Handler> _routes = {};

  /// 注册路由：'METHOD /path' → handler
  void on(String method, String path, _Handler handler) {
    _routes['${method.toUpperCase()} $path'] = handler;
  }

  /// 注册固定响应（不需要检查请求内容时使用）
  void onFixed(String method, String path, Map<String, dynamic> body,
      {int statusCode = 200}) {
    on(method, path, (_) => body);
    _statusCodes['${method.toUpperCase()} $path'] = statusCode;
  }

  final Map<String, int> _statusCodes = {};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final key = '${options.method.toUpperCase()} ${options.path}';
    final handler = _routes[key];

    if (handler == null) {
      throw DioException(
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: 404,
          statusMessage: 'Not Found: $key',
        ),
        type: DioExceptionType.badResponse,
      );
    }

    final statusCode = _statusCodes[key] ?? 200;
    final body = handler(options);

    if (statusCode >= 400) {
      throw DioException(
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: statusCode,
          data: body,
        ),
        type: DioExceptionType.badResponse,
      );
    }

    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

// ─── 工厂函数 ─────────────────────────────────────────────────────────────────

AuthApi _makeApi(_MockAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
  dio.httpClientAdapter = adapter;
  return AuthApi(dio: dio);
}

// ─── 测试 ─────────────────────────────────────────────────────────────────────

void main() {
  // ── sendSms ────────────────────────────────────────────────────────────────
  group('AuthApi.sendSms', () {
    test('成功返回验证码字符串', () async {
      final adapter = _MockAdapter();
      adapter.onFixed('POST', '/auth/sms', {
        'code': '123456',
        'message': '验证码已发送',
      });
      final api = _makeApi(adapter);

      final code = await api.sendSms('13800138000');

      expect(code, '123456');
    });

    test('服务器错误时抛出 DioException', () async {
      final adapter = _MockAdapter();
      adapter.onFixed('POST', '/auth/sms', {'error': 'server error'},
          statusCode: 500);
      final api = _makeApi(adapter);

      expect(
        () => api.sendSms('13800138000'),
        throwsA(isA<DioException>()),
      );
    });
  });

  // ── login ──────────────────────────────────────────────────────────────────
  group('AuthApi.login', () {
    const mockToken = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.mock.signature';
    const mockUserId = '9c5e836d-0f18-4bf7-9911-fa6df837fc71';

    test('登录成功返回 LoginResult', () async {
      final adapter = _MockAdapter();
      adapter.onFixed('POST', '/auth/login', {
        'token': mockToken,
        'user_id': mockUserId,
        'is_new_user': true,
      });
      final api = _makeApi(adapter);

      final result = await api.login('13800138000', '123456');

      expect(result.token, mockToken);
      expect(result.userId, mockUserId);
      expect(result.isNewUser, true);
    });

    test('登录成功后 token 保存到内存', () async {
      final adapter = _MockAdapter();
      adapter.onFixed('POST', '/auth/login', {
        'token': mockToken,
        'user_id': mockUserId,
        'is_new_user': false,
      });
      final api = _makeApi(adapter);

      expect(api.token, isNull);
      expect(api.isLoggedIn, false);

      await api.login('13800138000', '123456');

      expect(api.token, mockToken);
      expect(api.isLoggedIn, true);
    });

    test('验证码错误时抛出 DioException（401）', () async {
      final adapter = _MockAdapter();
      adapter.onFixed('POST', '/auth/login', {'error': 'unauthorized'},
          statusCode: 401);
      final api = _makeApi(adapter);

      expect(
        () => api.login('13800138000', '000000'),
        throwsA(isA<DioException>()),
      );
    });

    test('登录失败后 token 不被设置', () async {
      final adapter = _MockAdapter();
      adapter.onFixed('POST', '/auth/login', {'error': 'unauthorized'},
          statusCode: 401);
      final api = _makeApi(adapter);

      try {
        await api.login('13800138000', '000000');
      } catch (_) {}

      expect(api.token, isNull);
      expect(api.isLoggedIn, false);
    });

    test('老用户登录 is_new_user 为 false', () async {
      final adapter = _MockAdapter();
      adapter.onFixed('POST', '/auth/login', {
        'token': mockToken,
        'user_id': mockUserId,
        'is_new_user': false,
      });
      final api = _makeApi(adapter);

      final result = await api.login('13800138000', '123456');

      expect(result.isNewUser, false);
    });
  });

  // ── getProfile ─────────────────────────────────────────────────────────────
  group('AuthApi.getProfile', () {
    const mockToken = 'valid.jwt.token';
    const mockProfile = {
      'user_id': 'user-001',
      'phone': '13800138000',
      'nickname': '13800138000',
      'avatar': 'https://api.dicebear.com/7.x/thumbs/svg?seed=user-001',
    };

    Future<AuthApi> _loggedInApi() async {
      final adapter = _MockAdapter();
      adapter.onFixed('POST', '/auth/login', {
        'token': mockToken,
        'user_id': 'user-001',
        'is_new_user': false,
      });
      adapter.onFixed('GET', '/user/profile', mockProfile);
      final api = _makeApi(adapter);
      await api.login('13800138000', '123456');
      return api;
    }

    test('登录后获取用户信息成功', () async {
      final api = await _loggedInApi();
      final profile = await api.getProfile();

      expect(profile.userId, 'user-001');
      expect(profile.phone, '13800138000');
      expect(profile.nickname, '13800138000');
      expect(profile.avatar, contains('dicebear'));
    });

    test('未登录时 getProfile 抛出 Exception', () async {
      final adapter = _MockAdapter();
      final api = _makeApi(adapter);

      expect(
        () => api.getProfile(),
        throwsA(isA<Exception>()),
      );
    });

    test('getProfile 请求携带 Authorization header', () async {
      final adapter = _MockAdapter();
      adapter.onFixed('POST', '/auth/login', {
        'token': mockToken,
        'user_id': 'user-001',
        'is_new_user': false,
      });

      // 验证 header 中包含正确的 token
      adapter.on('GET', '/user/profile', (options) {
        final auth = options.headers['Authorization'] as String?;
        expect(auth, 'Bearer $mockToken');
        return mockProfile;
      });

      final api = _makeApi(adapter);
      await api.login('13800138000', '123456');
      await api.getProfile();
    });

    test('Token 无效时服务器返回 401，抛出 DioException', () async {
      final adapter = _MockAdapter();
      adapter.onFixed('POST', '/auth/login', {
        'token': 'expired.token',
        'user_id': 'user-001',
        'is_new_user': false,
      });
      adapter.onFixed('GET', '/user/profile', {'error': 'unauthorized'},
          statusCode: 401);
      final api = _makeApi(adapter);
      await api.login('13800138000', '123456');

      expect(
        () => api.getProfile(),
        throwsA(isA<DioException>()),
      );
    });
  });

  // ── logout ─────────────────────────────────────────────────────────────────
  group('AuthApi.logout', () {
    test('logout 后 token 清除', () async {
      final adapter = _MockAdapter();
      adapter.onFixed('POST', '/auth/login', {
        'token': 'some.token',
        'user_id': 'user-001',
        'is_new_user': false,
      });
      final api = _makeApi(adapter);
      await api.login('13800138000', '123456');

      expect(api.isLoggedIn, true);

      api.logout();

      expect(api.token, isNull);
      expect(api.isLoggedIn, false);
    });

    test('logout 后 getProfile 抛出 Exception', () async {
      final adapter = _MockAdapter();
      adapter.onFixed('POST', '/auth/login', {
        'token': 'some.token',
        'user_id': 'user-001',
        'is_new_user': false,
      });
      final api = _makeApi(adapter);
      await api.login('13800138000', '123456');
      api.logout();

      expect(
        () => api.getProfile(),
        throwsA(isA<Exception>()),
      );
    });

    test('未登录时 logout 不抛出异常', () {
      final adapter = _MockAdapter();
      final api = _makeApi(adapter);

      expect(() => api.logout(), returnsNormally);
    });

    test('多次 logout 不抛出异常', () async {
      final adapter = _MockAdapter();
      adapter.onFixed('POST', '/auth/login', {
        'token': 'some.token',
        'user_id': 'user-001',
        'is_new_user': false,
      });
      final api = _makeApi(adapter);
      await api.login('13800138000', '123456');

      api.logout();
      api.logout(); // 第二次不应抛出

      expect(api.isLoggedIn, false);
    });
  });

  // ── 完整登录流程 ────────────────────────────────────────────────────────────
  group('AuthApi 完整流程', () {
    test('sendSms → login → getProfile → logout 全流程', () async {
      const token = 'full.flow.token';
      final adapter = _MockAdapter();
      adapter.onFixed('POST', '/auth/sms', {'code': '888888', 'message': 'ok'});
      adapter.onFixed('POST', '/auth/login', {
        'token': token,
        'user_id': 'user-full',
        'is_new_user': true,
      });
      adapter.onFixed('GET', '/user/profile', {
        'user_id': 'user-full',
        'phone': '13900139000',
        'nickname': '13900139000',
        'avatar': 'https://example.com/avatar.svg',
      });

      final api = _makeApi(adapter);

      // 1. 发送验证码
      final code = await api.sendSms('13900139000');
      expect(code, '888888');

      // 2. 登录
      final result = await api.login('13900139000', code);
      expect(result.isNewUser, true);
      expect(api.isLoggedIn, true);

      // 3. 获取用户信息
      final profile = await api.getProfile();
      expect(profile.phone, '13900139000');

      // 4. 退出
      api.logout();
      expect(api.isLoggedIn, false);
    });
  });
}
