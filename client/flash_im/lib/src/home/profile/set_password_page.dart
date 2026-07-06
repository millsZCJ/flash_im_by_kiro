import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';

import 'package:flash_auth/flash_auth.dart';

/// 密码设置独立页面 — Navigator.push 进入
class SetPasswordPage extends StatefulWidget {
  final AuthRepository? authRepository;

  const SetPasswordPage({super.key, this.authRepository});

  @override
  State<SetPasswordPage> createState() => _SetPasswordPageState();
}

class _SetPasswordPageState extends State<SetPasswordPage> {
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  String? _error;

  String get password => _passwordCtrl.text.trim();
  String get confirm => _confirmCtrl.text.trim();
  bool get isValid => password.length >= 6 && password == confirm;

  @override
  void dispose() { _passwordCtrl.dispose(); _confirmCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!isValid || _loading) return;
    setState(() { _loading = true; _error = null; });

    try {
      final repo = widget.authRepository ?? (ModalRoute.of(context)?.settings.arguments as AuthRepository?);
      if (repo == null) throw Exception('AuthRepository 未传入');

      await repo.setPassword(password);
      if (!mounted) return;
      context.read<AuthCubit>().onPasswordSet();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('密码设置成功'), backgroundColor: const Color(0xFF07C160),
          behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), margin: const EdgeInsets.all(16),
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) setState(() { _error = '设置失败：$e'; _loading = false; });
    } finally {
      if (mounted && _loading) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FA), elevation: 0,
        title: const Text('设置密码', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, size: 20, color: Color(0xFF1A1A1A)), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 32),
          const Text('请设置您的登录密码', style: TextStyle(fontSize: 15, color: Color(0xFF888888))),
          const SizedBox(height: 32),
          LabeledInput(controller: _passwordCtrl, label: '新密码', hintText: '请输入密码（至少 6 位）',
            keyboardType: TextInputType.visiblePassword, inputFormatters: [LengthLimitingTextInputFormatter(32)],
            onChanged: (_) => setState(() {}), obscureText: _obscurePassword,
            suffix: GestureDetector(onTap: () => setState(() => _obscurePassword = !_obscurePassword),
              child: Padding(padding: const EdgeInsets.only(right: 4), child: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 22, color: const Color(0xFFAAAAAA))))),
          const SizedBox(height: 16),
          LabeledInput(controller: _confirmCtrl, label: '确认密码', hintText: '请再次输入密码',
            keyboardType: TextInputType.visiblePassword, inputFormatters: <TextInputFormatter>[LengthLimitingTextInputFormatter(32)],
            onChanged: (_) => setState(() {}), obscureText: _obscureConfirm,
            suffix: GestureDetector(onTap: () => setState(() => _obscureConfirm = !_obscureConfirm),
              child: Padding(padding: const EdgeInsets.only(right: 4), child: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 22, color: const Color(0xFFAAAAAA))))),
          if (_confirmCtrl.text.isNotEmpty && password != confirm) ...[
            SizedBox(height: 8), Text('两次密码不一致', style: TextStyle(fontSize: 13, color: Color(0xFFE53935))),
          ],
          SizedBox(height: 32),
          ActionButton(label: '确认设置', enabled: isValid, loading: _loading, onPressed: _submit),
          if (_error != null) ...[const SizedBox(height: 16), Text(_error!, style: const TextStyle(fontSize: 14, color: Color(0xFFE53935)))],
        ]),
      ),
    );
  }
}
