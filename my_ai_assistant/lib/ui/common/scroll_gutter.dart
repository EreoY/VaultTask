import 'package:flutter/material.dart';

import '../theme/glass_theme.dart';

class ScrollbarGutter {
  const ScrollbarGutter._();

  static const double laneWidth = 12;
  static const double contentGap = 10;
  static const double reservedSpace = laneWidth + contentGap;

  static EdgeInsets reserveRight(EdgeInsets padding, {double extraGap = 0}) {
    return padding.copyWith(right: padding.right + reservedSpace + extraGap);
  }
}

class ScrollbarGutterOverlay extends StatelessWidget {
  final double topInset;
  final double bottomInset;
  final double width;
  final Color? backgroundColor;
  final Color? dividerColor;
  final BorderRadiusGeometry? borderRadius;

  const ScrollbarGutterOverlay({
    super.key,
    this.topInset = 0,
    this.bottomInset = 0,
    this.width = ScrollbarGutter.laneWidth,
    this.backgroundColor,
    this.dividerColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          width: width,
          margin: EdgeInsets.only(top: topInset, bottom: bottomInset),
          decoration: BoxDecoration(
            color:
                backgroundColor ??
                GlassColors.surfaceHighest.withOpacity(0.028),
            border: Border(
              left: BorderSide(
                color:
                    dividerColor ??
                    GlassColors.outlineVariant.withOpacity(0.16),
                width: 1,
              ),
            ),
            borderRadius:
                borderRadius ??
                const BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
          ),
        ),
      ),
    );
  }
}

class ScrollbarGutterFrame extends StatelessWidget {
  final Widget child;
  final bool enabled;
  final double topInset;
  final double bottomInset;
  final BorderRadiusGeometry? clipRadius;
  final BorderRadiusGeometry? gutterRadius;
  final Color? gutterColor;
  final Color? dividerColor;

  const ScrollbarGutterFrame({
    super.key,
    required this.child,
    this.enabled = true,
    this.topInset = 0,
    this.bottomInset = 0,
    this.clipRadius,
    this.gutterRadius,
    this.gutterColor,
    this.dividerColor,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return child;
    }

    final overlay = Positioned.fill(
      child: ScrollbarGutterOverlay(
        topInset: topInset,
        bottomInset: bottomInset,
        borderRadius: gutterRadius,
        backgroundColor: gutterColor,
        dividerColor: dividerColor,
      ),
    );

    if (clipRadius == null) {
      return Stack(children: [child, overlay]);
    }

    return ClipRRect(
      borderRadius: clipRadius!,
      child: Stack(children: [child, overlay]),
    );
  }
}
