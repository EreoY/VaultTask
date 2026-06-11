import 'package:flutter/material.dart';

import '../theme/glass_theme.dart';

class WorkspaceCrumb {
  final IconData? icon;
  final String label;
  final Color? color;

  const WorkspaceCrumb({this.icon, required this.label, this.color});
}

class WorkspaceChromeHeader extends StatelessWidget {
  final List<WorkspaceCrumb> crumbs;
  final String metaText;
  final Widget title;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  final double gapAfterNav;
  final double gapAfterMeta;

  const WorkspaceChromeHeader({
    super.key,
    required this.crumbs,
    required this.metaText,
    required this.title,
    required this.padding,
    this.trailing,
    this.gapAfterNav = 10,
    this.gapAfterMeta = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WorkspaceBreadcrumbs(crumbs: crumbs),
          SizedBox(height: gapAfterNav),
          Text(
            metaText,
            style: GlassText.bodyMD().copyWith(
              color: GlassColors.onSurfaceVariant.withOpacity(0.48),
            ),
          ),
          SizedBox(height: gapAfterMeta),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: title),
              if (trailing != null) ...[const SizedBox(width: 16), trailing!],
            ],
          ),
        ],
      ),
    );
  }
}

class WorkspaceBreadcrumbs extends StatelessWidget {
  final List<WorkspaceCrumb> crumbs;

  const WorkspaceBreadcrumbs({super.key, required this.crumbs});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 0,
      runSpacing: 6,
      children: [
        for (var i = 0; i < crumbs.length; i++) ...[
          if (i > 0) _separator(),
          _crumb(crumbs[i]),
        ],
      ],
    );
  }

  Widget _separator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        '/',
        style: GlassText.bodyMD().copyWith(
          fontSize: 12,
          color: GlassColors.onSurfaceVariant.withOpacity(0.22),
        ),
      ),
    );
  }

  Widget _crumb(WorkspaceCrumb crumb) {
    final color = crumb.color ?? GlassColors.onSurfaceVariant.withOpacity(0.52);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (crumb.icon != null) ...[
          Icon(crumb.icon, size: 12, color: color),
          const SizedBox(width: 6),
        ],
        Text(
          crumb.label,
          style: GlassText.bodyMD().copyWith(fontSize: 12, color: color),
        ),
      ],
    );
  }
}
