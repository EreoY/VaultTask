import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/task_model.dart';
import '../../../models/board_model.dart';
import '../../../state_managers/state_tasks.dart';
import '../../../state_managers/state_boards.dart';
import '../../theme/glass_theme.dart';
import 'kanban_card.dart';
import '../../common/responsive_layout.dart';

class KanbanColumnWidget extends StatelessWidget {
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
  final bool isOverviewMode; // 🚀 Task 76.3: Tactical Zoom

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
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);

    // 🚀 Task 76.3: Dynamic Scaling Logic
    final double baseWidth = isMobile ? screenWidth * 0.82 : (isTablet ? 320.0 : 360.0);
    final double columnWidth = isOverviewMode ? (isMobile ? baseWidth * 0.7 : 260.0) : baseWidth;

    return Container(
      width: columnWidth,
      margin: EdgeInsets.zero,
      child: DragTarget<TaskModel>(
        onAcceptWithDetails: (details) {
          final task = details.data;
          if (task.status != columnName) {
            context.read<StateTasks>().updateTaskStatus(board, task, columnName);
          }
        },
        builder: (context, candidateData, rejectedData) {
          return GestureDetector(
            onLongPress: () {},
            child: Container(
              decoration: BoxDecoration(
                color: candidateData.isNotEmpty ? GlassColors.primary.withOpacity(0.05) : Colors.transparent,
                borderRadius: BorderRadius.circular(ExecutiveRadius.xl),
              ),
              child: Column(
                children: [
                  // Header
                  Consumer<StateTasks>(
                    builder: (context, state, child) {
                      final rawTasks = state.tasksForBoard(board.id).where((t) => t.status == columnName).toList();
                      final filteredTasks = activeOperativeId == null 
                          ? rawTasks 
                          : rawTasks.where((t) => t.members.contains(activeOperativeId)).toList();

                      return KanbanColumnHeader(
                        board: board,
                        columnName: columnName,
                        taskCount: filteredTasks.length,
                        isDark: isDark,
                        onAdd: onAdd,
                        onSettings: onSettings,
                        isOverviewMode: isOverviewMode,
                        dragHandle: activeOperativeId != null ? null : LongPressDraggable<int>(
                          data: columnIndex,
                          axis: Axis.horizontal,
                          delay: const Duration(milliseconds: 300),
                          feedback: Material(
                            color: Colors.transparent,
                            child: Opacity(
                              opacity: 0.9,
                              child: Transform.scale(
                                scale: 0.95,
                                child: Container(
                                  width: 320,
                                  decoration: GlassDecorations.surface(radius: ExecutiveRadius.xl, hasShadow: true),
                                  child: KanbanColumnHeader(
                                    board: board,
                                    columnName: columnName,
                                    taskCount: rawTasks.length,
                                    isDark: isDark,
                                    onAdd: () {},
                                    onSettings: () {},
                                    dragHandle: const Icon(Icons.drag_indicator_rounded, color: GlassColors.gold, size: 24),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          childWhenDragging: const Opacity(opacity: 0.1, child: Icon(Icons.drag_indicator_rounded, color: Colors.white12, size: 24)),
                          child: const MouseRegion(
                            cursor: SystemMouseCursors.grab,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Icon(Icons.drag_indicator_rounded, color: Colors.white24, size: 24),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  // Independent Task List
                  Expanded(
                    child: Consumer<StateTasks>(
                      builder: (context, state, child) {
                        final rawTasks = state.tasksForBoard(board.id).where((t) => t.status == columnName).toList();
                        final filteredTasks = activeOperativeId == null 
                            ? rawTasks 
                            : rawTasks.where((t) => t.members.contains(activeOperativeId)).toList();
                        
                        return ListView.builder(
                          itemCount: filteredTasks.length,
                          itemBuilder: (context, index) {
                            final task = filteredTasks[index];
                            final boardState = context.read<StateBoards>();
                            final memberProfiles = <String, Map<String, String>>{};
                            for (final uid in task.members) {
                              final profile = boardState.getMemberProfile(uid);
                              if (profile != null) memberProfiles[uid] = profile;
                            }

                            return DragTarget<TaskModel>(
                              onAcceptWithDetails: (details) {
                                final draggedTask = details.data;
                                if (draggedTask.status == columnName) {
                                  final fromIndex = rawTasks.indexWhere((t) => t.id == draggedTask.id);
                                  if (fromIndex != -1 && fromIndex != index) {
                                    state.reorderWithinColumn(board, columnName, fromIndex, index);
                                  }
                                } else {
                                  state.updateTaskStatus(board, draggedTask, columnName);
                                }
                              },
                              builder: (context, candidateData, rejectedData) {
                                return Column(
                                  children: [
                                    if (candidateData.isNotEmpty && activeOperativeId == null)
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        height: isOverviewMode ? 60 : 100,
                                        margin: const EdgeInsets.only(bottom: 12),
                                        decoration: BoxDecoration(
                                          color: GlassColors.gold.withOpacity(0.05),
                                          borderRadius: BorderRadius.circular(ExecutiveRadius.m),
                                          border: Border.all(color: GlassColors.gold.withOpacity(0.3), width: 1.5),
                                        ),
                                        child: Center(child: Text('PLACE HERE', style: GlassText.labelSM().copyWith(color: GlassColors.gold, letterSpacing: 2))),
                                      ),
                                    KanbanTaskCard(
                                      key: ValueKey('task_${task.id}'),
                                      task: task,
                                      board: board,
                                      isDark: isDark,
                                      memberProfiles: memberProfiles,
                                      onTap: () => onTaskTap(task),
                                      onToggleDone: (v) => state.updateTask(board, task.copyWith(isCompleted: v)),
                                      isSelectMode: isSelectMode,
                                      isSelected: selectedTaskIds.contains(task.id),
                                      onSelect: () => onTaskSelect(task.id),
                                      isDraggable: activeOperativeId == null,
                                      isOverviewMode: isOverviewMode, // 🚀 Task 76.3
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
                ],
              ),
            ),
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
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: isOverviewMode ? 8 : 16),
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
                    style: GlassText.labelSM().copyWith(
                      fontWeight: FontWeight.bold, 
                      letterSpacing: isOverviewMode ? 0.5 : 1.5, 
                      color: GlassColors.primary,
                      fontSize: isOverviewMode ? 8 : 10,
                      overflow: TextOverflow.ellipsis,
                    )
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: GlassColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Text(taskCount.toString(), style: GlassText.label().copyWith(fontSize: 8, color: GlassColors.primary)),
                ),
              ],
            ),
          ),
          if (!isOverviewMode)
            Row(
              children: [
                IconButton(icon: const Icon(Icons.add_rounded, size: 20), onPressed: onAdd, color: GlassColors.primary),
                IconButton(icon: const Icon(Icons.more_horiz_rounded, size: 20), onPressed: onSettings, color: GlassColors.onSurfaceVariant),
              ],
            ),
        ],
      ),
    );
  }
}
