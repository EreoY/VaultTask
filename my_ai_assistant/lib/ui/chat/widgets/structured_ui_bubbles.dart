import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/board_model.dart';
import '../../../models/task_model.dart';
import '../../../models/workspace_model.dart';
import '../../../state_managers/state_boards.dart';
import '../../../state_managers/state_tasks.dart';
import '../../kanban/widgets/task_edit_modal.dart';
import '../../theme/glass_theme.dart';

import 'dart:convert';

class StructuredUIBubble extends StatelessWidget {
  final dynamic data;
  final String type;
  final bool isDark;
  final ValueChanged<BoardModel>? onOpenBoard;
  const StructuredUIBubble({
    super.key,
    required this.data,
    required this.type,
    required this.isDark,
    this.onOpenBoard,
  });

  @override
  Widget build(BuildContext context) {
    var activeData = data;
    if (data is String) {
      try {
        activeData = jsonDecode(data);
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: GlassDecorations.surface(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.insights_rounded,
                size: 16,
                color: GlassColors.primary,
              ),
              const SizedBox(width: 12),
              Text(
                'TACTICAL DATA VIEW',
                style: GlassText.labelSM().copyWith(
                  color: GlassColors.primary,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (type == 'task_ids' && activeData is Map)
            _TaskIdsDataView(
              data: Map<String, dynamic>.from(activeData),
              isDark: isDark,
              onOpenBoard: onOpenBoard,
            )
          else if (type == 'table' && activeData is List)
            _buildTable(activeData)
          else if (type == 'status_summary' && activeData is Map)
            _buildSummary(Map<String, dynamic>.from(activeData))
          else if (type == 'plan_review' && activeData is List)
            _buildPlanReview(activeData)
          else if (type == 'empty_state')
            _buildEmptyState(activeData)
          else
            Text(data.toString()),
        ],
      ),
    );
  }

  Widget _buildPlanReview(List<dynamic> items) {
    return Column(
      children: items.map((item) {
        final Map<String, dynamic> m = Map<String, dynamic>.from(item as Map);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: GlassColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_outlined,
                  size: 14,
                  color: GlassColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m['title']?.toString() ?? 'Plan Item',
                      style: GlassText.bodyMD().copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (m['description'] != null)
                      Text(
                        m['description'].toString(),
                        style: GlassText.secondary().copyWith(fontSize: 12),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState(dynamic data) {
    final Map<String, dynamic> m = data is Map
        ? Map<String, dynamic>.from(data)
        : {};
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 24),
          Icon(
            Icons.inbox_outlined,
            size: 48,
            color: GlassColors.onSurfaceVariant.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            m['message']?.toString() ?? 'No strategic data found.',
            style: GlassText.bodyMD().copyWith(
              color: GlassColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTable(List<dynamic> rows) {
    if (rows.isEmpty) return const Text('No data');
    final keys = (rows.first as Map).keys.toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 24,
        horizontalMargin: 0,
        columns: keys
            .map(
              (k) => DataColumn(
                label: Text(
                  k.toString().toUpperCase(),
                  style: GlassText.labelSM().copyWith(fontSize: 10),
                ),
              ),
            )
            .toList(),
        rows: rows.map((row) {
          final m = row as Map;
          return DataRow(
            cells: keys
                .map(
                  (k) => DataCell(
                    Text(m[k].toString(), style: GlassText.bodyMD()),
                  ),
                )
                .toList(),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSummary(Map<String, dynamic> stats) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: stats.entries
          .map(
            (e) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: GlassColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    e.value.toString(),
                    style: GlassText.headlineLG().copyWith(fontSize: 24),
                  ),
                  Text(
                    e.key.toUpperCase(),
                    style: GlassText.labelSM().copyWith(
                      fontSize: 8,
                      color: GlassColors.primary.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _TaskIdsDataView extends StatefulWidget {
  final Map<String, dynamic> data;
  final bool isDark;
  final ValueChanged<BoardModel>? onOpenBoard;

  const _TaskIdsDataView({
    required this.data,
    required this.isDark,
    this.onOpenBoard,
  });

  @override
  State<_TaskIdsDataView> createState() => _TaskIdsDataViewState();
}

class _TaskIdsDataViewState extends State<_TaskIdsDataView> {
  Future<void>? _ensureLoadedFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureLoadedFuture ??= _ensureTaskStateLoaded();
  }

  Future<void> _ensureTaskStateLoaded() async {
    final boardsState = context.read<StateBoards>();
    if (boardsState.boards.isEmpty) {
      await boardsState.fetchAllBoards();
    }
    if (!mounted) return;
    await context.read<StateTasks>().fetchAllTasks(boardsState.boards);
  }

  @override
  Widget build(BuildContext context) {
    final taskIds = _parseTaskIds(widget.data['task_ids']);
    final title = widget.data['title']?.toString() ?? 'Task results';

    return FutureBuilder<void>(
      future: _ensureLoadedFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: GlassColors.primary.withOpacity(0.8),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Loading task details...',
                  style: GlassText.bodyMD().copyWith(
                    color: GlassColors.onSurfaceVariant.withOpacity(0.75),
                  ),
                ),
              ],
            ),
          );
        }

        final tasksState = context.watch<StateTasks>();
        final boardsState = context.watch<StateBoards>();
        final tasksById = {
          for (final task in tasksState.allTasks) task.id: task,
        };
        final rows = taskIds
            .map((id) => tasksById[id])
            .whereType<TaskModel>()
            .toList();

        if (taskIds.isEmpty || rows.isEmpty) {
          return _buildMissingTasks(taskIds);
        }

        return _buildTaskTable(
          title: title,
          rows: rows,
          boardsState: boardsState,
        );
      },
    );
  }

  static List<String> _parseTaskIds(dynamic raw) {
    if (raw is List)
      return raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded
              .map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList();
        }
      } catch (_) {
        return raw
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    }
    return const [];
  }

  Widget _buildTaskTable({
    required String title,
    required List<TaskModel> rows,
    required StateBoards boardsState,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width - 112;
        final tableWidth = availableWidth < 860 ? 860.0 : availableWidth;
        const horizontalPadding = 32.0;
        const cellGap = 18.0;
        const columnCount = 5;
        final contentWidth =
            tableWidth - horizontalPadding - (cellGap * (columnCount - 1));
        final taskWidth = contentWidth * 0.23;
        final ownerWidth = contentWidth * 0.16;
        final sourceWidth = contentWidth * 0.29;
        final phaseWidth = contentWidth * 0.14;
        final deadlineWidth = contentWidth * 0.18;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GlassText.bodyMD().copyWith(
                      fontWeight: FontWeight.w900,
                      color: GlassColors.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: GlassColors.primary.withOpacity(0.09),
                    borderRadius: BorderRadius.circular(ExecutiveRadius.s),
                    border: Border.all(
                      color: GlassColors.primary.withOpacity(0.18),
                    ),
                  ),
                  child: Text(
                    '${rows.length} TASKS',
                    style: GlassText.labelSM().copyWith(
                      color: GlassColors.primary,
                      fontSize: 10,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: tableWidth,
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: GlassColors.surface.withOpacity(0.34),
                    borderRadius: BorderRadius.circular(ExecutiveRadius.m),
                    border: Border.all(
                      color: GlassColors.glassBorder().withOpacity(0.7),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 13,
                        ),
                        decoration: BoxDecoration(
                          color: GlassColors.onSurface.withOpacity(0.035),
                          border: Border(
                            bottom: BorderSide(
                              color: GlassColors.glassBorder().withOpacity(
                                0.85,
                              ),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            _headerCell('Task', width: taskWidth),
                            _headerCell('Owner', width: ownerWidth),
                            _headerCell(
                              'Workspace / Board',
                              width: sourceWidth,
                            ),
                            _headerCell('Phase', width: phaseWidth),
                            _headerCell(
                              'Deadline',
                              width: deadlineWidth,
                              textAlign: TextAlign.right,
                            ),
                          ],
                        ),
                      ),
                      ...rows.asMap().entries.map((entry) {
                        final index = entry.key;
                        final task = entry.value;
                        final board = _findBoard(task, boardsState.boards);
                        final workspace = _findWorkspace(
                          board,
                          boardsState.workspaces,
                        );
                        final isLast = index == rows.length - 1;

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: board == null
                                ? null
                                : () => _openTaskEditor(task, board),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 15,
                              ),
                              decoration: BoxDecoration(
                                color: index.isEven
                                    ? Colors.transparent
                                    : GlassColors.onSurface.withOpacity(0.018),
                                border: isLast
                                    ? null
                                    : Border(
                                        bottom: BorderSide(
                                          color: GlassColors.glassBorder()
                                              .withOpacity(0.6),
                                        ),
                                      ),
                              ),
                              child: Row(
                                children: [
                                  _tableCell(
                                    width: taskWidth,
                                    child: _taskTitleCell(task),
                                  ),
                                  _tableCell(
                                    width: ownerWidth,
                                    child: _assigneeCell(task, boardsState),
                                  ),
                                  _tableCell(
                                    width: sourceWidth,
                                    child: _sourceCell(workspace, board),
                                  ),
                                  _tableCell(
                                    width: phaseWidth,
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: _phaseCell(task),
                                    ),
                                  ),
                                  _tableCell(
                                    width: deadlineWidth,
                                    isLast: true,
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: _deadlineCell(task),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _headerCell(
    String label, {
    required double width,
    TextAlign textAlign = TextAlign.left,
  }) {
    return SizedBox(
      width: width,
      child: Text(
        label.toUpperCase(),
        textAlign: textAlign,
        style: GlassText.labelSM().copyWith(
          color: GlassColors.onSurfaceVariant.withOpacity(0.76),
          fontSize: 10,
          letterSpacing: 1.1,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _tableCell({
    required double width,
    required Widget child,
    bool isLast = false,
  }) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: EdgeInsets.only(right: isLast ? 0 : 18),
        child: child,
      ),
    );
  }

  Widget _taskTitleCell(TaskModel task) {
    return Text(
      task.title,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: GlassText.bodyMD().copyWith(
        color: GlassColors.onSurface,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _assigneeCell(TaskModel task, StateBoards boardsState) {
    final names = task.members.map((uid) {
      final profile = boardsState.getMemberProfile(uid);
      final name = profile?['name']?.trim();
      return name != null && name.isNotEmpty ? name : uid;
    }).toList();
    return Text(
      names.isEmpty ? '-' : names.join(', '),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: GlassText.bodyMD().copyWith(
        color: GlassColors.onSurface.withOpacity(0.86),
      ),
    );
  }

  Widget _sourceCell(WorkspaceModel? workspace, BoardModel? board) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          workspace?.name ?? 'Unknown workspace',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GlassText.bodyMD().copyWith(
            color: GlassColors.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          board?.name ?? 'Unknown board',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GlassText.caption().copyWith(
            color: GlassColors.onSurfaceVariant.withOpacity(0.7),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _phaseCell(TaskModel task) {
    final label = task.isCompleted ? 'done' : task.status;
    final color = task.isCompleted ? GlassColors.success : GlassColors.primary;

    return Container(
      constraints: const BoxConstraints(minWidth: 64),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(ExecutiveRadius.s),
        border: Border.all(color: color.withOpacity(0.24)),
      ),
      child: Text(
        label.toUpperCase(),
        textAlign: TextAlign.center,
        style: GlassText.labelSM().copyWith(
          color: color,
          fontSize: 10,
          letterSpacing: 0.7,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _deadlineCell(TaskModel task) {
    final hasDeadline = task.dueDate.year != 1970;
    return Text(
      hasDeadline ? DateFormat('yyyy-MM-dd').format(task.dueDate) : '-',
      style: GlassText.bodyMD().copyWith(
        color: hasDeadline
            ? GlassColors.onSurface
            : GlassColors.onSurfaceVariant.withOpacity(0.55),
        fontWeight: hasDeadline ? FontWeight.w800 : FontWeight.w600,
      ),
    );
  }

  Widget _buildMissingTasks(List<String> ids) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        ids.isEmpty
            ? 'No task IDs were provided.'
            : 'No matching tasks were found for the provided IDs.',
        style: GlassText.bodyMD().copyWith(
          color: GlassColors.onSurfaceVariant.withOpacity(0.75),
        ),
      ),
    );
  }

  Future<void> _openTaskEditor(TaskModel task, BoardModel board) async {
    await TaskEditModal.show(
      context: context,
      board: board,
      existingTask: task,
      isDark: widget.isDark,
      collaborationPreview: true,
      onOpenBoard: widget.onOpenBoard == null
          ? null
          : () {
              Navigator.of(context).pop();
              widget.onOpenBoard!(board);
            },
    );
  }

  BoardModel? _findBoard(TaskModel task, List<BoardModel> boards) {
    for (final board in boards) {
      if (board.id == task.boardId) return board;
    }
    return null;
  }

  WorkspaceModel? _findWorkspace(
    BoardModel? board,
    List<WorkspaceModel> workspaces,
  ) {
    if (board == null) return null;
    for (final workspace in workspaces) {
      if (workspace.id == board.workspaceId) return workspace;
    }
    return null;
  }
}
