import 'package:flutter/material.dart';

import '../../theme/glass_theme.dart';

IconData calendarTaskTypeIcon(String type) {
  switch (type.trim().toLowerCase()) {
    case 'meeting':
      return Icons.event_note_rounded;
    case 'event':
      return Icons.event_rounded;
    case 'task':
    default:
      return Icons.checklist_rounded;
  }
}

Color calendarTaskTypeColor(String type, {bool active = true}) {
  switch (type.trim().toLowerCase()) {
    case 'meeting':
      return active
          ? GlassColors.primary.withOpacity(0.92)
          : GlassColors.primary.withOpacity(0.5);
    case 'event':
      return active
          ? GlassColors.gold.withOpacity(0.92)
          : GlassColors.gold.withOpacity(0.5);
    case 'task':
    default:
      return active
          ? GlassColors.onSurface.withOpacity(0.88)
          : GlassColors.onSurface.withOpacity(0.45);
  }
}
