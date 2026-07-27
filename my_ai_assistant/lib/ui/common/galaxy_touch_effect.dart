import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class GalaxyParticle {
  final double angle;
  final double speedFactor;
  final double size;
  final Color color;
  final double spinFactor;

  GalaxyParticle({
    required this.angle,
    required this.speedFactor,
    required this.size,
    required this.color,
    required this.spinFactor,
  });
}

class GalaxyExplosion {
  final Offset center;
  final int spawnTimeMs;
  final List<GalaxyParticle> particles;

  GalaxyExplosion({
    required this.center,
    required this.spawnTimeMs,
    required this.particles,
  });
}

class GalaxyTouchEffect extends StatefulWidget {
  final Widget child;

  const GalaxyTouchEffect({
    super.key,
    required this.child,
  });

  @override
  State<GalaxyTouchEffect> createState() => _GalaxyTouchEffectState();
}

class _GalaxyTouchEffectState extends State<GalaxyTouchEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<GalaxyExplosion> _explosions = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    // Continuous ticker that runs only when there are active explosions
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_onFrameTick);
  }

  @override
  void dispose() {
    _controller.removeListener(_onFrameTick);
    _controller.dispose();
    super.dispose();
  }

  void _onFrameTick() {
    if (!mounted) return;

    if (_explosions.isEmpty) {
      if (_controller.isAnimating) {
        _controller.stop();
      }
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    setState(() {
      // Keep only active explosions (duration = 650ms)
      _explosions.removeWhere((exp) => now - exp.spawnTimeMs > 650);
    });
  }

  List<GalaxyParticle> _generateParticles(int count) {
    final List<GalaxyParticle> list = [];
    final List<Color> colors = [
      const Color(0xFF00E5FF), // Cyan
      const Color(0xFFEA4C89), // Fuchsia / Magenta
      const Color(0xFFB8A2F2), // Nebula Violet
      const Color(0xFFFFFFFF), // Core White
    ];

    for (int i = 0; i < count; i++) {
      // Distribute starting angles evenly with noise
      final baseAngle = (i * 2 * math.pi / count) + (_random.nextDouble() - 0.5) * 0.35;
      final speedFactor = 0.45 + _random.nextDouble() * 0.65;
      final size = 1.2 + _random.nextDouble() * 2.4;
      final color = colors[_random.nextInt(colors.length)];
      // Spin speed and direction
      final spinDirection = _random.nextBool() ? 1.0 : -1.0;
      final spinFactor = spinDirection * (1.8 + _random.nextDouble() * 2.2);

      list.add(GalaxyParticle(
        angle: baseAngle,
        speedFactor: speedFactor,
        size: size,
        color: color,
        spinFactor: spinFactor,
      ));
    }
    return list;
  }

  void _handlePointerDown(PointerDownEvent event) {
    final localPos = event.localPosition;
    final now = DateTime.now().millisecondsSinceEpoch;

    setState(() {
      _explosions.add(GalaxyExplosion(
        center: localPos,
        spawnTimeMs: now,
        particles: _generateParticles(20), // 20 stars per galaxy explosion
      ));
    });

    if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _handlePointerDown,
      behavior: HitTestBehavior.translucent, // Allow touches to pass through seamlessly to children
      child: Stack(
        clipBehavior: Clip.antiAlias,
        children: [
          widget.child,
          if (_explosions.isNotEmpty)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: GalaxyExplosionPainter(
                    explosions: _explosions,
                    nowMs: DateTime.now().millisecondsSinceEpoch,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class GalaxyExplosionPainter extends CustomPainter {
  final List<GalaxyExplosion> explosions;
  final int nowMs;

  GalaxyExplosionPainter({
    required this.explosions,
    required this.nowMs,
  });

  @override
  void paint(Canvas canvas, ui.Size size) {
    final particlePaint = Paint()..style = PaintingStyle.fill;

    for (final exp in explosions) {
      final age = nowMs - exp.spawnTimeMs;
      double progress = age / 650.0; // 0.0 to 1.0 over 650ms
      progress = progress.clamp(0.0, 1.0);

      // 1. Draw central fading nebula core
      final double coreRadius = 14.0 * (1.0 - progress);
      if (coreRadius > 0.5) {
        final coreGlow = Paint()
          ..shader = ui.Gradient.radial(
            exp.center,
            coreRadius,
            [
              const Color(0xFFFFFFFF).withOpacity(0.5 * (1.0 - progress)),
              const Color(0xFFB8A2F2).withOpacity(0.2 * (1.0 - progress)),
              Colors.transparent,
            ],
            [0.0, 0.45, 1.0],
          );
        canvas.drawCircle(exp.center, coreRadius, coreGlow);
      }

      // 2. Draw galaxy particles spiraling out
      for (final p in exp.particles) {
        // Distance increases as time goes by
        final double distance = progress * 70.0 * p.speedFactor;
        // Angle rotates (spiraling)
        final double currentAngle = p.angle + progress * p.spinFactor;

        final double x = exp.center.dx + distance * math.cos(currentAngle);
        final double y = exp.center.dy + distance * math.sin(currentAngle);

        // Opacity fades out, with a rapid fade-in at first
        double opacity = 1.0;
        if (progress < 0.15) {
          opacity = progress / 0.15;
        } else {
          opacity = 1.0 - progress;
        }
        opacity = opacity.clamp(0.0, 1.0);

        if (opacity <= 0.0) continue;

        particlePaint.color = p.color.withOpacity(opacity);
        final double drawSize = p.size * (1.0 - progress * 0.4);

        // Draw sub-glow for larger stars
        if (p.size > 1.8 && opacity > 0.3) {
          final glowPaint = Paint()
            ..color = p.color.withOpacity(0.12 * opacity)
            ..style = PaintingStyle.fill;
          canvas.drawCircle(Offset(x, y), drawSize * 2.5, glowPaint);
        }

        canvas.drawCircle(Offset(x, y), drawSize, particlePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant GalaxyExplosionPainter oldDelegate) {
    return true; // Re-paint on every tick as long as explosions are active
  }
}
