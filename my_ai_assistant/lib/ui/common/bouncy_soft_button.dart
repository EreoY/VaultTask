import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum BouncyButtonVariant { purple, lavender, orange, blue, pink, dark }

/// Bouncy Soft UI Capsule Button matching Dashboard Bento Specs
class BouncySoftButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final BouncyButtonVariant variant;
  final IconData? icon;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final double fontSize;

  const BouncySoftButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = BouncyButtonVariant.dark,
    this.icon,
    this.width,
    this.padding,
    this.fontSize = 15,
  });

  const BouncySoftButton.purple({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.width,
    this.padding,
    this.fontSize = 15,
  }) : variant = BouncyButtonVariant.purple;

  const BouncySoftButton.lavender({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.width,
    this.padding,
    this.fontSize = 15,
  }) : variant = BouncyButtonVariant.lavender;

  const BouncySoftButton.orange({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.width,
    this.padding,
    this.fontSize = 15,
  }) : variant = BouncyButtonVariant.orange;

  const BouncySoftButton.blue({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.width,
    this.padding,
    this.fontSize = 15,
  }) : variant = BouncyButtonVariant.blue;

  const BouncySoftButton.pink({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.width,
    this.padding,
    this.fontSize = 15,
  }) : variant = BouncyButtonVariant.pink;

  const BouncySoftButton.dark({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.width,
    this.padding,
    this.fontSize = 15,
  }) : variant = BouncyButtonVariant.dark;

  @override
  State<BouncySoftButton> createState() => _BouncySoftButtonState();
}

class _BouncySoftButtonState extends State<BouncySoftButton> {
  bool _isPressed = false;

  Color get _backgroundColor {
    switch (widget.variant) {
      case BouncyButtonVariant.purple:
        return const Color(0xFFB1A5FF);
      case BouncyButtonVariant.lavender:
        return const Color(0xFFC4B5FD); // Bento Lavender Accent
      case BouncyButtonVariant.orange:
        return const Color(0xFFFFC061);
      case BouncyButtonVariant.blue:
        return const Color(0xFF74B9FF); // Bento Blue Accent
      case BouncyButtonVariant.pink:
        return const Color(0xFFFF85A2); // Bento Pink Accent
      case BouncyButtonVariant.dark:
        return const Color(0xFF1E1E24);
    }
  }

  Color get _textColor {
    switch (widget.variant) {
      case BouncyButtonVariant.purple:
      case BouncyButtonVariant.lavender:
        return Colors.white;
      case BouncyButtonVariant.orange:
        return const Color(0xFF1A1A1A);
      case BouncyButtonVariant.blue:
      case BouncyButtonVariant.pink:
      case BouncyButtonVariant.dark:
        return Colors.white;
    }
  }

  BoxShadow get _boxShadow {
    final color = _backgroundColor;
    if (_isPressed) {
      return BoxShadow(
        color: color.withOpacity(widget.variant == BouncyButtonVariant.dark ? 0.2 : 0.4),
        blurRadius: 12,
        offset: const Offset(0, 4),
      );
    }
    return BoxShadow(
      color: color.withOpacity(widget.variant == BouncyButtonVariant.dark ? 0.3 : 0.55),
      blurRadius: 24,
      offset: const Offset(0, 10),
    );
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _isPressed = false);
              widget.onPressed!();
            }
          : null,
      onTapCancel: enabled ? () => setState(() => _isPressed = false) : null,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: const Cubic(0.4, 0.0, 0.2, 1.0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: widget.width,
          padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: enabled ? _backgroundColor : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(999), // Capsule Pill
            boxShadow: enabled ? [_boxShadow] : [],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: 18, color: enabled ? _textColor : Colors.grey),
                  const SizedBox(width: 6),
                ],
                Text(
                  widget.text,
                  style: GoogleFonts.poppins(
                    fontSize: widget.fontSize,
                    fontWeight: FontWeight.w600,
                    color: enabled ? _textColor : Colors.grey,
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
