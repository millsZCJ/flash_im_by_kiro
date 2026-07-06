import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flash_im/src/auth/view/components/labeled_input.dart';
import 'package:flash_im/src/auth/logic/login/strategy/sms_login_strategy.dart';
import 'package:flash_im/src/auth/data/repository/auth_repository.dart';

/// 验证码登录表单 — 手机号 + 验证码 + 60秒倒计时
class SmsLoginForm extends StatefulWidget {
  final SmsLoginStrategy strategy;
  final AuthRepository authRepository;
  final ValueChanged<String> onCodeReceived;

  const SmsLoginForm({
    super.key,
    required this.strategy,
    required this.authRepository,
    required this.onCodeReceived,
  });

  @override
  State<SmsLoginForm> createState() => _SmsLoginFormState();
}

class _SmsLoginFormState extends State<SmsLoginForm> {
  final _phoneFocus = FocusNode();
  final _codeFocus = FocusNode();

  @override
  void dispose() {
    _phoneFocus.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!widget.strategy.canSendSms) return;

    setState(() => widget.strategy.sendingCode = true);

    try {
      final code = await widget.strategy.sendSms(widget.authRepository);
      widget.strategy.startCountdown();

      // 自动填入验证码（playground 特性，生产环境改为 toast 提示）
      widget.strategy.codeCtrl.text = code;
      widget.onCodeReceived(code);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('验证码已发送（已自动填入：$code）'),
          backgroundColor: const Color(0xFF07C160),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('发送失败：$e'),
          backgroundColor: const Color(0xFFE53935),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
        ));
      }
    } finally {
      if (mounted) setState(() => widget.strategy.sendingCode = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strategy = widget.strategy;
    final canSend = strategy.canSendSms;
    final label = strategy.countdown > 0
        ? '${strategy.countdown}s'
        : strategy.sendingCode
            ? '发送中'
            : '获取验证码';

    return Column(
      children: [
        LabeledInput(
          controller: strategy.phoneCtrl,
          focusNode: _phoneFocus,
          label: '手机号',
          hintText: '请输入手机号',
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)],
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _codeFocus.requestFocus(),
          prefix: const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Text('+86', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF1A1A1A))),
          ),
        ),
        const SizedBox(height: 16),
        LabeledInput(
          controller: strategy.codeCtrl,
          focusNode: _codeFocus,
          label: '验证码',
          hintText: '请输入 6 位验证码',
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) {},
          suffix: _buildSendButton(canSend, label),
        ),
      ],
    );
  }

  Widget _buildSendButton(bool canSend, String label) {
    return GestureDetector(
      onTap: canSend ? _sendCode : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: canSend ? const Color(0xFF07C160) : const Color(0xFFEEEEEE),
          borderRadius: BorderRadius.circular(6),
        ),
        child: widget.strategy.sendingCode
            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
            : Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: canSend ? Colors.white : const Color(0xFFAAAAAA))),
      ),
    );
  }
}
