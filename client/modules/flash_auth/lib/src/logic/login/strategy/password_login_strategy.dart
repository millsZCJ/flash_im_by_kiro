import 'package:flutter/material.dart';

import 'package:flash_auth/src/logic/login/strategy/login_strategy.dart';

/// 密码登录策略
class PasswordLoginStrategy extends LoginStrategy {
  final accountCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();

  String get account => accountCtrl.text.trim();
  String get password => passwordCtrl.text.trim();

  @override
  bool get isValid => account.isNotEmpty && password.length >= 6;

  @override
  void dispose() {
    accountCtrl.dispose();
    passwordCtrl.dispose();
  }
}
