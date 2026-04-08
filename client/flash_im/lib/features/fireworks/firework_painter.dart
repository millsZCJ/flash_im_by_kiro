import 'package:flutter/material.dart';
import 'firework_model.dart';

class FireworkPainter extends CustomPainter {
  final List<Firework> fireworks;

  FireworkPainter(this.fireworks);

  @override
  void paint(Canvas canvas, Size size) {
    for (final fw in fireworks) {
      if (!fw.launched && fw.rocket != null) {
        _drawRocket(canvas, fw.rocket!);
      }
      for (final p in fw.particles) {
        _drawParticle(canvas, p);
      }
    }
  }

  void _drawRocket(Canvas canvas, Particle p) {
    final paint = Paint()
      ..color = p.color.withOpacity(p.alpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(p.position, p.radius, paint);
  }

  void _drawParticle(Canvas canvas, Particle p) {
    // 发光效果：先画大模糊光晕，再画实心点
    final glowPaint = Paint()
      ..color = p.color.withOpacity(p.alpha * 0.4)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, p.radius * 2.5);
    canvas.drawCircle(p.position, p.radius * 2, glowPaint);

    final corePaint = Paint()
      ..color = p.isTrail
          ? Colors.white.withOpacity(p.alpha)
          : p.color.withOpacity(p.alpha);
    canvas.drawCircle(p.position, p.radius, corePaint);
  }

  @override
  bool shouldRepaint(FireworkPainter oldDelegate) => true;
}
