import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../config/env_config.dart';
import '../../../models/task_model.dart';
import '../../../models/board_model.dart';
import '../../../state_managers/state_boards.dart';
import '../../../state_managers/state_tasks.dart';
import '../../theme/glass_theme.dart';
import '../../common/glass_widgets.dart';
import '../../common/responsive_layout.dart';

class DailyTimelineView extends StatefulWidget {
  final DateTime date;
  final List<TaskModel> tasks;
  final List<BoardModel> boards;
  final bool isDark;
  final Function(int)? onNavigate;

  const DailyTimelineView({
    super.key,
    required this.date,
    required this.tasks,
    required this.boards,
    required this.isDark,
    this.onNavigate,
  });

  @override
  State<DailyTimelineView> createState() => _DailyTimelineViewState();
}

class _DailyTimelineViewState extends State<DailyTimelineView> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _currentHourKey = GlobalKey(); // 🚀 Task 74.2: Precise Sentinel


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
    final upcomingTasks = widget.tasks.where((t) => !t.isCompleted).toList();
    final isMobile = Responsive.isMobile(context);

    return Column(
      children: [
        _buildTimelineHeader(upcomingTasks),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 48, 
              vertical: isMobile ? 16 : 32
            ),
            itemCount: 24,
            itemBuilder: (context, hour) {
              final hourTasks = upcomingTasks.where((t) => t.dueDate.hour == hour).toList();
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
      padding: EdgeInsets.fromLTRB(isMobile ? 16 : 48, 0, isMobile ? 16 : 48, 24),
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
              style: GlassText.labelSM().copyWith(color: GlassColors.primary.withOpacity(0.5), letterSpacing: 1.5),
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
        Text(label, style: GlassText.labelSM().copyWith(fontSize: 8, color: GlassColors.onSurfaceVariant.withOpacity(0.4), letterSpacing: 1.0)),
        const SizedBox(height: 4),
        Text(value, style: GlassText.headlineLG().copyWith(fontSize: 24, color: GlassColors.primary)),
      ],
    );
  }

  Widget _buildHourRow(int hour, List<TaskModel> hourTasks) {
    final now = DateTime.now();
    final isMobile = Responsive.isMobile(context);
    final isToday = widget.date.day == now.day && widget.date.month == now.month && widget.date.year == now.year;
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
                        children: List.generate(12, (_) => Container(
                          width: 1.5, height: 1.5, 
                          decoration: BoxDecoration(
                            color: GlassColors.onSurface.withOpacity(0.06), 
                            shape: BoxShape.circle,
                          )
                        )),
                      ),
                    ),
                    
                    // Centered Marker
                    Center(
                      key: isCurrentHour ? _currentHourKey : null, // 🚀 Task 74.2: Marker Key
                      child: isCurrentHour
                          ? StreamBuilder(
                              stream: Stream.periodic(const Duration(seconds: 1)),
                              builder: (context, _) {
                                final t = DateTime.now();
                                final curMm = DateFormat('mm').format(t);
                                final curSs = DateFormat('ss').format(t);
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(hh, style: GlassText.headlineXL().copyWith(fontSize: isMobile ? 24 : 34, height: 0.9, color: GlassColors.gold, fontWeight: FontWeight.w900)),
                                    Text(curMm, style: GlassText.headlineXL().copyWith(fontSize: isMobile ? 24 : 34, height: 0.9, color: GlassColors.gold.withOpacity(0.5), fontWeight: FontWeight.w900)),
                                    const SizedBox(height: 2),
                                    // 🚀 Task 74.3: Digital Pulse Restoration
                                    Text(curSs, style: GlassText.labelSM().copyWith(fontSize: isMobile ? 9 : 10, color: GlassColors.gold.withOpacity(0.3), fontWeight: FontWeight.w900, fontFamily: 'monospace')),
                                  ],
                                );
                              },
                            )
                          : Text(
                              '$hh:00',
                              style: GlassText.labelSM().copyWith(
                                fontSize: isMobile ? 12 : (hasTasks ? 16 : 11),
                                fontWeight: hasTasks ? FontWeight.bold : FontWeight.w400,
                                color: hasTasks ? GlassColors.primary : GlassColors.onSurfaceVariant.withOpacity(0.2),
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
                    border: Border(bottom: BorderSide(color: GlassColors.ghostBorder, width: 0.5)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (hourTasks.isEmpty)
                        _buildGap()
                      else
                        ...hourTasks.map((t) => _buildTaskBlock(t)).toList(),
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
                              boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.8), blurRadius: 8)],
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 1.5,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.red.withOpacity(0.8), Colors.red.withOpacity(0.0)],
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
        style: GlassText.labelSM().copyWith(fontSize: 9, color: GlassColors.onSurfaceVariant.withOpacity(0.15), letterSpacing: 2.5),
      ),
    );
  }

  Widget _buildTaskBlock(TaskModel task) {
    final isMobile = Responsive.isMobile(context);
    int colorValue = GlassColors.primary.value;
    String boardName = 'Unknown Board';
    BoardModel? board;
    try {
      board = widget.boards.firstWhere((b) => b.id == task.boardId);
      colorValue = board.color;
      boardName = board.name;
    } catch (_) {}
    
    final color = Color(colorValue);

    return InkWell(
      onTap: () => _showStrategicPreview(context, task),
      borderRadius: BorderRadius.circular(ExecutiveRadius.m),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 20, 
          vertical: isMobile ? 10 : 14
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(ExecutiveRadius.m),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 3,
              height: 24,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
            ),
            SizedBox(width: isMobile ? 12 : 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    task.title.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GlassText.bodyMD().copyWith(
                      fontWeight: FontWeight.bold, 
                      letterSpacing: 0.5, 
                      fontSize: isMobile ? 13 : 15
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    boardName.toUpperCase(),
                    style: GlassText.labelSM().copyWith(
                      fontSize: 8, 
                      color: color.withOpacity(0.7), 
                      letterSpacing: 1.0
                    ),
                  ),
                ],
              ),
            ),
            if (!isMobile) ...[
              const SizedBox(width: 16),
              Text(
                DateFormat('HH:mm').format(task.dueDate),
                style: GlassText.labelSM().copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: GlassColors.primary),
              ),
              const SizedBox(width: 20),
              _buildAvatarStack(task.members),
            ],
          ],
        ),
      ),
    );
  }

  void _showStrategicPreview(BuildContext context, TaskModel initialTask) {
    final isMobile = Responsive.isMobile(context);
    final board = widget.boards.firstWhere((b) => b.id == initialTask.boardId, orElse: () => widget.boards.first);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: isMobile ? 0.9 : 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Consumer<StateTasks>(
          builder: (context, taskState, _) {
            final tasks = taskState.tasksForBoard(initialTask.boardId);
            final task = tasks.firstWhere((t) => t.id == initialTask.id, orElse: () => initialTask);
            final boardState = context.read<StateBoards>();
            
            final currentBoard = boardState.boards.firstWhere((b) => b.id == board.id, orElse: () => board);

            final coverImage = task.images.isEmpty 
                ? null 
                : task.images.firstWhere((img) => img.isCover, orElse: () => task.images.first);
            final hasCover = coverImage != null && coverImage.url.isNotEmpty;

            return Container(
              decoration: GlassDecorations.solidSurface(radius: 32, hasShadow: true),
              child: ListView(
                controller: scrollController,
                padding: EdgeInsets.zero,
                children: [
                  if (hasCover)
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                              child: Image.network(
                                EnvConfig.sanitizeUrl(coverImage.url),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: GlassColors.surfaceHighest.withOpacity(0.1),
                                  child: Center(
                                    child: Icon(Icons.broken_image_outlined, size: 32, color: GlassColors.primary.withOpacity(0.3)),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.black.withOpacity(0.4), Colors.transparent],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.all(isMobile ? 24 : 48),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('STRATEGIC PREVIEW', style: GlassText.labelSM().copyWith(color: GlassColors.gold, letterSpacing: 2.0)),
                            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Text(task.title.toUpperCase(), style: GlassText.headlineLG().copyWith(fontSize: isMobile ? 28 : 38)),
                        const SizedBox(height: 16),
                        
                        _buildPreviewMetadataStrip(currentBoard, task, boardState),
                        
                        const SizedBox(height: 32),
                        Text(task.description.isEmpty ? 'No strategic brief provided.' : task.description, style: GlassText.bodyLG().copyWith(fontSize: isMobile ? 16 : 18, color: GlassColors.onSurface.withOpacity(0.7))),
                        
                        if (task.images.isNotEmpty) ...[
                          const SizedBox(height: 48),
                          _buildSectionTitle('OPERATIONAL ASSETS'),
                          const SizedBox(height: 24),
                          ...task.images.map((img) => _buildPreviewAssetRow(img)).toList(),
                        ],

                        const SizedBox(height: 80),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  context.read<StateBoards>().setSelectedBoard(currentBoard);
                                  widget.onNavigate?.call(1);
                                  Navigator.pop(context);
                                },
                                borderRadius: BorderRadius.circular(ExecutiveRadius.circular),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 20),
                                  decoration: BoxDecoration(
                                    color: GlassColors.gold.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(ExecutiveRadius.circular),
                                    border: Border.all(color: GlassColors.gold.withOpacity(0.3)),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'NAVIGATE TO EXECUTION BOARD',
                                      style: GlassText.labelSM().copyWith(color: GlassColors.gold, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 64),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPreviewMetadataStrip(BoardModel board, TaskModel task, StateBoards boardState) {
    final activeLabels = board.labels.where((l) => task.labelIds.contains(l['id'])).toList();
    final isMobile = Responsive.isMobile(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GlassColors.onSurface.withOpacity(0.03),
        borderRadius: BorderRadius.circular(ExecutiveRadius.m),
        border: Border.all(color: GlassColors.ghostBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (activeLabels.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: activeLabels.map((l) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Color(l['color'] as int).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(ExecutiveRadius.s),
                  border: Border.all(color: Color(l['color'] as int).withOpacity(0.3)),
                ),
                child: Text((l['name'] as String).toUpperCase(), style: GlassText.labelSM().copyWith(fontSize: 8, color: Color(l['color'] as int))),
              )).toList(),
            ),
            const SizedBox(height: 16),
            Divider(color: GlassColors.ghostBorder, height: 1),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              _buildPreviewMetadataItem(Icons.layers_outlined, task.status.toUpperCase()),
              const SizedBox(width: 12),
              Expanded(child: _buildPreviewMetadataItem(Icons.calendar_today_rounded, DateFormat('MMM d, HH:mm').format(task.dueDate).toUpperCase())),
              _buildAvatarStack(task.members),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewMetadataItem(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: GlassColors.primary.withOpacity(0.5)),
        const SizedBox(width: 8),
        Text(
          label,
          style: GlassText.labelSM().copyWith(fontSize: 10, color: GlassColors.primary),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildPreviewAssetRow(TaskImage img) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ExecutiveRadius.m),
        border: Border.all(color: img.isCover ? GlassColors.gold.withOpacity(0.3) : GlassColors.ghostBorder),
        color: img.isCover ? GlassColors.gold.withOpacity(0.05) : Colors.transparent,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(ExecutiveRadius.s),
              color: GlassColors.surfaceHighest.withOpacity(0.1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(ExecutiveRadius.s),
              child: Image.network(
                EnvConfig.sanitizeUrl(img.url),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Center(
                  child: Icon(Icons.broken_image_outlined, size: 16, color: GlassColors.primary.withOpacity(0.3)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              img.aiDescription.isEmpty ? 'ASSET_${img.id.substring(img.id.length - 4)}' : img.aiDescription,
              style: GlassText.bodyMD().copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          if (img.isCover) const Icon(Icons.star_rounded, color: GlassColors.gold, size: 16),
          const SizedBox(width: 12),
          Icon(Icons.download_rounded, color: GlassColors.primary.withOpacity(0.5), size: 18),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GlassText.labelSM().copyWith(fontSize: 10, color: GlassColors.onSurfaceVariant.withOpacity(0.4), letterSpacing: 1.5),
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
              style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.bold),
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
