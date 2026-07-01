import 'package:flutter/material.dart';
import '../common/ime_safe_text_field.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/board_model.dart';
import '../../models/task_model.dart';
import '../../models/workspace_model.dart';
import '../../state_managers/state_boards.dart';
import '../../state_managers/state_tasks.dart';
import '../theme/glass_theme.dart';
import '../common/responsive_layout.dart';
import '../common/glass_widgets.dart';
import '../kanban/widgets/task_edit_modal.dart';
import 'widgets/dashboard_widgets.dart';

class DashboardPage extends StatefulWidget {
  final bool isDark;
  final ValueChanged<int>? onNavigate;
  final bool isActive;
  const DashboardPage({
    super.key,
    required this.isDark,
    this.onNavigate,
    this.isActive = true,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _milestonesLimit = 3;
  int _activityLimit = 10;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final boardsState = context.read<StateBoards>();
      await boardsState.fetchAllBoards();
      if (!mounted) return;
      await context.read<StateTasks>().fetchAllTasks(boardsState.boards);
    });
  }

  void _openTask(BuildContext context, BoardModel board, TaskModel task) {
    TaskEditModal.show(
      context: context,
      board: board,
      existingTask: task,
      isDark: widget.isDark,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final boardsState = context.watch<StateBoards>();
    final boards = boardsState.boards;
    final workspaces = boardsState.workspaces;
    final tasksState = context.watch<StateTasks>();

    // 1. Gather all tasks and compute milestones / activity updates
    final List<MilestoneItem> milestoneItems = [];
    final List<ActivityItem> activityItems = [];

    for (final board in boards) {
      final boardTasks = tasksState.tasksForBoard(board.id);
      for (final task in boardTasks) {
        if (!task.isCompleted) {
          milestoneItems.add(MilestoneItem(task: task, board: board));
        }
        for (final comment in task.comments) {
          activityItems.add(
            ActivityItem(comment: comment, task: task, board: board),
          );
        }
      }
    }

    // Sort milestones by closest due date first
    milestoneItems.sort((a, b) => a.task.dueDate.compareTo(b.task.dueDate));
    // Sort activity feed by newest comment first
    activityItems.sort((a, b) => b.comment.time.compareTo(a.comment.time));

    final unreadCommentIds = activityItems
        .where((item) => !tasksState.readCommentIds.contains(item.comment.id))
        .map((item) => item.comment.id)
        .toList();

    return SingleChildScrollView(
          padding: EdgeInsets.all(ExecutiveSpacing.containerPadding(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AetherStaggeredFadeIn(
                index: 0,
                isActive: widget.isActive,
                child: _buildGlassHeroSection(
                  workspaces.length,
                  boards.length,
                  tasksState.unreadCommentsCount,
                  milestoneItems.length,
                ),
              ),
              const SizedBox(height: 18),
              _buildHeader(workspaces.length, tasksState.unreadCommentsCount),
              SizedBox(height: isDesktop ? 24 : 20),

              isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            children: [
                              AetherStaggeredFadeIn(
                                index: 1,
                                isActive: widget.isActive,
                                child: _buildWorkspacesList(workspaces, boards),
                              ),
                              const SizedBox(height: 24),
                              AetherStaggeredFadeIn(
                                index: 2,
                                isActive: widget.isActive,
                                child: _buildMilestonesCard(milestoneItems),
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                        SizedBox(width: ExecutiveSpacing.gutter(context)),
                        Expanded(
                          flex: 2,
                          child: AetherStaggeredFadeIn(
                            index: 3,
                            isActive: widget.isActive,
                            child: _buildActivityFeedCard(
                              activityItems,
                              unreadCommentIds,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        AetherStaggeredFadeIn(
                          index: 1,
                          isActive: widget.isActive,
                          child: _buildWorkspacesList(workspaces, boards),
                        ),
                        const SizedBox(height: 24),
                        AetherStaggeredFadeIn(
                          index: 2,
                          isActive: widget.isActive,
                          child: _buildMilestonesCard(milestoneItems),
                        ),
                        const SizedBox(height: 24),
                        AetherStaggeredFadeIn(
                          index: 3,
                          isActive: widget.isActive,
                          child: _buildActivityFeedCard(activityItems, unreadCommentIds),
                        ),
                      ],
                    ),
            ],
          ),
    );
  }

  Widget _buildGlassHeroSection(
    int workspaceCount,
    int boardCount,
    int unreadCount,
    int milestoneCount,
  ) {
    return GlassCard(
      isDark: false,
      radius: 28,
      padding: const EdgeInsets.all(24),
      hasAmbientGlow: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildGlassTag('Glassmorphism active', Icons.auto_awesome_rounded),
                    _buildGlassTag('Live dashboard', Icons.dashboard_rounded),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'A premium dashboard with frosted surfaces and ambient depth.',
                  style: GlassText.headlineLG().copyWith(
                    fontSize: 34,
                    height: 1.15,
                    letterSpacing: -0.8,
                    color: GlassColors.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Text(
                    'Designed with high-fidelity glassmorphism, combining soft backdrops, subtle outlines, and glowing coordinates to keep your workspace clear and focused.',
                    style: GlassText.bodyLG().copyWith(
                      color: GlassColors.onSurfaceVariant.withOpacity(0.7),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildGlassButton(
                      label: 'Open Boards',
                      icon: Icons.grid_view_rounded,
                      accent: const Color(0xFFE19B6B),
                      onPressed: () => widget.onNavigate?.call(1),
                    ),
                    _buildGlassButton(
                      label: 'Open Chat',
                      icon: Icons.chat_bubble_outline_rounded,
                      accent: const Color(0xFFB8A2F2),
                      onPressed: () => widget.onNavigate?.call(3),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.end,
            children: [
              _buildMetricChip(
                icon: Icons.workspaces_rounded,
                label: 'Workspaces',
                value: workspaceCount.toString(),
                accent: const Color(0xFFE19B6B),
              ),
              _buildMetricChip(
                icon: Icons.view_kanban_rounded,
                label: 'Boards',
                value: boardCount.toString(),
                accent: const Color(0xFFB8A2F2),
              ),
              _buildMetricChip(
                icon: Icons.alarm_rounded,
                label: 'Pending',
                value: milestoneCount.toString(),
                accent: const Color(0xFFF0B96C),
              ),
              _buildMetricChip(
                icon: Icons.notifications_none_rounded,
                label: 'Unread',
                value: unreadCount.toString(),
                accent: const Color(0xFFE67E7E),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlassTag(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: GlassColors.primary.withOpacity(0.04),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: GlassColors.primary.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: GlassColors.primary.withOpacity(0.8)),
          const SizedBox(width: 8),
          Text(
            label.toUpperCase(),
            style: GlassText.labelSM().copyWith(
              color: GlassColors.onSurfaceVariant.withOpacity(0.9),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassButton({
    required String label,
    required IconData icon,
    required Color accent,
    VoidCallback? onPressed,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: accent.withOpacity(0.06),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: accent.withOpacity(0.24)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: accent),
              const SizedBox(width: 10),
              Text(
                label.toUpperCase(),
                style: GlassText.labelSM().copyWith(
                  color: GlassColors.onSurface,
                  fontSize: 12,
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricChip({
    required IconData icon,
    required String label,
    required String value,
    Color accent = GlassColors.primary,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: GlassColors.surface.withOpacity(0.4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: GlassColors.ghostBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: accent),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: GlassText.headlineMD().copyWith(
                  fontSize: 22,
                  height: 1.0,
                  color: GlassColors.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label.toUpperCase(),
                style: GlassText.labelSM().copyWith(
                  fontSize: 9,
                  color: GlassColors.onSurfaceVariant.withOpacity(0.6),
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlassOrb(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withOpacity(0.15), color.withOpacity(0.0)],
        ),
      ),
    );
  }

  Widget _buildHeader(int workspaceCount, int unreadCount) {
    final now = DateTime.now();
    final isSmall = MediaQuery.of(context).size.width < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: GlassColors.onSurface.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: GlassColors.onSurface.withOpacity(0.12),
                ),
              ),
              child: Text(
                '$workspaceCount Workspaces',
                style: GlassText.bodyMD().copyWith(
                  fontSize: 11,
                  color: GlassColors.onSurfaceVariant.withOpacity(0.8),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.notifications_none_rounded,
                  color: GlassColors.onSurfaceVariant.withOpacity(0.6),
                  size: 20,
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: GlassColors.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Center(
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'STRATEGIC HUB',
          style: GlassText.headlineXL().copyWith(
            fontSize: isSmall ? 30 : 46,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
            height: 1.0,
            color: GlassColors.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Today is ${DateFormat('EEEE, MMMM d').format(now)}',
          style: GlassText.bodyLG().copyWith(
            color: GlassColors.onSurfaceVariant.withOpacity(0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildWorkspacesList(
    List<WorkspaceModel> workspaces,
    List<BoardModel> boards,
  ) {
    final boardsState = context.read<StateBoards>();

    return DashboardBentoCard(
      title: 'Active Workspaces',
      icon: Icons.assignment_outlined,
      isDark: widget.isDark,
      trailing: _buildGhostButton(
        '+ JOIN WORKSPACE',
        Icons.person_add_rounded,
        onTap: () => _showJoinWorkspaceDialog(context),
      ),
      child: workspaces.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'No active workspaces found. Join or create one.',
                style: GlassText.bodyMD().copyWith(
                  color: GlassColors.onSurfaceVariant.withOpacity(0.5),
                ),
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: workspaces.length,
              separatorBuilder: (context, index) =>
                  Divider(height: 1, color: GlassColors.ghostBorder),
              itemBuilder: (context, index) {
                final workspace = workspaces[index];
                final workspaceBoards = boards
                    .where((b) => b.workspaceId == workspace.id)
                    .toList();

                return InkWell(
                  onTap: () {
                    boardsState.setSelectedWorkspace(workspace);
                    boardsState.setSelectedBoard(null);
                    widget.onNavigate?.call(1);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 8,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: GlassColors.primary.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: GlassColors.primary.withOpacity(0.12),
                            ),
                          ),
                          child: Icon(
                            workspace.type == 'personal'
                                ? Icons.person_rounded
                                : Icons.group_rounded,
                            color: GlassColors.primary,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    workspace.name,
                                    style: GlassText.bodyMD().copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: GlassColors.onSurface
                                          .withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      workspace.type.toUpperCase(),
                                      style: GlassText.labelSM().copyWith(
                                        fontSize: 8,
                                        color: GlassColors.onSurfaceVariant
                                            .withOpacity(0.8),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (workspaceBoards.isEmpty)
                                Text(
                                  'No projects inside this workspace',
                                  style: GlassText.secondary().copyWith(
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                  ),
                                )
                              else
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: workspaceBoards.map((board) {
                                    return InkWell(
                                      onTap: () {
                                        boardsState.setSelectedWorkspace(
                                          workspace,
                                        );
                                        boardsState.setSelectedBoard(board);
                                        widget.onNavigate?.call(1);
                                      },
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: GlassColors.onSurface
                                              .withOpacity(0.04),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: GlassColors.onSurface
                                                .withOpacity(0.08),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 6,
                                              height: 6,
                                              decoration: BoxDecoration(
                                                color: Color(board.color),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              board.name,
                                              style: GlassText.bodyMD()
                                                  .copyWith(
                                                    fontSize: 11,
                                                    color: GlassColors
                                                        .onSurface
                                                        .withOpacity(0.9),
                                                    fontWeight:
                                                        FontWeight.w600,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.edit_rounded,
                            size: 16,
                            color: GlassColors.onSurfaceVariant.withOpacity(
                              0.5,
                            ),
                          ),
                          tooltip: 'Rename Workspace',
                          onPressed: () =>
                              _showRenameWorkspaceDialog(context, workspace),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.copy_rounded,
                            size: 16,
                            color: GlassColors.onSurfaceVariant.withOpacity(
                              0.5,
                            ),
                          ),
                          tooltip: 'Copy Workspace ID',
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: workspace.id),
                            );
                            GlassNotifications.show(
                              context,
                              'Workspace ID copied to clipboard',
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildMilestonesCard(List<MilestoneItem> milestoneItems) {
    final displayedMilestones = milestoneItems.take(_milestonesLimit).toList();
    final hasMore = milestoneItems.length > _milestonesLimit;

    return DashboardBentoCard(
      title: 'Upcoming Milestones',
      icon: Icons.alarm_rounded,
      isDark: widget.isDark,
      child: displayedMilestones.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'No pending milestones.',
                style: GlassText.bodyMD().copyWith(
                  color: GlassColors.onSurfaceVariant.withOpacity(0.5),
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayedMilestones.length,
                  separatorBuilder: (context, index) =>
                      Divider(height: 1, color: GlassColors.ghostBorder),
                  itemBuilder: (context, index) {
                    final item = displayedMilestones[index];
                    final task = item.task;
                    final board = item.board;

                    final now = DateTime.now();
                    final diff = task.dueDate.difference(now);
                    final isOverdue = diff.isNegative;
                    final daysLeft = diff.inDays;

                    String dueText;
                    Color dueColor;
                    if (isOverdue) {
                      dueText = 'Overdue';
                      dueColor = GlassColors.error;
                    } else if (daysLeft == 0) {
                      dueText = 'Due Today';
                      dueColor = GlassColors.gold;
                    } else if (daysLeft == 1) {
                      dueText = 'Due Tomorrow';
                      dueColor = GlassColors.gold;
                    } else {
                      dueText = 'Due in $daysLeft days';
                      dueColor = GlassColors.primary;
                    }

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              task.title,
                              style: GlassText.bodyMD().copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            dueText.toUpperCase(),
                            style: GlassText.labelSM().copyWith(
                              fontSize: 8,
                              color: dueColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      subtitle: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Color(board.color).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              board.name.toUpperCase(),
                              style: GlassText.labelSM().copyWith(
                                fontSize: 8,
                                color: Color(board.color),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            task.status.toUpperCase(),
                            style: GlassText.secondary().copyWith(fontSize: 10),
                          ),
                        ],
                      ),
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: GlassColors.onSurfaceVariant.withOpacity(0.3),
                      ),
                      onTap: () => _openTask(context, board, task),
                    );
                  },
                ),
                if (hasMore) ...[
                  const SizedBox(height: 16),
                  Center(
                    child: _buildGhostButton(
                      '+ LOAD MORE',
                      Icons.expand_more_rounded,
                      onTap: () {
                        setState(() {
                          _milestonesLimit += 5;
                        });
                      },
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildActivityFeedCard(
    List<ActivityItem> activityItems,
    List<String> unreadCommentIds,
  ) {
    final displayedActivities = activityItems.take(_activityLimit).toList();
    final hasMore = activityItems.length > _activityLimit;
    final tasksState = context.watch<StateTasks>();

    return DashboardBentoCard(
      title: 'Discussion Updates',
      icon: Icons.chat_bubble_outline_rounded,
      isDark: widget.isDark,
      trailing: unreadCommentIds.isNotEmpty
          ? _buildGhostButton(
              'MARK ALL READ',
              Icons.done_all_rounded,
              onTap: () => context.read<StateTasks>().markCommentsAsRead(
                unreadCommentIds,
              ),
            )
          : null,
      child: displayedActivities.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'No recent updates or discussion points.',
                style: GlassText.bodyMD().copyWith(
                  color: GlassColors.onSurfaceVariant.withOpacity(0.5),
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayedActivities.length,
                  separatorBuilder: (context, index) =>
                      Divider(height: 1, color: GlassColors.ghostBorder),
                  itemBuilder: (context, index) {
                    final item = displayedActivities[index];
                    final comment = item.comment;
                    final task = item.task;
                    final board = item.board;
                    final isUnread = !tasksState.readCommentIds.contains(
                      comment.id,
                    );
                    final memberColor = GlassColors.getMemberColor(
                      comment.userId,
                    );

                    return InkWell(
                      onTap: () async {
                        await context.read<StateTasks>().markCommentAsRead(
                          comment.id,
                        );
                        if (mounted) {
                          _openTask(context, board, task);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: memberColor.withOpacity(0.1),
                              child: Text(
                                comment.userName.isNotEmpty
                                    ? comment.userName[0].toUpperCase()
                                    : '?',
                                style: GlassText.labelSM().copyWith(
                                  color: memberColor,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          comment.userName,
                                          style: GlassText.bodyMD().copyWith(
                                            fontWeight: isUnread
                                                ? FontWeight.bold
                                                : FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        DateFormat(
                                          'MMM d, HH:mm',
                                        ).format(comment.time),
                                        style: GlassText.secondary().copyWith(
                                          fontSize: 10,
                                          color: GlassColors.onSurfaceVariant
                                              .withOpacity(0.4),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'on ${task.title}',
                                    style: GlassText.labelSM().copyWith(
                                      fontSize: 10,
                                      color: Color(board.color),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    comment.text,
                                    style: GlassText.bodyMD().copyWith(
                                      fontSize: 12,
                                      color: isUnread
                                          ? GlassColors.onSurface
                                          : GlassColors.onSurfaceVariant,
                                      height: 1.4,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            if (isUnread) ...[
                              const SizedBox(width: 12),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: GlassColors.gold,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
                if (hasMore) ...[
                  const SizedBox(height: 16),
                  Center(
                    child: _buildGhostButton(
                      '+ LOAD MORE',
                      Icons.expand_more_rounded,
                      onTap: () {
                        setState(() {
                          _activityLimit += 10;
                        });
                      },
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildGhostButton(String label, IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: GlassColors.gold.withOpacity(0.1),
          borderRadius: BorderRadius.circular(ExecutiveRadius.circular),
          border: Border.all(color: GlassColors.gold.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: GlassColors.gold),
            const SizedBox(width: 8),
            Text(
              label,
              style: GlassText.labelSM().copyWith(
                color: GlassColors.gold,
                fontSize: 9,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showJoinWorkspaceDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => Center(
        child: Container(
          width: 400,
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: GlassDecorations.solidSurface(radius: 24),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'JOIN TEAM WORKSPACE',
                  style: GlassText.labelSM().copyWith(
                    color: GlassColors.primary,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Enter the Workspace ID shared by your colleague.',
                  style: GlassText.bodyMD().copyWith(
                    color: GlassColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                ImeSafeTextField(
                  controller: controller,
                  autofocus: true,
                  style: GlassText.bodyLG(),
                  decoration: InputDecoration(
                    hintText: 'e.g., default_team_xxxx',
                    hintStyle: GlassText.bodyLG().copyWith(
                      color: GlassColors.onSurfaceVariant.withOpacity(0.3),
                    ),
                    filled: true,
                    fillColor: GlassColors.primary.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
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
                          final id = controller.text.trim();
                          if (id.isEmpty) return;
                          final boardsState = context.read<StateBoards>();
                          final navigator = Navigator.of(dialogContext);
                          try {
                            await boardsState.joinWorkspaceById(id);
                            navigator.pop();
                            GlassNotifications.show(
                              context,
                              'Joined workspace successfully!',
                            );
                          } catch (e) {
                            navigator.pop();
                            GlassNotifications.show(
                              context,
                              'Failed to join workspace: $e',
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
                          'JOIN WORKSPACE',
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

  void _showRenameWorkspaceDialog(
    BuildContext context,
    WorkspaceModel workspace,
  ) {
    final controller = TextEditingController(text: workspace.name);
    showDialog(
      context: context,
      builder: (dialogContext) => Center(
        child: Container(
          width: 400,
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: GlassDecorations.solidSurface(radius: 24),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RENAME WORKSPACE',
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
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: GlassColors.primary.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
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
                          if (newName.isEmpty || newName == workspace.name) {
                            return;
                          }
                          final boardsState = context.read<StateBoards>();
                          final navigator = Navigator.of(dialogContext);
                          try {
                            await boardsState.updateWorkspaceName(
                              workspace,
                              newName,
                            );
                            navigator.pop();
                            GlassNotifications.show(
                              context,
                              'Workspace renamed successfully!',
                            );
                          } catch (e) {
                            GlassNotifications.show(
                              context,
                              'Failed to rename workspace: $e',
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
}

class MilestoneItem {
  final TaskModel task;
  final BoardModel board;
  MilestoneItem({required this.task, required this.board});
}

class ActivityItem {
  final TaskComment comment;
  final TaskModel task;
  final BoardModel board;
  ActivityItem({
    required this.comment,
    required this.task,
    required this.board,
  });
}
