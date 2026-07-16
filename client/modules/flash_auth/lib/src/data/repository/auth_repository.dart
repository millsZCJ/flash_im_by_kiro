import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flash_core/flash_core.dart';

import 'package:flash_auth/src/data/model/login_result.dart';

/// 认证仓库 — API 调用 + Token/用户信息 持久化到 SharedPreferences
class AuthRepository {
  final Dio _dio;
  String? _token;

  String? get token => _token;

  AuthRepository({required Dio dio}) : _dio = dio;

  // ─── 本地缓存 Key ──────────────────────────────────────────────────────────

  static const _keyToken = 'auth_token';
  static const _keyUserInfo = 'user_info';
  static const _keyHasPassword = 'has_password';

  // ─── Token 管理 ────────────────────────────────────────────────────────────

  Future<void> _saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
  }

  Future<void> _cacheUserInfo(User user, bool hasPassword) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserInfo, jsonEncode(user.toJson()));
    await prefs.setBool(_keyHasPassword, hasPassword);
  }

  Future<void> _clearAll() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUserInfo);
    await prefs.remove(_keyHasPassword);
  }

  // ─── API 方法 ──────────────────────────────────────────────────────────────

  /// 发送验证码
  Future<String> sendSms(String phone) async {
    final resp = await _dio.post('/auth/sms', data: {'phone': phone});
    return resp.data['code'] as String;
  }

  /// 登录（验证码或密码）→ 返回 (LoginResult, User)
  Future<({LoginResult loginResult, User user})> login(
    String phone,
    String credential,
    String type,
  ) async {
    // 1. POST /auth/login
    final resp = await _dio.post('/auth/login', data: {
      'login_type': type,
      'phone': phone,
      if (type == 'sms') 'code': credential,
      if (type == 'password') 'password': credential,
    });
    final loginResult = LoginResult.fromJson(resp.data as Map<String, dynamic>);

    // 2. 保存 Token
    await _saveToken(loginResult.token);

    // 3. GET /user/profile
    final profileResp = await _dio.get(
      '/user/profile',
      options: Options(headers: {'Authorization': 'Bearer ${loginResult.token}'}),
    );
    final user = User.fromJson(profileResp.data as Map<String, dynamic>);

    // 4. 缓存用户信息
    await _cacheUserInfo(user, loginResult.hasPassword);

    return (loginResult: loginResult, user: user);
  }

  /// 设置密码（路径已迁移到 /user/password）
  Future<void> setPassword(String newPassword) async {
    await _dio.post(
      '/user/password',
      data: {'new_password': newPassword},
    );
    // 更新本地 hasPassword 标记
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHasPassword, true);
  }

  /// 退出登录
  Future<void> logout() async {
    await _clearAll();
  }
}
