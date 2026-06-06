import 'package:flutter/material.dart';
import '../common/ime_safe_text_field.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  const DashboardPage({super.key, required this.isDark, this.onNavigate});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Set<String> _readCommentIds = {};

  @override
  void initState() {
    super.initState();
    _loadReadComments();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<StateBoards>().fetchAllBoards();
      if (mounted) {
        final boards = context.read<StateBoards>().boards;
        context.read<StateTasks>().fetchAllTasks(boards);
      }
    });
  }

  Future<void> _loadReadComments() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('read_comment_ids') ?? [];
    if (mounted) {
      setState(() {
        _readCommentIds = list.toSet();
      });
    }
  }

  Future<void> _markCommentAsRead(String id) async {
    if (_readCommentIds.contains(id)) return;
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _readCommentIds.add(id);
    });
    await prefs.setStringList('read_comment_ids', _readCommentIds.toList());
  }

  Future<void> _markAllCommentsAsRead(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _readCommentIds.addAll(ids);
    });
    await prefs.setStringList('read_comment_ids', _readCommentIds.toList());
  }

  void _openTask(BuildContext context, BoardModel board, TaskModel task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TaskEditModal(
        board: board,
        existingTask: task,
        isDark: widget.isDark,
      ),
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
        if (task.status.toLowerCase() != 'completed' && task.status.toLowerCase() != 'done') {
          milestoneItems.add(MilestoneItem(task: task, board: board));
        }
        for (final comment in task.comments) {
          activityItems.add(ActivityItem(comment: comment, task: task, board: board));
        }
      }
    }

    // Sort milestones by closest due date first
    milestoneItems.sort((a, b) => a.task.dueDate.compareTo(b.task.dueDate));
    // Sort activity feed by newest comment first
    activityItems.sort((a, b) => b.comment.time.compareTo(a.comment.time));

    final unreadCommentIds = activityItems
        .where((item) => !_readCommentIds.contains(item.comment.id))
        .map((item) => item.comment.id)
        .toList();

    return SingleChildScrollView(
      padding: EdgeInsets.all(ExecutiveSpacing.containerPadding(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(workspaces.length),
          SizedBox(height: ExecutiveSpacing.sectionGap(context)),
          
          isDesktop 
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3, 
                    child: Column(
                      children: [
                        _buildWorkspacesList(workspaces, boards),
                        const SizedBox(height: 24),
                        _buildMilestonesCard(milestoneItems),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                  SizedBox(width: ExecutiveSpacing.gutter(context)),
                  Expanded(
                    flex: 2, 
                    child: _buildActivityFeedCard(activityItems, unreadCommentIds),
                  ),
                ],
              )
            : Column(
                children: [
                  _buildWorkspacesList(workspaces, boards),
                  const SizedBox(height: 24),
                  _buildMilestonesCard(milestoneItems),
                  const SizedBox(height: 24),
                  _buildActivityFeedCard(activityItems, unreadCommentIds),
                ],
              ),
        ],
      ),
    );
  }

  Widget _buildHeader(int workspaceCount) {
    final now = DateTime.now();
    final isSmall = MediaQuery.of(context).size.width < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'STRATEGIC HUB',
              style: GlassText.headlineXL().copyWith(
                fontSize: isSmall ? 28 : 44,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
                color: GlassColors.onSurface,
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: GlassColors.onSurface.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: GlassColors.onSurface.withOpacity(0.12)),
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
            const SizedBox(width: 12),
            Icon(
              Icons.notifications_none_rounded,
              color: GlassColors.onSurfaceVariant.withOpacity(0.6),
              size: 20,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          DateFormat('MMMM d').format(now),
          style: GlassText.bodyLG().copyWith(
            color: GlassColors.onSurfaceVariant.withOpacity(0.6),
            fontWeight: FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildWorkspacesList(List<WorkspaceModel> workspaces, List<BoardModel> boards) {
    final boardsState = context.read<StateBoards>();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.assignment_outlined,
                  color: GlassColors.onSurfaceVariant.withOpacity(0.6),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'ACTIVE WORKSPACES (${workspaces.length})',
                  style: GlassText.bodyMD().copyWith(
                    fontSize: 11,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w900,
                    color: GlassColors.onSurface,
                  ),
                ),
              ],
            ),
            OutlinedButton.icon(
              onPressed: () => _showJoinWorkspaceDialog(context),
              icon: const Icon(Icons.person_add_rounded, size: 14, color: GlassColors.gold),
              label: Text(
                '+ JOIN WORKSPACE',
                style: GlassText.labelSM().copyWith(color: GlassColors.gold, fontSize: 10, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: GlassColors.gold, width: 1),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        workspaces.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'No active workspaces found. Join or create one.',
                  style: GlassText.bodyMD().copyWith(color: GlassColors.onSurfaceVariant.withOpacity(0.5)),
                ),
              )
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: workspaces.length,
                separatorBuilder: (context, index) => Divider(height: 1, color: GlassColors.ghostBorder),
                itemBuilder: (context, index) {
                  final workspace = workspaces[index];
                  final workspaceBoards = boards.where((b) => b.workspaceId == workspace.id).toList();

                  return InkWell(
                    onTap: () {
                      boardsState.setSelectedWorkspace(workspace);
                      boardsState.setSelectedBoard(null);
                      widget.onNavigate?.call(1);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: GlassColors.primary.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: GlassColors.primary.withOpacity(0.12)),
                            ),
                            child: Icon(
                              workspace.type == 'personal' ? Icons.person_rounded : Icons.group_rounded,
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
                                      style: GlassText.bodyMD().copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: GlassColors.onSurface.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        workspace.type.toUpperCase(),
                                        style: GlassText.labelSM().copyWith(
                                          fontSize: 8,
                                          color: GlassColors.onSurfaceVariant.withOpacity(0.8),
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
                                    style: GlassText.secondary().copyWith(fontSize: 11, fontStyle: FontStyle.italic),
                                  )
                                else
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: workspaceBoards.map((board) {
                                      return InkWell(
                                        onTap: () {
                                          boardsState.setSelectedWorkspace(workspace);
                                          boardsState.setSelectedBoard(board);
                                          widget.onNavigate?.call(1);
                                        },
                                        borderRadius: BorderRadius.circular(16),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: GlassColors.onSurface.withOpacity(0.04),
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(color: GlassColors.onSurface.withOpacity(0.08)),
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
                                                style: GlassText.bodyMD().copyWith(
                                                  fontSize: 11,
                                                  color: GlassColors.onSurface.withOpacity(0.9),
                                                  fontWeight: FontWeight.w600,
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
                            icon: Icon(Icons.edit_rounded, size: 16, color: GlassColors.onSurfaceVariant.withOpacity(0.5)),
                            tooltip: 'Rename Workspace',
                            onPressed: () => _showRenameWorkspaceDialog(context, workspace),
                          ),
                          IconButton(
                            icon: Icon(Icons.copy_rounded, size: 16, color: GlassColors.onSurfaceVariant.withOpacity(0.5)),
                            tooltip: 'Copy Workspace ID',
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: workspace.id));
                              GlassNotifications.show(context, 'Workspace ID copied to clipboard');
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ],
    );
  }

  Widget _buildMilestonesCard(List<MilestoneItem> milestoneItems) {
    final displayedMilestones = milestoneItems.take(5).toList();

    return DashboardBentoCard(
      title: 'Upcoming Milestones',
      icon: Icons.alarm_rounded,
      isDark: widget.isDark,
      child: displayedMilestones.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'No pending milestones.',
                style: GlassText.bodyMD().copyWith(color: GlassColors.onSurfaceVariant.withOpacity(0.5)),
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayedMilestones.length,
              separatorBuilder: (context, index) => Divider(height: 1, color: GlassColors.ghostBorder),
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
                          style: GlassText.bodyMD().copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        dueText.toUpperCase(),
                        style: GlassText.labelSM().copyWith(fontSize: 8, color: dueColor, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  subtitle: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Color(board.color).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          board.name.toUpperCase(),
                          style: GlassText.labelSM().copyWith(fontSize: 8, color: Color(board.color)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        task.status.toUpperCase(),
                        style: GlassText.secondary().copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                  trailing: Icon(Icons.chevron_right_rounded, color: GlassColors.onSurfaceVariant.withOpacity(0.3)),
                  onTap: () => _openTask(context, board, task),
                );
              },
            ),
    );
  }

  Widget _buildActivityFeedCard(List<ActivityItem> activityItems, List<String> unreadCommentIds) {
    final displayedActivities = activityItems.take(8).toList();

    return DashboardBentoCard(
      title: 'Discussion Updates',
      icon: Icons.chat_bubble_outline_rounded,
      isDark: widget.isDark,
      trailing: unreadCommentIds.isNotEmpty
          ? _buildGhostButton(
              'MARK ALL READ',
              Icons.done_all_rounded,
              onTap: () => _markAllCommentsAsRead(unreadCommentIds),
            )
          : null,
      child: displayedActivities.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'No recent updates or discussion points.',
                style: GlassText.bodyMD().copyWith(color: GlassColors.onSurfaceVariant.withOpacity(0.5)),
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayedActivities.length,
              separatorBuilder: (context, index) => Divider(height: 1, color: GlassColors.ghostBorder),
              itemBuilder: (context, index) {
                final item = displayedActivities[index];
                final comment = item.comment;
                final task = item.task;
                final board = item.board;
                final isUnread = !_readCommentIds.contains(comment.id);
                final memberColor = GlassColors.getMemberColor(comment.userId);

                return InkWell(
                  onTap: () async {
                    await _markCommentAsRead(comment.id);
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
                            comment.userName.isNotEmpty ? comment.userName[0].toUpperCase() : '?',
                            style: GlassText.labelSM().copyWith(color: memberColor, fontSize: 10),
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
                                        fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    DateFormat('MMM d, HH:mm').format(comment.time),
                                    style: GlassText.secondary().copyWith(
                                      fontSize: 10,
                                      color: GlassColors.onSurfaceVariant.withOpacity(0.4),
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
                                  color: isUnread ? GlassColors.onSurface : GlassColors.onSurfaceVariant,
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
            Text(label, style: GlassText.labelSM().copyWith(color: GlassColors.gold, fontSize: 9, letterSpacing: 1.0)),
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
          decoration: GlassDecorations.surface(radius: 24),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('JOIN TEAM WORKSPACE', style: GlassText.labelSM().copyWith(color: GlassColors.primary, letterSpacing: 2)),
                const SizedBox(height: 24),
                Text('Enter the Workspace ID shared by your colleague.', style: GlassText.bodyMD().copyWith(color: GlassColors.onSurfaceVariant)),
                const SizedBox(height: 24),
                ImeSafeTextField(
                  controller: controller,
                  autofocus: true,
                  style: GlassText.bodyLG(),
                  decoration: InputDecoration(
                    hintText: 'e.g., default_team_xxxx',
                    hintStyle: GlassText.bodyLG().copyWith(color: GlassColors.onSurfaceVariant.withOpacity(0.3)),
                    filled: true,
                    fillColor: GlassColors.primary.withOpacity(0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('CANCEL', style: GlassText.labelSM().copyWith(color: GlassColors.onSurfaceVariant.withOpacity(0.6))),
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
                            GlassNotifications.show(context, 'Joined workspace successfully!');
                          } catch (e) {
                            navigator.pop();
                            GlassNotifications.show(context, 'Failed to join workspace: $e', isError: true);
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: GlassColors.gold, width: 1.5),
                          backgroundColor: GlassColors.gold.withOpacity(0.05),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('JOIN WORKSPACE', style: GlassText.labelSM().copyWith(color: GlassColors.gold, fontWeight: FontWeight.bold)),
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


  void _showRenameWorkspaceDialog(BuildContext context, WorkspaceModel workspace) {
    final controller = TextEditingController(text: workspace.name);
    showDialog(
      context: context,
      builder: (dialogContext) => Center(
        child: Container(
          width: 400,
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: GlassDecorations.surface(radius: 24),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('RENAME WORKSPACE', style: GlassText.labelSM().copyWith(color: GlassColors.primary, letterSpacing: 2)),
                const SizedBox(height: 24),
                ImeSafeTextField(
                  controller: controller,
                  autofocus: true,
                  style: GlassText.bodyLG(),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: GlassColors.primary.withOpacity(0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('CANCEL', style: GlassText.labelSM().copyWith(color: GlassColors.onSurfaceVariant.withOpacity(0.6))),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final newName = controller.text.trim();
                          if (newName.isEmpty || newName == workspace.name) return;
                          final boardsState = context.read<StateBoards>();
                          final navigator = Navigator.of(dialogContext);
                          try {
                            await boardsState.updateWorkspaceName(workspace, newName);
                            navigator.pop();
                            GlassNotifications.show(context, 'Workspace renamed successfully!');
                          } catch (e) {
                            GlassNotifications.show(context, 'Failed to rename workspace: $e', isError: true);
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: GlassColors.gold, width: 1.5),
                          backgroundColor: GlassColors.gold.withOpacity(0.05),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('RENAME', style: GlassText.labelSM().copyWith(color: GlassColors.gold, fontWeight: FontWeight.bold)),
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
  ActivityItem({required this.comment, required this.task, required this.board});
}
