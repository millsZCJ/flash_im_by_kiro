import 'dart:math';
import 'package:flutter/material.dart';

final _rng = Random();

// 单个粒子
class Particle {
  Offset position;
  Offset velocity;
  Color color;
  double radius;
  double alpha;
  double gravity;
  double drag;
  bool isTrail; // 拖尾粒子

  Particle({
    required this.position,
    required this.velocity,
    required this.color,
    this.radius = 3.0,
    this.alpha = 1.0,
    this.gravity = 0.12,
    this.drag = 0.97,
    this.isTrail = false,
  });

  void update() {
    velocity = Offset(velocity.dx * drag, velocity.dy * drag + gravity);
    position += velocity;
    alpha -= isTrail ? 0.04 : 0.018;
  }

  bool get isDead => alpha <= 0;
}

// 烟花形状枚举
enum FireworkShape { circle, star, heart, ring, spiral }

// 一枚烟花（包含所有爆炸粒子）
class Firework {
  final List<Particle> particles = [];
  bool launched = false;

  // 上升阶段的火箭粒子
  Particle? rocket;
  final Offset target;
  final Color baseColor;
  final FireworkShape shape;

  Firework({required Offset start, required this.target, required this.baseColor, required this.shape}) {
    final dx = (target.dx - start.dx) / 40;
    final dy = (target.dy - start.dy) / 40;
    rocket = Particle(
      position: start,
      velocity: Offset(dx, dy),
      color: baseColor,
      radius: 4,
      gravity: 0.05,
      drag: 1.0,
      alpha: 1.0,
    );
  }

  void explode() {
    launched = true;
    rocket = null;
    final pos = target;
    final count = _particleCount(shape);

    for (int i = 0; i < count; i++) {
      final angle = _angleForShape(shape, i, count);
      final speed = _speedForShape(shape) * (0.6 + _rng.nextDouble() * 0.8);
      final vx = cos(angle) * speed;
      final vy = sin(angle) * speed;

      // 颜色变体
      final color = _colorVariant(baseColor, i, count);

      particles.add(Particle(
        position: pos,
        velocity: Offset(vx, vy),
        color: color,
        radius: 2.5 + _rng.nextDouble() * 2,
        gravity: 0.08 + _rng.nextDouble() * 0.06,
        drag: 0.95 + _rng.nextDouble() * 0.03,
      ));

      // 拖尾
      if (_rng.nextDouble() > 0.5) {
        particles.add(Particle(
          position: pos,
          velocity: Offset(vx * 0.5, vy * 0.5),
          color: Colors.white,
          radius: 1.5,
          isTrail: true,
          gravity: 0.04,
          drag: 0.93,
        ));
      }
    }
  }

  int _particleCount(FireworkShape s) {
    switch (s) {
      case FireworkShape.star: return 80;
      case FireworkShape.heart: return 100;
      case FireworkShape.ring: return 60;
      case FireworkShape.spiral: return 120;
      default: return 90;
    }
  }

  double _speedForShape(FireworkShape s) {
    switch (s) {
      case FireworkShape.ring: return 5.0;
      case FireworkShape.spiral: return 4.0;
      default: return 6.0;
    }
  }

  double _angleForShape(FireworkShape s, int i, int count) {
    switch (s) {
      case FireworkShape.circle:
        return (2 * pi * i / count) + _rng.nextDouble() * 0.3;
      case FireworkShape.star:
        final base = (2 * pi * i / count);
        final isPoint = i % (count ~/ 5) == 0;
        return base + (isPoint ? 0 : _rng.nextDouble() * 0.5);
      case FireworkShape.heart:
        final t = 2 * pi * i / count;
        return atan2(sin(t) - sin(3 * t), cos(t));
      case FireworkShape.ring:
        return 2 * pi * i / count;
      case FireworkShape.spiral:
        return (2 * pi * i / count) + (i / count) * pi;
    }
  }

  Color _colorVariant(Color base, int i, int count) {
    final hslBase = HSLColor.fromColor(base);
    final hue = (hslBase.hue + (i / count) * 60) % 360;
    return HSLColor.fromAHSL(1.0, hue, hslBase.saturation, hslBase.lightness).toColor();
  }

  void update() {
    if (!launched) {
      rocket?.update();
      // 判断是否到达目标附近
      if (rocket != null) {
        final d = (rocket!.position - target).distance;
        if (d < 8 || rocket!.velocity.dy >= 0) explode();
      }
    } else {
      for (final p in particles) {
        p.update();
      }
      particles.removeWhere((p) => p.isDead);
    }
  }

  bool get isDead => launched && particles.isEmpty;
}
