import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flash_im/src/auth/view/components/labeled_input.dart';
import 'package:flash_im/src/auth/logic/login/strategy/password_login_strategy.dart';

/// 密码登录表单 — 账号 + 密码
class PasswordLoginForm extends StatefulWidget {
  final PasswordLoginStrategy strategy;

  const PasswordLoginForm({super.key, required this.strategy});

  @override
  State<PasswordLoginForm> createState() => _PasswordLoginFormState();
}

class _PasswordLoginFormState extends State<PasswordLoginForm> {
  final _accountFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _accountFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strategy = widget.strategy;

    return Column(
      children: [
        LabeledInput(
          controller: strategy.accountCtrl,
          focusNode: _accountFocus,
          label: '账号',
          hintText: '请输入手机号',
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)],
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _passwordFocus.requestFocus(),
          prefix: const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Text('+86', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF1A1A1A))),
          ),
        ),
        const SizedBox(height: 16),
        LabeledInput(
          controller: strategy.passwordCtrl,
          focusNode: _passwordFocus,
          label: '密码',
          hintText: '请输入密码（至少 6 位）',
          keyboardType: TextInputType.visiblePassword,
          inputFormatters: [LengthLimitingTextInputFormatter(32)],
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) {},
          obscureText: _obscurePassword,
          suffix: GestureDetector(
            onTap: () => setState(() => _obscurePassword = !_obscurePassword),
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 22,
                color: const Color(0xFFAAAAAA),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
