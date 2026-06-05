import 'dart:ui';
import 'package:flutter/material.dart';
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item.icon,
                        color: isActive 
                            ? GlassColors.primary 
                            : GlassColors.onSurfaceVariant.withOpacity(0.6),
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: GlassText.bodyMD().copyWith(
                          fontSize: 10,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                          color: isActive 
                              ? GlassColors.primary 
                              : GlassColors.onSurfaceVariant.withOpacity(0.6),
                        ),
                      ),
                    ],
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

class GlassNotifications {
  static void show(BuildContext context, String message, {bool isError = false}) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.clearSnackBars();
    scaffoldMessenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        padding: EdgeInsets.zero,
        duration: const Duration(seconds: 3),
        content: GlassContainer(
          isDark: true,
          radius: 12,
          blur: 16,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: GlassColors.surface.withOpacity(0.85),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isError ? GlassColors.error.withOpacity(0.5) : GlassColors.gold.withOpacity(0.5),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
                color: isError ? GlassColors.error : GlassColors.gold,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: GlassText.bodyMD().copyWith(
                    color: GlassColors.onSurface,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


