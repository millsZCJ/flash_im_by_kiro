import 'dart:async';
import 'package:flutter/material.dart';

import 'package:flash_auth/src/logic/login/strategy/login_strategy.dart';
import 'package:flash_auth/src/data/repository/auth_repository.dart';

/// 短信验证码登录策略
class SmsLoginStrategy extends LoginStrategy {
  final phoneCtrl = TextEditingController();
  final codeCtrl = TextEditingController();
  int countdown = 0;
  bool sendingCode = false;
  Timer? _timer;

  String get phone => phoneCtrl.text.trim();
  String get code => codeCtrl.text.trim();

  bool get isPhoneValid => phone.length == 11 && phone.startsWith('1');
  bool get isCodeValid => code.length == 6;
  @override
  bool get isValid => isPhoneValid && isCodeValid;
  bool get canSendSms => isPhoneValid && countdown <= 0 && !sendingCode;

  /// 发送验证码
  Future<String> sendSms(AuthRepository repo) async {
    sendingCode = true;
    try {
      final code = await repo.sendSms(phone);
      return code;
    } finally {
      sendingCode = false;
    }
  }

  /// 开始 60 秒倒计时
  void startCountdown() {
    countdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      countdown--;
      if (countdown <= 0) t.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    phoneCtrl.dispose();
    codeCtrl.dispose();
  }
}
