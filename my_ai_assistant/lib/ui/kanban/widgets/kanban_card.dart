import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../config/env_config.dart';
import '../../../models/task_model.dart';
import '../../../models/board_model.dart';
import '../../../state_managers/state_tasks.dart';
import '../../theme/glass_theme.dart';

class KanbanTaskCard extends StatelessWidget {
  final TaskModel task;
  final BoardModel board;
  final bool isDark;
  final Map<String, Map<String, String>> memberProfiles;
  final VoidCallback onTap;
  final Function(bool) onToggleDone;
  final bool isSelectMode;
  final bool isSelected;
  final VoidCallback? onSelect;
  final bool isDraggable;
  final bool isOverviewMode; // 🚀 Task 76.3: Tactical Zoom

  const KanbanTaskCard({
    super.key,
    required this.task,
    required this.board,
    required this.isDark,
    required this.memberProfiles,
    required this.onTap,
    required this.onToggleDone,
    this.isSelectMode = false,
    this.isSelected = false,
    this.onSelect,
    this.isDraggable = true,
    this.isOverviewMode = false,
  });

  @override
  Widget build(BuildContext context) {
    // 🚀 Task 64.3: Subscribe to individual task notifier for millisecond updates
    final state = context.read<StateTasks>();
    final notifier = state.getTaskNotifier(task.id);

    if (notifier == null) return _buildFullCard(context, task);

    return ValueListenableBuilder<TaskModel>(
      valueListenable: notifier,
      builder: (context, latestTask, _) {
        return _buildFullCard(context, latestTask);
      },
    );
  }

  Widget _buildFullCard(BuildContext context, TaskModel currentTask) {
    TaskImage? coverImage;
    if (currentTask.images.isNotEmpty) {
      try {
        coverImage = currentTask.images.firstWhere(
          (img) => img.isCover,
          orElse: () => currentTask.images.first,
        );
      } catch (_) {
        coverImage = currentTask.images.first;
      }
    }

    // 🚀 Task 76.3: Dynamic Scaling
    final double cardPaddingH = isOverviewMode ? 12 : 16;
    final double cardPaddingV = isOverviewMode ? 12 : 14;
    final double titleSize = isOverviewMode ? 13 : 15;
    final double imageHeight = isOverviewMode ? 84 : 108;
    final hasCover = coverImage != null && coverImage.url.isNotEmpty;
    final double headerTopInset = hasCover ? 12 : cardPaddingV;
    final double checkboxSlotSize = isOverviewMode ? 0 : 34;
    final double dragSlotSize = isOverviewMode ? 28 : 40;
    final double overlayTop =
        (hasCover ? imageHeight : 0) + headerTopInset - 4;

    final cardContent = Padding(
      padding: EdgeInsets.only(bottom: isOverviewMode ? 8 : 12),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.025)
              : Colors.black.withOpacity(0.018),
          borderRadius: BorderRadius.circular(ExecutiveRadius.l),
          border: Border.all(
            color: GlassColors.hairlineStrong.withOpacity(0.72),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasCover)
              SizedBox(
                height: imageHeight,
                width: double.infinity,
                child: Image.network(
                  EnvConfig.sanitizeUrl(coverImage.url),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: imageHeight,
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      size: 24,
                      color: GlassColors.primary.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                cardPaddingH,
                hasCover ? 12 : cardPaddingV,
                cardPaddingH,
                cardPaddingV,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (!isOverviewMode)
                        Opacity(
                          opacity: 0,
                          child: SizedBox(
                            width: checkboxSlotSize,
                            height: checkboxSlotSize,
                            child: Checkbox(value: false, onChanged: null),
                          ),
                        ),
                      if (!isOverviewMode) const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          currentTask.title,
                          maxLines: isOverviewMode ? 2 : 3,
                          overflow: TextOverflow.ellipsis,
                          style: GlassText.headlineLG().copyWith(
                            fontSize: titleSize,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0,
                            decoration: currentTask.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            color: currentTask.isCompleted
                                ? GlassColors.onSurface.withOpacity(0.3)
                                : GlassColors.onSurface,
                          ),
                        ),
                      ),
                      SizedBox(width: dragSlotSize),
                    ],
                  ),
                  if (currentTask.labelIds.isNotEmpty && !isOverviewMode) ...[
                    const SizedBox(height: 10),
                    _buildLabelPills(currentTask),
                  ],
                  if (currentTask.description.isNotEmpty &&
                      !isOverviewMode) ...[
                    const SizedBox(height: 10),
                    Text(
                      currentTask.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GlassText.bodyMD().copyWith(
                        fontSize: 12,
                        color: GlassColors.onSurface.withOpacity(0.56),
                        height: 1.4,
                      ),
                    ),
                  ],
                  if (currentTask.hasChecklist) ...[
                    const SizedBox(height: 10),
                    _buildChecklistProgress(currentTask),
                  ],
                  SizedBox(height: isOverviewMode ? 12 : 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: GlassColors.primary.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                DateFormat(
                                  'MMM d',
                                ).format(currentTask.dueDate).toUpperCase(),
                                style: GlassText.labelSM().copyWith(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: GlassColors.primary.withOpacity(0.7),
                                ),
                              ),
                            ),
                            if (isOverviewMode &&
                                currentTask.labelIds.isNotEmpty)
                              ...board.labels
                                  .where(
                                    (l) =>
                                        currentTask.labelIds.contains(l['id']),
                                  )
                                  .map((l) {
                                    final color = Color(
                                      l['color'] as int? ??
                                          GlassColors.primary.value,
                                    );
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: color.withOpacity(0.3),
                                        ),
                                      ),
                                      child: Text(
                                        (l['name'] as String).toUpperCase(),
                                        style: GlassText.labelSM().copyWith(
                                          fontSize: 7,
                                          color: color,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  }),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      _buildAvatarStack(currentTask),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return Stack(
      children: [
        cardContent,
        if (!isSelectMode)
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(ExecutiveRadius.m),
              ),
            ),
          ),

        if (!isSelectMode && !isOverviewMode)
          Positioned(
            left: 10,
            top: overlayTop,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.all(6),
                color: Colors.transparent,
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: Checkbox(
                    value: currentTask.isCompleted,
                    onChanged: (v) => onToggleDone(v ?? false),
                    activeColor: GlassColors.success,
                    side: BorderSide(
                      color: GlassColors.primary.withOpacity(0.4),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(ExecutiveRadius.s),
                    ),
                  ),
                ),
              ),
            ),
          ),

        if (isSelectMode)
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onSelect,
                borderRadius: BorderRadius.circular(ExecutiveRadius.m),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? GlassColors.gold.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(ExecutiveRadius.m),
                    border: isSelected
                        ? Border.all(color: GlassColors.gold, width: 2)
                        : null,
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Icon(
                      isSelected
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: isSelected
                          ? GlassColors.gold
                          : Colors.white.withOpacity(0.2),
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),

        if (!isSelectMode && isDraggable)
          Positioned(
            right: 8,
            top: overlayTop - (isOverviewMode ? 0 : 3),
            child: Draggable<TaskModel>(
              data: currentTask,
              feedback: Material(
                color: Colors.transparent,
                child: Transform.rotate(
                  angle: 0.05,
                  child: SizedBox(
                    width: isOverviewMode ? 240 : 340,
                    child: Opacity(opacity: 0.9, child: cardContent),
                  ),
                ),
              ),
              childWhenDragging: Opacity(opacity: 0.2, child: cardContent),
              child: Container(
                padding: EdgeInsets.all(isOverviewMode ? 6 : 12),
                color: Colors.transparent,
                child: Icon(
                  Icons.drag_indicator_rounded,
                  color: Colors.white30,
                  size: isOverviewMode ? 18 : 24,
                ),
              ),
            ),
          ),

        if (!isSelectMode && !isDraggable)
          Positioned(
            right: 8,
            top: overlayTop - (isOverviewMode ? 0 : 3),
            child: Container(
              padding: EdgeInsets.all(isOverviewMode ? 6 : 12),
              child: Icon(
                Icons.lock_outline_rounded,
                color: Colors.white.withOpacity(0.1),
                size: isOverviewMode ? 16 : 20,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildChecklistProgress(TaskModel currentTask) {
    final total = currentTask.checklistTotalCount;
    final done = currentTask.checklistDoneCount;
    final progress = total == 0 ? 0.0 : done / total;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isOverviewMode ? 10 : 12,
        vertical: isOverviewMode ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: GlassColors.success.withOpacity(0.07),
        borderRadius: BorderRadius.circular(ExecutiveRadius.m),
        border: Border.all(color: GlassColors.success.withOpacity(0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                size: isOverviewMode ? 14 : 15,
                color: GlassColors.success,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Checklist',
                  style: GlassText.labelSM().copyWith(
                    fontSize: isOverviewMode ? 9 : 10,
                    fontWeight: FontWeight.w700,
                    color: GlassColors.success,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              Text(
                '$done/$total',
                style: GlassText.labelSM().copyWith(
                  fontSize: isOverviewMode ? 9 : 10,
                  fontWeight: FontWeight.w800,
                  color: GlassColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: isOverviewMode ? 4 : 5,
              value: progress,
              backgroundColor: GlassColors.success.withOpacity(0.12),
              valueColor: const AlwaysStoppedAnimation<Color>(
                GlassColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabelPills(TaskModel currentTask) {
    final activeLabels = board.labels
        .where((l) => currentTask.labelIds.contains(l['id']))
        .toList();
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: activeLabels.map((l) {
        final color = Color(l['color'] as int? ?? GlassColors.primary.value);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Text(
            (l['name'] as String).toUpperCase(),
            style: GlassText.labelSM().copyWith(
              fontSize: 7,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAvatarStack(TaskModel currentTask) {
    if (currentTask.members.isEmpty) return const SizedBox.shrink();
    final scale = isOverviewMode ? 0.8 : 1.0;
    final maxShown = 3;
    final membersToShow = currentTask.members.take(maxShown).toList();
    final double avatarSize = 24.0 * scale;
    final double overlapSpacing = 16.0 * scale;

    return SizedBox(
      width: avatarSize + (membersToShow.length - 1) * overlapSpacing,
      height: avatarSize,
      child: Stack(
        children: List.generate(membersToShow.length, (index) {
          final uid = membersToShow[index];
          final profile = memberProfiles[uid];
          final name = profile?['name'] ?? 'Operative';
          final photo = profile?['photo'] ?? '';
          final color = GlassColors.getMemberColor(uid);

          return Positioned(
            left: index * overlapSpacing,
            top: 0,
            width: avatarSize,
            height: avatarSize,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.2),
                border: Border.all(color: GlassColors.background, width: 2),
              ),
              child: ClipOval(
                child: photo.isNotEmpty
                    ? Image.network(
                        EnvConfig.sanitizeUrl(photo),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: TextStyle(
                              fontSize: 9 * scale,
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: TextStyle(
                            fontSize: 9 * scale,
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
