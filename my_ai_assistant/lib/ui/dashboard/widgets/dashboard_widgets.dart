import 'package:flutter/material.dart';
import '../../theme/glass_theme.dart';
import '../../common/glass_widgets.dart';

/// Bento Widgets for the Aether AI Dashboard

class DashboardBentoCard extends StatelessWidget {
  final String title;
  final Widget child;
  final IconData? icon;
  final Widget? trailing;
  final bool isDark;
  final double? height;

  const DashboardBentoCard({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.trailing,
    required this.isDark,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      isDark: isDark,
      padding: const EdgeInsets.all(24),
      radius: ExecutiveRadius.l,
      hasAmbientGlow: true,
      child: SizedBox(
        height: height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: GlassColors.primary, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  title.toUpperCase(),
                  style: GlassText.bodyMD().copyWith(
                    fontSize: 11,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w900,
                    color: GlassColors.onSurface,
                  ),
                ),
                const Spacer(),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 20),
            if (height != null)
              Expanded(child: child)
            else
              child,
          ],
        ),
      ),
    );
  }
}

class ProgressMetric extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const ProgressMetric({
    super.key,
    required this.label,
    required this.value,
    this.color = GlassColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GlassText.body().copyWith(fontSize: 14)),
            Text('${(value * 100).round()}%', style: GlassText.label().copyWith(color: color)),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 6,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
