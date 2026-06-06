import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/board_model.dart';
import '../../state_managers/state_tasks.dart';
import '../../state_managers/state_boards.dart';
import '../../models/task_model.dart';
import '../theme/glass_theme.dart';
import '../common/glass_widgets.dart';
import '../common/responsive_layout.dart';
import '../kanban/widgets/task_edit_modal.dart';
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
      if (!mounted) return;
      final boardState = context.read<StateBoards>();
      await boardState.fetchAllBoards();
      // 🔄 Refresh task data when navigating to calendar
      final taskState = context.read<StateTasks>();
      await taskState.fetchAllTasks(boardState.boards);
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
    await prefs.setString('calendar_selected_date', _selectedDate.toIso8601String());
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

    return Container(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 16 : 48, 
        isMobile ? 16 : 48, 
        isMobile ? 16 : 48, 
        24
      ),
      child: isMobile
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('MMMM yyyy').format(_currentMonth).toUpperCase(),
                    style: GlassText.headlineLG().copyWith(fontSize: 28),
                  ),
                  Row(
                    children: [
                      _buildNavButton(Icons.add_rounded, () => _showAddTask(context), size: 36),
                      const SizedBox(width: 8),
                      _buildNavButton(Icons.chevron_left_rounded, () {
                        setState(() {
                          _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
                        });
                      }, size: 36),
                      const SizedBox(width: 8),
                      _buildNavButton(Icons.chevron_right_rounded, () {
                        setState(() {
                          _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
                        });
                      }, size: 36),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildViewToggle(),
            ],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isDayView ? 'DAILY STRATEGIC TIMELINE' : 'STRATEGIC TEMPORAL MAP',
                    style: GlassText.labelSM().copyWith(letterSpacing: 2.0, color: GlassColors.primary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isDayView ? DateFormat('MMMM d').format(_selectedDate).toUpperCase() : DateFormat('MMMM yyyy').format(_currentMonth).toUpperCase(),
                    style: GlassText.headlineXL().copyWith(fontSize: isTablet ? 32 : 48),
                  ),
                ],
              ),
              Row(
                children: [
                  _buildViewToggle(),
                  const SizedBox(width: 16),
                  _buildNavButton(Icons.add_rounded, () => _showAddTask(context)),
                  const SizedBox(width: 12),
                  _buildNavButton(Icons.chevron_left_rounded, () {
                    setState(() {
                      if (_isDayView) {
                        _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                      } else {
                        _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
                      }
                    });
                    _saveCalendarSettings();
                  }),
                  const SizedBox(width: 12),
                  _buildNavButton(Icons.chevron_right_rounded, () {
                    setState(() {
                      if (_isDayView) {
                        _selectedDate = _selectedDate.add(const Duration(days: 1));
                      } else {
                        _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
                      }
                    });
                    _saveCalendarSettings();
                  }),
                ],
              ),
            ],
          ),
    );
  }

  Widget _buildViewToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: GlassColors.onSurface.withOpacity(0.05),
        borderRadius: BorderRadius.circular(ExecutiveRadius.m),
        border: Border.all(color: GlassColors.ghostBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleItem('MONTH', !_isDayView, () {
            setState(() => _isDayView = false);
            _saveCalendarSettings();
          }),
          _buildToggleItem('DAY', _isDayView, () {
            setState(() => _isDayView = true);
            _saveCalendarSettings();
          }),
        ],
      ),
    );
  }

  Widget _buildToggleItem(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? GlassColors.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(ExecutiveRadius.s),
        ),
        child: Text(
          label,
          style: GlassText.labelSM().copyWith(
            fontSize: 10,
            color: active ? GlassColors.primary : GlassColors.onSurfaceVariant.withOpacity(0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildWeekDayStrip() {
    final isMobile = Responsive.isMobile(context);
    final now = DateTime.now();
    final firstDayOfWeek = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
    
    return Container(
      height: isMobile ? 100 : 120,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 48, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (index) {
          final date = firstDayOfWeek.add(Duration(days: index));
          final isToday = date.day == now.day && date.month == now.month && date.year == now.year;
          final isSelected = date.day == _selectedDate.day && date.month == _selectedDate.month && date.year == _selectedDate.year;
          
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _selectedDate = date;
                _isDayView = true;
                _saveCalendarSettings();
              }),
              child: Consumer<StateTasks>(
                builder: (context, taskState, _) {
                  final currentUser = FirebaseAuth.instance.currentUser;
                  final dailyTaskCount = taskState.allTasksWithDueDate.where((t) => 
                    t.members.contains(currentUser?.uid) &&
                    !t.isCompleted &&
                    t.dueDate.year == date.year && 
                    t.dueDate.month == date.month && 
                    t.dueDate.day == date.day
                  ).length;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(ExecutiveRadius.m),
                      border: Border.all(
                        color: isSelected ? GlassColors.gold : (isToday ? GlassColors.primary.withOpacity(0.3) : GlassColors.ghostBorder),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                      color: isSelected ? GlassColors.gold.withOpacity(0.08) : (isToday ? GlassColors.primary.withOpacity(0.02) : Colors.transparent),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('EEE').format(date).toUpperCase()[0],
                          style: GlassText.labelSM().copyWith(
                            fontSize: 10, 
                            color: isSelected ? GlassColors.gold : GlassColors.onSurfaceVariant.withOpacity(0.5),
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
                            width: 4, height: 4,
                            decoration: const BoxDecoration(color: GlassColors.primary, shape: BoxShape.circle),
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
    final allTasks = context.watch<StateTasks>().allTasksWithDueDate;
    
    final myTasks = allTasks.where((t) {
      return t.members.contains(currentUser?.uid) &&
             !t.isCompleted &&
             t.dueDate.year == _selectedDate.year &&
             t.dueDate.month == _selectedDate.month &&
             t.dueDate.day == _selectedDate.day;
    }).toList();

    final boards = context.watch<StateBoards>().boards;

    return DailyTimelineView(
      date: _selectedDate,
      tasks: myTasks,
      boards: boards,
      isDark: widget.isDark,
      onNavigate: widget.onNavigate,
    );
  }

  Widget _buildNavButton(IconData icon, VoidCallback onTap, {double size = 44}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ExecutiveRadius.circular),
          border: Border.all(color: GlassColors.outlineVariant.withOpacity(0.3)),
        ),
        child: Icon(icon, size: size * 0.45, color: GlassColors.onSurface),
      ),
    );
  }

  Widget _buildMonthlyGrid() {
    final isMobile = Responsive.isMobile(context);
    return Column(
      children: [
        _buildWeekdayHeader(),
        Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              isMobile ? 16 : 48, 
              0, 
              isMobile ? 16 : 48, 
              isMobile ? 16 : 48
            ),
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: isMobile ? 8 : 16,
                crossAxisSpacing: isMobile ? 8 : 16,
                childAspectRatio: isMobile ? 0.6 : 0.8,
              ),
              itemCount: _getDaysInMonth(_currentMonth),
              itemBuilder: (context, index) {
                final day = index + 1;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = DateTime(_currentMonth.year, _currentMonth.month, day);
                      _isDayView = true;
                    });
                    _saveCalendarSettings();
                  },
                  child: _buildDayCell(day, true),
                );
              },
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
        horizontal: isMobile ? 24 : 64, 
        vertical: 16
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: days.map((day) => Expanded(
          child: Center(
            child: Text(
              isMobile ? day[0] : day,
              style: GlassText.labelSM().copyWith(
                fontSize: 10, 
                color: GlassColors.onSurfaceVariant.withOpacity(0.4), 
                letterSpacing: 2.0
              ),
            ),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildDayCell(int day, bool isCurrentMonth) {
    final isMobile = Responsive.isMobile(context);
    final isToday = isCurrentMonth && day == DateTime.now().day && _currentMonth.month == DateTime.now().month;
    final date = DateTime(_currentMonth.year, _currentMonth.month, day);
    final currentUser = FirebaseAuth.instance.currentUser;
    
    final allTasks = context.watch<StateTasks>().allTasksWithDueDate;
    final myTasks = allTasks.where((t) => 
      t.members.contains(currentUser?.uid) &&
      !t.isCompleted &&
      isCurrentMonth &&
      t.dueDate.year == date.year &&
      t.dueDate.month == date.month &&
      t.dueDate.day == date.day
    ).toList();

    // 🚀 Task 72.2: Group by Board for Row/Column Logic
    final Map<String, List<TaskModel>> groupedTasks = {};
    for (var t in myTasks) {
      groupedTasks.putIfAbsent(t.boardId, () => []).add(t);
    }

    return Container(
      padding: EdgeInsets.all(isMobile ? 4 : 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isMobile ? ExecutiveRadius.m : ExecutiveRadius.xl),
        border: Border.all(
          color: isToday ? GlassColors.primary : GlassColors.ghostBorder,
          width: isToday ? 1.5 : 1.0,
        ),
        color: isToday ? GlassColors.primary.withOpacity(0.05) : Colors.transparent,
      ),
      child: Opacity(
        opacity: isCurrentMonth ? 1.0 : 0.2,
        child: Column(
          crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          children: [
            Text(
              '$day',
              style: GlassText.bodyMD().copyWith(
                fontSize: isMobile ? 12 : 14,
                fontWeight: isToday ? FontWeight.bold : FontWeight.w400,
                color: isToday ? GlassColors.primary : null,
              ),
            ),
            const SizedBox(height: 4),
            if (isMobile)
              // 🚀 Task 72.2: Multi-Column Strategic Dots (Grouped by board)
              Expanded(
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Wrap(
                    spacing: 2,
                    runSpacing: 2,
                    children: groupedTasks.values.expand((tasks) {
                      final board = context.read<StateBoards>().boards.firstWhere((b) => b.id == tasks.first.boardId, orElse: () => context.read<StateBoards>().boards.first);
                      final color = Color(board.color);
                      return tasks.map((t) => Container(
                        width: 4, height: 4,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      ));
                    }).toList(),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView(
                  physics: const NeverScrollableScrollPhysics(),
                  children: myTasks.take(4).map((task) {
                    final boards = context.read<StateBoards>().boards;
                    BoardModel? board;
                    try { board = boards.firstWhere((b) => b.id == task.boardId); } catch (_) {}
                    final boardColor = board != null ? Color(board.color) : GlassColors.primary;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: boardColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: boardColor.withOpacity(0.3), width: 0.8),
                      ),
                      child: Text(
                        task.title.toUpperCase(),
                        maxLines: 1,
                        style: GlassText.labelSM().copyWith(
                          fontSize: 8, 
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showAddTask(BuildContext context) {
    final boardState = context.read<StateBoards>();
    final boards = boardState.boards.where((b) => b.type == 'team').toList();
    if (boards.isEmpty) {
      GlassNotifications.show(context, 'No team boards available. Create a board first.', isError: true);
      return;
    }
    final board = boardState.selectedBoard ?? boards.first;
    TaskEditModal.show(
      context: context,
      board: board,
      initialDate: _selectedDate,
      isDark: widget.isDark,
    );
  }

  int _getDaysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }
}
