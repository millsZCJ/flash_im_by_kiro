import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 通用底线输入框组件 — 带标签 + 竖线分隔
class LabeledInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String label;
  final String hintText;
  final TextInputType keyboardType;
  final List<TextInputFormatter> inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? prefix;
  final Widget? suffix;
  final bool obscureText;
  final int maxLength;

  const LabeledInput({
    super.key,
    required this.controller,
    required this.label,
    required this.hintText,
    this.focusNode,
    this.keyboardType = TextInputType.text,
    this.inputFormatters = const [],
    this.onChanged,
    this.onSubmitted,
    this.prefix,
    this.suffix,
    this.obscureText = false,
    this.maxLength = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF555555)),
        ),
        const SizedBox(height: 8),
        Container(
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE8E8E8)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
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
                  obscureText: obscureText,
                  maxLength: maxLength > 0 ? maxLength : null,
                  style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A1A), fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: const TextStyle(fontSize: 15, color: Color(0xFFBBBBBB)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    isDense: true,
                    counterText: '',
                  ),
                ),
              ),
              if (suffix != null) ...[suffix!, const SizedBox(width: 12)],
            ],
          ),
        ),
      ],
    );
  }
}
