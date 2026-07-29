import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/board_model.dart';
import '../../../models/meeting_model.dart';
import '../../../models/task_model.dart';
import '../../../models/workspace_model.dart';
import '../../theme/glass_theme.dart';
import '../../common/responsive_layout.dart';
import 'task_type_icon.dart';

class MonthCalendarPanel extends StatelessWidget {
  final DateTime currentMonth;
  final DateTime selectedDate;
  final List<TaskModel> allTasks;
  final List<MeetingModel> allMeetings;
  final List<BoardModel> boards;
  final List<WorkspaceModel> workspaces;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<DateTime> onMonthSelected;
  final ValueChanged<DateTime> onDateSelected;
  final void Function(TaskModel task, BoardModel? board) onTaskTap;
  final void Function(MeetingModel meeting, BoardModel? board) onMeetingTap;

  const MonthCalendarPanel({
    super.key,
    required this.currentMonth,
    required this.selectedDate,
    required this.allTasks,
    required this.allMeetings,
    required this.boards,
    required this.workspaces,
    required this.onPrevious,
    required this.onNext,
    required this.onMonthSelected,
    required this.onDateSelected,
    required this.onTaskTap,
    required this.onMeetingTap,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final dates = _visibleMonthDates(currentMonth);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(ExecutiveRadius.xl),
        border: Border.all(color: GlassColors.ghostBorder),
      ),
      padding: EdgeInsets.all(isMobile ? 8 : 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavButton(Icons.chevron_left_rounded, onPrevious),
              InkWell(
                onTap: () => _showMonthPickerDialog(context),
                borderRadius: BorderRadius.circular(ExecutiveRadius.s),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat(
                          'MMMM yyyy',
                        ).format(currentMonth).toUpperCase(),
                        style: GlassText.headlineLG().copyWith(
                          color: GlassColors.gold,
                          fontSize: isMobile ? 15 : 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: GlassColors.gold.withOpacity(0.9),
                      ),
                    ],
                  ),
                ),
              ),
              _buildNavButton(Icons.chevron_right_rounded, onNext),
            ],
          ),
          SizedBox(height: isMobile ? 8 : 16),
          _buildWeekdayHeader(context),
          SizedBox(height: isMobile ? 4 : 8),
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.zero,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: isMobile ? 0.55 : 0.96,
                crossAxisSpacing: isMobile ? 3 : 8,
                mainAxisSpacing: isMobile ? 3 : 8,
              ),
              itemCount: dates.length,
              itemBuilder: (context, index) {
                final date = dates[index];
                final isCurrentMonth = date.month == currentMonth.month;
                final weekIndex = index ~/ 7;
                return _buildDayCell(
                  context,
                  date: date,
                  isCurrentMonth: isCurrentMonth,
                  isWeekendColumn: index % 7 == 0 || index % 7 == 6,
                  weekIndex: weekIndex,
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

  Future<void> _showMonthPickerDialog(BuildContext context) async {
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (_) => _MonthYearPickerDialog(initialMonth: currentMonth),
    );
    if (picked != null) {
      onMonthSelected(DateTime(picked.year, picked.month));
    }
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
    required int weekIndex,
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
    final dayMeetings =
        allMeetings
            .where(
              (meeting) =>
                  isCurrentMonth &&
                  meeting.startAt.year == date.year &&
                  meeting.startAt.month == date.month &&
                  meeting.startAt.day == date.day,
            )
            .toList()
          ..sort((a, b) => a.startAt.compareTo(b.startAt));
    final totalItems = myTasks.length + dayMeetings.length;

    final Border borderStyle;
    if (isToday) {
      borderStyle = Border.all(
        color: GlassColors.gold,
        width: 2.0,
      );
    } else if (isSelected) {
      borderStyle = Border.all(
        color: GlassColors.primary.withOpacity(0.9),
        width: 1.4,
      );
    } else {
      borderStyle = Border(
        top: BorderSide(
          color: GlassColors.ghostBorder.withOpacity(0.6),
          width: 0.5,
        ),
        left: BorderSide(
          color: GlassColors.ghostBorder.withOpacity(0.6),
          width: 0.5,
        ),
        right: BorderSide(
          color: GlassColors.ghostBorder.withOpacity(0.6),
          width: 0.5,
        ),
        bottom: BorderSide(
          color: weekIndex < 5
              ? GlassColors.gold.withOpacity(0.28)
              : GlassColors.ghostBorder.withOpacity(0.6),
          width: weekIndex < 5 ? 1.2 : 0.5,
        ),
      );
    }

    return InkWell(
      onTap: () => onDateSelected(date),
      borderRadius: BorderRadius.circular(ExecutiveRadius.s),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isToday
              ? GlassColors.gold.withOpacity(0.12)
              : (isSelected
                    ? GlassColors.primary.withOpacity(0.08)
                    : (isWeekendColumn
                          ? GlassColors.surfaceHighest.withOpacity(0.35)
                          : Colors.white.withOpacity(0.01))),
          borderRadius: BorderRadius.circular(ExecutiveRadius.s),
          border: borderStyle,
          boxShadow: isToday
              ? [
                  BoxShadow(
                    color: GlassColors.gold.withOpacity(0.25),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 3 : 10,
                isMobile ? 3 : 8,
                isMobile ? 3 : 10,
                2,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${date.day}',
                      style: GlassText.bodyMD().copyWith(
                        fontSize: isMobile ? 11 : 14,
                        fontWeight: isToday
                            ? FontWeight.w900
                            : (isSelected ? FontWeight.w800 : FontWeight.w600),
                        color: !isCurrentMonth
                            ? GlassColors.onSurfaceVariant.withOpacity(0.22)
                            : (isToday
                                  ? GlassColors.gold
                                  : (isSelected
                                        ? GlassColors.primary
                                        : GlassColors.onSurface.withOpacity(0.92))),
                      ),
                    ),
                  ),
                  if (isCurrentMonth && totalItems > 0)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 4 : 6,
                        vertical: isMobile ? 1 : 3,
                      ),
                      decoration: BoxDecoration(
                        color: isToday
                            ? GlassColors.gold.withOpacity(0.2)
                            : Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: isToday
                              ? GlassColors.gold.withOpacity(0.5)
                              : GlassColors.ghostBorder.withOpacity(0.9),
                        ),
                      ),
                      child: Text(
                        '$totalItems',
                        style: GlassText.labelSM().copyWith(
                          fontSize: isMobile ? 7.5 : 8,
                          fontWeight: FontWeight.w700,
                          color: isToday
                              ? GlassColors.gold
                              : GlassColors.onSurfaceVariant.withOpacity(0.72),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 2 : 8,
                  1,
                  isMobile ? 2 : 8,
                  isMobile ? 2 : 8,
                ),
                child: isMobile
                    ? _buildMobileTaskList(myTasks, dayMeetings, isCurrentMonth)
                    : _buildMonthTaskList(myTasks, dayMeetings, isCurrentMonth),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileTaskList(
    List<TaskModel> tasks,
    List<MeetingModel> meetings,
    bool isCurrentMonth,
  ) {
    if (!isCurrentMonth) return const SizedBox.shrink();
    if (tasks.isEmpty && meetings.isEmpty) return const SizedBox.shrink();

    final items = <Widget>[];

    for (final task in tasks) {
      final board = _findBoard(task);
      final boardColor = board != null ? Color(board.color) : GlassColors.primary;
      final isCompleted = task.isCompleted;

      items.add(
        InkWell(
          onTap: () => onTaskTap(task, board),
          borderRadius: BorderRadius.circular(3),
          child: Container(
            margin: const EdgeInsets.only(bottom: 2),
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1.5),
            decoration: BoxDecoration(
              color: isCompleted
                  ? boardColor.withOpacity(0.12)
                  : boardColor.withOpacity(0.24),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Row(
              children: [
                Container(
                  width: 2.5,
                  height: 10,
                  decoration: BoxDecoration(
                    color: boardColor,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  calendarTaskTypeIcon(task.type),
                  size: 9,
                  color: calendarTaskTypeColor(task.type, active: !isCompleted),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GlassText.bodyMD().copyWith(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w600,
                      height: 1.1,
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                      color: GlassColors.onSurface.withOpacity(
                        isCompleted ? 0.45 : 0.95,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    for (final meeting in meetings) {
      final board = _findBoardById(meeting.boardId);
      final boardColor = board != null ? Color(board.color) : GlassColors.primary;

      items.add(
        InkWell(
          onTap: () => onMeetingTap(meeting, board),
          borderRadius: BorderRadius.circular(3),
          child: Container(
            margin: const EdgeInsets.only(bottom: 2),
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1.5),
            decoration: BoxDecoration(
              color: boardColor.withOpacity(0.18),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Row(
              children: [
                Container(
                  width: 2.5,
                  height: 10,
                  decoration: BoxDecoration(
                    color: boardColor,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  calendarTaskTypeIcon('meeting'),
                  size: 9,
                  color: calendarTaskTypeColor('meeting'),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    meeting.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GlassText.bodyMD().copyWith(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w600,
                      height: 1.1,
                      color: GlassColors.onSurface.withOpacity(0.95),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ScrollConfiguration(
      behavior: const _CalendarHiddenScrollBehavior(),
      child: ListView(
        padding: EdgeInsets.zero,
        primary: false,
        physics: const ClampingScrollPhysics(),
        children: items,
      ),
    );
  }

  Widget _buildMonthTaskList(
    List<TaskModel> tasks,
    List<MeetingModel> meetings,
    bool isCurrentMonth,
  ) {
    if (!isCurrentMonth) return const SizedBox.shrink();

    final entries = <Widget>[
      ...tasks.map((task) {
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Row(
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
                    ),
                    if (task.hasChecklist) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: GlassColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: GlassColors.success.withOpacity(0.22),
                          ),
                        ),
                        child: Text(
                          task.checklistProgressLabel,
                          style: GlassText.labelSM().copyWith(
                            fontSize: 7.4,
                            fontWeight: FontWeight.w700,
                            color: GlassColors.success.withOpacity(0.98),
                          ),
                        ),
                      ),
                    ],
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
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
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
      ...meetings.map((meeting) {
        final board = _findBoardById(meeting.boardId);
        final boardColor = board != null
            ? Color(board.color)
            : GlassColors.primary;
        final sourceLabel =
            '${_workspaceName(board)} / ${board?.name ?? 'Unknown board'}';
        return InkWell(
          onTap: () => onMeetingTap(meeting, board),
          borderRadius: BorderRadius.circular(4),
          child: Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: boardColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: boardColor.withOpacity(0.22)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      calendarTaskTypeIcon('meeting'),
                      size: 12,
                      color: calendarTaskTypeColor('meeting'),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        meeting.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GlassText.bodyMD().copyWith(
                          fontSize: 11.2,
                          fontWeight: FontWeight.w700,
                          color: GlassColors.onSurface.withOpacity(0.92),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  sourceLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GlassText.labelSM().copyWith(
                    fontSize: 7.8,
                    color: GlassColors.onSurface.withOpacity(0.56),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    ];

    return ScrollConfiguration(
      behavior: const _CalendarHiddenScrollBehavior(),
      child: ListView(
        padding: EdgeInsets.zero,
        primary: false,
        physics: const ClampingScrollPhysics(),
        children: entries,
      ),
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

  BoardModel? _findBoardById(String boardId) {
    for (final board in boards) {
      if (board.id == boardId) return board;
    }
    return null;
  }

  Color _boardColorById(String boardId) {
    final board = _findBoardById(boardId);
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

class _CalendarHiddenScrollBehavior extends MaterialScrollBehavior {
  const _CalendarHiddenScrollBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

class _MonthYearPickerDialog extends StatefulWidget {
  final DateTime initialMonth;

  const _MonthYearPickerDialog({required this.initialMonth});

  @override
  State<_MonthYearPickerDialog> createState() => _MonthYearPickerDialogState();
}

class _MonthYearPickerDialogState extends State<_MonthYearPickerDialog> {
  late int _year;

  @override
  void initState() {
    super.initState();
    _year = widget.initialMonth.year;
  }

  @override
  Widget build(BuildContext context) {
    final monthLabels = List.generate(
      12,
      (index) =>
          DateFormat('MMM').format(DateTime(_year, index + 1)).toUpperCase(),
    );

    return Dialog(
      backgroundColor: GlassColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ExecutiveRadius.l),
        side: BorderSide(color: GlassColors.ghostBorder),
      ),
      child: SizedBox(
        width: 380,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Select month',
                    style: GlassText.headlineLG().copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  _buildYearButton(Icons.chevron_left_rounded, -1),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      '$_year',
                      style: GlassText.headlineLG().copyWith(
                        color: GlassColors.gold,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  _buildYearButton(Icons.chevron_right_rounded, 1),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Jump directly to any month and year.',
                style: GlassText.bodyMD().copyWith(
                  color: GlassColors.onSurfaceVariant.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 18),
              GridView.builder(
                shrinkWrap: true,
                itemCount: 12,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.9,
                ),
                itemBuilder: (context, index) {
                  final monthDate = DateTime(_year, index + 1);
                  final isActive =
                      widget.initialMonth.year == monthDate.year &&
                      widget.initialMonth.month == monthDate.month;
                  return InkWell(
                    onTap: () => Navigator.of(context).pop(monthDate),
                    borderRadius: BorderRadius.circular(10),
                    child: Ink(
                      decoration: BoxDecoration(
                        color: isActive
                            ? GlassColors.gold.withOpacity(0.14)
                            : Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isActive
                              ? GlassColors.gold.withOpacity(0.45)
                              : GlassColors.ghostBorder,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          monthLabels[index],
                          style: GlassText.labelSM().copyWith(
                            color: isActive
                                ? GlassColors.gold
                                : GlassColors.onSurface.withOpacity(0.8),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Close',
                      style: GlassText.bodyMD().copyWith(
                        color: GlassColors.onSurfaceVariant.withOpacity(0.72),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(DateTime.now()),
                    child: Text(
                      'Today',
                      style: GlassText.bodyMD().copyWith(
                        color: GlassColors.gold,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildYearButton(IconData icon, int yearDelta) {
    return InkWell(
      onTap: () => setState(() => _year += yearDelta),
      borderRadius: BorderRadius.circular(ExecutiveRadius.s),
      child: SizedBox(
        width: 32,
        height: 32,
        child: Icon(
          icon,
          size: 18,
          color: GlassColors.onSurfaceVariant.withOpacity(0.8),
        ),
      ),
    );
  }
}
