import 'package:dio/dio.dart';
import '../../../core/network/app_config.dart';
import '../model/auth_model.dart';

/// 认证 API
///
/// Token 存储在内存中（playground 阶段）。
/// [dio] 可在测试中注入 mock，生产代码使用默认值。
class AuthApi {
  final Dio _dio;

  /// 当前登录 Token（内存存储）
  String? _token;
  String? get token => _token;
  bool get isLoggedIn => _token != null;

  AuthApi({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: AppConfig.baseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ));

  // ── POST /auth/sms ──────────────────────────────────────────────────────────

  /// 发送验证码，返回验证码（playground 模式直接返回）
  Future<String> sendSms(String phone) async {
    final resp = await _dio.post('/auth/sms', data: {'phone': phone});
    return resp.data['code'] as String;
  }

  // ── POST /auth/login ────────────────────────────────────────────────────────

  /// 短信验证码登录，成功后自动保存 Token
  Future<LoginResult> login(String phone, String code) async {
    final resp = await _dio.post('/auth/login', data: {
      'login_type': LoginType.sms.value,
      'phone': phone,
      'code': code,
    });
    final result = LoginResult.fromJson(resp.data as Map<String, dynamic>);
    _token = result.token;
    return result;
  }

  /// 密码登录，成功后自动保存 Token
  Future<LoginResult> loginWithPassword(String phone, String password) async {
    final resp = await _dio.post('/auth/login', data: {
      'login_type': LoginType.password.value,
      'phone': phone,
      'password': password,
    });
    final result = LoginResult.fromJson(resp.data as Map<String, dynamic>);
    _token = result.token;
    return result;
  }

  // ── GET /user/profile ───────────────────────────────────────────────────────

  /// 获取当前登录用户信息，自动携带 Token
  Future<UserProfile> getProfile() async {
    if (_token == null) throw Exception('未登录');
    final resp = await _dio.get(
      '/user/profile',
      options: Options(headers: {'Authorization': 'Bearer $_token'}),
    );
    return UserProfile.fromJson(resp.data as Map<String, dynamic>);
  }

  // ── 退出登录 ────────────────────────────────────────────────────────────────

  void logout() {
    _token = null;
  }
}
