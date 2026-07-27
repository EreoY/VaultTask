import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/glass_theme.dart';

class AetherDynamicBackdrop extends StatefulWidget {
  const AetherDynamicBackdrop({super.key});

  @override
  State<AetherDynamicBackdrop> createState() => _AetherDynamicBackdropState();
}

class _AetherDynamicBackdropState extends State<AetherDynamicBackdrop>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // 25-second continuous loop for slow, elegant drifting and pulsing
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final double pi2 = 2 * math.pi;

        // Orb 1: Muted Blue (Top-Right drifting and pulsing)
        final x1 = 0.5 + 0.3 * math.sin(t * pi2);
        final y1 = -0.4 + 0.2 * math.cos(t * pi2);
        final size1 = 400.0 + 80.0 * math.sin(t * pi2 * 3); // gentle size pulse
        final opacity1 = (0.15 + 0.07 * math.sin(t * pi2 * 5)).clamp(0.05, 0.22); // gentle flicker

        // Orb 2: Executive Muted Gold (Bottom-Left drifting and pulsing)
        final x2 = -0.5 + 0.25 * math.cos(t * pi2 + 1.2);
        final y2 = 0.4 + 0.2 * math.sin(t * pi2 + 1.2);
        final size2 = 420.0 + 90.0 * math.cos(t * pi2 * 2.5);
        final opacity2 = (0.12 + 0.06 * math.cos(t * pi2 * 4.0)).clamp(0.04, 0.18);

        // Orb 3: Pastel Muted Purple (Center-Right drifting and pulsing)
        final x3 = 0.3 + 0.25 * math.sin(t * pi2 * 2 + 2.0); // faster movement
        final y3 = 0.2 + 0.25 * math.cos(t * pi2 + 2.0);
        final size3 = 340.0 + 60.0 * math.sin(t * pi2 * 6);
        final opacity3 = (0.10 + 0.05 * math.sin(t * pi2 * 7.5)).clamp(0.03, 0.15);

        return Stack(
          children: [
            // Solid dark background foundation
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: GlassGradients.background(),
                ),
              ),
            ),
            // Orb 1 (Electric Cyan)
            Align(
              alignment: Alignment(x1, y1),
              child: _OrbWidget(
                color: const Color(0xFF00E5FF), // Electric Cyan
                size: size1,
                opacity: opacity1,
              ),
            ),
            // Orb 2 (Gold Core)
            Align(
              alignment: Alignment(x2, y2),
              child: _OrbWidget(
                color: GlassColors.gold, // Warm Gold
                size: size2,
                opacity: opacity2,
              ),
            ),
            // Orb 3 (Fuchsia Pink)
            Align(
              alignment: Alignment(x3, y3),
              child: _OrbWidget(
                color: const Color(0xFFEA4C89), // Fuchsia Pink
                size: size3,
                opacity: opacity3,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _OrbWidget extends StatelessWidget {
  final Color color;
  final double size;
  final double opacity;

  const _OrbWidget({
    required this.color,
    required this.size,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withOpacity(opacity),
            color.withOpacity(opacity * 0.55),
            color.withOpacity(opacity * 0.2),
            Colors.transparent,
          ],
          stops: const [0.0, 0.45, 0.75, 1.0],
        ),
      ),
    );
  }
}
