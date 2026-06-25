import 'package:flutter/material.dart';
import '../theme/glass_theme.dart';

/// A glassmorphic pill UI indicator for showing auto-save status.
/// Supports 'Saved', 'Saving...', and 'Error' states.
class AutoSaveStatusIndicator extends StatelessWidget {
  final String? status;

  const AutoSaveStatusIndicator({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint('[UI] [Render] Building AutoSaveStatusIndicator with status: $status');
    if (status == null || status!.isEmpty) {
      return const SizedBox.shrink();
    }

    final Color bgColor;
    final Color borderColor;
    final Color textColor;
    final Widget leadingWidget;
    final String displayText;

    switch (status) {
      case 'Saved':
        bgColor = Colors.green.withOpacity(0.12);
        borderColor = Colors.green.withOpacity(0.3);
        textColor = Colors.green;
        leadingWidget = const Icon(
          Icons.cloud_done_outlined,
          size: 12,
          color: Colors.green,
        );
        displayText = 'Saved';
        break;
      case 'Saving...':
        bgColor = Colors.amber.withOpacity(0.15);
        borderColor = Colors.amber.withOpacity(0.35);
        textColor = Colors.amber;
        leadingWidget = const SizedBox(
          width: 10,
          height: 10,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
          ),
        );
        displayText = 'Saving...';
        break;
      case 'Error':
        bgColor = Colors.red.withOpacity(0.12);
        borderColor = Colors.red.withOpacity(0.3);
        textColor = Colors.red;
        leadingWidget = const Icon(
          Icons.error_outline_rounded,
          size: 12,
          color: Colors.red,
        );
        displayText = 'Error';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leadingWidget,
          const SizedBox(width: 6),
          Text(
            displayText,
            style: GlassText.caption().copyWith(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
