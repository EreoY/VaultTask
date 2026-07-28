import 'package:flutter/material.dart';

class AetherDynamicBackdrop extends StatelessWidget {
  const AetherDynamicBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? const Color(0xFF0F121C) : const Color(0xFFF8F9FA),
    );
  }
}
