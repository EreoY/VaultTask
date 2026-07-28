import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/glass_theme.dart';

/// Horizontal Scrollable List of Vertical Pill-shaped Date Selectors
class VerticalPillDateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final int daysCount;

  const VerticalPillDateSelector({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.daysCount = 14,
  });

  @override
  Widget build(BuildContext context) {
    // Generate dates starting from 3 days ago up to daysCount
    final startDate = DateTime.now().subtract(const Duration(days: 3));
    final dates = List.generate(daysCount, (index) => startDate.add(Duration(days: index)));

    return SizedBox(
      height: 94,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: dates.length,
        itemBuilder: (context, index) {
          final date = dates[index];
          final isSelected =
              date.day == selectedDate.day &&
              date.month == selectedDate.month &&
              date.year == selectedDate.year;

          final dayName = DateFormat('EEE').format(date); // e.g. Mon, Tue
          final dayNum = DateFormat('d').format(date);     // e.g. 24

          return GestureDetector(
            onTap: () => onDateSelected(date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 12),
              width: 58,
              decoration: BoxDecoration(
                color: isSelected ? GlassColors.deepBlack : Colors.transparent,
                borderRadius: BorderRadius.circular(28), // Vertical pill shape
                border: Border.all(
                  color: isSelected
                      ? GlassColors.deepBlack
                      : GlassColors.outlineVariant.withOpacity(0.8),
                  width: 1.2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: GlassColors.deepBlack.withOpacity(0.18),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayName.toUpperCase(),
                    style: GlassText.labelSM().copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white70 : GlassColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dayNum,
                    style: GlassText.headlineMD().copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : GlassColors.deepBlack,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Active State Indicator Dot
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? Colors.white : Colors.transparent,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
