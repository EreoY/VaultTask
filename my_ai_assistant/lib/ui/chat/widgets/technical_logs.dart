import 'package:flutter/material.dart';
import '../../theme/glass_theme.dart';

class DiagnosticToolLog extends StatelessWidget {
  final String toolName;
  final int count;
  const DiagnosticToolLog({super.key, required this.toolName, this.count = 1});

  @override
  Widget build(BuildContext context) {
    String displayLabel = 'EXECUTING: $toolName';
    if (count > 1) {
      displayLabel = '$count ATOMIC OPERATIONS EXECUTED';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: GlassColors.primary.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GlassColors.primary.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.terminal_rounded, size: 14, color: GlassColors.primary),
          const SizedBox(width: 10),
          Text(
            displayLabel,
            style: GlassText.labelSM().copyWith(
              color: GlassColors.primary,
              fontSize: 9,
              letterSpacing: 1.5,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
