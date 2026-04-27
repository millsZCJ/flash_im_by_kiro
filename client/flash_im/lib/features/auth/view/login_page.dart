import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api/auth_api.dart';
import 'profile_page.dart';

class LoginPage extends StatefulWidget {
  final AuthApi api;
  const LoginPage({super.key, required this.api});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phoneCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _phoneFocus = FocusNode();
  final _codeFocus = FocusNode();

  bool _sendingCode = false;
  bool _loggingIn = false;
  int _countdown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    _phoneFocus.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  bool get _phoneValid => _phoneCtrl.text.trim().length == 11;
  bool get _codeValid => _codeCtrl.text.trim().length == 6;
  bool get _canSend => _phoneValid && _countdown == 0 && !_sendingCode;
  bool get _canLogin => _phoneValid && _codeValid && !_loggingIn;

  // ── 发送验证码 ──────────────────────────────────────────────────────────────

  Future<void> _sendCode() async {
    if (!_canSend) return;
    setState(() => _sendingCode = true);

    try {
      final code = await widget.api.sendSms(_phoneCtrl.text.trim());

      // playground：自动填入验证码
      _codeCtrl.text = code;
      _codeFocus.requestFocus();

      _startCountdown();
      if (mounted) {
        _showSnack('验证码已发送（已自动填入：$code）', isError: false);
      }
    } on Exception catch (e) {
      if (mounted) _showSnack('发送失败：$e');
    } finally {
      if (mounted) setState(() => _sendingCode = false);
    }
  }

  void _startCountdown() {
    setState(() => _countdown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _countdown--;
        if (_countdown <= 0) t.cancel();
      });
    });
  }

  // ── 登录 ────────────────────────────────────────────────────────────────────

  Future<void> _login() async {
    if (!_canLogin) return;
    setState(() => _loggingIn = true);

    try {
      final result = await widget.api.login(
        _phoneCtrl.text.trim(),
        _codeCtrl.text.trim(),
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => ProfilePage(
            api: widget.api,
            isNewUser: result.isNewUser,
          ),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    } on Exception {
      if (mounted) _showSnack('验证码错误或已过期，请重新获取');
    } finally {
      if (mounted) setState(() => _loggingIn = false);
    }
  }

  void _showSnack(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? const Color(0xFFE53935) : const Color(0xFF07C160),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    ));
  }

  // ── UI ──────────────────────────────────────────────────────────────────────

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
              _buildPhoneField(),
              const SizedBox(height: 16),
              _buildCodeField(),
              const SizedBox(height: 32),
              _buildLoginButton(),
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
        const Text(
          '欢迎回来',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '手机号验证码登录，安全快捷',
          style: TextStyle(fontSize: 15, color: Color(0xFF888888)),
        ),
      ],
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '手机号',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF555555),
          ),
        ),
        const SizedBox(height: 8),
        _InputField(
          controller: _phoneCtrl,
          focusNode: _phoneFocus,
          hintText: '请输入手机号',
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(11),
          ],
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _codeFocus.requestFocus(),
          prefix: const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Text(
              '+86',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCodeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '验证码',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF555555),
          ),
        ),
        const SizedBox(height: 8),
        _InputField(
          controller: _codeCtrl,
          focusNode: _codeFocus,
          hintText: '请输入 6 位验证码',
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _login(),
          suffix: _buildSendButton(),
        ),
      ],
    );
  }

  Widget _buildSendButton() {
    final canSend = _canSend;
    final label = _countdown > 0
        ? '${_countdown}s'
        : _sendingCode
            ? '发送中'
            : '获取验证码';

    return GestureDetector(
      onTap: canSend ? _sendCode : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: canSend ? const Color(0xFF07C160) : const Color(0xFFEEEEEE),
          borderRadius: BorderRadius.circular(6),
        ),
        child: _sendingCode
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: canSend ? Colors.white : const Color(0xFFAAAAAA),
                ),
              ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: AnimatedOpacity(
        opacity: _canLogin ? 1.0 : 0.5,
        duration: const Duration(milliseconds: 200),
        child: ElevatedButton(
          onPressed: _canLogin ? _login : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF07C160),
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFF07C160),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _loggingIn
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : const Text(
                  '登录 / 注册',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
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
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16, color: Color(0xFFE6A817)),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Playground 模式：验证码将自动填入输入框',
              style: TextStyle(fontSize: 12, color: Color(0xFF8A6914)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 通用输入框组件 ─────────────────────────────────────────────────────────────

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final TextInputType keyboardType;
  final List<TextInputFormatter> inputFormatters;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final Widget? prefix;
  final Widget? suffix;

  const _InputField({
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.keyboardType,
    required this.inputFormatters,
    required this.onChanged,
    required this.onSubmitted,
    this.prefix,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E8E8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (prefix != null) ...[
            const SizedBox(width: 16),
            prefix!,
            Container(width: 1, height: 20, color: const Color(0xFFE8E8E8)),
          ],
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF1A1A1A),
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFFBBBBBB),
                  fontWeight: FontWeight.normal,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                isDense: true,
              ),
            ),
          ),
          if (suffix != null) ...[
            suffix!,
            const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }
}
