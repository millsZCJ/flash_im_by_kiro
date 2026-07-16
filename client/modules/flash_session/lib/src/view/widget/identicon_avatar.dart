import 'package:flutter/material.dart';

/// DJB2 哈希算法 — 将字符串转为 32 位整数
int _djb2Hash(String input) {
  int hash = 5381;
  for (int i = 0; i < input.length; i++) {
    hash = ((hash << 5) + hash) + input.codeUnitAt(i);
    hash = hash & 0xFFFFFFFF; // 保持 32 位
  }
  return hash;
}

/// 从 hash 生成 16 字节（4 组 × 4 字节）
List<int> _hashToBytes(String seed) {
  final hash1 = _djb2Hash(seed);
  final hash2 = _djb2Hash('${seed}_2');
  final hash3 = _djb2Hash('${seed}_3');
  final hash4 = _djb2Hash('${seed}_4');

  final bytes = <int>[];
  bytes.addAll(_intToBytes(hash1));
  bytes.addAll(_intToBytes(hash2));
  bytes.addAll(_intToBytes(hash3));
  bytes.addAll(_intToBytes(hash4));
  return bytes;
}

List<int> _intToBytes(int value) {
  return [
    (value >> 24) & 0xFF,
    (value >> 16) & 0xFF,
    (value >> 8) & 0xFF,
    value & 0xFF,
  ];
}

/// 从字节生成填充矩阵（5×5，左 3 列决定，右 2 列镜像对称）
List<List<bool>> _generateMatrix(List<int> bytes) {
  final matrix = List.generate(5, (_) => List.filled(5, false));

  for (int row = 0; row < 5; row++) {
    for (int col = 0; col < 3; col++) {
      final byteIndex = row * 3 + col;
      final bitIndex = byteIndex % 8;
      final byteValue = bytes[byteIndex ~/ 8];
      final isFilled = ((byteValue >> bitIndex) & 1) == 1;
      matrix[row][col] = isFilled;
      // 镜像对称：右 2 列
      matrix[row][4 - col] = isFilled;
    }
  }
  return matrix;
}

/// 从字节生成颜色
Color _generateColor(List<int> bytes) {
  final r = bytes[0];
  final g = bytes[1];
  final b = bytes[2];
  // 确保 RGB 值足够鲜明（不低于 50，不超过 200）
  final clampedR = (r % 150) + 50;
  final clampedG = (g % 150) + 50;
  final clampedB = (b % 150) + 50;
  return Color.fromARGB(255, clampedR, clampedG, clampedB);
}

/// IdenticonPainter — 5×5 对称方块图案 CustomPainter
class IdenticonPainter extends CustomPainter {
  final String seed;

  IdenticonPainter({required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final bytes = _hashToBytes(seed);
    final matrix = _generateMatrix(bytes);
    final color = _generateColor(bytes);

    // 15% 内边距
    final padding = size.width * 0.15;
    final drawWidth = size.width - padding * 2;
    final drawHeight = size.height - padding * 2;
    final cellWidth = drawWidth / 5;
    final cellHeight = drawHeight / 5;

    final paint = Paint()..color = color;

    // 绘制背景
    final bgPaint = Paint()..color = const Color(0xFFF0F0F0);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 绘制填充方块
    for (int row = 0; row < 5; row++) {
      for (int col = 0; col < 5; col++) {
        if (matrix[row][col]) {
          final x = padding + col * cellWidth;
          final y = padding + row * cellHeight;
          canvas.drawRect(
            Rect.fromLTWH(x, y, cellWidth, cellHeight),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(IdenticonPainter oldDelegate) => seed != oldDelegate.seed;
}

/// IdenticonAvatar — 基于 seed 的对称方块图案头像组件
class IdenticonAvatar extends StatelessWidget {
  final String seed;
  final double size;
  final double borderRadius;

  const IdenticonAvatar({
    super.key,
    required this.seed,
    this.size = 64,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: IdenticonPainter(seed: seed),
        ),
      ),
    );
  }
}
