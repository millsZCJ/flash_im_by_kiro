import 'package:flutter/material.dart';

/// 通用按钮组件 — 启用态绿色实心 / 禁用态半透明
class ActionButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final bool loading;
  final VoidCallback? onPressed;
  final Color activeColor;

  const ActionButton({
    super.key,
    required this.label,
    this.enabled = true,
    this.loading = false,
    this.onPressed,
    this.activeColor = const Color(0xFF07C160),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.5,
        duration: const Duration(milliseconds: 200),
        child: ElevatedButton(
          onPressed: enabled && !loading ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: activeColor,
            foregroundColor: Colors.white,
            disabledBackgroundColor: activeColor,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: loading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
              : Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}
