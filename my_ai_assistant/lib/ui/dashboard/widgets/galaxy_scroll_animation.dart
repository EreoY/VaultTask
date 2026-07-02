import 'dart:math' as math;
import 'package:flutter/material.dart';

class GalaxyStar {
  final double radius;      // Distance from galaxy core
  final double armAngle;    // Base spiral arm angle
  final double noiseX;      // Perturbation noise X
  final double noiseY;      // Perturbation noise Y
  final double noiseZ;      // Initial depth Z
  final double size;        // Base particle size
  final Color color;        // Cosmic color
  final double speedFactor; // Custom speed for depth flow

  GalaxyStar({
    required this.radius,
    required this.armAngle,
    required this.noiseX,
    required this.noiseY,
    required this.noiseZ,
    required this.size,
    required this.color,
    required this.speedFactor,
  });
}

class GalaxyScrollAnimation extends StatefulWidget {
  final double height;
  final Widget? child;

  const GalaxyScrollAnimation({
    super.key,
    this.height = 420,
    this.child,
  });

  @override
  State<GalaxyScrollAnimation> createState() => _GalaxyScrollAnimationState();
}

class _GalaxyScrollAnimationState extends State<GalaxyScrollAnimation>
    with SingleTickerProviderStateMixin {
  late List<GalaxyStar> _stars;
  late AnimationController _animationController;
  final int _starsCount = 800;

  // Gesture rotation & tilt state
  double _dragRotation = 0.0;
  double _dragTilt = 0.52;      // Default viewing tilt (approx 30 degrees)
  double _dragVelocity = 0.0;   // Spin inertia velocity
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _stars = _generateStars(_starsCount);

    // Continuous ticker for automatic slow rotation, forward flow, and drag physics update
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();

    _animationController.addListener(_onFrameTick);
  }

  @override
  void dispose() {
    _animationController.removeListener(_onFrameTick);
    _animationController.dispose();
    super.dispose();
  }

  void _onFrameTick() {
    if (!mounted) return;

    if (!_isDragging) {
      if (_dragVelocity.abs() > 0.0001) {
        setState(() {
          _dragRotation += _dragVelocity;
          _dragVelocity *= 0.95; // Physics Damping (5% decay per frame)
        });
      } else {
        // Slow constant automatic idle drift when no active drag or momentum
        setState(() {
          _dragRotation += 0.0005;
        });
      }
    }
  }

  List<GalaxyStar> _generateStars(int count) {
    final random = math.Random(1337);
    final List<GalaxyStar> list = [];
    const armsCount = 3;
    const maxRadius = 260.0;

    for (int i = 0; i < count; i++) {
      final armIndex = random.nextInt(armsCount);
      final armAngle = armIndex * (2 * math.pi / armsCount);
      final radius = math.pow(random.nextDouble(), 1.7) * maxRadius;

      final noiseX = (random.nextDouble() - 0.5) * 45.0;
      final noiseY = (random.nextDouble() - 0.5) * 45.0;
      final noiseZ = random.nextDouble() * 1000.0; // Depth coordinate

      final size = random.nextDouble() * 2.3 + 0.4;
      final speedFactor = 0.7 + random.nextDouble() * 0.5;

      Color color;
      final normalizedRadius = radius / maxRadius;

      if (normalizedRadius < 0.12) {
        // Star Core: White-Gold
        color = Color.lerp(
          const Color(0xFFFFFFFF),
          const Color(0xFFFFE0B2),
          random.nextDouble(),
        )!;
      } else if (normalizedRadius < 0.45) {
        // Inner arms: Fuchsia / Purple / Orchid
        color = Color.lerp(
          const Color(0xFFEA4C89),
          const Color(0xFF8A2BE2),
          random.nextDouble(),
        )!;
      } else {
        // Outer arms: Electric Cyan / Nebula Blue
        color = Color.lerp(
          const Color(0xFF00E5FF),
          const Color(0xFF1E3C72),
          random.nextDouble(),
        )!;
      }

      list.add(GalaxyStar(
        radius: radius,
        armAngle: armAngle,
        noiseX: noiseX,
        noiseY: noiseY,
        noiseZ: noiseZ,
        size: size,
        color: color,
        speedFactor: speedFactor,
      ));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanDown: (_) {
        setState(() {
          _isDragging = true;
          _dragVelocity = 0.0;
        });
      },
      onPanUpdate: (details) {
        setState(() {
          // Horizontal drag rotates the galaxy around Y-axis
          _dragRotation += details.delta.dx * 0.007;
          // Vertical drag tilts the galaxy viewing angle (pitch)
          _dragTilt = (_dragTilt - details.delta.dy * 0.004).clamp(0.1, 1.4);
        });
      },
      onPanEnd: (details) {
        setState(() {
          _isDragging = false;
          // Convert drag speed into drag velocity for physics momentum
          _dragVelocity = details.velocity.pixelsPerSecond.dx * 0.000035;
        });
      },
      child: Container(
        height: widget.height,
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFF080614).withOpacity(0.65), // Galaxy dark canvas tint
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFB8A2F2).withOpacity(0.08)),
        ),
        child: Stack(
          children: [
            // 3D Starfield Custom Paint Canvas
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return CustomPaint(
                  size: Size(double.infinity, widget.height),
                  painter: GalaxyPainter(
                    timeProgress: _animationController.value,
                    dragRotation: _dragRotation,
                    dragTilt: _dragTilt,
                    stars: _stars,
                  ),
                );
              },
            ),

            // Main child content overlay (Text, buttons, custom widgets)
            if (widget.child != null)
              Positioned.fill(
                child: widget.child!,
              ),
          ],
        ),
      ),
    );
  }
}

class GalaxyPainter extends CustomPainter {
  final double timeProgress;
  final double dragRotation;
  final double dragTilt;
  final List<GalaxyStar> stars;

  GalaxyPainter({
    required this.timeProgress,
    required this.dragRotation,
    required this.dragTilt,
    required this.stars,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final center = Offset(centerX, centerY);

    // 1. Central cosmic nebula glow
    final radialPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF140D36).withOpacity(0.9),
          const Color(0xFF0A071E).withOpacity(0.45),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.45));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), radialPaint);

    // 2. Cosmic core glow (galaxy black hole core)
    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFFFFF).withOpacity(0.7),
          const Color(0xFFFF77FF).withOpacity(0.22),
          const Color(0xFF673AB7).withOpacity(0.04),
          Colors.transparent,
        ],
        stops: const [0.0, 0.25, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: 140));
    canvas.drawCircle(center, 130, corePaint);

    // 3. Project stars (3D flight and rotation)
    const double fov = 480.0;
    final List<MapEntry<GalaxyStar, double>> depthSortedStars = [];

    // Calculate time-based continuous forward motion along Z depth (0.0 to 1000.0)
    final double timeZ = timeProgress * 1000.0;

    for (final star in stars) {
      double relativeZ = (star.noiseZ - timeZ * 0.4 * star.speedFactor) % 1000.0;
      if (relativeZ < 0) {
        relativeZ += 1000.0;
      }
      depthSortedStars.add(MapEntry(star, relativeZ));
    }

    // Sort: draw furthest stars first
    depthSortedStars.sort((a, b) => b.value.compareTo(a.value));

    final starPaint = Paint()..style = PaintingStyle.fill;

    for (final entry in depthSortedStars) {
      final star = entry.key;
      final z = entry.value;

      // Calculate twisting spiral arms
      const spiralTightness = 3.6;
      final double twist = (star.radius / 260.0) * spiralTightness;
      final double finalAngle = star.armAngle + twist + dragRotation;

      // Base 3D coordinates relative to galaxy center
      double x3d = star.radius * math.cos(finalAngle) + star.noiseX;
      double y3d = star.radius * math.sin(finalAngle) + star.noiseY;

      // Apply perspective tilt (pitch) rotation around X-axis
      double rotY = y3d * math.cos(dragTilt) - x3d * math.sin(dragTilt) * 0.22;
      double rotX = x3d;

      // 3D perspective projection scale
      final double depthScale = fov / (z + 75.0);

      // Map to 2D screen coordinates
      final double screenX = centerX + rotX * depthScale;
      final double screenY = centerY + rotY * depthScale;

      // Performance optimization: skip stars that are off-screen
      if (screenX < -15 || screenX > size.width + 15 || screenY < -15 || screenY > size.height + 15) {
        continue;
      }

      // Draw size depends on distance (larger when closer)
      final double drawSize = star.size * (depthScale * 1.6).clamp(0.2, 5.5);

      // Fade-in at distance, fade-out when passing the camera
      double opacity = 1.0;
      if (z < 120) {
        opacity = (z - 25) / 95.0;
      } else if (z > 780) {
        opacity = (1000.0 - z) / 220.0;
      }
      opacity = opacity.clamp(0.0, 1.0);

      if (opacity <= 0.0) continue;

      starPaint.color = star.color.withOpacity(star.color.opacity * opacity);

      // Glow halo for larger bright stars
      if (star.size > 1.9 && opacity > 0.45) {
        final glowPaint = Paint()
          ..color = star.color.withOpacity(0.14 * opacity)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(screenX, screenY), drawSize * 2.6, glowPaint);
      }

      canvas.drawCircle(Offset(screenX, screenY), drawSize, starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant GalaxyPainter oldDelegate) {
    return oldDelegate.timeProgress != timeProgress ||
        oldDelegate.dragRotation != dragRotation ||
        oldDelegate.dragTilt != dragTilt;
  }
}
