import 'package:flutter/material.dart';

import '../theme/glass_theme.dart';

class WorkspaceCrumb {
  final IconData? icon;
  final String label;
  final Color? color;
  final VoidCallback? onTap;

  const WorkspaceCrumb({
    this.icon,
    required this.label,
    this.color,
    this.onTap,
  });
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

/// A clearly-visible back button used by the Docs/Meetings board pages.
class WorkspaceBackButton extends StatelessWidget {
  final VoidCallback onTap;
  final String tooltip;

  const WorkspaceBackButton({
    super.key,
    required this.onTap,
    this.tooltip = 'Back to Workspace',
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: GlassColors.outlineVariant.withOpacity(0.18),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: GlassColors.onSurface,
                ),
                const SizedBox(width: 6),
                Text(
                  'Back',
                  style: GlassText.bodyMD().copyWith(
                    color: GlassColors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
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
    if (crumb.onTap != null) {
      return _ClickableCrumb(crumb: crumb, baseColor: color);
    }
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

/// A breadcrumb segment that is tappable (navigates back) with a subtle
/// hover underline + click cursor so users know it is interactive.
class _ClickableCrumb extends StatefulWidget {
  final WorkspaceCrumb crumb;
  final Color baseColor;

  const _ClickableCrumb({required this.crumb, required this.baseColor});

  @override
  State<_ClickableCrumb> createState() => _ClickableCrumbState();
}

class _ClickableCrumbState extends State<_ClickableCrumb> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final crumb = widget.crumb;
    final color = _hover
        ? GlassColors.onSurface.withOpacity(0.9)
        : widget.baseColor;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: crumb.onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (crumb.icon != null) ...[
              Icon(crumb.icon, size: 12, color: color),
              const SizedBox(width: 6),
            ],
            Text(
              crumb.label,
              style: GlassText.bodyMD().copyWith(
                fontSize: 12,
                color: color,
                decoration: _hover ? TextDecoration.underline : null,
                decorationColor: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
