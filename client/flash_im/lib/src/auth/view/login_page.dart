import 'package:flutter/material.dart';

import 'package:flash_im/src/auth/logic/login/login_mixin.dart';
import 'package:flash_im/src/auth/data/repository/auth_repository.dart';
import 'package:flash_im/src/auth/view/components/action_button.dart';
import 'package:flash_im/src/auth/view/components/agreement_row.dart';
import 'package:flash_im/src/auth/view/components/sms_login_form.dart';
import 'package:flash_im/src/auth/view/components/password_login_form.dart';

/// 登录页 — 支持验证码/密码切换，通过 LoginMixin 管理状态
class LoginPage extends StatefulWidget {
  final AuthRepository authRepository;

  const LoginPage({super.key, required this.authRepository});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with LoginMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 72),
              _buildHeader(),
              const SizedBox(height: 56),
              _buildForm(),
              const SizedBox(height: 24),
              AgreementRow(agreed: agreed, onChanged: (v) => setState(() => agreed = v)),
              const SizedBox(height: 24),
              ActionButton(
                label: '登录 / 注册',
                enabled: canLogin,
                loading: isLoading,
                onPressed: canLogin ? () => doLogin(widget.authRepository) : null,
              ),
              const SizedBox(height: 24),
              _buildModeSwitch(),
              if (errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(errorMessage!, style: const TextStyle(fontSize: 14, color: Color(0xFFE53935))),
              ],
              const SizedBox(height: 24),
              _buildPlaygroundHint(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF07C160),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 24),
        const Text('欢迎回来', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A), letterSpacing: -0.5)),
        const SizedBox(height: 8),
        const Text('手机号验证码登录，安全快捷', style: TextStyle(fontSize: 15, color: Color(0xFF888888))),
      ],
    );
  }

  Widget _buildForm() {
    if (mode == LoginMode.sms) {
      return SmsLoginForm(
        strategy: smsStrategy,
        authRepository: widget.authRepository,
        onCodeReceived: (_) {},
      );
    } else {
      return PasswordLoginForm(strategy: passwordStrategy);
    }
  }

  Widget _buildModeSwitch() {
    final isSms = mode == LoginMode.sms;
    return Center(
      child: GestureDetector(
        onTap: toggleMode,
        child: Text(
          isSms ? '使用密码登录 →' : '使用验证码登录 →',
          style: const TextStyle(fontSize: 14, color: Color(0xFF07C160), fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildPlaygroundHint() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFE082)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: Color(0xFFE6A817)),
          SizedBox(width: 8),
          Expanded(child: Text('Playground 模式：验证码将自动填入输入框', style: TextStyle(fontSize: 12, color: Color(0xFF8A6914)))),
        ],
      ),
    );
  }
}
