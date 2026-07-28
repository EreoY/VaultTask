import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../models/board_model.dart';
import '../../models/task_model.dart';
import '../../state_managers/state_boards.dart';
import '../../state_managers/state_tasks.dart';
import '../theme/glass_theme.dart';
import '../kanban/widgets/task_edit_modal.dart';
import 'widgets/bento_box_widgets.dart';

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
  final ScrollController _scrollController = ScrollController();

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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName ?? user?.email?.split('@').first ?? 'Lesley';
    final boardsState = context.watch<StateBoards>();
    final boards = boardsState.boards;
    final tasksState = context.watch<StateTasks>();

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 160),
      child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section A: Header Greeting
              BentoHeaderSection(
                userName: userName,
                onSearchPressed: () {
                  // Navigate to boards / search
                  widget.onNavigate?.call(1);
                },
                onProfilePressed: () {
                  // Navigate to profile
                  widget.onNavigate?.call(4);
                },
              ),

              // Section B: Bento Hero Card (Lavender)
              BentoHeroCard(
                title: 'Finish 3 Tasks for your Team Board',
                subtitle: 'Keep up your daily streak & earn badges!',
                description: 'Track team goals and complete daily challenges seamlessly.',
                buttonText: 'Start now',
                imageAssetPath: 'assets/images/calendarV2.png',
                onTap: () {
                  widget.onNavigate?.call(1); // Open boards
                },
              ),

              // Section B.5: Weekly Date Strip Capsules
              const BentoWeeklyDateStrip(),

              const SizedBox(height: 8),

              // Section C: Bento Plan Grid (Your Plan)
              BentoPlanGrid(
                onLeftCardTap: () {
                  final boardsState = context.read<StateBoards>();
                  final targetBoard = boardsState.selectedBoard ??
                      (boardsState.boards.isNotEmpty ? boardsState.boards.first : null);
                  if (targetBoard != null) {
                    boardsState.openBoardMeetings(targetBoard);
                  } else {
                    boardsState.setBoardSurface(BoardSurfaceMode.meetings);
                  }
                  widget.onNavigate?.call(1); // Open Meeting Board Page
                },
                onTopRightTap: () {
                  widget.onNavigate?.call(2); // Open Chat menu
                },
                onBottomRightTap: () {
                  widget.onNavigate?.call(3); // Open Calendar / Sync
                },
              ),

              const SizedBox(height: 16),

              // Section D: Active Tasks Overview (Recent Activity List)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Tasks',
                      style: GlassText.headlineMD().copyWith(
                        fontWeight: FontWeight.w800,
                        color: GlassColors.deepBlack,
                        fontSize: 20,
                      ),
                    ),
                    TextButton(
                      onPressed: () => widget.onNavigate?.call(1),
                      child: const Text('See All'),
                    ),
                  ],
                ),
              ),

              _buildRecentTaskList(context, boards, tasksState),
            ],
          ),
    );
  }

  Widget _buildRecentTaskList(
    BuildContext context,
    List<BoardModel> boards,
    StateTasks tasksState,
  ) {
    final List<_TaskBoardPair> recentTasks = [];

    for (final board in boards) {
      final tasks = tasksState.tasksForBoard(board.id);
      for (final t in tasks) {
        if (!t.isCompleted) {
          recentTasks.add(_TaskBoardPair(task: t, board: board));
        }
      }
    }

    if (recentTasks.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(ExecutiveRadius.xl),
          border: Border.all(color: GlassColors.outlineVariant),
        ),
        child: Center(
          child: Text(
            'No pending tasks. You are all caught up!',
            style: GlassText.secondary(),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: recentTasks.length > 4 ? 4 : recentTasks.length,
      itemBuilder: (context, index) {
        final item = recentTasks[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(ExecutiveRadius.xl),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: CircleAvatar(
              backgroundColor: GlassColors.bentoLavender,
              child: const Icon(Icons.check_box_outline_blank_rounded, color: GlassColors.deepBlack),
            ),
            title: Text(
              item.task.title,
              style: GlassText.bodyMD().copyWith(
                fontWeight: FontWeight.w700,
                color: GlassColors.deepBlack,
              ),
            ),
            subtitle: Text(
              '${item.board.name} • ${item.task.status}',
              style: GlassText.secondary().copyWith(fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, color: GlassColors.onSurfaceVariant),
            onTap: () => _openTask(context, item.board, item.task),
          ),
        );
      },
    );
  }
}

class _TaskBoardPair {
  final TaskModel task;
  final BoardModel board;
  _TaskBoardPair({required this.task, required this.board});
}
