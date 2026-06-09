import 'package:flutter/material.dart';

import '../../../models/board_model.dart';
import '../../../models/task_model.dart';
import '../../../models/workspace_model.dart';
import '../../common/responsive_layout.dart';
import '../../theme/glass_theme.dart';
import 'task_type_icon.dart';

class UnscheduledTaskBucket extends StatelessWidget {
  final List<TaskModel> tasks;
  final List<BoardModel> boards;
  final List<WorkspaceModel> workspaces;
  final ValueChanged<TaskModel> onTaskTap;
  final void Function(TaskModel task, bool value) onToggleComplete;

  const UnscheduledTaskBucket({
    super.key,
    required this.tasks,
    required this.boards,
    required this.workspaces,
    required this.onTaskTap,
    required this.onToggleComplete,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final sortedTasks = [...tasks]
      ..sort((a, b) {
        if (a.isCompleted != b.isCompleted) {
          return a.isCompleted ? 1 : -1;
        }
        return b.updatedAt.compareTo(a.updatedAt);
      });

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(ExecutiveRadius.xl),
        border: Border.all(color: GlassColors.ghostBorder),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: GlassColors.gold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${sortedTasks.length}',
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
            child: sortedTasks.isEmpty
                ? Center(
                    child: Text(
                      'No unscheduled tasks',
                      textAlign: TextAlign.center,
                      style: GlassText.bodyMD().copyWith(
                        color: GlassColors.onSurface.withOpacity(0.3),
                        fontSize: 11,
                      ),
                    ),
                  )
                : ListView.builder(
                    scrollDirection: isMobile ? Axis.horizontal : Axis.vertical,
                    itemCount: sortedTasks.length,
                    itemBuilder: (context, index) {
                      final task = sortedTasks[index];
                      return Container(
                        width: isMobile ? 260 : double.infinity,
                        margin: isMobile
                            ? const EdgeInsets.only(right: 12)
                            : const EdgeInsets.only(bottom: 10),
                        child: _buildTaskCard(task),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(TaskModel task) {
    final board = _findBoard(task);
    final boardColor = board != null ? Color(board.color) : GlassColors.primary;
    final workspaceName = _workspaceName(board);
    final sourceLabel = '$workspaceName / ${board?.name ?? 'Unknown board'}';
    final isCompleted = task.isCompleted;

    return InkWell(
      onTap: () => onTaskTap(task),
      borderRadius: BorderRadius.circular(ExecutiveRadius.m),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isCompleted
              ? boardColor.withOpacity(0.16)
              : boardColor.withOpacity(0.24),
          borderRadius: BorderRadius.circular(ExecutiveRadius.m),
          border: Border.all(
            color: boardColor.withOpacity(isCompleted ? 0.22 : 0.38),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: isCompleted,
                onChanged: (value) {
                  if (value == null) return;
                  onToggleComplete(task, value);
                },
                activeColor: GlassColors.success,
                side: BorderSide(
                  color: GlassColors.onSurface.withOpacity(0.38),
                  width: 1.3,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        calendarTaskTypeIcon(task.type),
                        size: 13,
                        color: calendarTaskTypeColor(
                          task.type,
                          active: !isCompleted,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          task.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GlassText.bodyMD().copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            decoration: isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            color: GlassColors.onSurface.withOpacity(
                              isCompleted ? 0.48 : 0.94,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (task.description.trim().isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      task.description.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GlassText.bodyMD().copyWith(
                        fontSize: 10,
                        height: 1.15,
                        color: GlassColors.onSurface.withOpacity(
                          isCompleted ? 0.34 : 0.64,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    sourceLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GlassText.labelSM().copyWith(
                      fontSize: 8.2,
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
          ],
        ),
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
}
