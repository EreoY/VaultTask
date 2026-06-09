import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/board_model.dart';
import '../../models/workspace_model.dart';
import '../../state_managers/state_tasks.dart';
import '../../state_managers/state_boards.dart';
import '../../models/task_model.dart';
import '../theme/glass_theme.dart';
import '../common/responsive_layout.dart';
import 'widgets/daily_timeline_view.dart';

class CalendarPage extends StatefulWidget {
  final bool isDark;
  final Function(int)? onNavigate;

  const CalendarPage({super.key, required this.isDark, this.onNavigate});

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
        _buildCalendarHeader(),
        if (_isDayView) _buildWeekDayStrip(),
        Expanded(
          child: _isDayView ? _buildDailyTimeline() : _buildMonthlyGrid(),
        ),
      ],
    );
  }

  Widget _buildCalendarHeader() {
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);
    final titleDate = _isDayView ? _selectedDate : _currentMonth;

    return Container(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 16 : 36,
        isMobile ? 16 : 28,
        isMobile ? 16 : 36,
        12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Strategic Temporal Map: ${DateFormat('MMMM yyyy').format(_currentMonth).toUpperCase()}',
            style: GlassText.labelSM().copyWith(
              color: GlassColors.onSurfaceVariant.withOpacity(0.7),
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _isDayView
                ? DateFormat('EEEE, MMMM d').format(_selectedDate)
                : 'Strategic Temporal Map: ${DateFormat('MMMM yyyy').format(titleDate).toUpperCase()}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GlassText.headlineXL().copyWith(
              fontSize: isMobile ? 28 : (isTablet ? 34 : 42),
              height: 1.04,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 14 : 18,
              vertical: isMobile ? 12 : 14,
            ),
            decoration: BoxDecoration(
              color: GlassColors.onSurface.withOpacity(0.045),
              border: Border.all(color: GlassColors.ghostBorder),
              borderRadius: BorderRadius.circular(ExecutiveRadius.s),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  size: 16,
                  color: GlassColors.onSurfaceVariant.withOpacity(0.7),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Overview of your strategic timeline.',
                    style: GlassText.bodyMD().copyWith(
                      fontSize: 13,
                      color: GlassColors.onSurface.withOpacity(0.78),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _buildToolbar(isMobile, titleDate),
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

  Widget _buildToolbar(bool isMobile, DateTime titleDate) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: GlassColors.ghostBorder.withOpacity(0.75)),
        ),
      ),
      child: Row(
        children: [
          _buildViewToggle(),
          const Spacer(),
          if (!isMobile)
            Text(
              DateFormat(
                _isDayView ? 'MMM d, yyyy' : 'MMMM yyyy',
              ).format(titleDate),
              style: GlassText.labelSM().copyWith(
                color: GlassColors.onSurfaceVariant.withOpacity(0.56),
              ),
            ),
          if (!isMobile) const SizedBox(width: 12),
          _buildNavButton(Icons.chevron_left_rounded, _goToPrevious),
          const SizedBox(width: 6),
          _buildNavButton(Icons.chevron_right_rounded, _goToNext),
        ],
      ),
    );
  }

  Widget _buildViewToggle() {
    return Row(
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
        const SizedBox(width: 16),
        _buildToggleItem(Icons.view_day_outlined, 'Day', _isDayView, () {
          setState(() => _isDayView = true);
          _currentMonth = DateTime(_selectedDate.year, _selectedDate.month);
          _saveCalendarSettings();
        }),
      ],
    );
  }

  Widget _buildToggleItem(
    IconData icon,
    String label,
    bool active,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ExecutiveRadius.s),
      child: SizedBox(
        height: 34,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 13,
                    color: active
                        ? GlassColors.onSurface
                        : GlassColors.onSurfaceVariant.withOpacity(0.55),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: GlassText.labelSM().copyWith(
                      fontSize: 11,
                      color: active
                          ? GlassColors.onSurface
                          : GlassColors.onSurfaceVariant.withOpacity(0.55),
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: active ? 38 : 38,
              height: 2,
              decoration: BoxDecoration(
                color: active ? GlassColors.onSurface : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton(
    IconData icon,
    VoidCallback onTap, {
    double size = 32,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ExecutiveRadius.s),
      child: SizedBox(
        width: size,
        height: size,
        child: Icon(
          icon,
          size: size * 0.55,
          color: GlassColors.onSurfaceVariant.withOpacity(0.75),
        ),
      ),
    );
  }

  Widget _buildWeekDayStrip() {
    final isMobile = Responsive.isMobile(context);
    final now = DateTime.now();
    final firstDayOfWeek = _selectedDate.subtract(
      Duration(days: _selectedDate.weekday - 1),
    );

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
                            !t.isCompleted &&
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

    final myTasks = allTasks.where((t) {
      return t.members.contains(currentUser?.uid) &&
          !t.isCompleted &&
          t.dueDate.year == _selectedDate.year &&
          t.dueDate.month == _selectedDate.month &&
          t.dueDate.day == _selectedDate.day;
    }).toList();

    final boards = context.select<StateBoards, List<BoardModel>>(
      (state) => state.boards,
    );

    return DailyTimelineView(
      date: _selectedDate,
      tasks: myTasks,
      boards: boards,
      isDark: widget.isDark,
      onNavigate: widget.onNavigate,
    );
  }

  Widget _buildMonthlyGrid() {
    final isMobile = Responsive.isMobile(context);
    final allTasks = context.select<StateTasks, List<TaskModel>>(
      (state) => state.allTasksWithDueDate,
    );
    final boards = context.select<StateBoards, List<BoardModel>>(
      (state) => state.boards,
    );
    final workspaces = context.select<StateBoards, List<WorkspaceModel>>(
      (state) => state.workspaces,
    );
    final dates = _visibleMonthDates(_currentMonth);

    return Column(
      children: [
        _buildWeekdayHeader(),
        Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              isMobile ? 16 : 48,
              0,
              isMobile ? 16 : 48,
              isMobile ? 16 : 48,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(ExecutiveRadius.s),
              child: GridView.builder(
                padding: EdgeInsets.zero,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 1.02,
                ),
                itemCount: dates.length,
                itemBuilder: (context, index) {
                  final date = dates[index];
                  final isCurrentMonth = date.month == _currentMonth.month;
                  return _buildDayCell(
                    date,
                    isCurrentMonth,
                    index % 7 >= 5,
                    allTasks,
                    boards,
                    workspaces,
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekdayHeader() {
    final isMobile = Responsive.isMobile(context);
    final days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 48,
        vertical: 10,
      ),
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
                      color: entry.key >= 5
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
    DateTime date,
    bool isCurrentMonth,
    bool isWeekendColumn,
    List<TaskModel> allTasks,
    List<BoardModel> boards,
    List<WorkspaceModel> workspaces,
  ) {
    final isMobile = Responsive.isMobile(context);
    final currentUser = FirebaseAuth.instance.currentUser;
    final isToday = _isSameDay(date, DateTime.now());
    final isSelected = _isSameDay(date, _selectedDate);

    final myTasks = allTasks
        .where(
          (t) =>
              t.members.contains(currentUser?.uid) &&
              !t.isCompleted &&
              isCurrentMonth &&
              t.dueDate.year == date.year &&
              t.dueDate.month == date.month &&
              t.dueDate.day == date.day,
        )
        .toList();

    return InkWell(
      onTap: () {
        setState(() {
          _selectedDate = date;
          _currentMonth = DateTime(date.year, date.month);
          _isDayView = true;
        });
        _saveCalendarSettings();
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isToday
              ? GlassColors.primary.withOpacity(0.055)
              : GlassColors.surface.withOpacity(0.08),
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
                            : (isWeekendColumn
                                  ? GlassColors.gold.withOpacity(0.9)
                                  : GlassColors.onSurface.withOpacity(0.92))),
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
                    ? _buildMobileTaskDots(myTasks, boards)
                    : _buildMonthTaskList(
                        myTasks,
                        boards,
                        workspaces,
                        isCurrentMonth,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileTaskDots(List<TaskModel> tasks, List<BoardModel> boards) {
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
              color: _boardColor(task, boards),
              shape: BoxShape.circle,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMonthTaskList(
    List<TaskModel> tasks,
    List<BoardModel> boards,
    List<WorkspaceModel> workspaces,
    bool isCurrentMonth,
  ) {
    if (!isCurrentMonth) return const SizedBox.shrink();

    final visibleTasks = tasks.take(3).toList();
    final overflow = tasks.length - visibleTasks.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...visibleTasks.map((task) {
          final board = _findBoard(task, boards);
          final boardColor = board != null
              ? Color(board.color)
              : GlassColors.primary;
          final workspaceName = _workspaceName(board, workspaces);
          return InkWell(
            onTap: () => _showTaskPreview(task, board, workspaceName),
            borderRadius: BorderRadius.circular(4),
            child: Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: GlassColors.onSurface.withOpacity(0.055),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: GlassColors.onSurfaceVariant.withOpacity(0.26),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 14,
                    decoration: BoxDecoration(
                      color: boardColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          task.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GlassText.bodyMD().copyWith(
                            fontSize: 10.5,
                            height: 1.05,
                            color: GlassColors.onSurface.withOpacity(0.82),
                          ),
                        ),
                        Text(
                          workspaceName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GlassText.labelSM().copyWith(
                            fontSize: 7.5,
                            height: 1.0,
                            color: GlassColors.onSurfaceVariant.withOpacity(
                              0.54,
                            ),
                          ),
                        ),
                      ],
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

  void _showTaskPreview(
    TaskModel task,
    BoardModel? board,
    String workspaceName,
  ) {
    final boardColor = board != null ? Color(board.color) : GlassColors.primary;
    final isMobile = Responsive.isMobile(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: isMobile ? 0.72 : 0.62,
          minChildSize: 0.42,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: GlassDecorations.solidSurface(
                radius: 28,
                hasShadow: true,
              ),
              child: ListView(
                controller: scrollController,
                padding: EdgeInsets.all(isMobile ? 24 : 36),
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 28,
                        decoration: BoxDecoration(
                          color: boardColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'TASK PREVIEW',
                          style: GlassText.labelSM().copyWith(
                            color: boardColor,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Text(
                    task.title,
                    style: GlassText.headlineLG().copyWith(
                      fontSize: isMobile ? 28 : 34,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _buildPreviewChip(
                        Icons.workspaces_outline,
                        workspaceName,
                      ),
                      _buildPreviewChip(
                        Icons.dashboard_outlined,
                        board?.name ?? 'Unknown board',
                      ),
                      _buildPreviewChip(
                        Icons.calendar_today_rounded,
                        DateFormat('MMM d, HH:mm').format(task.dueDate),
                      ),
                      _buildPreviewChip(Icons.layers_outlined, task.status),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    task.description.isEmpty
                        ? 'No strategic brief provided.'
                        : task.description,
                    style: GlassText.bodyLG().copyWith(
                      color: GlassColors.onSurface.withOpacity(0.72),
                    ),
                  ),
                  const SizedBox(height: 32),
                  InkWell(
                    onTap: board == null
                        ? null
                        : () {
                            context.read<StateBoards>().setSelectedBoard(board);
                            widget.onNavigate?.call(1);
                            Navigator.pop(context);
                          },
                    borderRadius: BorderRadius.circular(
                      ExecutiveRadius.circular,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: board == null
                            ? GlassColors.onSurface.withOpacity(0.04)
                            : boardColor.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(
                          ExecutiveRadius.circular,
                        ),
                        border: Border.all(
                          color: board == null
                              ? GlassColors.ghostBorder
                              : boardColor.withOpacity(0.38),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          board == null ? 'BOARD NOT AVAILABLE' : 'OPEN BOARD',
                          style: GlassText.labelSM().copyWith(
                            color: board == null
                                ? GlassColors.onSurfaceVariant.withOpacity(0.55)
                                : boardColor,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPreviewChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: GlassColors.onSurface.withOpacity(0.04),
        borderRadius: BorderRadius.circular(ExecutiveRadius.s),
        border: Border.all(color: GlassColors.ghostBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: GlassColors.onSurfaceVariant),
          const SizedBox(width: 7),
          Text(
            label,
            style: GlassText.labelSM().copyWith(
              fontSize: 10,
              color: GlassColors.onSurface.withOpacity(0.78),
            ),
          ),
        ],
      ),
    );
  }

  BoardModel? _findBoard(TaskModel task, List<BoardModel> boards) {
    for (final board in boards) {
      if (board.id == task.boardId) return board;
    }
    return null;
  }

  String _workspaceName(BoardModel? board, List<WorkspaceModel> workspaces) {
    if (board == null || board.workspaceId.isEmpty) return 'Unknown workspace';
    for (final workspace in workspaces) {
      if (workspace.id == board.workspaceId) return workspace.name;
    }
    return 'Unknown workspace';
  }

  Color _boardColor(TaskModel task, List<BoardModel> boards) {
    for (final board in boards) {
      if (board.id == task.boardId) return Color(board.color);
    }
    return GlassColors.primary;
  }

  List<DateTime> _visibleMonthDates(DateTime month) {
    final first = DateTime(month.year, month.month);
    final firstVisible = first.subtract(Duration(days: first.weekday - 1));
    return List.generate(
      42,
      (index) => firstVisible.add(Duration(days: index)),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
