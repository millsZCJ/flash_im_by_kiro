import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flash_im/src/auth/data/repository/auth_repository.dart';
import 'package:flash_im/src/auth/logic/auth/auth_cubit.dart';
import 'package:flash_im/src/auth/logic/login/strategy/login_strategy.dart';
import 'package:flash_im/src/auth/logic/login/strategy/sms_login_strategy.dart';
import 'package:flash_im/src/auth/logic/login/strategy/password_login_strategy.dart';
import 'package:flash_im/src/auth/view/login_page.dart';

/// 登录模式枚举
enum LoginMode { sms, password }

/// LoginMixin — 登录页共享状态 + 登录调度
mixin LoginMixin on State<LoginPage> {
  late final SmsLoginStrategy smsStrategy;
  late final PasswordLoginStrategy passwordStrategy;
  LoginMode mode = LoginMode.sms;
  bool agreed = false;
  bool isLoading = false;
  String? errorMessage;

  LoginStrategy get currentStrategy =>
      mode == LoginMode.sms ? smsStrategy : passwordStrategy;

  bool get canLogin => agreed && !isLoading && currentStrategy.isValid;

  void toggleMode() {
    setState(() {
      mode = mode == LoginMode.sms ? LoginMode.password : LoginMode.sms;
      errorMessage = null;
    });
  }

  Future<void> doLogin(AuthRepository repo) async {
    if (!canLogin) return;
    setState(() { isLoading = true; errorMessage = null; });

    try {
      final phone = mode == LoginMode.sms
          ? smsStrategy.phone
          : passwordStrategy.account;
      final credential = mode == LoginMode.sms
          ? smsStrategy.code
          : passwordStrategy.password;
      final type = mode == LoginMode.sms ? 'sms' : 'password';

      final (:loginResult, :user) = await repo.login(phone, credential, type);

      if (!mounted) return;

      context.read<AuthCubit>().login(loginResult, user);
      context.go('/home');
    } catch (e) {
      if (mounted) {
        setState(() { errorMessage = '登录失败：$e'; isLoading = false; });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    smsStrategy = SmsLoginStrategy();
    passwordStrategy = PasswordLoginStrategy();
  }

  @override
  void dispose() {
    smsStrategy.dispose();
    passwordStrategy.dispose();
    super.dispose();
  }
}
