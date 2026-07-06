import 'package:flutter/material.dart';

/// 用户协议勾选行
class AgreementRow extends StatelessWidget {
  final bool agreed;
  final ValueChanged<bool> onChanged;

  const AgreementRow({super.key, required this.agreed, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!agreed),
      child: Row(
        children: [
          Icon(
            agreed ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 20,
            color: agreed ? const Color(0xFF07C160) : const Color(0xFFCCCCCC),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 13, color: Color(0xFF888888)),
                children: [
                  TextSpan(text: '我已阅读并同意'),
                  TextSpan(text: '《用户协议》', style: TextStyle(color: Color(0xFF07C160))),
                  TextSpan(text: '和'),
                  TextSpan(text: '《隐私政策》', style: TextStyle(color: Color(0xFF07C160))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
