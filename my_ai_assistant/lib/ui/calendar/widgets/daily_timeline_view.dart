import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../config/env_config.dart';
import '../../../models/task_model.dart';
import '../../../models/board_model.dart';
import '../../../models/workspace_model.dart';
import '../../../state_managers/state_boards.dart';
import '../../kanban/widgets/task_edit_modal.dart';
import '../../theme/glass_theme.dart';
import '../../common/responsive_layout.dart';
import 'task_type_icon.dart';

class DailyTimelineView extends StatefulWidget {
  final DateTime date;
  final List<TaskModel> tasks;
  final List<BoardModel> boards;
  final List<WorkspaceModel> workspaces;
  final bool isDark;
  final Function(int)? onNavigate;

  const DailyTimelineView({
    super.key,
    required this.date,
    required this.tasks,
    required this.boards,
    required this.workspaces,
    required this.isDark,
    this.onNavigate,
  });

  @override
  State<DailyTimelineView> createState() => _DailyTimelineViewState();
}

class _DailyTimelineViewState extends State<DailyTimelineView> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _currentHourKey =
      GlobalKey(); // 🚀 Task 74.2: Precise Sentinel

  @override
  void initState() {
    super.initState();

    _scrollToCurrentHour();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrentHour() {
    // 🚀 Task 74.2: Triple-layered Precise Scroll
    WidgetsBinding.instance.addPostFrameCallback((_) {
      void performScroll() {
        if (_scrollController.hasClients) {
          final hourContext = _currentHourKey.currentContext;
          if (hourContext != null) {
            Scrollable.ensureVisible(
              hourContext,
              duration: const Duration(seconds: 1),
              curve: Curves.easeOutQuart,
              alignment: 0.3, // Keep the hour marker slightly above center
            );
          } else {
            // Precise Fallback
            final isMobile = Responsive.isMobile(context);
            final hourHeight = isMobile ? 100.0 : 120.0;
            final topPadding = isMobile ? 16.0 : 32.0;
            final hour = DateTime.now().hour;
            final offset = (hour * hourHeight) + topPadding;

            _scrollController.animateTo(
              offset.clamp(0.0, _scrollController.position.maxScrollExtent),
              duration: const Duration(seconds: 1),
              curve: Curves.easeOutQuart,
            );
          }
        }
      }

      // Initial Scroll (Fast)
      Future.delayed(const Duration(milliseconds: 300), performScroll);
      // Secondary Verification (Layout stabilized)
      Future.delayed(const Duration(milliseconds: 1200), performScroll);
    });
  }

  @override
  Widget build(BuildContext context) {
    final upcomingTasks = List<TaskModel>.from(widget.tasks)
      ..sort((a, b) {
        if (a.isCompleted != b.isCompleted) {
          return a.isCompleted ? 1 : -1;
        }
        return a.dueDate.compareTo(b.dueDate);
      });
    final isMobile = Responsive.isMobile(context);

    return Column(
      children: [
        _buildTimelineHeader(upcomingTasks),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 48,
              vertical: isMobile ? 16 : 32,
            ),
            itemCount: 24,
            itemBuilder: (context, hour) {
              final hourTasks = upcomingTasks
                  .where((t) => t.dueDate.hour == hour)
                  .toList();
              return _buildHourRow(hour, hourTasks);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineHeader(List<TaskModel> activeTasks) {
    final isMobile = Responsive.isMobile(context);
    return Container(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 16 : 48,
        0,
        isMobile ? 16 : 48,
        24,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: GlassColors.ghostBorder)),
      ),
      child: Row(
        children: [
          _buildStat('EXECUTIONS', activeTasks.length.toString()),
          SizedBox(width: isMobile ? 24 : 48),
          _buildStat('STRATEGIC GAPS', (24 - activeTasks.length).toString()),
          if (!isMobile) ...[
            const Spacer(),
            Text(
              'INTENSITY: ${(activeTasks.length / 24 * 100).toStringAsFixed(0)}%',
              style: GlassText.labelSM().copyWith(
                color: GlassColors.primary.withOpacity(0.5),
                letterSpacing: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GlassText.labelSM().copyWith(
            fontSize: 8,
            color: GlassColors.onSurfaceVariant.withOpacity(0.4),
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GlassText.headlineLG().copyWith(
            fontSize: 24,
            color: GlassColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildHourRow(int hour, List<TaskModel> hourTasks) {
    final now = DateTime.now();
    final isMobile = Responsive.isMobile(context);
    final isToday =
        widget.date.day == now.day &&
        widget.date.month == now.month &&
        widget.date.year == now.year;
    final isCurrentHour = isToday && now.hour == hour;

    final hh = DateFormat('HH').format(DateTime(2024, 1, 1, hour));

    final hasTasks = hourTasks.isNotEmpty;

    final timeColumnWidth = isMobile ? 60.0 : 80.0;

    return IntrinsicHeight(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ⏱️ Time Column
              SizedBox(
                width: timeColumnWidth,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(
                          12,
                          (_) => Container(
                            width: 1.5,
                            height: 1.5,
                            decoration: BoxDecoration(
                              color: GlassColors.onSurface.withOpacity(0.06),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Centered Marker
                    Center(
                      key: isCurrentHour
                          ? _currentHourKey
                          : null, // 🚀 Task 74.2: Marker Key
                      child: isCurrentHour
                          ? StreamBuilder(
                              stream: Stream.periodic(
                                const Duration(seconds: 1),
                              ),
                              builder: (context, _) {
                                final t = DateTime.now();
                                final curMm = DateFormat('mm').format(t);
                                final curSs = DateFormat('ss').format(t);
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      hh,
                                      style: GlassText.headlineXL().copyWith(
                                        fontSize: isMobile ? 24 : 34,
                                        height: 0.9,
                                        color: GlassColors.gold,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    Text(
                                      curMm,
                                      style: GlassText.headlineXL().copyWith(
                                        fontSize: isMobile ? 24 : 34,
                                        height: 0.9,
                                        color: GlassColors.gold.withOpacity(
                                          0.5,
                                        ),
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    // 🚀 Task 74.3: Digital Pulse Restoration
                                    Text(
                                      curSs,
                                      style: GlassText.labelSM().copyWith(
                                        fontSize: isMobile ? 9 : 10,
                                        color: GlassColors.gold.withOpacity(
                                          0.3,
                                        ),
                                        fontWeight: FontWeight.w900,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ],
                                );
                              },
                            )
                          : Text(
                              '$hh:00',
                              style: GlassText.labelSM().copyWith(
                                fontSize: isMobile ? 12 : (hasTasks ? 16 : 11),
                                fontWeight: hasTasks
                                    ? FontWeight.bold
                                    : FontWeight.w400,
                                color: hasTasks
                                    ? GlassColors.primary
                                    : GlassColors.onSurfaceVariant.withOpacity(
                                        0.2,
                                      ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: isMobile ? 12 : 24),
              Expanded(
                child: Container(
                  constraints: BoxConstraints(minHeight: isMobile ? 100 : 120),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: GlassColors.ghostBorder,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (hourTasks.isEmpty)
                        _buildGap()
                      else
                        ...hourTasks.map((t) => _buildTaskBlock(t)),
                    ],
                  ),
                ),
              ),
            ],
          ),

          if (isCurrentHour)
            Positioned.fill(
              child: StreamBuilder(
                stream: Stream.periodic(const Duration(seconds: 10)),
                builder: (context, _) {
                  final t = DateTime.now();
                  return Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: (t.minute / 60) * (isMobile ? 100 : 120),
                      ),
                      child: Row(
                        children: [
                          SizedBox(width: timeColumnWidth - 3),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: GlassColors.gold,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.8),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 1.5,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.red.withOpacity(0.8),
                                    Colors.red.withOpacity(0.0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGap() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      alignment: Alignment.centerLeft,
      child: Text(
        'NO STRATEGIC TASKS',
        style: GlassText.labelSM().copyWith(
          fontSize: 9,
          color: GlassColors.onSurfaceVariant.withOpacity(0.15),
          letterSpacing: 2.5,
        ),
      ),
    );
  }

  Widget _buildTaskBlock(TaskModel task) {
    final isMobile = Responsive.isMobile(context);
    int colorValue = GlassColors.primary.value;
    String boardName = 'Unknown Board';
    String workspaceName = 'Unknown Workspace';
    BoardModel? board;
    try {
      board = widget.boards.firstWhere((b) => b.id == task.boardId);
      colorValue = board.color;
      boardName = board.name;
      if (board.workspaceId.isNotEmpty) {
        for (final workspace in widget.workspaces) {
          if (workspace.id == board.workspaceId) {
            workspaceName = workspace.name;
            break;
          }
        }
      }
    } catch (_) {}

    final color = Color(colorValue);
    final isCompleted = task.isCompleted;

    return InkWell(
      onTap: () => _showStrategicPreview(context, task),
      borderRadius: BorderRadius.circular(ExecutiveRadius.m),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 20,
          vertical: isMobile ? 10 : 14,
        ),
        decoration: BoxDecoration(
          color: isCompleted
              ? color.withOpacity(0.16)
              : color.withOpacity(0.24),
          borderRadius: BorderRadius.circular(ExecutiveRadius.m),
          border: Border.all(
            color: color.withOpacity(isCompleted ? 0.24 : 0.38),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        calendarTaskTypeIcon(task.type),
                        size: isMobile ? 14 : 15,
                        color: calendarTaskTypeColor(
                          task.type,
                          active: !isCompleted,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          task.title.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GlassText.bodyMD().copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            fontSize: isMobile ? 13 : 15,
                            decoration: isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            color: GlassColors.onSurface.withOpacity(
                              isCompleted ? 0.46 : 0.92,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (task.description.trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      task.description.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GlassText.bodyMD().copyWith(
                        fontSize: isMobile ? 10 : 11,
                        height: 1.15,
                        color: GlassColors.onSurface.withOpacity(
                          isCompleted ? 0.32 : 0.62,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    '$workspaceName / $boardName'.toUpperCase(),
                    style: GlassText.labelSM().copyWith(
                      fontSize: 8.4,
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      color: GlassColors.onSurface.withOpacity(
                        isCompleted ? 0.28 : 0.56,
                      ),
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            if (!isMobile) ...[
              const SizedBox(width: 16),
              Text(
                DateFormat('HH:mm').format(task.dueDate),
                style: GlassText.labelSM().copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: GlassColors.primary,
                ),
              ),
              const SizedBox(width: 20),
              _buildAvatarStack(task.members),
            ],
          ],
        ),
      ),
    );
  }

  BoardModel? _findBoard(String boardId, [List<BoardModel>? boards]) {
    for (final board in boards ?? widget.boards) {
      if (board.id == boardId) return board;
    }
    return null;
  }

  void _showStrategicPreview(BuildContext context, TaskModel initialTask) {
    final board = _findBoard(initialTask.boardId);
    if (board == null) return;
    TaskEditModal.show(
      context: context,
      board: board,
      existingTask: initialTask,
      isDark: widget.isDark,
      onOpenBoard: () {
        Navigator.of(context).pop();
        context.read<StateBoards>().setSelectedBoard(board);
        widget.onNavigate?.call(1);
      },
    );
  }

  Widget _buildAvatarStack(List<String> uids) {
    if (uids.isEmpty) return const SizedBox.shrink();
    final boardState = context.read<StateBoards>();
    final maxShown = 3;
    final membersToShow = uids.take(maxShown).toList();
    const double avatarSize = 26.0;
    const double overlapSpacing = 18.0;

    return SizedBox(
      width: avatarSize + (membersToShow.length - 1) * overlapSpacing,
      height: avatarSize,
      child: Stack(
        children: List.generate(membersToShow.length, (index) {
          final uid = membersToShow[index];
          final profile = boardState.getMemberProfile(uid);
          final name = profile?['name'] ?? 'Operative';
          final photo = profile?['photo'] ?? '';
          final color = GlassColors.getMemberColor(uid);

          final fallback = Center(
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: 9,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          );

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
                        errorBuilder: (context, error, stackTrace) => fallback,
                      )
                    : fallback,
              ),
            ),
          );
        }),
      ),
    );
  }
}
