import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/board_model.dart';
import '../../../models/task_model.dart';
import '../../../state_managers/state_boards.dart';
import '../../../state_managers/state_tasks.dart';
import '../../common/responsive_layout.dart';
import '../../common/scroll_gutter.dart';
import '../../theme/glass_theme.dart';
import 'kanban_card.dart';

class KanbanColumnWidget extends StatefulWidget {
  final BoardModel board;
  final String columnName;
  final bool isDark;
  final bool isSelectMode;
  final Set<String> selectedTaskIds;
  final Function(TaskModel) onTaskTap;
  final Function(String) onTaskSelect;
  final VoidCallback onAdd;
  final VoidCallback onSettings;
  final int columnIndex;
  final String? activeOperativeId;
  final bool isOverviewMode;

  const KanbanColumnWidget({
    super.key,
    required this.board,
    required this.columnName,
    required this.isDark,
    required this.isSelectMode,
    required this.selectedTaskIds,
    required this.onTaskTap,
    required this.onTaskSelect,
    required this.onAdd,
    required this.onSettings,
    required this.columnIndex,
    this.activeOperativeId,
    this.isOverviewMode = false,
  });

  @override
  State<KanbanColumnWidget> createState() => _KanbanColumnWidgetState();
}

class _KanbanColumnWidgetState extends State<KanbanColumnWidget> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildColumnDragHandle(double columnWidth, int rawTaskCount) {
    return LongPressDraggable<int>(
      data: widget.columnIndex,
      axis: Axis.horizontal,
      delay: const Duration(milliseconds: 300),
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.92,
          child: Transform.scale(
            scale: 0.96,
            child: Container(
              width: columnWidth,
              decoration: GlassDecorations.surface(
                radius: ExecutiveRadius.xl,
                hasShadow: true,
              ),
              child: KanbanColumnHeader(
                board: widget.board,
                columnName: widget.columnName,
                taskCount: rawTaskCount,
                isDark: widget.isDark,
                onAdd: () {},
                onSettings: () {},
                dragHandle: const Icon(
                  Icons.drag_indicator_rounded,
                  color: GlassColors.gold,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
      ),
      childWhenDragging: const Opacity(
        opacity: 0.1,
        child: Icon(
          Icons.drag_indicator_rounded,
          color: Colors.white12,
          size: 22,
        ),
      ),
      child: const MouseRegion(
        cursor: SystemMouseCursors.grab,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Icon(
            Icons.drag_indicator_rounded,
            color: Colors.white24,
            size: 20,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewportHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);
    final baseWidth = isMobile ? screenWidth * 0.8 : (isTablet ? 292.0 : 316.0);
    final columnWidth = widget.isOverviewMode
        ? (isMobile ? baseWidth * 0.76 : 244.0)
        : baseWidth;

    return SizedBox(
      width: columnWidth,
      child: DragTarget<TaskModel>(
        onAcceptWithDetails: (details) {
          final task = details.data;
          if (task.status != widget.columnName) {
            context.read<StateTasks>().updateTaskStatus(
              widget.board,
              task,
              widget.columnName,
            );
          }
        },
        builder: (context, candidateData, rejectedData) {
          final highlight = candidateData.isNotEmpty;

          return Consumer<StateTasks>(
            builder: (context, state, child) {
              final rawTasks = state
                  .tasksForBoard(widget.board.id)
                  .where((t) => t.status == widget.columnName)
                  .toList();
              final filteredTasks = widget.activeOperativeId == null
                  ? rawTasks
                  : rawTasks
                        .where((t) => t.members.contains(widget.activeOperativeId))
                        .toList();

              final headerHeight = widget.isOverviewMode ? 54.0 : 58.0;
              // Even in overview mode, we base the shell height on the standard card height (210.0)
              // so the column container doesn't shrink, allowing it to hold more of the smaller cards.
              final estimatedCardHeight = 210.0;
              final estimatedDropHeight = widget.isOverviewMode ? 56.0 : 74.0;
              final contentPaddingBottom = widget.isOverviewMode ? 8.0 : 10.0;
              final contentPaddingTop = 4.0;
              final estimatedContentHeight =
                  filteredTasks.length * estimatedCardHeight +
                  contentPaddingTop +
                  contentPaddingBottom;
              final desiredShellHeight =
                  headerHeight + estimatedContentHeight + 8.0;

              // 🚀 Task 168.3: Set Dynamic Max Height Constraints and Align Limits
              final maxShellHeight = widget.isOverviewMode
                  ? math.min(
                      isMobile ? viewportHeight * 0.78 : viewportHeight * 0.90,
                      isMobile ? 640.0 : 940.0,
                    )
                  : math.min(
                      isMobile ? viewportHeight * 0.72 : viewportHeight * 0.84,
                      isMobile ? 580.0 : 800.0,
                    );
              final shellHeight = math.min(maxShellHeight, desiredShellHeight);

              return Container(
                height: shellHeight,
                decoration: BoxDecoration(
                  color: highlight
                      ? GlassColors.primary.withOpacity(0.045)
                      : Colors.white.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(ExecutiveRadius.xl),
                  border: Border.all(
                    color: highlight
                        ? GlassColors.primary.withOpacity(0.26)
                        : GlassColors.hairlineStrong.withOpacity(0.72),
                  ),
                ),
                child: Column(
                  children: [
                    KanbanColumnHeader(
                      board: widget.board,
                      columnName: widget.columnName,
                      taskCount: filteredTasks.length,
                      isDark: widget.isDark,
                      onAdd: widget.onAdd,
                      onSettings: widget.onSettings,
                      isOverviewMode: widget.isOverviewMode,
                      dragHandle: widget.activeOperativeId != null
                          ? null
                          : _buildColumnDragHandle(
                              columnWidth,
                              rawTasks.length,
                            ),
                    ),
                    Expanded(
                      child: ScrollbarGutterFrame(
                        gutterRadius: const BorderRadius.only(
                          bottomRight: Radius.circular(ExecutiveRadius.xl - 1),
                        ),
                        clipRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(ExecutiveRadius.xl - 1),
                          bottomRight: Radius.circular(ExecutiveRadius.xl - 1),
                        ),
                        gutterColor: Colors.white.withOpacity(0.005),
                        dividerColor: GlassColors.outlineVariant.withOpacity(0.12),
                        child: Scrollbar(
                          controller: _scrollController,
                          child: ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.fromLTRB(
                            12,
                            contentPaddingTop,
                            24,
                            contentPaddingBottom,
                          ),
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          itemCount: filteredTasks.length,
                          itemBuilder: (context, index) {
                            final task = filteredTasks[index];
                            final boardState = context.read<StateBoards>();
                            final memberProfiles =
                                <String, Map<String, String>>{};

                            for (final uid in task.members) {
                              final profile = boardState.getMemberProfile(uid);
                              if (profile != null) {
                                memberProfiles[uid] = profile;
                              }
                            }

                            return DragTarget<TaskModel>(
                              onAcceptWithDetails: (details) {
                                final draggedTask = details.data;
                                if (draggedTask.status == widget.columnName) {
                                  final fromIndex = rawTasks.indexWhere(
                                    (t) => t.id == draggedTask.id,
                                  );
                                  if (fromIndex != -1 && fromIndex != index) {
                                    state.reorderWithinColumn(
                                      widget.board,
                                      widget.columnName,
                                      fromIndex,
                                      index,
                                    );
                                  }
                                } else {
                                  state.updateTaskStatus(
                                    widget.board,
                                    draggedTask,
                                    widget.columnName,
                                  );
                                }
                              },
                              builder: (context, candidateData, rejectedData) {
                                return Column(
                                  children: [
                                    if (candidateData.isNotEmpty &&
                                        widget.activeOperativeId == null)
                                      AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        height: estimatedDropHeight,
                                        margin: const EdgeInsets.only(
                                          bottom: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: GlassColors.gold.withOpacity(
                                            0.05,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            ExecutiveRadius.m,
                                          ),
                                          border: Border.all(
                                            color: GlassColors.gold.withOpacity(
                                              0.28,
                                            ),
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            'PLACE HERE',
                                            style: GlassText.labelSM().copyWith(
                                              color: GlassColors.gold,
                                              letterSpacing: 1.4,
                                            ),
                                          ),
                                        ),
                                      ),
                                    KanbanTaskCard(
                                      key: ValueKey('task_${task.id}'),
                                      task: task,
                                      board: widget.board,
                                      isDark: widget.isDark,
                                      memberProfiles: memberProfiles,
                                      onTap: () => widget.onTaskTap(task),
                                      onToggleDone: (v) => state.updateTask(
                                        widget.board,
                                        task.copyWith(isCompleted: v),
                                      ),
                                      isSelectMode: widget.isSelectMode,
                                      isSelected: widget.selectedTaskIds.contains(
                                        task.id,
                                      ),
                                      onSelect: () => widget.onTaskSelect(task.id),
                                      isDraggable: widget.activeOperativeId == null,
                                      isOverviewMode: widget.isOverviewMode,
                                    ),
                                  ],
                                );
                              },
                            );
                          },
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
      ),
    );
  }
}

class KanbanColumnHeader extends StatelessWidget {
  final BoardModel board;
  final String columnName;
  final int taskCount;
  final bool isDark;
  final VoidCallback onAdd;
  final VoidCallback onSettings;
  final Widget? dragHandle;
  final bool isOverviewMode;

  const KanbanColumnHeader({
    super.key,
    required this.board,
    required this.columnName,
    required this.taskCount,
    required this.isDark,
    required this.onAdd,
    required this.onSettings,
    this.dragHandle,
    this.isOverviewMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        isOverviewMode ? 10 : 12,
        24,
        isOverviewMode ? 8 : 10,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: GlassColors.hairlineStrong.withOpacity(0.72),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                if (dragHandle != null) ...[
                  dragHandle!,
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(
                    columnName.toUpperCase(),
                    overflow: TextOverflow.ellipsis,
                    style: GlassText.labelSM().copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: isOverviewMode ? 0.4 : 1.1,
                      color: GlassColors.onSurfaceVariant,
                      fontSize: isOverviewMode ? 9 : 10,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: GlassColors.hairlineStrong.withOpacity(0.75),
                    ),
                  ),
                  child: Text(
                    taskCount.toString(),
                    style: GlassText.label().copyWith(
                      fontSize: 8,
                      color: GlassColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!isOverviewMode)
            Row(
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  onPressed: onAdd,
                  color: GlassColors.onSurfaceVariant,
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.more_horiz_rounded, size: 18),
                  onPressed: onSettings,
                  color: GlassColors.onSurfaceVariant,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
