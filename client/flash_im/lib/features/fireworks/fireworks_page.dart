import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'firework_model.dart';
import 'firework_painter.dart';

final _rng = Random();

// 预设的炫彩颜色
const _palette = [
  Color(0xFFFF4081),
  Color(0xFFFF6D00),
  Color(0xFFFFD600),
  Color(0xFF00E676),
  Color(0xFF00B0FF),
  Color(0xFFD500F9),
  Color(0xFF76FF03),
  Color(0xFFFF1744),
  Color(0xFF00E5FF),
  Color(0xFFFFAB40),
];

class FireworksPage extends StatefulWidget {
  const FireworksPage({super.key});

  @override
  State<FireworksPage> createState() => _FireworksPageState();
}

class _FireworksPageState extends State<FireworksPage> {
  final List<Firework> _fireworks = [];
  late Timer _ticker;
  Size _size = Size.zero;

  // 背景星星
  late List<_Star> _stars;

  @override
  void initState() {
    super.initState();
    _stars = List.generate(80, (_) => _Star());
    _ticker = Timer.periodic(const Duration(milliseconds: 16), (_) {
      setState(() {
        for (final fw in _fireworks) {
          fw.update();
        }
        _fireworks.removeWhere((fw) => fw.isDead);
        for (final s in _stars) {
          s.twinkle();
        }
      });
    });
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  void _launchAt(Offset tapPos) {
    // 每次点击发射 2~4 枚烟花，稍微错开位置
    final count = 2 + _rng.nextInt(3);
    for (int i = 0; i < count; i++) {
      final offset = Offset(
        (_rng.nextDouble() - 0.5) * 60,
        (_rng.nextDouble() - 0.5) * 60,
      );
      final target = tapPos + offset;
      final start = Offset(
        _size.width * (0.3 + _rng.nextDouble() * 0.4),
        _size.height + 20,
      );
      final color = _palette[_rng.nextInt(_palette.length)];
      final shape =
          FireworkShape.values[_rng.nextInt(FireworkShape.values.length)];
      _fireworks.add(
        Firework(start: start, target: target, baseColor: color, shape: shape),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          _size = Size(constraints.maxWidth, constraints.maxHeight);
          // 初始化星星位置（只在 size 确定后）
          if (_stars.first.x == 0) {
            for (final s in _stars) {
              s.init(_size);
            }
          }
          return GestureDetector(
            onTapDown: (d) => _launchAt(d.localPosition),
            onPanUpdate: (d) {
              if (_rng.nextDouble() > 0.85) _launchAt(d.localPosition);
            },
            child: Stack(
              children: [
                // 星空背景
                CustomPaint(size: _size, painter: _StarPainter(_stars)),
                // 烟花层
                CustomPaint(size: _size, painter: FireworkPainter(_fireworks)),
                // 提示文字
                if (_fireworks.isEmpty)
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🎆', style: TextStyle(fontSize: 64)),
                        const SizedBox(height: 16),
                        Text(
                          '点击屏幕，释放烟花',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 20,
                            letterSpacing: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                // 返回按钮
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 12,
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white70,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                // 标题
                Positioned(
                  top: MediaQuery.of(context).padding.top + 12,
                  left: 0,
                  right: 0,
                  child: const Center(
                    child: Text(
                      '✨ 烟花秀',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                        letterSpacing: 6,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// 背景星星
class _Star {
  double x = 0, y = 0, radius = 1, alpha = 1, alphaSpeed = 0.01;

  void init(Size size) {
    x = _rng.nextDouble() * size.width;
    y = _rng.nextDouble() * size.height;
    radius = 0.5 + _rng.nextDouble() * 1.5;
    alpha = _rng.nextDouble();
    alphaSpeed = 0.005 + _rng.nextDouble() * 0.015;
  }

  void twinkle() {
    alpha += alphaSpeed;
    if (alpha >= 1 || alpha <= 0) alphaSpeed = -alphaSpeed;
    alpha = alpha.clamp(0.0, 1.0);
  }
}

class _StarPainter extends CustomPainter {
  final List<_Star> stars;
  _StarPainter(this.stars);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final s in stars) {
      paint.color = Colors.white.withOpacity(s.alpha * 0.8);
      canvas.drawCircle(Offset(s.x, s.y), s.radius, paint);
    }
  }

  @override
  bool shouldRepaint(_StarPainter old) => true;
}
