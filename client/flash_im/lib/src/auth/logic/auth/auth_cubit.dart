import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flash_im/src/auth/data/repository/auth_repository.dart';
import 'package:flash_im/src/auth/data/model/login_result.dart';
import 'package:flash_im/src/domain/model/user.dart';
import 'package:flash_im/src/auth/logic/auth/auth_state.dart';

/// AuthCubit — 全局认证状态管理，生命周期与 App 一致
class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;

  AuthCubit({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthState.unknown());

  /// 启动时从 SP 恢复认证状态
  void applyStartupSnapshot({
    required String? token,
    User? user,
    bool hasPassword = false,
  }) {
    if (token != null && user != null) {
      emit(AuthState.authenticated(
        token: token,
        user: user,
        hasPassword: hasPassword,
      ));
    } else {
      emit(const AuthState.unauthenticated());
    }
  }

  /// 登录成功后调用
  void login(LoginResult loginResult, User user) {
    emit(AuthState.authenticated(
      token: loginResult.token,
      user: user,
      hasPassword: loginResult.hasPassword,
    ));
  }

  /// 退出登录
  Future<void> logout() async {
    await _authRepository.logout();
    emit(const AuthState.unauthenticated());
  }

  /// 设置密码成功后更新 hasPassword
  void onPasswordSet() {
    if (state.status == AuthStatus.authenticated) {
      emit(AuthState.authenticated(
        token: state.token!,
        user: state.user,
        hasPassword: true,
      ));
    }
  }
}
