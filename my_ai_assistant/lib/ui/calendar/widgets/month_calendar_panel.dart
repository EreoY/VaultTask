import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/board_model.dart';
import '../../../models/task_model.dart';
import '../../../models/workspace_model.dart';
import '../../theme/glass_theme.dart';
import '../../common/responsive_layout.dart';
import 'task_type_icon.dart';

class MonthCalendarPanel extends StatelessWidget {
  final DateTime currentMonth;
  final DateTime selectedDate;
  final List<TaskModel> allTasks;
  final List<BoardModel> boards;
  final List<WorkspaceModel> workspaces;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<DateTime> onDateSelected;
  final void Function(TaskModel task, BoardModel? board) onTaskTap;

  const MonthCalendarPanel({
    super.key,
    required this.currentMonth,
    required this.selectedDate,
    required this.allTasks,
    required this.boards,
    required this.workspaces,
    required this.onPrevious,
    required this.onNext,
    required this.onDateSelected,
    required this.onTaskTap,
  });

  @override
  Widget build(BuildContext context) {
    final dates = _visibleMonthDates(currentMonth);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(ExecutiveRadius.xl),
        border: Border.all(color: GlassColors.ghostBorder),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavButton(Icons.chevron_left_rounded, onPrevious),
              Text(
                DateFormat('MMMM yyyy').format(currentMonth).toUpperCase(),
                style: GlassText.headlineLG().copyWith(
                  color: GlassColors.gold,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              _buildNavButton(Icons.chevron_right_rounded, onNext),
            ],
          ),
          const SizedBox(height: 16),
          _buildWeekdayHeader(context),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.zero,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 0.96,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: dates.length,
              itemBuilder: (context, index) {
                final date = dates[index];
                final isCurrentMonth = date.month == currentMonth.month;
                return _buildDayCell(
                  context,
                  date: date,
                  isCurrentMonth: isCurrentMonth,
                  isWeekendColumn: index % 7 == 0 || index % 7 == 6,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ExecutiveRadius.s),
      child: SizedBox(
        width: 34,
        height: 34,
        child: Icon(
          icon,
          size: 18,
          color: GlassColors.onSurfaceVariant.withOpacity(0.75),
        ),
      ),
    );
  }

  Widget _buildWeekdayHeader(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final days = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: days
            .asMap()
            .entries
            .map(
              (entry) => Expanded(
                child: Center(
                  child: Text(
                    isMobile ? entry.value[0] : entry.value,
                    style: GlassText.labelSM().copyWith(
                      fontSize: 10,
                      color: entry.key == 0 || entry.key == 6
                          ? GlassColors.gold.withOpacity(0.72)
                          : GlassColors.onSurfaceVariant.withOpacity(0.48),
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildDayCell(
    BuildContext context, {
    required DateTime date,
    required bool isCurrentMonth,
    required bool isWeekendColumn,
  }) {
    final isMobile = Responsive.isMobile(context);
    final currentUser = FirebaseAuth.instance.currentUser;
    final isToday = _isSameDay(date, DateTime.now());
    final isSelected = _isSameDay(date, selectedDate);

    final myTasks =
        allTasks
            .where(
              (t) =>
                  t.members.contains(currentUser?.uid) &&
                  isCurrentMonth &&
                  t.dueDate.year == date.year &&
                  t.dueDate.month == date.month &&
                  t.dueDate.day == date.day,
            )
            .toList()
          ..sort((a, b) {
            if (a.isCompleted != b.isCompleted) {
              return a.isCompleted ? 1 : -1;
            }
            return b.updatedAt.compareTo(a.updatedAt);
          });

    return InkWell(
      onTap: () => onDateSelected(date),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isToday
              ? GlassColors.primary.withOpacity(0.055)
              : (isWeekendColumn
                    ? GlassColors.surfaceHighest.withOpacity(0.4)
                    : Colors.white.withOpacity(0.01)),
          borderRadius: BorderRadius.circular(ExecutiveRadius.s),
          border: Border.all(
            color: isSelected
                ? GlassColors.primary.withOpacity(0.9)
                : GlassColors.ghostBorder.withOpacity(0.8),
            width: isSelected ? 1.2 : 0.55,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 6 : 10,
                isMobile ? 5 : 8,
                isMobile ? 6 : 10,
                2,
              ),
              child: Text(
                '${date.day}',
                style: GlassText.bodyMD().copyWith(
                  fontSize: isMobile ? 11 : 14,
                  fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                  color: !isCurrentMonth
                      ? GlassColors.onSurfaceVariant.withOpacity(0.22)
                      : (isToday
                            ? GlassColors.primary
                            : GlassColors.onSurface.withOpacity(0.92)),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 5 : 8,
                  2,
                  isMobile ? 5 : 8,
                  isMobile ? 5 : 8,
                ),
                child: isMobile
                    ? _buildMobileTaskDots(myTasks)
                    : _buildMonthTaskList(myTasks, isCurrentMonth),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileTaskDots(List<TaskModel> tasks) {
    return Align(
      alignment: Alignment.topLeft,
      child: Wrap(
        spacing: 3,
        runSpacing: 3,
        children: tasks.take(12).map((task) {
          return Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: _boardColor(task),
              shape: BoxShape.circle,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMonthTaskList(List<TaskModel> tasks, bool isCurrentMonth) {
    if (!isCurrentMonth) return const SizedBox.shrink();

    final visibleTasks = tasks.take(2).toList();
    final overflow = tasks.length - visibleTasks.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...visibleTasks.map((task) {
          final board = _findBoard(task);
          final boardColor = board != null
              ? Color(board.color)
              : GlassColors.primary;
          final sourceLabel =
              '${_workspaceName(board)} / ${board?.name ?? 'Unknown board'}';
          final isCompleted = task.isCompleted;
          return InkWell(
            onTap: () => onTaskTap(task, board),
            borderRadius: BorderRadius.circular(4),
            child: Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: isCompleted
                    ? boardColor.withOpacity(0.18)
                    : boardColor.withOpacity(0.28),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: boardColor.withOpacity(isCompleted ? 0.22 : 0.42),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        calendarTaskTypeIcon(task.type),
                        size: 12,
                        color: calendarTaskTypeColor(
                          task.type,
                          active: !isCompleted,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          task.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GlassText.bodyMD().copyWith(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            decoration: isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            color: GlassColors.onSurface.withOpacity(
                              isCompleted ? 0.46 : 0.92,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (task.description.trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      task.description.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GlassText.bodyMD().copyWith(
                        fontSize: 9.2,
                        height: 1.1,
                        color: GlassColors.onSurface.withOpacity(
                          isCompleted ? 0.32 : 0.62,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 3),
                  Text(
                    sourceLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GlassText.labelSM().copyWith(
                      fontSize: 7.8,
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      color: GlassColors.onSurface.withOpacity(
                        isCompleted ? 0.28 : 0.56,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        if (overflow > 0)
          Text(
            '+$overflow more',
            style: GlassText.labelSM().copyWith(
              fontSize: 10,
              color: GlassColors.onSurfaceVariant.withOpacity(0.52),
            ),
          ),
      ],
    );
  }

  BoardModel? _findBoard(TaskModel task) {
    for (final board in boards) {
      if (board.id == task.boardId) return board;
    }
    return null;
  }

  String _workspaceName(BoardModel? board) {
    if (board == null || board.workspaceId.isEmpty) return 'Unknown workspace';
    for (final workspace in workspaces) {
      if (workspace.id == board.workspaceId) return workspace.name;
    }
    return 'Unknown workspace';
  }

  Color _boardColor(TaskModel task) {
    final board = _findBoard(task);
    return board != null ? Color(board.color) : GlassColors.primary;
  }

  List<DateTime> _visibleMonthDates(DateTime month) {
    final first = DateTime(month.year, month.month);
    final firstVisible = _startOfCalendarWeek(first);
    return List.generate(
      42,
      (index) => firstVisible.add(Duration(days: index)),
    );
  }

  DateTime _startOfCalendarWeek(DateTime date) {
    final daysFromSunday = date.weekday % 7;
    return date.subtract(Duration(days: daysFromSunday));
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
