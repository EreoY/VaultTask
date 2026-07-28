import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/glass_theme.dart';
import '../chat/widgets/aether_chat_view.dart';
import 'responsive_layout.dart';

class FloatingAssistantShell extends StatefulWidget {
  const FloatingAssistantShell({super.key});

  @override
  State<FloatingAssistantShell> createState() => _FloatingAssistantShellState();
}

class _FloatingAssistantShellState extends State<FloatingAssistantShell> {
  // 📍 Position & State
  Offset _headPosition = const Offset(0, 150);
  Offset _panelPosition = const Offset(0, 0);
  bool _isExpanded = false;
  bool _isHeadDragging = false;
  bool _isPanelDragging = false;
  bool _isResizing = false;
  bool _initialized = false;

  // 📏 Dynamic Dimensions
  double _panelWidth = 360;
  double _panelHeight = 550;
  final double _headSize = 54;

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _panelWidth = prefs.getDouble('aether_panel_width') ?? 360;
        _panelHeight = prefs.getDouble('aether_panel_height') ?? 550;
        final dx = prefs.getDouble('aether_head_x');
        final dy = prefs.getDouble('aether_head_y');
        if (dx != null && dy != null) {
          _headPosition = Offset(dx, dy);
        }
      });
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('aether_panel_width', _panelWidth);
    await prefs.setDouble('aether_panel_height', _panelHeight);
    await prefs.setDouble('aether_head_x', _headPosition.dx);
    await prefs.setDouble('aether_head_y', _headPosition.dy);
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _onHeadPanUpdate(DragUpdateDetails details, BoxConstraints constraints) {
    if (_isExpanded) return;
    setState(() {
      _isHeadDragging = true;
      _headPosition += details.delta;
    });
  }

  void _onHeadPanEnd(DragEndDetails details, BoxConstraints constraints) {
    if (_isExpanded) return;
    setState(() {
      _isHeadDragging = false;
      // 🚀 Fix: Ensure draggability on mobile with screen clamping
      double targetX = _headPosition.dx < (constraints.maxWidth / 2)
          ? 20
          : constraints.maxWidth - _headSize - 20;
      double targetY = _headPosition.dy.clamp(
        60,
        constraints.maxHeight - _headSize - 100,
      );
      _headPosition = Offset(targetX, targetY);
      _saveSettings();
    });
  }

  void _onPanelPanUpdate(DragUpdateDetails details) {
    setState(() {
      _isPanelDragging = true;
      _panelPosition += details.delta;
    });
  }

  void _onResizeUpdate(DragUpdateDetails details) {
    setState(() {
      _isResizing = true;
      _panelWidth = (_panelWidth + details.delta.dx).clamp(300, 600);
      _panelHeight = (_panelHeight + details.delta.dy).clamp(400, 800);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = Responsive.isMobile(context);

        if (constraints.maxWidth > 0 && !isMobile) {
          if (_panelWidth > constraints.maxWidth * 0.9)
            _panelWidth = constraints.maxWidth * 0.85;
          if (_panelHeight > constraints.maxHeight * 0.9)
            _panelHeight = constraints.maxHeight * 0.85;

          if (_headPosition.dx > constraints.maxWidth - _headSize) {
            _headPosition = Offset(
              constraints.maxWidth - _headSize - 20,
              _headPosition.dy,
            );
          }
          if (_headPosition.dy > constraints.maxHeight - _headSize) {
            _headPosition = Offset(
              _headPosition.dx,
              constraints.maxHeight - _headSize - 60,
            );
          }
        }

        if (!_initialized && constraints.maxWidth > 0) {
          if (isMobile) {
            _headPosition = Offset(
              constraints.maxWidth - _headSize - 20,
              constraints.maxHeight - _headSize - 120,
            );
          } else {
            _headPosition = Offset(
              constraints.maxWidth - _headSize - 20,
              constraints.maxHeight * 0.3,
            );
            _panelPosition = Offset(
              (constraints.maxWidth - _panelWidth) / 2,
              (constraints.maxHeight - _panelHeight) / 2,
            );
          }
          _initialized = true;
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // 🎭 1. Messenger-Style Chat Panel
            if (_isExpanded)
              isMobile
                  ? Positioned.fill(child: _buildMessengerExpandedUI())
                  : Positioned(
                      left: _panelPosition.dx,
                      top: _panelPosition.dy,
                      child: _buildExpandedPanel(isMobile: false),
                    ),

            // 🔘 2. Draggable Chat Head
            // On mobile expanded, it stays at top-right (Messenger Style)
            AnimatedPositioned(
              duration: _isHeadDragging
                  ? Duration.zero
                  : const Duration(milliseconds: 400),
              curve: Curves.easeOutBack,
              left: (isMobile && _isExpanded)
                  ? constraints.maxWidth - _headSize - 20
                  : _headPosition.dx,
              top: (isMobile && _isExpanded) ? 20 : _headPosition.dy,
              child: GestureDetector(
                onPanUpdate: (d) => _onHeadPanUpdate(d, constraints),
                onPanEnd: (d) => _onHeadPanEnd(d, constraints),
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                child: _buildChatHead(isSmall: isMobile && _isExpanded),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMessengerExpandedUI() {
    return Stack(
      children: [
        // Background Peek (Dark Overlay)
        GestureDetector(
          onTap: () => setState(() => _isExpanded = false),
          child: Container(color: Colors.black.withOpacity(0.5)),
        ),

        // Main Chat Content
        Padding(
          padding: const EdgeInsets.only(top: 80), // Messenger style top offset
          child: Container(
            decoration: const BoxDecoration(
              color: GlassColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    color: GlassColors.surfaceHighest.withOpacity(0.1),
                    border: Border(
                      bottom: BorderSide(
                        color: GlassColors.ghostBorder,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        color: GlassColors.gold,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'SATURN',
                        style: GlassText.labelSM().copyWith(
                          letterSpacing: 2.0,
                          color: GlassColors.gold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(child: AetherChatView(isDark: true, isFloating: true)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChatHead({bool isSmall = false}) {
    final size = isSmall ? _headSize * 0.8 : _headSize;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: SaturnIcon(size: size),
    );
  }

  Widget _buildExpandedPanel({required bool isMobile}) {
    return Container(
      width: isMobile ? null : _panelWidth,
      height: isMobile ? null : _panelHeight,
      decoration: BoxDecoration(
        color: GlassColors.background,
        borderRadius: BorderRadius.circular(isMobile ? 0 : 24),
        border: isMobile
            ? null
            : Border.all(color: GlassColors.gold.withOpacity(0.2), width: 1.2),
        boxShadow: isMobile
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 60,
                  spreadRadius: 5,
                ),
              ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Column(
            children: [
              GestureDetector(
                onPanUpdate: isMobile ? null : _onPanelPanUpdate,
                onPanEnd: (d) => setState(() => _isPanelDragging = false),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: isMobile ? 16 : 12,
                  ),
                  decoration: BoxDecoration(
                    color: GlassColors.surfaceHighest.withOpacity(0.2),
                    border: Border(
                      bottom: BorderSide(
                        color: GlassColors.ghostBorder,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.auto_awesome_rounded,
                            color: GlassColors.gold,
                            size: 16,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'SATURN',
                            style: GlassText.labelSM().copyWith(
                              letterSpacing: 1.5,
                              color: GlassColors.gold,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          isMobile
                              ? Icons.close_rounded
                              : Icons.close_fullscreen_rounded,
                          size: 22,
                          color: GlassColors.onSurfaceVariant,
                        ),
                        onPressed: () => setState(() => _isExpanded = false),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(child: AetherChatView(isDark: true, isFloating: true)),
            ],
          ),
          if (!isMobile)
            Positioned(
              right: 0,
              bottom: 0,
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeDownRight,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanUpdate: _onResizeUpdate,
                  onPanEnd: (d) {
                    setState(() => _isResizing = false);
                    _saveSettings();
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    padding: const EdgeInsets.all(8),
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: GlassColors.gold.withOpacity(0.1),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomRight: Radius.circular(16),
                          ),
                        ),
                        child: Icon(
                          Icons.south_east_rounded,
                          size: 18,
                          color: GlassColors.gold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class SaturnIcon extends StatefulWidget {
  final double size;
  const SaturnIcon({super.key, this.size = 54});

  @override
  State<SaturnIcon> createState() => _SaturnIconState();
}

class _SaturnIconState extends State<SaturnIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // 6-second slow animation loop for rocking and pulsing
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
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

        // Rocking/swaying rotation angle (radians)
        final swayAngle = math.sin(t * pi2) * 0.14; // -8 to +8 degrees

        // Ring opening aspect ratio (ry / rx)
        // Animates between 0.33 and 0.41 to simulate 3D tilt pulsing
        final ringOpening = 0.37 + math.cos(t * pi2) * 0.04;

        // Glow pulse value (between 0.85 and 1.15)
        final pulseValue = 1.0 + math.sin(t * pi2 * 2) * 0.15;

        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: SaturnPainter(
            swayAngle: swayAngle,
            ringOpening: ringOpening,
            pulseValue: pulseValue,
          ),
        );
      },
    );
  }
}

class SaturnPainter extends CustomPainter {
  final double swayAngle;
  final double ringOpening;
  final double pulseValue;

  SaturnPainter({
    required this.swayAngle,
    required this.ringOpening,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    
    // Saturn dimensions relative to custom widget size
    final double planetRadius = size.width * 0.25;
    final double ringRadiusX = size.width * 0.44;
    final double ringRadiusY = ringRadiusX * ringOpening;

    // Save canvas state to apply rotation for the sway
    canvas.save();
    canvas.translate(centerX, centerY);
    canvas.rotate(swayAngle);

    // 1. Draw outer neon glow behind Saturn
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF00E5FF).withOpacity(0.28 * pulseValue),
          const Color(0xFFEA4C89).withOpacity(0.12 * pulseValue),
          Colors.transparent,
        ],
        stops: const [0.0, 0.65, 1.0],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: size.width * 0.5));
    canvas.drawCircle(Offset.zero, size.width * 0.48, glowPaint);

    // 2. Draw BACK ring (semi-ellipse from 180 to 360 degrees)
    final ringRect = Rect.fromCenter(
      center: Offset.zero,
      width: ringRadiusX * 2,
      height: ringRadiusY * 2,
    );

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.085
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFFFD580), // Warm gold outer
          Color(0xFFEA4C89), // Fuchsia mid
          Color(0xFF00E5FF), // Cyan inner
        ],
        stops: [0.0, 0.55, 1.0],
      ).createShader(ringRect);

    // Top half of rings in rotated coordinate space: pi to 2*pi
    canvas.drawArc(ringRect, math.pi, math.pi, false, ringPaint);

    // Extra thin neon coordinate accent line on the ring for 3D HUD feel
    final thinRingPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
      
    final thinRingRect = Rect.fromCenter(
      center: Offset.zero,
      width: (ringRadiusX * 1.1) * 2,
      height: (ringRadiusY * 1.1) * 2,
    );
    thinRingPaint.shader = const LinearGradient(
      colors: [
        Color(0x7FFFFFFF),
        Color(0x1F00E5FF),
      ],
    ).createShader(thinRingRect);
    canvas.drawArc(thinRingRect, math.pi, math.pi, false, thinRingPaint);

    // 3. Draw Planet Sphere (Spherical Gradient)
    final planetPaint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0xFFFFD580), // Golden core
          Color(0xFFEA4C89), // Fuchsia shade
          Color(0xFF080614), // Dark space shadow
        ],
        stops: [0.0, 0.72, 1.0],
        center: Alignment(-0.25, -0.25), // Top-left light source
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: planetRadius));

    canvas.drawCircle(Offset.zero, planetRadius, planetPaint);

    // Draw atmospheric glow accent ring around planet
    final atmospherePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFF00E5FF).withOpacity(0.4);
    canvas.drawCircle(Offset.zero, planetRadius + 0.5, atmospherePaint);

    // 4. Draw FRONT ring (semi-ellipse from 0 to 180 degrees)
    // Bottom half of rings: 0 to pi
    canvas.drawArc(ringRect, 0, math.pi, false, ringPaint);
    canvas.drawArc(thinRingRect, 0, math.pi, false, thinRingPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant SaturnPainter oldDelegate) {
    return oldDelegate.swayAngle != swayAngle ||
        oldDelegate.ringOpening != ringOpening ||
        oldDelegate.pulseValue != pulseValue;
  }
}
