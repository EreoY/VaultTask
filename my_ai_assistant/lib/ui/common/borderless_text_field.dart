import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ime_safe_text_field.dart';

/// A completely borderless TextField wrapper designed for high-fidelity UI overlays.
/// Under the hood, it uses ImeSafeTextField to maintain IME focus stability on Web.
class BorderlessTextField extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final TextStyle? style;
  final String? hintText;
  final TextStyle? hintStyle;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final int? maxLines;
  final int? minLines;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool readOnly;
  final bool autofocus;
  final bool? enabled;
  final List<TextInputFormatter>? inputFormatters;

  const BorderlessTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.style,
    this.hintText,
    this.hintStyle,
    this.onChanged,
    this.onSubmitted,
    this.maxLines = 1,
    this.minLines,
    this.keyboardType,
    this.textInputAction,
    this.readOnly = false,
    this.autofocus = false,
    this.enabled,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint('[UI] [Render] Building BorderlessTextField for: $hintText');
    return ImeSafeTextField(
      controller: controller,
      focusNode: focusNode,
      style: style,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      maxLines: maxLines,
      minLines: minLines,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      readOnly: readOnly,
      autofocus: autofocus,
      enabled: enabled,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: hintStyle,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        filled: false,
        fillColor: Colors.transparent,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}
