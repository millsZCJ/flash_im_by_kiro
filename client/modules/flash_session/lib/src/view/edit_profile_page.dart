import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flash_core/flash_core.dart';
import 'package:flash_session/src/logic/session_cubit.dart';
import 'package:flash_session/src/logic/session_state.dart';
import 'package:flash_session/src/view/widget/user_card.dart';

/// 编辑资料页面 — 微信风格列表页，即时保存
class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDEDED),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        title: const Text('个人资料', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, size: 20, color: Color(0xFF1A1A1A)), onPressed: () => Navigator.pop(context)),
      ),
      body: BlocBuilder<SessionCubit, SessionState>(
        builder: (context, state) {
          final user = state.user;
          if (user == null) return const Center(child: Text('加载中...'));
          return _buildContent(context, user);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, User user) {
    final phoneMasked = _maskPhone(user.phone);
    final userIdShort = user.userId.length > 8 ? user.userId.substring(0, 8) : user.userId;

    return ListView(
      children: [
        // 第一组：头像 + 名字
        Container(color: Colors.white, child: Column(children: [
          _ProfileRow(
            label: '头像',
            valueWidget: Row(mainAxisSize: MainAxisSize.min, children: [
              UserAvatar(user: user, size: 40, borderRadius: 6),
            ]),
            onTap: () => _navigateToAvatarEdit(context, user),
          ),
          const Divider(height: 1, indent: 72 + 16, color: Color(0xFFF0F0F0)),
          _ProfileRow(
            label: '名字',
            value: user.nickname,
            onTap: () => _navigateToTextEdit(context, field: 'nickname', initialValue: user.nickname, maxLength: 20),
          ),
        ])),
        const SizedBox(height: 12),
        // 第二组：手机号 + 闪讯号
        Container(color: Colors.white, child: Column(children: [
          _ProfileRow(label: '手机号', value: phoneMasked),
          const Divider(height: 1, indent: 72 + 16, color: Color(0xFFF0F0F0)),
          _ProfileRow(label: '闪讯号', value: userIdShort),
        ])),
        const SizedBox(height: 12),
        // 第三组：签名
        Container(color: Colors.white, child: Column(children: [
          _ProfileRow(
            label: '签名',
            value: user.signature.isEmpty ? '未设置' : user.signature,
            valueStyle: user.signature.isEmpty
                ? const TextStyle(fontSize: 15, color: Color(0xFFBBBBBB))
                : const TextStyle(fontSize: 15, color: Color(0xFF888888)),
            onTap: () => _navigateToTextEdit(context, field: 'signature', initialValue: user.signature, maxLength: 100),
          ),
        ])),
        const SizedBox(height: 32),
      ],
    );
  }

  void _navigateToTextEdit(BuildContext context, {
    required String field,
    required String initialValue,
    required int maxLength,
  }) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => _TextEditPage(
        title: field == 'nickname' ? '修改名字' : '修改签名',
        initialValue: initialValue,
        maxLength: maxLength,
        onSave: (value) async {
          if (field == 'nickname') {
            await context.read<SessionCubit>().updateProfile(nickname: value);
          } else {
            await context.read<SessionCubit>().updateProfile(signature: value);
          }
        },
      ),
    ));
  }

  void _navigateToAvatarEdit(BuildContext context, User user) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => BlocProvider.value(
        value: context.read<SessionCubit>(),
        child: _AvatarEditPage(user: user),
      ),
    ));
  }

  /// 手机号脱敏：前 3 后 2，中间为 *
  String _maskPhone(String phone) {
    if (phone.length < 5) return phone;
    return '${phone.substring(0, 3)}****${phone.substring(phone.length - 2)}';
  }
}

/// 资料行组件
class _ProfileRow extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? valueWidget;
  final TextStyle? valueStyle;
  final VoidCallback? onTap;

  const _ProfileRow({
    required this.label,
    this.value,
    this.valueWidget,
    this.valueStyle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          SizedBox(
            width: 72,
            child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
          ),
          Expanded(
            child: valueWidget ?? Text(
              value ?? '',
              style: valueStyle ?? const TextStyle(fontSize: 15, color: Color(0xFF888888)),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          if (onTap != null) const SizedBox(width: 8),
          if (onTap != null) const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFFCCCCCC)),
        ]),
      ),
    );
  }
}

/// 文本编辑子页面 — 即时保存
class _TextEditPage extends StatefulWidget {
  final String title;
  final String initialValue;
  final int maxLength;
  final Future<void> Function(String) onSave;

  const _TextEditPage({
    required this.title,
    required this.initialValue,
    required this.maxLength,
    required this.onSave,
  });

  @override
  State<_TextEditPage> createState() => _TextEditPageState();
}

class _TextEditPageState extends State<_TextEditPage> {
  late final TextEditingController _controller;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      setState(() { _error = '内容不能为空'; });
      return;
    }
    setState(() { _loading = true; _error = null; });

    try {
      await widget.onSave(value);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() { _error = '保存失败：$e'; _loading = false; });
    } finally {
      if (mounted && _loading) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        title: Text(widget.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, size: 20, color: Color(0xFF1A1A1A)), onPressed: () => Navigator.pop(context)),
        actions: [
          TextButton(
            onPressed: _loading ? null : _save,
            child: _loading
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('完成', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF07C160))),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(children: [
          TextField(
            controller: _controller,
            maxLength: widget.maxLength,
            autofocus: true,
            style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A1A)),
            decoration: InputDecoration(
              hintText: '请输入${widget.title.replaceFirst('修改', '')}',
              hintStyle: const TextStyle(fontSize: 15, color: Color(0xFFBBBBBB)),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE8E8E8))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE8E8E8))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF07C160))),
              counterStyle: const TextStyle(fontSize: 12, color: Color(0xFFAAAAAA)),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(fontSize: 14, color: Color(0xFFE53935))),
          ],
        ]),
      ),
    );
  }
}

/// 头像编辑子页面 — 预览大图 + 随机更换
class _AvatarEditPage extends StatelessWidget {
  final User user;

  const _AvatarEditPage({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        title: const Text('更换头像', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, size: 20, color: Color(0xFF1A1A1A)), onPressed: () => Navigator.pop(context)),
      ),
      body: BlocBuilder<SessionCubit, SessionState>(
        builder: (context, state) {
          final currentUser = state.user ?? user;
          return Column(children: [
            const SizedBox(height: 40),
            // 预览大图
            Center(child: UserAvatar(user: currentUser, size: 120, borderRadius: 12)),
            const SizedBox(height: 32),
            // 随机更换按钮（仅 identicon 模式）
            if (!currentUser.hasCustomAvatar)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton(
                    onPressed: () => context.read<SessionCubit>().randomizeAvatar(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF07C160)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('随机更换', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF07C160))),
                  ),
                ),
              ),
          ]);
        },
      ),
    );
  }
}
