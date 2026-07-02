import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/board_model.dart';
import '../../models/meeting_model.dart';
import '../../models/workspace_model.dart';
import '../../state_managers/state_meetings.dart';
import '../../state_managers/state_tasks.dart';
import '../../state_managers/state_boards.dart';
import '../../models/task_model.dart';
import '../theme/glass_theme.dart';
import '../common/responsive_layout.dart';
import '../common/glass_widgets.dart';
import 'widgets/daily_timeline_view.dart';
import 'widgets/month_calendar_panel.dart';
import 'widgets/unscheduled_task_bucket.dart';
import '../kanban/widgets/task_edit_modal.dart';

class CalendarPage extends StatefulWidget {
  final bool isDark;
  final Function(int)? onNavigate;
  final bool isActive;

  const CalendarPage({
    super.key,
    required this.isDark,
    this.onNavigate,
    this.isActive = true,
  });

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _currentMonth = DateTime.now();
  DateTime _selectedDate = DateTime.now();
  bool _isDayView = false;

  @override
  void initState() {
    super.initState();
    _loadCalendarSettings();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final boardsState = context.read<StateBoards>();
      await boardsState.fetchAllBoards();
      if (!mounted) return;
      await context.read<StateTasks>().fetchAllTasks(boardsState.boards);
      await context.read<StateMeetings>().fetchAllMeetings(
        boardsState.boards,
        silent: true,
      );
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadCalendarSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isDayView = prefs.getBool('calendar_is_day_view') ?? false;
        final savedDate = prefs.getString('calendar_selected_date');
        if (savedDate != null) {
          try {
            _selectedDate = DateTime.parse(savedDate);
            _currentMonth = DateTime(_selectedDate.year, _selectedDate.month);
          } catch (_) {}
        }
      });
    }
  }

  Future<void> _saveCalendarSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('calendar_is_day_view', _isDayView);
    await prefs.setString(
      'calendar_selected_date',
      _selectedDate.toIso8601String(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AetherStaggeredFadeIn(
          index: 0,
          isActive: widget.isActive,
          child: _buildCalendarHeader(),
        ),
        if (_isDayView)
          AetherStaggeredFadeIn(
            index: 1,
            isActive: widget.isActive,
            child: _buildWeekDayStrip(),
          ),
        Expanded(
          child: AetherStaggeredFadeIn(
            index: 2,
            isActive: widget.isActive,
            child: _isDayView ? _buildDailyTimeline() : _buildMonthlyGrid(),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarHeader() {
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);
    final todayLabel = DateFormat('EEEE, MMMM d').format(DateTime.now());
    final heroTitle = _isDayView
        ? DateFormat('EEEE, MMMM d').format(_selectedDate)
        : DateFormat('MMMM yyyy').format(_currentMonth).toUpperCase();
    final supportLabel = _isDayView
        ? 'Calenda Daily Focus'
        : 'Strategic Temporal Map';
    const contextLabel = 'Calenda Timeline';

    return Container(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 16 : 36,
        isMobile ? 16 : 28,
        isMobile ? 16 : 36,
        8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_month_rounded,
                size: 14,
                color: GlassColors.onSurfaceVariant.withOpacity(0.72),
              ),
              const SizedBox(width: 6),
              Text(
                contextLabel,
                style: GlassText.labelSM().copyWith(
                  color: GlassColors.onSurfaceVariant.withOpacity(0.78),
                  letterSpacing: 0.35,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            heroTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GlassText.headlineXL().copyWith(
              fontSize: isMobile ? 28 : (isTablet ? 36 : 46),
              height: 1.02,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_month_rounded,
                    size: 13,
                    color: GlassColors.onSurfaceVariant.withOpacity(0.7),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    supportLabel,
                    style: GlassText.labelSM().copyWith(
                      color: GlassColors.onSurfaceVariant.withOpacity(0.78),
                      letterSpacing: 0.35,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Text(
                '•',
                style: GlassText.labelSM().copyWith(
                  color: GlassColors.onSurfaceVariant.withOpacity(0.35),
                ),
              ),
              Text(
                'Today is $todayLabel',
                style: GlassText.bodyMD().copyWith(
                  color: GlassColors.onSurfaceVariant.withOpacity(0.62),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildToolbar(),
        ],
      ),
    );
  }

  void _goToPrevious() {
    setState(() {
      if (_isDayView) {
        _selectedDate = _selectedDate.subtract(const Duration(days: 1));
        _currentMonth = DateTime(_selectedDate.year, _selectedDate.month);
      } else {
        _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
      }
    });
    _saveCalendarSettings();
  }

  void _goToNext() {
    setState(() {
      if (_isDayView) {
        _selectedDate = _selectedDate.add(const Duration(days: 1));
        _currentMonth = DateTime(_selectedDate.year, _selectedDate.month);
      } else {
        _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
      }
    });
    _saveCalendarSettings();
  }

  void _handleMonthSelected(DateTime month) {
    final clampedDay = _selectedDate.day.clamp(
      1,
      DateUtils.getDaysInMonth(month.year, month.month),
    );
    setState(() {
      _currentMonth = DateTime(month.year, month.month);
      _selectedDate = DateTime(month.year, month.month, clampedDay);
    });
    _saveCalendarSettings();
  }

  Widget _buildToolbar() {
    return SizedBox(
      height: 36,
      child: Align(alignment: Alignment.centerLeft, child: _buildViewToggle()),
    );
  }

  Widget _buildViewToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: GlassColors.ghostBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleItem(
            Icons.calendar_month_outlined,
            'Month',
            !_isDayView,
            () {
              setState(() => _isDayView = false);
              _saveCalendarSettings();
            },
          ),
          _buildToggleItem(Icons.view_day_outlined, 'Day', _isDayView, () {
            setState(() => _isDayView = true);
            _currentMonth = DateTime(_selectedDate.year, _selectedDate.month);
            _saveCalendarSettings();
          }),
        ],
      ),
    );
  }

  Widget _buildToggleItem(
    IconData icon,
    String label,
    bool active,
    VoidCallback onTap,
  ) {
    final isMobile = Responsive.isMobile(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: active
              ? GlassColors.gold.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: active
                  ? GlassColors.gold
                  : GlassColors.onSurface.withOpacity(0.4),
            ),
            const SizedBox(width: 6),
            Text(
              label.toUpperCase(),
              style: GlassText.labelSM().copyWith(
                fontSize: isMobile ? 9 : 10,
                fontWeight: active ? FontWeight.bold : FontWeight.w500,
                color: active
                    ? GlassColors.gold
                    : GlassColors.onSurface.withOpacity(0.4),
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekDayStrip() {
    final isMobile = Responsive.isMobile(context);
    final now = DateTime.now();
    final firstDayOfWeek = _startOfCalendarWeek(_selectedDate);

    return Container(
      height: isMobile ? 100 : 120,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 48,
        vertical: 16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (index) {
          final date = firstDayOfWeek.add(Duration(days: index));
          final isToday =
              date.day == now.day &&
              date.month == now.month &&
              date.year == now.year;
          final isSelected =
              date.day == _selectedDate.day &&
              date.month == _selectedDate.month &&
              date.year == _selectedDate.year;

          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _selectedDate = date;
                _isDayView = true;
                _saveCalendarSettings();
              }),
              child: Selector<StateTasks, int>(
                selector: (_, taskState) {
                  final currentUser = FirebaseAuth.instance.currentUser;
                  return taskState.allTasksWithDueDate
                      .where(
                        (t) =>
                            t.members.contains(currentUser?.uid) &&
                            t.dueDate.year == date.year &&
                            t.dueDate.month == date.month &&
                            t.dueDate.day == date.day,
                      )
                      .length;
                },
                builder: (context, dailyTaskCount, _) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(ExecutiveRadius.m),
                      border: Border.all(
                        color: isSelected
                            ? GlassColors.gold
                            : (isToday
                                  ? GlassColors.primary.withOpacity(0.3)
                                  : GlassColors.ghostBorder),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                      color: isSelected
                          ? GlassColors.gold.withOpacity(0.08)
                          : (isToday
                                ? GlassColors.primary.withOpacity(0.02)
                                : Colors.transparent),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('EEE').format(date).toUpperCase()[0],
                          style: GlassText.labelSM().copyWith(
                            fontSize: 10,
                            color: isSelected
                                ? GlassColors.gold
                                : GlassColors.onSurfaceVariant.withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${date.day}',
                          style: GlassText.headlineLG().copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? GlassColors.gold : null,
                          ),
                        ),
                        if (dailyTaskCount > 0) ...[
                          const SizedBox(height: 4),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              color: GlassColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDailyTimeline() {
    final currentUser = FirebaseAuth.instance.currentUser;
    final allTasks = context.select<StateTasks, List<TaskModel>>(
      (state) => state.allTasksWithDueDate,
    );
    final workspaces = context.select<StateBoards, List<WorkspaceModel>>(
      (state) => state.workspaces,
    );
    final allMeetings = context.select<StateMeetings, List<MeetingModel>>(
      (state) => state.allMeetings,
    );

    final myTasks = allTasks.where((t) {
      return t.members.contains(currentUser?.uid) &&
          t.dueDate.year == _selectedDate.year &&
          t.dueDate.month == _selectedDate.month &&
          t.dueDate.day == _selectedDate.day;
    }).toList();
    final dayMeetings = allMeetings.where((meeting) {
      return meeting.startAt.year == _selectedDate.year &&
          meeting.startAt.month == _selectedDate.month &&
          meeting.startAt.day == _selectedDate.day;
    }).toList();

    final boards = context.select<StateBoards, List<BoardModel>>(
      (state) => state.boards,
    );

    return DailyTimelineView(
      date: _selectedDate,
      tasks: myTasks,
      meetings: dayMeetings,
      boards: boards,
      workspaces: workspaces,
      isDark: widget.isDark,
      onNavigate: widget.onNavigate,
      onMeetingTap: _showMeetingPreview,
    );
  }

  Widget _buildMonthlyGrid() {
    final isMobile = Responsive.isMobile(context);
    final currentUser = FirebaseAuth.instance.currentUser;
    final allTasks = context.select<StateTasks, List<TaskModel>>(
      (state) => state.allTasksWithDueDate,
    );
    final boards = context.select<StateBoards, List<BoardModel>>(
      (state) => state.boards,
    );
    final allMeetings = context.select<StateMeetings, List<MeetingModel>>(
      (state) => state.allMeetings,
    );
    final workspaces = context.select<StateBoards, List<WorkspaceModel>>(
      (state) => state.workspaces,
    );
    final unscheduledTasks = allTasks
        .where(
          (t) => t.members.contains(currentUser?.uid) && t.dueDate.year == 1970,
        )
        .toList();

    final monthPanel = MonthCalendarPanel(
      currentMonth: _currentMonth,
      selectedDate: _selectedDate,
      allTasks: allTasks,
      allMeetings: allMeetings,
      boards: boards,
      workspaces: workspaces,
      onPrevious: _goToPrevious,
      onNext: _goToNext,
      onMonthSelected: _handleMonthSelected,
      onDateSelected: (date) {
        setState(() {
          _selectedDate = date;
          _currentMonth = DateTime(date.year, date.month);
          _isDayView = true;
        });
        _saveCalendarSettings();
      },
      onTaskTap: _showTaskPreview,
      onMeetingTap: _showMeetingPreview,
    );

    final bucket = UnscheduledTaskBucket(
      tasks: unscheduledTasks,
      boards: boards,
      workspaces: workspaces,
      onTaskTap: (task) => _showTaskPreview(task, _findBoard(task, boards)),
      onToggleComplete: (task, value) async {
        final board = _findBoard(task, boards);
        if (board == null) return;
        await context.read<StateTasks>().updateTask(
          board,
          task.copyWith(isCompleted: value),
        );
      },
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 16 : 48,
        0,
        isMobile ? 16 : 48,
        isMobile ? 16 : 48,
      ),
      child: isMobile
          ? Column(
              children: [
                Expanded(child: monthPanel),
                const SizedBox(height: 16),
                SizedBox(height: 190, child: bucket),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: monthPanel),
                const SizedBox(width: 24),
                SizedBox(width: 300, child: bucket),
              ],
            ),
    );
  }

  void _showTaskPreview(TaskModel task, BoardModel? board) {
    if (board == null) return;
    TaskEditModal.show(
      context: context,
      board: board,
      existingTask: task,
      isDark: widget.isDark,
      onOpenBoard: () {
        Navigator.of(context).pop();
        context.read<StateBoards>().setSelectedBoard(board);
        widget.onNavigate?.call(1);
      },
    );
  }

  void _showMeetingPreview(MeetingModel meeting, BoardModel? board) {
    if (board == null) return;
    context.read<StateMeetings>().openMeetingDetail(board.id, meeting.id);
    context.read<StateBoards>().openBoardMeetings(board);
    widget.onNavigate?.call(1);
  }

  BoardModel? _findBoard(TaskModel task, List<BoardModel> boards) {
    for (final board in boards) {
      if (board.id == task.boardId) return board;
    }
    return null;
  }

  DateTime _startOfCalendarWeek(DateTime date) {
    final daysFromSunday = date.weekday % 7;
    return date.subtract(Duration(days: daysFromSunday));
  }
}
