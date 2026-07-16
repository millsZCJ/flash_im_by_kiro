import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flash_core/flash_core.dart';

import 'package:flash_session/src/data/session_repository.dart';
import 'package:flash_session/src/logic/session_state.dart';

/// SessionCubit — 用户资料 + 密码管理状态
class SessionCubit extends Cubit<SessionState> {
  final SessionRepository _sessionRepository;

  SessionCubit({required SessionRepository sessionRepository})
      : _sessionRepository = sessionRepository,
        super(const SessionState.initial());

  /// 初始化：从 AuthCubit 接收初始用户数据
  void init({User? user, bool hasPassword = false}) {
    if (user != null) {
      emit(SessionState.ready(user: user, hasPassword: hasPassword));
    }
  }

  /// 更新用户资料（昵称、签名、头像）
  Future<void> updateProfile({
    String? nickname,
    String? signature,
    String? avatar,
  }) async {
    try {
      final updatedUser = await _sessionRepository.updateProfile(
        nickname: nickname,
        signature: signature,
        avatar: avatar,
      );
      emit(SessionState.ready(
        user: updatedUser,
        hasPassword: state.hasPassword,
      ));
    } catch (e) {
      emit(SessionState.error('更新失败：$e'));
      // 恢复上一个 ready 状态
      if (state.status == SessionStatus.error && state.user != null) {
        emit(SessionState.ready(
          user: state.user,
          hasPassword: state.hasPassword,
        ));
      }
    }
  }

  /// 修改密码（需旧密码）
  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      await _sessionRepository.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
      return true;
    } on DioException catch (e) {
      // 401 = 旧密码错误
      if (e.response?.statusCode == 401) {
        return false;
      }
      throw Exception('修改密码失败：${e.message}');
    } catch (e) {
      throw Exception('修改密码失败：$e');
    }
  }

  /// 设置密码（首次）
  Future<void> setPassword(String newPassword) async {
    await _sessionRepository.setPassword(newPassword);
    emit(SessionState.ready(
      user: state.user,
      hasPassword: true,
    ));
  }

  /// 随机更换默认头像（更改 identicon seed）
  Future<void> randomizeAvatar() async {
    final user = state.user;
    if (user == null) return;
    // 生成新的 identicon seed：当前时间戳 + 随机数
    final newSeed = '${user.userId}_${DateTime.now().millisecondsSinceEpoch}';
    await updateProfile(avatar: 'identicon:$newSeed');
  }
}
