import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui';
import '../../services/auth_service.dart';
import '../theme/glass_theme.dart';
import '../common/glass_widgets.dart';

class LoginPage extends StatefulWidget {
  final bool isDark;
  const LoginPage({super.key, this.isDark = true});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late List<BackgroundStar> _bgStars;
  late List<GalaxyStar> _galaxyStars;
  late List<MidnightShootingStar> _shootingStars;
  late List<ConsoleSparkle> _consoleSparkles;
  late AnimationController _animationController;
  
  final int _bgStarsCount = 120;
  final int _galaxyStarsCount = 600;
  final int _sparklesCount = 15;

  @override
  void initState() {
    super.initState();
    _bgStars = _generateBackgroundStars(_bgStarsCount);
    _galaxyStars = _generateGalaxyStars(_galaxyStarsCount);
    _shootingStars = _generateShootingStars();
    _consoleSparkles = _generateConsoleSparkles(_sparklesCount);
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25), // Calm and smooth rotation speed
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<BackgroundStar> _generateBackgroundStars(int count) {
    final random = math.Random(2026);
    return List.generate(count, (index) {
      return BackgroundStar(
        xRatio: random.nextDouble(),
        yRatio: random.nextDouble() * 0.75,
        size: 0.5 + random.nextDouble() * 1.5,
        twinkleSpeed: 0.6 + random.nextDouble() * 1.4,
        phaseOffset: random.nextDouble() * 2 * math.pi,
      );
    });
  }

  List<GalaxyStar> _generateGalaxyStars(int count) {
    final random = math.Random(1337);
    const double maxRadius = 390.0;
    const int armsCount = 3;

    return List.generate(count, (index) {
      final armIndex = random.nextInt(armsCount);
      final double armAngle = armIndex * (2 * math.pi / armsCount);

      final double radius = math.pow(random.nextDouble(), 1.7) * maxRadius;
      
      const double spiralTightness = 3.6;
      final double twist = (radius / maxRadius) * spiralTightness;
      final double angleOffset = armAngle + twist + (random.nextDouble() - 0.5) * 0.45;

      final double size = random.nextDouble() * 2.3 + 0.4;
      final double normalizedRadius = radius / maxRadius;

      Color color;
      if (normalizedRadius < 0.12) {
        color = Color.lerp(
          const Color(0xFFFFFFFF),
          const Color(0xFFFFE0B2),
          random.nextDouble(),
        )!;
      } else if (normalizedRadius < 0.45) {
        color = Color.lerp(
          const Color(0xFFEA4C89),
          const Color(0xFF8A2BE2),
          random.nextDouble(),
        )!;
      } else {
        color = Color.lerp(
          const Color(0xFF00E5FF),
          const Color(0xFF1E3C72),
          random.nextDouble(),
        )!;
      }

      return GalaxyStar(
        distance: radius,
        angleOffset: angleOffset,
        size: size,
        color: color,
        twinkleOffset: random.nextDouble() * 2 * math.pi,
      );
    });
  }

  List<MidnightShootingStar> _generateShootingStars() {
    return [
      MidnightShootingStar(startX: 100, startY: 80, dx: -180, dy: 180, startOffset: 0.08, duration: 0.05),
      MidnightShootingStar(startX: 380, startY: 40, dx: -200, dy: 200, startOffset: 0.28, duration: 0.06),
      MidnightShootingStar(startX: 220, startY: 120, dx: -220, dy: 220, startOffset: 0.48, duration: 0.06),
      MidnightShootingStar(startX: 450, startY: 90, dx: -190, dy: 190, startOffset: 0.68, duration: 0.05),
      MidnightShootingStar(startX: 290, startY: 50, dx: -210, dy: 210, startOffset: 0.88, duration: 0.06),
    ];
  }

  List<ConsoleSparkle> _generateConsoleSparkles(int count) {
    final random = math.Random(99);
    return List.generate(count, (index) {
      return ConsoleSparkle(
        xRatio: 0.05 + random.nextDouble() * 0.9,
        yRatio: 0.05 + random.nextDouble() * 0.9,
        size: 2.5 + random.nextDouble() * 4.5,
        twinkleSpeed: 1.2 + random.nextDouble() * 1.8,
        phaseOffset: random.nextDouble() * 2 * math.pi,
      );
    });
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    try {
      final cred = await AuthService().signInWithGoogle();
      if (cred == null && mounted) {
        GlassNotifications.show(context, 'Login cancelled or failed', isError: true);
      }
    } catch (e) {
      if (mounted) {
        GlassNotifications.show(context, 'Login failed: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 800;

    return Scaffold(
      backgroundColor: const Color(0xFF080614), // Pure deep space dark
      body: isWide
          ? Row(
              children: [
                // Left Side: Beautiful unobstructed Midnight Galaxy Ocean scene (60% width)
                Expanded(
                  flex: 6,
                  child: Container(
                    color: Colors.transparent,
                    child: Stack(
                      children: [
                        // Midnight Galaxy Scene Canvas (stars centered in left pane)
                        Positioned.fill(
                          child: AnimatedBuilder(
                            animation: _animationController,
                            builder: (context, child) {
                              return CustomPaint(
                                painter: MidnightGalaxyOceanPainter(
                                  animationValue: _animationController.value,
                                  bgStars: _bgStars,
                                  galaxyStars: _galaxyStars,
                                  shootingStars: _shootingStars,
                                  sparkles: _consoleSparkles,
                                  centerXOffset: 0.0, // Centered in the left container
                                  centerYOffset: -20.0,
                                ),
                              );
                            },
                          ),
                        ),
                        
                        // Cyberpunk branding info overlays on the left side
                        Positioned(
                          left: 48,
                          top: 48,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD5B370).withOpacity(0.03),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: const Color(0xFFD5B370).withOpacity(0.15),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF00E5FF), // Cyber Cyan light
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'AETHER SECURE ACCESS LINK v2.4',
                                  style: GlassText.mono(9).copyWith(
                                    letterSpacing: 1.5,
                                    color: const Color(0xFFD5B370),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        Positioned(
                          left: 48,
                          bottom: 120, // Sit above the ocean waves
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'VAULTTASK',
                                style: GlassText.headline().copyWith(
                                  fontSize: 48,
                                  letterSpacing: 14,
                                  fontWeight: FontWeight.w100,
                                  color: const Color(0xFFF4EFDF),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'YOUR AI EXECUTIVE ASSISTANT',
                                style: GlassText.label().copyWith(
                                  letterSpacing: 4.0,
                                  color: const Color(0xFFD5B370).withOpacity(0.7),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Right Side: High-Tech Matte Navy Console Panel with grid pattern (40% width)
                Expanded(
                  flex: 4,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF0F1B35), // Saturated deep steel-navy (very distinct from black space)
                          Color(0xFF060B18), // Deep matte navy-black base
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Symmetrical thin cyberpunk grid texture in background
                        Positioned.fill(
                          child: CustomPaint(
                            painter: ConsoleGridPainter(),
                          ),
                        ),
                        
                        // Crisper gold/bronze vertical divider highlight line
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          child: Container(
                            width: 1.8,
                            color: const Color(0xFFD5B370).withOpacity(0.16),
                          ),
                        ),

                        // Redesigned Ultra-Premium Glassmorphic Login Card
                        Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(40),
                            child: PremiumGlassmorphicCard(
                              radius: 28,
                              child: Container(
                                constraints: const BoxConstraints(maxWidth: 320),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Brand Title
                                    Text(
                                      'VAULTTASK',
                                      style: GlassText.headline().copyWith(
                                        fontSize: 32,
                                        letterSpacing: 10,
                                        fontWeight: FontWeight.w200,
                                        color: const Color(0xFFF4EFDF),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'EXECUTIVE AI PORTAL',
                                      style: GlassText.label().copyWith(
                                        letterSpacing: 3.0,
                                        color: const Color(0xFFD5B370).withOpacity(0.6),
                                        fontSize: 9,
                                      ),
                                    ),
                                    
                                    // Symmetrical Hairline Divider
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 24),
                                      child: Divider(
                                        color: Colors.white.withOpacity(0.08),
                                        thickness: 1,
                                      ),
                                    ),
                                    
                                    // Symmetrical connection status dot
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF34D399), // Neon success green
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'SECURE CONNECTION ESTABLISHED',
                                          style: GlassText.mono(8.0).copyWith(
                                            letterSpacing: 1.0,
                                            color: const Color(0xFF34D399).withOpacity(0.9),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 28),

                                    _isLoading
                                      ? const CircularProgressIndicator(color: Color(0xFFD5B370))
                                      : GlassButton(
                                          label: 'CONTINUE WITH GOOGLE',
                                          width: double.infinity,
                                          isDark: widget.isDark,
                                          isGold: true,
                                          onPressed: _handleGoogleLogin,
                                        ),
                                    
                                    const SizedBox(height: 36),
                                    Text(
                                      'STRICTLY FOR EXECUTIVE USE',
                                      style: GlassText.label().copyWith(
                                        fontSize: 8.5,
                                        color: const Color(0xFF5A6D8A),
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'SESSION AES-256 KEY ENCRYPTED',
                                      style: GlassText.mono(7.5).copyWith(
                                        color: const Color(0xFF5A6D8A).withOpacity(0.6),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : Stack(
              children: [
                // Mobile layout: Draw full-screen Midnight Galaxy Scene
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: MidnightGalaxyOceanPainter(
                          animationValue: _animationController.value,
                          bgStars: _bgStars,
                          galaxyStars: _galaxyStars,
                          shootingStars: _shootingStars,
                          sparkles: _consoleSparkles,
                          centerXOffset: 0.0,
                          centerYOffset: -120.0,
                        ),
                      );
                    },
                  ),
                ),
                
                // Lower section: Scrollable content with redesigned glass card at the bottom
                Positioned.fill(
                  child: Column(
                    children: [
                      // Space holder to let the galaxy core show freely in upper screen
                      SizedBox(height: size.height * 0.32),
                      
                      // Bottom card content
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                          child: PremiumGlassmorphicCard(
                            radius: 24,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 320),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'VAULTTASK',
                                    style: GlassText.headline().copyWith(
                                      fontSize: 32,
                                      letterSpacing: 10,
                                      fontWeight: FontWeight.w200,
                                      color: const Color(0xFFF4EFDF),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'EXECUTIVE AI PORTAL',
                                    style: GlassText.label().copyWith(
                                      letterSpacing: 3.0,
                                      color: const Color(0xFFD5B370).withOpacity(0.6),
                                      fontSize: 9,
                                    ),
                                  ),

                                  // Symmetrical Hairline Divider
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 20),
                                    child: Divider(
                                      color: Colors.white.withOpacity(0.08),
                                      thickness: 1,
                                    ),
                                  ),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 5,
                                        height: 5,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF34D399),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'SECURE CONNECTION ESTABLISHED',
                                        style: GlassText.mono(7.5).copyWith(
                                          letterSpacing: 0.8,
                                          color: const Color(0xFF34D399).withOpacity(0.9),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),

                                  _isLoading
                                    ? const CircularProgressIndicator(color: Color(0xFFD5B370))
                                    : GlassButton(
                                        label: 'CONTINUE WITH GOOGLE',
                                        width: double.infinity,
                                        isDark: widget.isDark,
                                        isGold: true,
                                        onPressed: _handleGoogleLogin,
                                      ),
                                  
                                  const SizedBox(height: 28),
                                  Text(
                                    'STRICTLY FOR EXECUTIVE USE',
                                    style: GlassText.label().copyWith(
                                      fontSize: 8,
                                      color: const Color(0xFF5A6D8A),
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class BackgroundStar {
  final double xRatio;
  final double yRatio;
  final double size;
  final double twinkleSpeed;
  final double phaseOffset;

  BackgroundStar({
    required this.xRatio,
    required this.yRatio,
    required this.size,
    required this.twinkleSpeed,
    required this.phaseOffset,
  });
}

class GalaxyStar {
  final double distance;
  final double angleOffset;
  final double size;
  final Color color;
  final double twinkleOffset;

  GalaxyStar({
    required this.distance,
    required this.angleOffset,
    required this.size,
    required this.color,
    required this.twinkleOffset,
  });
}

class MidnightShootingStar {
  final double startX;
  final double startY;
  final double dx;
  final double dy;
  final double startOffset;
  final double duration;

  MidnightShootingStar({
    required this.startX,
    required this.startY,
    required this.dx,
    required this.dy,
    required this.startOffset,
    required this.duration,
  });
}

class ConsoleSparkle {
  final double xRatio;
  final double yRatio;
  final double size;
  final double twinkleSpeed;
  final double phaseOffset;

  ConsoleSparkle({
    required this.xRatio,
    required this.yRatio,
    required this.size,
    required this.twinkleSpeed,
    required this.phaseOffset,
  });
}

class PremiumGlassmorphicCard extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;

  const PremiumGlassmorphicCard({
    super.key,
    required this.child,
    this.radius = 28.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          // Soft ambient drop shadow
          BoxShadow(
            color: Colors.black.withOpacity(0.42),
            blurRadius: 36,
            spreadRadius: 2,
            offset: const Offset(0, 16),
          ),
          // Subtle glowing rim shadow
          BoxShadow(
            color: const Color(0xFFB8A2F2).withOpacity(0.04),
            blurRadius: 40,
            spreadRadius: -4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.07),
                  Colors.white.withOpacity(0.015),
                  const Color(0xFFB8A2F2).withOpacity(0.02),
                ],
                stops: const [0.0, 0.75, 1.0],
              ),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: Colors.white.withOpacity(0.12),
                width: 1.2,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class MidnightGalaxyOceanPainter extends CustomPainter {
  final double animationValue;
  final List<BackgroundStar> bgStars;
  final List<GalaxyStar> galaxyStars;
  final List<MidnightShootingStar> shootingStars;
  final List<ConsoleSparkle> sparkles;
  final double centerXOffset;
  final double centerYOffset;

  MidnightGalaxyOceanPainter({
    required this.animationValue,
    required this.bgStars,
    required this.galaxyStars,
    required this.shootingStars,
    required this.sparkles,
    this.centerXOffset = 0.0,
    this.centerYOffset = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2 + centerXOffset;
    final centerY = size.height / 2 + centerYOffset;

    // 1. Draw pure Midnight/Black background canvas matching the dashboard's dark space feel
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final bgPaint = Paint()..color = const Color(0xFF080614);
    canvas.drawRect(rect, bgPaint);

    final galaxyCenter = Offset(centerX, centerY);

    // 2. Draw central cosmic nebula glow (High-saturation, exactly matching GalaxyPainter from dashboard)
    final radialPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF140D36).withOpacity(0.95), // Deep dark indigo purple
          const Color(0xFF0A071E).withOpacity(0.55),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: galaxyCenter, radius: size.width * 0.45));
    canvas.drawRect(rect, radialPaint);

    // 3. Draw high-saturation colorful nebula cloud layers for a vibrant glow
    // Fuchsia glow (Opacity raised to 0.48 for intense vibrant coloring, scaled up)
    final fuchsiaGlow = Paint()
      ..shader = RadialGradient(
        colors: [const Color(0xFFEA4C89).withOpacity(0.48), Colors.transparent],
      ).createShader(Rect.fromCircle(center: galaxyCenter, radius: 320));
    canvas.drawCircle(galaxyCenter, 320.0, fuchsiaGlow);

    // Cyan glow (Opacity raised to 0.42, scaled up)
    final cyanGlow = Paint()
      ..shader = RadialGradient(
        colors: [const Color(0xFF00E5FF).withOpacity(0.42), Colors.transparent],
      ).createShader(Rect.fromCircle(center: galaxyCenter + const Offset(-40, 20), radius: 270));
    canvas.drawCircle(galaxyCenter + const Offset(-40, 20), 270.0, cyanGlow);

    // Purple/Orchid glow (Opacity raised to 0.38, scaled up)
    final purpleGlow = Paint()
      ..shader = RadialGradient(
        colors: [const Color(0xFF8A2BE2).withOpacity(0.38), Colors.transparent],
      ).createShader(Rect.fromCircle(center: galaxyCenter + const Offset(30, -30), radius: 350));
    canvas.drawCircle(galaxyCenter + const Offset(30, -30), 350.0, purpleGlow);

    // 4. Draw Twinkling Background Stars (120 particles)
    final starPaint = Paint()..style = PaintingStyle.fill;
    for (final star in bgStars) {
      final screenX = star.xRatio * size.width;
      final screenY = star.yRatio * size.height;
      
      final double progress = animationValue * 2 * math.pi * star.twinkleSpeed + star.phaseOffset;
      final double opacity = 0.2 + (math.sin(progress) + 1.0) * 0.35;
      
      starPaint.color = const Color(0xFFF4EFDF).withOpacity(opacity.clamp(0.0, 1.0));
      canvas.drawCircle(Offset(screenX, screenY), star.size, starPaint);
    }

    // 5. Draw Swirling Galaxy Stars (600 particles with vibrant core-arms colors, scaled up)
    for (final star in galaxyStars) {
      final double speedMultiplier = 0.4 + (100.0 / (star.distance + 50.0));
      final double currentAngle = star.angleOffset + (animationValue * 2 * math.pi * 0.05 * speedMultiplier);

      final double x = galaxyCenter.dx + star.distance * math.cos(currentAngle);
      final double y = galaxyCenter.dy + star.distance * math.sin(currentAngle) * 0.52;

      final double twinkleProgress = animationValue * 2 * math.pi * 1.2 + star.twinkleOffset;
      final double opacity = 0.35 + (math.sin(twinkleProgress) + 1.0) * 0.4;

      starPaint.color = star.color.withOpacity((star.color.opacity * opacity).clamp(0.0, 1.0));

      if (star.size > 1.9) {
        final glowPaint = Paint()
          ..color = star.color.withOpacity(0.18 * opacity)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x, y), star.size * 2.6, glowPaint);
      }

      canvas.drawCircle(Offset(x, y), star.size, starPaint);
    }

    // Glowing Galaxy Core Center (Bright white-gold core, matching dashboard, scaled up)
    for (int i = 3; i > 0; i--) {
      final corePaint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFFFFF).withOpacity(0.72),
            const Color(0xFFFF77FF).withOpacity(0.24),
            const Color(0xFF673AB7).withOpacity(0.04),
            Colors.transparent,
          ],
          stops: const [0.0, 0.25, 0.6, 1.0],
        ).createShader(Rect.fromCircle(center: galaxyCenter, radius: i * 35));
      canvas.drawCircle(galaxyCenter, i * 35.0, corePaint);
    }

    // 6. Draw Shooting Stars (ดาวตก)
    for (final star in shootingStars) {
      final double trigger = star.startOffset;
      final double dur = star.duration;
      if (animationValue >= trigger && animationValue <= trigger + dur) {
        final double t = (animationValue - trigger) / dur;
        
        final double currentX = star.startX + t * star.dx;
        final double currentY = star.startY + t * star.dy;
        
        final double tailX = currentX - star.dx * 0.22;
        final double tailY = currentY - star.dy * 0.22;
        
        final lineShader = LinearGradient(
          colors: [
            Colors.white.withOpacity(0.95 * (1.0 - t)),
            const Color(0xFF00E5FF).withOpacity(0.45 * (1.0 - t)),
            Colors.transparent,
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(Rect.fromPoints(Offset(currentX, currentY), Offset(tailX, tailY)));
        
        final trailPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round
          ..shader = lineShader;
          
        canvas.drawLine(Offset(tailX, tailY), Offset(currentX, currentY), trailPaint);
      }
    }

    // 7. Draw Twinkling/Floating Sparkles (cross lens flares)
    for (final sparkle in sparkles) {
      final double screenX = sparkle.xRatio * size.width;
      final double floatY = math.sin(animationValue * 2 * math.pi * 0.5 + sparkle.phaseOffset) * 10.0;
      final double screenY = sparkle.yRatio * size.height + floatY;

      final double progress = animationValue * 2 * math.pi * sparkle.twinkleSpeed + sparkle.phaseOffset;
      final double opacity = 0.15 + (math.sin(progress) + 1.0) * 0.45;

      _drawSparkle(
        canvas,
        Offset(screenX, screenY),
        sparkle.size,
        const Color(0xFFFFD580),
        opacity.clamp(0.0, 1.0),
      );
    }

    // 8. Draw 3 layers of rolling Ocean Waves at the bottom of the canvas
    _drawWave(
      canvas: canvas,
      width: size.width,
      height: size.height,
      amplitude: 12.0,
      wavelength: 240.0,
      phase: animationValue * 2 * math.pi,
      color: const Color(0xFF11284D).withOpacity(0.55),
      baselineY: size.height - 65,
    );

    _drawWave(
      canvas: canvas,
      width: size.width,
      height: size.height,
      amplitude: 18.0,
      wavelength: 340.0,
      phase: -animationValue * 1.4 * math.pi + 1.2,
      color: const Color(0xFF17315C).withOpacity(0.7),
      baselineY: size.height - 45,
    );

    _drawWave(
      canvas: canvas,
      width: size.width,
      height: size.height,
      amplitude: 14.0,
      wavelength: 280.0,
      phase: animationValue * 1.1 * math.pi + 2.4,
      color: const Color(0xFF264B6F).withOpacity(0.85),
      baselineY: size.height - 25,
    );
  }

  void _drawSparkle(Canvas canvas, Offset center, double size, Color color, double opacity) {
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.fill;
      
    final path = Path();
    path.moveTo(center.dx, center.dy - size);
    path.quadraticBezierTo(center.dx, center.dy, center.dx + size, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + size);
    path.quadraticBezierTo(center.dx, center.dy, center.dx - size, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - size);
    path.close();
    
    canvas.drawPath(path, paint);
  }

  void _drawWave({
    required Canvas canvas,
    required double width,
    required double height,
    required double amplitude,
    required double wavelength,
    required double phase,
    required Color color,
    required double baselineY,
  }) {
    final wavePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
      
    final path = Path();
    path.moveTo(0, baselineY);
    
    for (double x = 0; x <= width; x += 4) {
      final double y = baselineY + amplitude * math.sin((x / wavelength) * 2 * math.pi + phase);
      path.lineTo(x, y);
    }
    
    path.lineTo(width, height);
    path.lineTo(0, height);
    path.close();
    
    canvas.drawPath(path, wavePaint);
  }

  @override
  bool shouldRepaint(covariant MidnightGalaxyOceanPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

class ConsoleGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00E5FF).withOpacity(0.025) // Very faint cyber cyan grid lines
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
      
    const double gridSize = 32.0;

    // Draw vertical grid lines
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw horizontal grid lines
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
