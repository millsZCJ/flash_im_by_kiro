import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';

import 'package:flash_auth/flash_auth.dart' show LabeledInput, ActionButton;
import 'package:flash_session/src/logic/session_cubit.dart';

/// 修改密码页面 — 旧密码 + 新密码两个输入框
class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _oldPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  String? _error;

  String get oldPassword => _oldPasswordCtrl.text.trim();
  String get newPassword => _newPasswordCtrl.text.trim();
  String get confirm => _confirmCtrl.text.trim();
  bool get isValid =>
      oldPassword.isNotEmpty &&
      newPassword.length >= 6 &&
      newPassword == confirm;

  @override
  void dispose() {
    _oldPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!isValid || _loading) return;
    setState(() { _loading = true; _error = null; });

    try {
      final success = await context.read<SessionCubit>().changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('密码修改成功'),
          backgroundColor: const Color(0xFF07C160),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
        ));
        Navigator.pop(context);
      } else {
        // 401 = 旧密码错误
        setState(() { _error = '原密码不正确'; _loading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
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
        title: const Text('修改密码', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, size: 20, color: Color(0xFF1A1A1A)), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 32),
          const Text('请输入原密码和新密码', style: TextStyle(fontSize: 15, color: Color(0xFF888888))),
          const SizedBox(height: 32),
          LabeledInput(controller: _oldPasswordCtrl, label: '原密码', hintText: '请输入原密码',
            keyboardType: TextInputType.visiblePassword,
            inputFormatters: [LengthLimitingTextInputFormatter(32)],
            onChanged: (_) => setState(() {}),
            obscureText: _obscureOld,
            suffix: GestureDetector(onTap: () => setState(() => _obscureOld = !_obscureOld),
              child: Padding(padding: const EdgeInsets.only(right: 4),
                child: Icon(_obscureOld ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 22, color: const Color(0xFFAAAAAA)))),
          ),
          const SizedBox(height: 16),
          LabeledInput(controller: _newPasswordCtrl, label: '新密码', hintText: '请输入新密码（至少 6 位）',
            keyboardType: TextInputType.visiblePassword,
            inputFormatters: [LengthLimitingTextInputFormatter(32)],
            onChanged: (_) => setState(() {}),
            obscureText: _obscureNew,
            suffix: GestureDetector(onTap: () => setState(() => _obscureNew = !_obscureNew),
              child: Padding(padding: const EdgeInsets.only(right: 4),
                child: Icon(_obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 22, color: const Color(0xFFAAAAAA)))),
          ),
          const SizedBox(height: 16),
          LabeledInput(controller: _confirmCtrl, label: '确认密码', hintText: '请再次输入新密码',
            keyboardType: TextInputType.visiblePassword,
            inputFormatters: [LengthLimitingTextInputFormatter(32)],
            onChanged: (_) => setState(() {}),
            obscureText: _obscureConfirm,
            suffix: GestureDetector(onTap: () => setState(() => _obscureConfirm = !_obscureConfirm),
              child: Padding(padding: const EdgeInsets.only(right: 4),
                child: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 22, color: const Color(0xFFAAAAAA)))),
          ),
          if (_confirmCtrl.text.isNotEmpty && newPassword != confirm) ...[
            const SizedBox(height: 8),
            const Text('两次密码不一致', style: TextStyle(fontSize: 13, color: Color(0xFFE53935))),
          ],
          const SizedBox(height: 32),
          ActionButton(label: '确认修改', enabled: isValid, loading: _loading, onPressed: _submit),
          if (_error != null) ...[const SizedBox(height: 16), Text(_error!, style: const TextStyle(fontSize: 14, color: Color(0xFFE53935)))],
        ]),
      ),
    );
  }
}
