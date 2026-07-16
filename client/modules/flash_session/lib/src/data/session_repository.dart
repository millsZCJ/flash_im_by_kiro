import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flash_core/flash_core.dart';

/// 会话仓库 — 用户资料 + 密码管理 API + 本地缓存
class SessionRepository {
  final Dio _dio;

  SessionRepository({required Dio dio}) : _dio = dio;

  // ─── 本地缓存 Key ──────────────────────────────────────────────────────────

  static const _keyUserInfo = 'user_info';
  static const _keyHasPassword = 'has_password';

  // ─── 本地缓存 ──────────────────────────────────────────────────────────────

  Future<void> cacheUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserInfo, jsonEncode(user.toJson()));
  }

  Future<void> cacheHasPassword(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHasPassword, value);
  }

  // ─── API 方法 ──────────────────────────────────────────────────────────────

  /// 更新用户资料（字段可选，只传需要修改的）
  Future<User> updateProfile({
    String? nickname,
    String? avatar,
    String? signature,
  }) async {
    final data = <String, dynamic>{
      if (nickname != null) 'nickname': nickname,
      if (avatar != null) 'avatar': avatar,
      if (signature != null) 'signature': signature,
    };
    final resp = await _dio.put('/user/profile', data: data);
    final user = User.fromJson(resp.data as Map<String, dynamic>);
    await cacheUser(user);
    return user;
  }

  /// 设置密码（首次）
  Future<void> setPassword(String newPassword) async {
    await _dio.post('/user/password', data: {'new_password': newPassword});
    await cacheHasPassword(true);
  }

  /// 修改密码（需旧密码）
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    await _dio.put('/user/password', data: {
      'old_password': oldPassword,
      'new_password': newPassword,
    });
  }
}
