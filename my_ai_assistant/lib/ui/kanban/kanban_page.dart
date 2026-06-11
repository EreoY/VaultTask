import 'package:flutter/material.dart';
import '../common/ime_safe_text_field.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../models/board_model.dart';
import '../../models/task_model.dart';
import '../../state_managers/state_boards.dart';
import '../../state_managers/state_tasks.dart';
import '../theme/glass_theme.dart';
import '../common/glass_widgets.dart';
import '../common/responsive_layout.dart';
import 'widgets/kanban_column.dart';
import 'widgets/kanban_workspace_controls.dart';
import 'widgets/task_edit_modal.dart';
import 'widgets/column_edit_modal.dart';
import 'widgets/member_role_modal.dart';

enum OperativeFilterMode { all, mine, select }

class KanbanPage extends StatefulWidget {
  final BoardModel board;
  final bool isDark;

  const KanbanPage({super.key, required this.board, required this.isDark});

  @override
  State<KanbanPage> createState() => _KanbanPageState();
}

class _KanbanPageState extends State<KanbanPage> {
  bool _isSelectMode = false;
  bool _isOverviewMode = false; // 🚀 Tactical Zoom State
  bool _isCalendarMode = false;
  DateTime _calendarMonth = DateTime.now();
  OperativeFilterMode _filterMode = OperativeFilterMode.all;
  String? _activeOperativeId; // 🚀 null = ALL
  String? _selectedOperativeId; // 🚀 Chosen operative for select mode
  final Set<String> _selectedTaskIds = {};
  StateTasks? _taskStateRef;

  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _taskStateRef = context.read<StateTasks>();
      _taskStateRef?.fetchTasksForBoard(widget.board);
      _taskStateRef?.subscribeBoard(widget.board);
    });
  }

  @override
  void dispose() {
    // 🔄 KEEP CONNECTION ALIVE: Unsubscribing here breaks cross-page broadcasts
    // (e.g. AI creates task from chat → needs active channel to send Supabase broadcast)
    // Channel cleanup happens automatically in StateTasks.dispose() when app closes.
    _horizontalScrollController.dispose();
    super.dispose();
  }

  Future<void> _moveSelectedTasks(String targetColumnId) async {
    if (_selectedTaskIds.isEmpty) return;
    final taskState = context.read<StateTasks>();
    final board = context.read<StateBoards>().selectedBoard ?? widget.board;
    final tasks = taskState.tasksForBoard(board.id);
    int successCount = 0;
    for (final taskId in _selectedTaskIds) {
      try {
        final task = tasks.firstWhere((t) => t.id == taskId);
        await taskState.updateTaskStatus(board, task, targetColumnId);
        successCount++;
      } catch (_) {}
    }
    if (mounted) {
      GlassNotifications.show(
        context,
        'STRATEGY EXECUTED: $successCount TASKS',
      );
      setState(() {
        _isSelectMode = false;
        _selectedTaskIds.clear();
      });
    }
  }

  void _exportToMarkdown() {
    if (_selectedTaskIds.isEmpty) return;
    final tasks = context.read<StateTasks>().tasksForBoard(widget.board.id);
    final selectedTasks = tasks
        .where((t) => _selectedTaskIds.contains(t.id))
        .toList();
    StringBuffer buffer = StringBuffer();
    buffer.writeln('# STRATEGIC REQUIREMENTS EXPORT');
    buffer.writeln('Board: ${widget.board.name}\n');
    for (int i = 0; i < selectedTasks.length; i++) {
      final t = selectedTasks[i];

      final labelNames = widget.board.labels
          .where((l) => t.labelIds.contains(l['id']))
          .map((l) => (l['name'] as String).toUpperCase())
          .join(', ');

      buffer.writeln('Requirement [${i + 1}]: ${t.title}');
      buffer.writeln(
        'Description: ${t.description.isEmpty ? "No detailed brief." : t.description}',
      );
      buffer.writeln('Task Category: ${t.status.toUpperCase()}');
      buffer.writeln('Labels: ${labelNames.isEmpty ? "NONE" : labelNames}');
      buffer.writeln('-------------------\n');
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (mounted) {
      GlassNotifications.show(context, 'MARKDOWN EXPORTED');
      setState(() {
        _isSelectMode = false;
        _selectedTaskIds.clear();
      });
    }
  }

  void _onTaskTap(TaskModel task) {
    _showTaskDetails(widget.board, task);
  }

  Future<void> _reorderColumns(int fromIndex, int toIndex) async {
    if (_activeOperativeId != null) return;

    final boardState = context.read<StateBoards>();
    final currentBoard = boardState.selectedBoard ?? widget.board;
    final List<String> newColumns = List.from(currentBoard.columns);
    final String moving = newColumns.removeAt(fromIndex);
    newColumns.insert(toIndex, moving);

    final updatedBoard = currentBoard.copyWith(columns: newColumns);
    await boardState.updateBoard(updatedBoard);

    if (mounted) {
      GlassNotifications.show(context, 'STRUCTURE REORGANIZED');
    }
  }

  void _onTaskSelect(String taskId) {
    setState(() {
      if (_selectedTaskIds.contains(taskId)) {
        _selectedTaskIds.remove(taskId);
      } else {
        _selectedTaskIds.add(taskId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final board = context.watch<StateBoards>().selectedBoard ?? widget.board;
    final isMobile = Responsive.isMobile(context);
    final selectFilterLabel = _resolveSelectFilterLabel(context);

    return Stack(
      children: [
        Column(
          children: [
            KanbanWorkspaceHeader(
              board: board,
              isCalendarMode: _isCalendarMode,
              isSelectMode: _isSelectMode,
              isOverviewMode: _isOverviewMode,
              filterAllSelected: _filterMode == OperativeFilterMode.all,
              filterMineSelected: _filterMode == OperativeFilterMode.mine,
              filterSelectSelected: _filterMode == OperativeFilterMode.select,
              selectFilterLabel: selectFilterLabel,
              onBack: () => context.read<StateBoards>().setSelectedBoard(null),
              onShowColumnSettings: () => _showColumnSettings(board),
              onToggleSelectMode: () => setState(() {
                _isSelectMode = !_isSelectMode;
                if (!_isSelectMode) _selectedTaskIds.clear();
              }),
              onShowAddTask: () => _showAddTask(board),
              onShowBoardInfo: () => _showBoardInfoDialog(board),
              onShowRenameBoard: () => _showRenameBoardDialog(context, board),
              onShowRoleManager: () => _showRoleManager(board),
              onToggleOverview: () =>
                  setState(() => _isOverviewMode = !_isOverviewMode),
              onSelectBoardView: () => setState(() => _isCalendarMode = false),
              onSelectCalendarView: () =>
                  setState(() => _isCalendarMode = true),
              onSetFilterAll: () => setState(() {
                _filterMode = OperativeFilterMode.all;
                _activeOperativeId = null;
              }),
              onSetFilterMine: () => setState(() {
                _filterMode = OperativeFilterMode.mine;
                _activeOperativeId = AuthService().currentUser?.uid;
              }),
              onTapSelectFilter: () => _handleSelectFilterTap(board),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 16 : ExecutiveSpacing.containerPadding(context),
                  isMobile ? 8 : 16,
                  isMobile ? 0 : ExecutiveSpacing.containerPadding(context),
                  0,
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: _isCalendarMode
                          ? _buildCalendarView(board, context)
                          : Consumer<StateBoards>(
                              builder: (context, boardState, child) {
                                final latestBoard =
                                    boardState.selectedBoard ?? board;
                                return ListView.builder(
                                  controller: _horizontalScrollController,
                                  scrollDirection: Axis.horizontal,
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  itemCount: latestBoard.columns.length,
                                  itemBuilder: (context, index) {
                                    final columnName =
                                        latestBoard.columns[index];
                                    return DragTarget<int>(
                                      onAcceptWithDetails: (details) =>
                                          _reorderColumns(details.data, index),
                                      builder:
                                          (
                                            context,
                                            candidateData,
                                            rejectedData,
                                          ) {
                                            return Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                if (index > 0) ...[
                                                  SizedBox(
                                                    width: _isOverviewMode
                                                        ? 16
                                                        : 24,
                                                  ),
                                                ],
                                                if (candidateData.isNotEmpty &&
                                                    _activeOperativeId == null)
                                                  AnimatedContainer(
                                                    duration: const Duration(
                                                      milliseconds: 200,
                                                    ),
                                                    width: _isOverviewMode
                                                        ? 80
                                                        : 120,
                                                    margin:
                                                        const EdgeInsets.only(
                                                          right: 12,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: GlassColors.gold
                                                          .withOpacity(0.05),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            ExecutiveRadius.xl,
                                                          ),
                                                      border: Border.all(
                                                        color: GlassColors.gold
                                                            .withOpacity(0.3),
                                                        width: 1.5,
                                                      ),
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        'INSERT PHASE',
                                                        style:
                                                            GlassText.labelSM()
                                                                .copyWith(
                                                                  color:
                                                                      GlassColors
                                                                          .gold,
                                                                  fontSize: 8,
                                                                  letterSpacing:
                                                                      2,
                                                                ),
                                                      ),
                                                    ),
                                                  ),
                                                KanbanColumnWidget(
                                                  board: latestBoard,
                                                  columnName: columnName,
                                                  isDark: widget.isDark,
                                                  isSelectMode: _isSelectMode,
                                                  selectedTaskIds:
                                                      _selectedTaskIds,
                                                  onTaskTap: _onTaskTap,
                                                  onTaskSelect: _onTaskSelect,
                                                  onAdd: () => _showAddTask(
                                                    latestBoard,
                                                    columnName,
                                                  ),
                                                  onSettings: () =>
                                                      _showColumnSettings(
                                                        latestBoard,
                                                        columnName,
                                                      ),
                                                  columnIndex: index,
                                                  activeOperativeId:
                                                      _activeOperativeId,
                                                  isOverviewMode:
                                                      _isOverviewMode,
                                                ),
                                                if (index ==
                                                    latestBoard.columns.length -
                                                        1)
                                                  SizedBox(
                                                    width: _isOverviewMode
                                                        ? 16
                                                        : 24,
                                                  ),
                                              ],
                                            );
                                          },
                                    );
                                  },
                                );
                              },
                            ),
                    ),
                    SizedBox(height: ExecutiveSpacing.stackMd(context)),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (_isSelectMode && _selectedTaskIds.isNotEmpty)
          Positioned(
            left: 0,
            right: 0,
            bottom: isMobile ? 32 : 64,
            child: Center(
              child: KanbanBulkToolbar(
                selectedCount: _selectedTaskIds.length,
                onMove: () => _showMoveMenu(context, board),
                onExport: _exportToMarkdown,
                onClear: () => setState(() => _selectedTaskIds.clear()),
              ),
            ),
          ),
      ],
    );
  }

  void _showOperativeFilterMenu(BuildContext context, BoardModel board) {
    final boardState = context.read<StateBoards>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: GlassDecorations.solidSurface(radius: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'STRATEGIC OPERATIVE FILTER',
              style: GlassText.labelSM().copyWith(
                letterSpacing: 2.0,
                color: GlassColors.gold,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Icon(
                Icons.group_rounded,
                color: _filterMode == OperativeFilterMode.all
                    ? GlassColors.primary
                    : Colors.white30,
              ),
              title: Text(
                'ALL OPERATIVES',
                style: GlassText.bodyMD().copyWith(
                  fontWeight: _filterMode == OperativeFilterMode.all
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              onTap: () {
                setState(() {
                  _filterMode = OperativeFilterMode.all;
                  _activeOperativeId = null;
                });
                Navigator.pop(context);
              },
            ),
            const Divider(color: Colors.white10),
            ...board.members.map((uid) {
              final profile = boardState.getMemberProfile(uid);
              final name = profile?['name'] ?? 'Operative';
              final color = GlassColors.getMemberColor(uid);
              final isSelected =
                  _filterMode == OperativeFilterMode.select &&
                  _activeOperativeId == uid;

              return ListTile(
                leading: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(0.2),
                  ),
                  child: Center(
                    child: Text(
                      name[0].toUpperCase(),
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  name.toUpperCase(),
                  style: GlassText.bodyMD().copyWith(
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: GlassColors.primary,
                        size: 20,
                      )
                    : null,
                onTap: () {
                  setState(() {
                    _filterMode = OperativeFilterMode.select;
                    _selectedOperativeId = uid;
                    _activeOperativeId = uid;
                  });
                  Navigator.pop(context);
                },
              );
            }),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _resolveSelectFilterLabel(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    var selectLabel = isMobile ? 'SELECT' : 'SELECT OPERATIVE';
    if (_filterMode == OperativeFilterMode.select &&
        _selectedOperativeId != null) {
      final profile = context.read<StateBoards>().getMemberProfile(
        _selectedOperativeId!,
      );
      if (profile != null) {
        selectLabel = profile['name'] ?? selectLabel;
      }
    }
    return selectLabel;
  }

  void _handleSelectFilterTap(BoardModel board) {
    if (_filterMode == OperativeFilterMode.select) {
      _showOperativeFilterMenu(context, board);
      return;
    }
    if (_selectedOperativeId == null) {
      _showOperativeFilterMenu(context, board);
      return;
    }
    setState(() {
      _filterMode = OperativeFilterMode.select;
      _activeOperativeId = _selectedOperativeId;
    });
  }

  void _showAddTask(BoardModel board, [String? col]) => TaskEditModal.show(
    context: context,
    board: board,
    initialStatus: col,
    isDark: widget.isDark,
  );
  void _showColumnSettings(BoardModel board, [String? col]) =>
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) =>
            ColumnEditModal(board: board, existingColumn: col),
      );
  void _showTaskDetails(BoardModel board, TaskModel task) => TaskEditModal.show(
    context: context,
    board: board,
    existingTask: task,
    isDark: widget.isDark,
  );
  void _showRoleManager(BoardModel board) => showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => MemberRoleModal(board: board),
  );
  void _showBoardInfoDialog(BoardModel board) => showDialog(
    context: context,
    builder: (context) => _BoardInfoDialog(board: board),
  );

  void _showMoveMenu(BuildContext context, BoardModel board) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: GlassDecorations.solidSurface(radius: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SELECT TARGET PHASE',
              style: GlassText.labelSM().copyWith(letterSpacing: 2),
            ),
            const SizedBox(height: 24),
            ...board.columns.map(
              (col) => ListTile(
                title: Text(col.toUpperCase(), style: GlassText.bodyMD()),
                leading: const Icon(
                  Icons.subdirectory_arrow_right_rounded,
                  color: GlassColors.primary,
                  size: 20,
                ),
                onTap: () {
                  Navigator.pop(context);
                  _moveSelectedTasks(col);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameBoardDialog(BuildContext context, BoardModel board) {
    final controller = TextEditingController(text: board.name);
    showDialog(
      context: context,
      builder: (dialogContext) => Center(
        child: Container(
          width: 400,
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: GlassDecorations.solidSurface(
            radius: 24,
            hasShadow: true,
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RENAME BOARD',
                  style: GlassText.labelSM().copyWith(
                    color: GlassColors.primary,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 24),
                ImeSafeTextField(
                  controller: controller,
                  autofocus: true,
                  style: GlassText.bodyLG(),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: GlassColors.ghostBorder),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'CANCEL',
                          style: GlassText.labelSM().copyWith(
                            color: GlassColors.onSurfaceVariant.withOpacity(
                              0.6,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final newName = controller.text.trim();
                          if (newName.isEmpty || newName == board.name) return;
                          final boardsState = context.read<StateBoards>();
                          final navigator = Navigator.of(dialogContext);
                          try {
                            await boardsState.updateBoard(
                              board.copyWith(name: newName),
                            );
                            navigator.pop();
                            GlassNotifications.show(
                              context,
                              'Board renamed successfully!',
                            );
                          } catch (e) {
                            GlassNotifications.show(
                              context,
                              'Failed to rename board: $e',
                              isError: true,
                            );
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(
                            color: GlassColors.gold,
                            width: 1.5,
                          ),
                          backgroundColor: GlassColors.gold.withOpacity(0.05),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'RENAME',
                          style: GlassText.labelSM().copyWith(
                            color: GlassColors.gold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarView(BoardModel board, BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final taskState = context.watch<StateTasks>();
    final tasks = taskState.tasksForBoard(board.id);

    // Filter tasks based on current filters
    final filteredTasks = tasks.where((t) {
      if (_filterMode == OperativeFilterMode.mine) {
        final currentUid = AuthService().currentUser?.uid;
        return t.members.contains(currentUid);
      } else if (_filterMode == OperativeFilterMode.select &&
          _activeOperativeId != null) {
        return t.members.contains(_activeOperativeId);
      }
      return true;
    }).toList();

    final scheduledTasks = filteredTasks
        .where((t) => t.dueDate.year != 1970)
        .toList();
    final unscheduledTasks = filteredTasks
        .where((t) => t.dueDate.year == 1970)
        .toList();

    final calendarWidget = _buildCalendarGrid(scheduledTasks, board, context);
    final bucketWidget = _buildUnscheduledBucket(
      unscheduledTasks,
      board,
      context,
    );

    if (isMobile) {
      return Column(
        children: [
          Expanded(child: calendarWidget),
          const SizedBox(height: 16),
          SizedBox(height: 180, child: bucketWidget),
        ],
      );
    } else {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: calendarWidget),
          const SizedBox(width: 24),
          SizedBox(width: 300, height: double.infinity, child: bucketWidget),
        ],
      );
    }
  }

  Widget _buildCalendarGrid(
    List<TaskModel> scheduledTasks,
    BoardModel board,
    BuildContext context,
  ) {
    final firstDay = DateTime(_calendarMonth.year, _calendarMonth.month, 1);
    final startOffset = firstDay.weekday == 7 ? 0 : firstDay.weekday;
    final totalDaysInMonth = DateTime(
      _calendarMonth.year,
      _calendarMonth.month + 1,
      0,
    ).day;

    final daysList = <DateTime?>[];
    for (int i = 0; i < startOffset; i++) {
      daysList.add(null);
    }
    for (int i = 1; i <= totalDaysInMonth; i++) {
      daysList.add(DateTime(_calendarMonth.year, _calendarMonth.month, i));
    }

    while (daysList.length % 7 != 0) {
      daysList.add(null);
    }

    final weekdays = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];

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
              IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: GlassColors.primary.withOpacity(0.7),
                  size: 18,
                ),
                onPressed: () => setState(() {
                  _calendarMonth = DateTime(
                    _calendarMonth.year,
                    _calendarMonth.month - 1,
                  );
                }),
              ),
              Text(
                DateFormat('MMMM yyyy').format(_calendarMonth).toUpperCase(),
                style: GlassText.headlineLG().copyWith(
                  color: GlassColors.gold,
                  fontSize: 18,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: GlassColors.primary.withOpacity(0.7),
                  size: 18,
                ),
                onPressed: () => setState(() {
                  _calendarMonth = DateTime(
                    _calendarMonth.year,
                    _calendarMonth.month + 1,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: weekdays
                .map(
                  (day) => Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(
                          day,
                          style: GlassText.labelSM().copyWith(
                            color: GlassColors.onSurface.withOpacity(0.4),
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.builder(
              itemCount: daysList.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.1,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                final date = daysList[index];
                if (date == null) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(ExecutiveRadius.s),
                    ),
                  );
                }

                final dayTasks = scheduledTasks.where((t) {
                  return t.dueDate.year == date.year &&
                      t.dueDate.month == date.month &&
                      t.dueDate.day == date.day;
                }).toList();

                final isToday = DateUtils.isSameDay(date, DateTime.now());

                return DragTarget<TaskModel>(
                  onAcceptWithDetails: (details) async {
                    final task = details.data;
                    final updatedTask = task.copyWith(dueDate: date);
                    final taskState = context.read<StateTasks>();
                    await taskState.updateTask(board, updatedTask);
                    if (mounted) {
                      GlassNotifications.show(
                        context,
                        'TASK RESCHEDULED TO ${DateFormat('MMM d').format(date).toUpperCase()}',
                      );
                    }
                  },
                  builder: (context, candidateData, rejectedData) {
                    final isOver = candidateData.isNotEmpty;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isOver
                            ? GlassColors.gold.withOpacity(0.1)
                            : (isToday
                                  ? GlassColors.primary.withOpacity(0.05)
                                  : Colors.white.withOpacity(0.01)),
                        borderRadius: BorderRadius.circular(ExecutiveRadius.s),
                        border: Border.all(
                          color: isOver
                              ? GlassColors.gold
                              : (isToday
                                    ? GlassColors.primary.withOpacity(0.4)
                                    : GlassColors.ghostBorder),
                          width: isOver || isToday ? 1.5 : 1,
                        ),
                      ),
                      padding: const EdgeInsets.all(6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${date.day}',
                                style: GlassText.bodyMD().copyWith(
                                  fontWeight: isToday
                                      ? FontWeight.w900
                                      : FontWeight.w600,
                                  color: isToday
                                      ? GlassColors.primary
                                      : GlassColors.onSurface.withOpacity(0.8),
                                  fontSize: 11,
                                ),
                              ),
                              if (dayTasks.isNotEmpty)
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: GlassColors.gold,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Expanded(
                            child: ListView.builder(
                              itemCount: dayTasks.length,
                              itemBuilder: (context, tIndex) {
                                final task = dayTasks[tIndex];
                                return _buildCalendarTaskCard(
                                  task,
                                  board,
                                  context,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarTaskCard(
    TaskModel task,
    BoardModel board,
    BuildContext context,
  ) {
    final state = context.read<StateTasks>();
    final notifier = state.getTaskNotifier(task.id);

    Container cardContent(TaskModel currentTask) => Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: currentTask.isCompleted
            ? GlassColors.success.withOpacity(0.1)
            : GlassColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: currentTask.isCompleted
              ? GlassColors.success.withOpacity(0.3)
              : GlassColors.primary.withOpacity(0.15),
          width: 0.5,
        ),
      ),
      child: Text(
        currentTask.title.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GlassText.bodyMD().copyWith(
          fontSize: 8,
          fontWeight: FontWeight.bold,
          decoration: currentTask.isCompleted
              ? TextDecoration.lineThrough
              : null,
          color: currentTask.isCompleted
              ? GlassColors.success.withOpacity(0.7)
              : GlassColors.onSurface.withOpacity(0.9),
        ),
      ),
    );

    final widgetBody = notifier == null
        ? cardContent(task)
        : ValueListenableBuilder<TaskModel>(
            valueListenable: notifier,
            builder: (context, latestTask, _) => cardContent(latestTask),
          );

    return Draggable<TaskModel>(
      data: task,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          width: 140,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.85),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: GlassColors.gold),
          ),
          child: Text(
            task.title.toUpperCase(),
            style: GlassText.bodyMD().copyWith(
              fontSize: 10,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: widgetBody),
      child: GestureDetector(onTap: () => _onTaskTap(task), child: widgetBody),
    );
  }

  Widget _buildUnscheduledBucket(
    List<TaskModel> unscheduledTasks,
    BoardModel board,
    BuildContext context,
  ) {
    final isMobile = Responsive.isMobile(context);
    return DragTarget<TaskModel>(
      onAcceptWithDetails: (details) async {
        final task = details.data;
        if (task.dueDate.year == 1970) return;
        final updatedTask = task.copyWith(dueDate: DateTime(1970, 1, 1));
        final taskState = context.read<StateTasks>();
        await taskState.updateTask(board, updatedTask);
        if (mounted) {
          GlassNotifications.show(context, 'TASK UNSCHEDULED');
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isOver = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isOver
                ? GlassColors.gold.withOpacity(0.08)
                : Colors.white.withOpacity(0.02),
            borderRadius: BorderRadius.circular(ExecutiveRadius.xl),
            border: Border.all(
              color: isOver ? GlassColors.gold : GlassColors.ghostBorder,
              width: isOver ? 1.5 : 1,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'UNSCHEDULED',
                      style: GlassText.labelSM().copyWith(
                        color: GlassColors.gold,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: GlassColors.gold.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${unscheduledTasks.length}',
                      style: GlassText.labelSM().copyWith(
                        color: GlassColors.gold,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: unscheduledTasks.isEmpty
                    ? Center(
                        child: Text(
                          'DRAG HERE TO UNSCHEDULE',
                          textAlign: TextAlign.center,
                          style: GlassText.bodyMD().copyWith(
                            color: GlassColors.onSurface.withOpacity(0.3),
                            fontSize: 11,
                          ),
                        ),
                      )
                    : ListView.builder(
                        scrollDirection: isMobile
                            ? Axis.horizontal
                            : Axis.vertical,
                        itemCount: unscheduledTasks.length,
                        itemBuilder: (context, index) {
                          final task = unscheduledTasks[index];
                          return Container(
                            width: isMobile ? 180 : double.infinity,
                            margin: isMobile
                                ? const EdgeInsets.only(right: 12, bottom: 4)
                                : const EdgeInsets.only(bottom: 8),
                            child: _buildBucketTaskCard(task, board, context),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBucketTaskCard(
    TaskModel task,
    BoardModel board,
    BuildContext context,
  ) {
    final state = context.read<StateTasks>();
    final notifier = state.getTaskNotifier(task.id);

    Container cardContent(TaskModel currentTask) => Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(ExecutiveRadius.m),
        border: Border.all(color: GlassColors.ghostBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: Checkbox(
                  value: currentTask.isCompleted,
                  onChanged: (v) async {
                    final updated = currentTask.copyWith(
                      isCompleted: v ?? false,
                    );
                    await state.updateTask(board, updated);
                  },
                  activeColor: GlassColors.success,
                  side: BorderSide(
                    color: GlassColors.primary.withOpacity(0.4),
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  currentTask.title.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GlassText.headlineLG().copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    decoration: currentTask.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                    color: currentTask.isCompleted
                        ? GlassColors.onSurface.withOpacity(0.3)
                        : GlassColors.onSurface,
                  ),
                ),
              ),
            ],
          ),
          if (currentTask.labelIds.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: board.labels
                  .where((l) => currentTask.labelIds.contains(l['id']))
                  .map((l) {
                    final color = Color(
                      l['color'] as int? ?? GlassColors.primary.value,
                    );
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: color.withOpacity(0.2)),
                      ),
                      child: Text(
                        (l['name'] as String).toUpperCase(),
                        style: GlassText.labelSM().copyWith(
                          fontSize: 6,
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  })
                  .toList(),
            ),
          ],
        ],
      ),
    );

    final widgetBody = notifier == null
        ? cardContent(task)
        : ValueListenableBuilder<TaskModel>(
            valueListenable: notifier,
            builder: (context, latestTask, _) => cardContent(latestTask),
          );

    return Draggable<TaskModel>(
      data: task,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: 200,
          child: Opacity(opacity: 0.9, child: widgetBody),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.2, child: widgetBody),
      child: GestureDetector(onTap: () => _onTaskTap(task), child: widgetBody),
    );
  }
}

class _BoardInfoDialog extends StatelessWidget {
  final BoardModel board;
  const _BoardInfoDialog({required this.board});
  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 400,
      padding: const EdgeInsets.all(32),
      decoration: GlassDecorations.solidSurface(radius: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('BOARD ID', style: GlassText.labelSM()),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SelectableText(
            board.id,
            style: GlassText.bodyMD().copyWith(
              fontFamily: 'monospace',
              color: GlassColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () => Clipboard.setData(ClipboardData(text: board.id)),
          ),
        ],
      ),
    ),
  );
}
