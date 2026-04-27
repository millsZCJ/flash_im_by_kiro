import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../features/auth/api/auth_api.dart';
import 'shell/im_shell.dart';

/// IM Playground 入口
///
/// 启动命令：
///   flutter run -t lib/im_playground/main_im_playground.dart -d chrome
class ImPlaygroundApp extends StatelessWidget {
  const ImPlaygroundApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flash IM',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF07C160)),
        scaffoldBackgroundColor: const Color(0xFFEDEDED),
      ),
      home: _AuthGate(),
    );
  }
}

// ─── 认证门控 ─────────────────────────────────────────────────────────────────

class _AuthGate extends StatefulWidget {
  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  final _api = AuthApi();

  @override
  Widget build(BuildContext context) {
    if (!_api.isLoggedIn) {
      return _ImLoginPage(
        api: _api,
        onSuccess: () => setState(() {}),
      );
    }
    return ImShell(authApi: _api, onLogout: () => setState(() {}));
  }
}

// ─── IM 专用登录页（登录成功后回调，不做页面跳转）────────────────────────────

class _ImLoginPage extends StatefulWidget {
  final AuthApi api;
  final VoidCallback onSuccess;

  const _ImLoginPage({required this.api, required this.onSuccess});

  @override
  State<_ImLoginPage> createState() => _ImLoginPageState();
}

class _ImLoginPageState extends State<_ImLoginPage> {
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

  Future<void> _sendCode() async {
    if (!_canSend) return;
    setState(() => _sendingCode = true);
    try {
      final code = await widget.api.sendSms(_phoneCtrl.text.trim());
      _codeCtrl.text = code;
      _codeFocus.requestFocus();
      _startCountdown();
      if (mounted) _showSnack('验证码已发送（已自动填入：$code）', isError: false);
    } catch (e) {
      if (mounted) _showSnack('发送失败：$e');
    } finally {
      if (mounted) setState(() => _sendingCode = false);
    }
  }

  void _startCountdown() {
    setState(() => _countdown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() { _countdown--; if (_countdown <= 0) t.cancel(); });
    });
  }

  Future<void> _login() async {
    if (!_canLogin) return;
    setState(() => _loggingIn = true);
    try {
      await widget.api.login(_phoneCtrl.text.trim(), _codeCtrl.text.trim());
      if (mounted) widget.onSuccess();
    } catch (_) {
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
    ));
  }

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
              // Logo + 标题
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF07C160),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 30),
              ),
              const SizedBox(height: 24),
              const Text('欢迎使用 Flash IM',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A), letterSpacing: -0.5)),
              const SizedBox(height: 8),
              const Text('手机号验证码登录',
                  style: TextStyle(fontSize: 15, color: Color(0xFF888888))),
              const SizedBox(height: 48),
              // 手机号
              _buildLabel('手机号'),
              const SizedBox(height: 8),
              _buildPhoneField(),
              const SizedBox(height: 16),
              // 验证码
              _buildLabel('验证码'),
              const SizedBox(height: 8),
              _buildCodeField(),
              const SizedBox(height: 32),
              // 登录按钮
              _buildLoginButton(),
              const SizedBox(height: 20),
              // Playground 提示
              _buildHint(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
          color: Color(0xFF555555)));

  Widget _buildPhoneField() {
    return _FieldBox(
      child: Row(children: [
        const SizedBox(width: 16),
        const Text('+86', style: TextStyle(fontSize: 15,
            fontWeight: FontWeight.w500, color: Color(0xFF1A1A1A))),
        const SizedBox(width: 12),
        Container(width: 1, height: 20, color: const Color(0xFFE8E8E8)),
        Expanded(
          child: TextField(
            controller: _phoneCtrl,
            focusNode: _phoneFocus,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(11)],
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _codeFocus.requestFocus(),
            style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A1A)),
            decoration: const InputDecoration(
              hintText: '请输入手机号',
              hintStyle: TextStyle(color: Color(0xFFBBBBBB)),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16),
              isDense: true,
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildCodeField() {
    final canSend = _canSend;
    final label = _countdown > 0 ? '${_countdown}s'
        : _sendingCode ? '发送中' : '获取验证码';

    return _FieldBox(
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: _codeCtrl,
            focusNode: _codeFocus,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6)],
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _login(),
            style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A1A)),
            decoration: const InputDecoration(
              hintText: '请输入 6 位验证码',
              hintStyle: TextStyle(color: Color(0xFFBBBBBB)),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16),
              isDense: true,
            ),
          ),
        ),
        GestureDetector(
          onTap: canSend ? _sendCode : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: canSend ? const Color(0xFF07C160) : const Color(0xFFEEEEEE),
              borderRadius: BorderRadius.circular(6),
            ),
            child: _sendingCode
                ? const SizedBox(width: 14, height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white)))
                : Text(label, style: TextStyle(fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: canSend ? Colors.white : const Color(0xFFAAAAAA))),
          ),
        ),
      ]),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _loggingIn
              ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white)))
              : const Text('登录 / 注册',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _buildHint() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFE082)),
      ),
      child: const Row(children: [
        Icon(Icons.info_outline, size: 16, color: Color(0xFFE6A817)),
        SizedBox(width: 8),
        Expanded(child: Text('Playground 模式：验证码将自动填入输入框',
            style: TextStyle(fontSize: 12, color: Color(0xFF8A6914)))),
      ]),
    );
  }
}

class _FieldBox extends StatelessWidget {
  final Widget child;
  const _FieldBox({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E8E8)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }
}
