import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../theme/glass_theme.dart';

/// Aether AI Refined Glassmorphism Widgets

class GlassContainer extends StatelessWidget {
  final Widget child;
  final bool isDark;
  final double? radius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BoxDecoration? decoration;
  final double blur;

  const GlassContainer({
    super.key,
    required this.child,
    required this.isDark,
    this.radius,
    this.padding,
    this.margin,
    this.decoration,
    this.blur = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    final hasBlur = blur > 0.0 && GlassColors.glassSurface.opacity < 1.0;
    Widget container = Container(
      margin: margin,
      padding: padding,
      decoration: decoration ?? GlassDecorations.surface(isDark: isDark, radius: radius ?? ExecutiveRadius.l),
      child: child,
    );

    if (hasBlur) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius ?? ExecutiveRadius.l),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: container,
        ),
      );
    } else {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius ?? ExecutiveRadius.l),
        child: container,
      );
    }
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final bool isDark;
  final double? radius;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final bool elevated;
  final bool hasAmbientGlow;

  const GlassCard({
    super.key,
    required this.child,
    required this.isDark,
    this.radius,
    this.padding,
    this.onTap,
    this.elevated = false,
    this.hasAmbientGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = GlassContainer(
      isDark: isDark,
      radius: radius ?? ExecutiveRadius.l,
      padding: padding ?? EdgeInsets.all(ExecutiveSpacing.m),

      decoration: elevated 
        ? GlassDecorations.elevated(isDark: isDark, radius: radius ?? ExecutiveRadius.l)
        : null,
      child: Stack(
        children: [
          if (hasAmbientGlow)
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: GlassColors.primary.withOpacity(0.05),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                  child: const SizedBox.shrink(),
                ),
              ),
            ),
          child,
        ],
      ),
    );

    if (onTap != null) {
      content = MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: content,
        ),
      );
    }

    return content;
  }
}

class GlassButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isDark;
  final bool isGold;
  final double? width;

  const GlassButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    required this.isDark,
    this.isGold = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final Color contentColor = isGold ? GlassColors.gold : GlassColors.primary;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: width,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: GlassDecorations.button(isDark: isDark, isGold: isGold),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: contentColor, size: 18),
                const SizedBox(width: 10),
              ],
              Text(
                label.toUpperCase(),
                style: GlassText.label(isDark).copyWith(
                  color: contentColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isDark;
  final double size;

  const GlassIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    required this.isDark,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onPressed,
        child: GlassContainer(
          isDark: isDark,
          radius: size / 2,
          blur: 16,
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            child: Icon(icon, color: GlassColors.onSurfaceVariant, size: size * 0.45),
          ),
        ),
      ),
    );
  }
}

class BentoCard extends StatelessWidget {
  final Widget child;
  final String? title;
  final IconData? icon;
  final bool isDark;

  const BentoCard({
    super.key,
    required this.child,
    this.title,
    this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      isDark: isDark,
      hasAmbientGlow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: GlassColors.primary, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(title!.toUpperCase(), style: GlassText.label(isDark)),
              ],
            ),
            SizedBox(height: ExecutiveSpacing.m),
            ],
            child,
            ],
            ),
            );
            }
            }



class GlassBottomBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final List<GlassBottomBarItem> items;
  final bool isDark;

  const GlassBottomBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.items,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72 + MediaQuery.of(context).padding.bottom,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: GlassColors.background.withOpacity(0.4),
        border: Border(
          top: BorderSide(color: GlassColors.ghostBorder, width: 1.0),
        ),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isActive = selectedIndex == index;

              return Expanded(
                child: InkWell(
                  onTap: () => onItemSelected(index),
                  child: Center(
                    child: Icon(
                      item.icon,
                      color: isActive
                          ? GlassColors.primary
                          : GlassColors.onSurfaceVariant.withOpacity(0.6),
                      size: 26,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class GlassBottomBarItem {
  final IconData icon;
  final String label;

  const GlassBottomBarItem({
    required this.icon,
    required this.label,
  });
}

class GlassNotificationWidget extends StatefulWidget {
  final String message;
  final bool isError;
  final VoidCallback onDismiss;

  const GlassNotificationWidget({
    super.key,
    required this.message,
    required this.isError,
    required this.onDismiss,
  });

  @override
  State<GlassNotificationWidget> createState() => _GlassNotificationWidgetState();
}

class _GlassNotificationWidgetState extends State<GlassNotificationWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    // Auto dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _controller.reverse().then((_) {
          if (mounted) widget.onDismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return SafeArea(
      child: Align(
        alignment: isMobile ? Alignment.topCenter : Alignment.topRight,
        child: Padding(
          padding: EdgeInsets.only(
            top: 24,
            left: isMobile ? 24 : 0,
            right: 24,
          ),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Material(
                color: Colors.transparent,
                child: GlassContainer(
                  isDark: true,
                  radius: 12,
                  blur: 16,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: GlassColors.surface.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.isError ? GlassColors.error.withOpacity(0.5) : GlassColors.gold.withOpacity(0.5),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
                          color: widget.isError ? GlassColors.error : GlassColors.gold,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.message,
                            style: GlassText.bodyMD().copyWith(
                              color: GlassColors.onSurface,
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 16),
                          color: GlassColors.onSurface.withOpacity(0.4),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            _controller.reverse().then((_) {
                              if (mounted) widget.onDismiss();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GlassNotifications {
  static OverlayEntry? _currentEntry;

  static void show(BuildContext context, String message, {bool isError = false}) {
    try {
      ScaffoldMessenger.of(context).clearSnackBars();
    } catch (_) {}

    _currentEntry?.remove();
    _currentEntry = null;

    final overlay = Overlay.of(context);
    late final OverlayEntry entry;
    
    entry = OverlayEntry(
      builder: (context) => GlassNotificationWidget(
        message: message,
        isError: isError,
        onDismiss: () {
          if (_currentEntry == entry) {
            entry.remove();
            _currentEntry = null;
          }
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }
}

class HitTestBoundOffset extends SingleChildRenderObjectWidget {
  final double left;
  final double right;
  final double top;
  final double bottom;

  const HitTestBoundOffset({
    super.key,
    required super.child,
    this.left = 0,
    this.right = 0,
    this.top = 0,
    this.bottom = 0,
  });

  @override
  RenderHitTestBoundOffset createRenderObject(BuildContext context) {
    return RenderHitTestBoundOffset(left, right, top, bottom);
  }

  @override
  void updateRenderObject(BuildContext context, RenderHitTestBoundOffset renderObject) {
    renderObject
      ..left = left
      ..right = right
      ..top = top
      ..bottom = bottom;
  }
}

class RenderHitTestBoundOffset extends RenderProxyBox {
  double left;
  double right;
  double top;
  double bottom;

  RenderHitTestBoundOffset(this.left, this.right, this.top, this.bottom);

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final Rect hitTestRect = Rect.fromLTRB(
      -left,
      -top,
      size.width + right,
      size.height + bottom,
    );

    if (hitTestRect.contains(position)) {
      bool hitChild = false;
      if (child != null) {
        hitChild = result.addWithPaintOffset(
          offset: Offset.zero,
          position: position,
          hitTest: (BoxHitTestResult result, Offset transformed) {
            return child!.hitTest(result, position: transformed);
          },
        );
      }
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }
}


