import 'package:flutter/material.dart';
import '../common/ime_safe_text_field.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../models/board_model.dart';
import '../../models/task_model.dart';
import '../../state_managers/state_boards.dart';
import '../../state_managers/state_tasks.dart';
import '../theme/glass_theme.dart';
import '../common/glass_widgets.dart';
import '../common/responsive_layout.dart';
import 'widgets/kanban_column.dart'; 
import 'widgets/task_edit_modal.dart';
import 'widgets/column_edit_modal.dart';
import 'widgets/member_role_modal.dart';

class KanbanPage extends StatefulWidget {
  final BoardModel board;
  final bool isDark;

  const KanbanPage({
    super.key,
    required this.board,
    required this.isDark,
  });

  @override
  State<KanbanPage> createState() => _KanbanPageState();
}

class _KanbanPageState extends State<KanbanPage> {
  bool _isSelectMode = false;
  bool _isOverviewMode = false; // 🚀 Tactical Zoom State
  String? _activeOperativeId; // 🚀 null = ALL
  final Set<String> _selectedTaskIds = {};
  StateTasks? _taskStateRef;
  
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _taskStateRef = context.read<StateTasks>();
      _taskStateRef?.fetchTasksForBoard(widget.board);
      _taskStateRef?.subscribeBoard(widget.board);
    });
  }

  @override
  void dispose() {
    // 🔄 KEEP CONNECTION ALIVE: Unsubscribing here breaks cross-page broadcasts
    // (e.g. AI creates task from chat → needs active channel to send Supabase broadcast)
    // Channel cleanup happens automatically in StateTasks.dispose() when app closes.
    _horizontalScrollController.dispose();
    super.dispose();
  }

  Future<void> _moveSelectedTasks(String targetColumnId) async {
    if (_selectedTaskIds.isEmpty) return;
    final taskState = context.read<StateTasks>();
    final board = context.read<StateBoards>().selectedBoard ?? widget.board;
    final tasks = taskState.tasksForBoard(board.id);
    int successCount = 0;
    for (final taskId in _selectedTaskIds) {
      try {
        final task = tasks.firstWhere((t) => t.id == taskId);
        await taskState.updateTaskStatus(board, task, targetColumnId);
        successCount++;
      } catch (_) {}
    }
    if (mounted) {
      GlassNotifications.show(context, 'STRATEGY EXECUTED: $successCount TASKS');
      setState(() { _isSelectMode = false; _selectedTaskIds.clear(); });
    }
  }

  void _exportToMarkdown() {
    if (_selectedTaskIds.isEmpty) return;
    final tasks = context.read<StateTasks>().tasksForBoard(widget.board.id);
    final selectedTasks = tasks.where((t) => _selectedTaskIds.contains(t.id)).toList();
    StringBuffer buffer = StringBuffer();
    buffer.writeln('# STRATEGIC REQUIREMENTS EXPORT');
    buffer.writeln('Board: ${widget.board.name}\n');
    for (int i = 0; i < selectedTasks.length; i++) {
      final t = selectedTasks[i];
      
      final labelNames = widget.board.labels
          .where((l) => t.labelIds.contains(l['id']))
          .map((l) => (l['name'] as String).toUpperCase())
          .join(', ');

      buffer.writeln('Requirement [${i + 1}]: ${t.title}');
      buffer.writeln('Description: ${t.description.isEmpty ? "No detailed brief." : t.description}');
      buffer.writeln('Task Category: ${t.status.toUpperCase()}'); 
      buffer.writeln('Labels: ${labelNames.isEmpty ? "NONE" : labelNames}');
      buffer.writeln('-------------------\n');
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (mounted) {
      GlassNotifications.show(context, 'MARKDOWN EXPORTED');
      setState(() { _isSelectMode = false; _selectedTaskIds.clear(); });
    }
  }

  void _onTaskTap(TaskModel task) {
    _showTaskDetails(widget.board, task);
  }

  Future<void> _reorderColumns(int fromIndex, int toIndex) async {
    if (_activeOperativeId != null) return;

    final boardState = context.read<StateBoards>();
    final currentBoard = boardState.selectedBoard ?? widget.board;
    final List<String> newColumns = List.from(currentBoard.columns);
    final String moving = newColumns.removeAt(fromIndex);
    newColumns.insert(toIndex, moving);
    
    final updatedBoard = currentBoard.copyWith(columns: newColumns);
    await boardState.updateBoard(updatedBoard);
    
    if (mounted) {
      GlassNotifications.show(context, 'STRUCTURE REORGANIZED');
    }
  }

  void _onTaskSelect(String taskId) {
    setState(() {
      if (_selectedTaskIds.contains(taskId)) {
        _selectedTaskIds.remove(taskId);
      } else {
        _selectedTaskIds.add(taskId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final board = context.watch<StateBoards>().selectedBoard ?? widget.board;
    final isMobile = Responsive.isMobile(context);

    return Stack(
      children: [
        Column(
          children: [
            _buildHeader(board, context),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 16 : ExecutiveSpacing.containerPadding(context), 
                  isMobile ? 8 : 16, 
                  isMobile ? 0 : ExecutiveSpacing.containerPadding(context), 
                  0
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: Consumer<StateBoards>(
                        builder: (context, boardState, child) {
                          final latestBoard = boardState.selectedBoard ?? board;
                          return ListView.builder(
                            controller: _horizontalScrollController,
                            scrollDirection: Axis.horizontal,
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: latestBoard.columns.length,
                            itemBuilder: (context, index) {
                              final columnName = latestBoard.columns[index];
                              return DragTarget<int>(
                                onAcceptWithDetails: (details) => _reorderColumns(details.data, index),
                                builder: (context, candidateData, rejectedData) {
                                  return Row(
                                    children: [
                                      if (candidateData.isNotEmpty && _activeOperativeId == null)
                                        AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          width: _isOverviewMode ? 80 : 120,
                                          margin: const EdgeInsets.only(right: 24),
                                          decoration: BoxDecoration(
                                            color: GlassColors.gold.withOpacity(0.05),
                                            borderRadius: BorderRadius.circular(ExecutiveRadius.xl),
                                            border: Border.all(color: GlassColors.gold.withOpacity(0.3), width: 1.5),
                                          ),
                                          child: Center(child: Text('INSERT PHASE', style: GlassText.labelSM().copyWith(color: GlassColors.gold, fontSize: 8, letterSpacing: 2))),
                                        ),
                                      KanbanColumnWidget(
                                        board: latestBoard,
                                        columnName: columnName,
                                        isDark: widget.isDark,
                                        isSelectMode: _isSelectMode,
                                        selectedTaskIds: _selectedTaskIds,
                                        onTaskTap: _onTaskTap,
                                        onTaskSelect: _onTaskSelect,
                                        onAdd: () => _showAddTask(latestBoard, columnName),
                                        onSettings: () => _showColumnSettings(latestBoard, columnName),
                                        columnIndex: index,
                                        activeOperativeId: _activeOperativeId,
                                        isOverviewMode: _isOverviewMode,
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
                    SizedBox(height: ExecutiveSpacing.stackMd(context)),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (_isSelectMode && _selectedTaskIds.isNotEmpty)
          Positioned(left: 0, right: 0, bottom: isMobile ? 32 : 64, child: Center(child: _buildBulkToolbar(board, context))),
      ],
    );
  }

  Widget _buildBulkToolbar(BoardModel board, BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 16),
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 0),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        borderRadius: BorderRadius.circular(ExecutiveRadius.circular),
        border: Border.all(color: GlassColors.gold.withOpacity(0.5), width: 1.5),
        boxShadow: [const BoxShadow(color: Colors.black54, blurRadius: 40)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${_selectedTaskIds.length} ${isMobile ? "" : "SELECTED"}', style: GlassText.labelSM().copyWith(color: GlassColors.gold, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          SizedBox(width: isMobile ? 16 : 32),
          _buildToolbarButton(isMobile ? 'MOVE' : 'MOVE TO', Icons.drive_file_move_rtl_rounded, onTap: () => _showMoveMenu(context, board)),
          const SizedBox(width: 12),
          _buildToolbarButton(isMobile ? 'EXPORT' : 'EXPORT MD', Icons.terminal_rounded, onTap: _exportToMarkdown),
          SizedBox(width: isMobile ? 12 : 24),
          IconButton(icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 20), onPressed: () => setState(() => _selectedTaskIds.clear())),
        ],
      ),
    );
  }

  Widget _buildToolbarButton(String label, IconData icon, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(color: GlassColors.gold.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: GlassColors.gold.withOpacity(0.2))),
        child: Row(children: [Icon(icon, size: 16, color: GlassColors.gold), const SizedBox(width: 8), Text(label, style: GlassText.labelSM().copyWith(color: GlassColors.gold, fontSize: 9, fontWeight: FontWeight.bold))]),
      ),
    );
  }

  Widget _buildHeader(BoardModel currentBoard, BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);

    return Container(
      padding: EdgeInsets.fromLTRB(ExecutiveSpacing.containerPadding(context), ExecutiveSpacing.containerPadding(context), ExecutiveSpacing.containerPadding(context), 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Row(
              children: [
                _buildNavButton(Icons.arrow_back_ios_new_rounded, () => context.read<StateBoards>().setSelectedBoard(null)),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(currentBoard.name, style: GlassText.headlineXL().copyWith(fontSize: isTablet ? 32 : 48), overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 8),
                      Text('${currentBoard.type.toUpperCase()} PROJECT • ${currentBoard.columns.length} STRATEGIC PHASES', style: GlassText.bodyMD().copyWith(color: GlassColors.onSurfaceVariant.withOpacity(0.6), fontSize: 12)),
                      const SizedBox(height: 16),
                      // 🚀 Unified Cluster Strip (Avatars + Filter + Gear)
                      _buildClusterOperatives(currentBoard),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Row(
            children: [
              if (!isMobile) ...[
                _buildGhostButton('ADD PHASE', Icons.view_column_rounded, onTap: () => _showColumnSettings(currentBoard)),
                const SizedBox(width: 12),
                _buildGhostButton(_isSelectMode ? 'EXIT BULK' : 'BULK ACTION', Icons.checklist_rtl_rounded, onTap: () => setState(() { _isSelectMode = !_isSelectMode; if (!_isSelectMode) _selectedTaskIds.clear(); })),
                const SizedBox(width: 12),
                _buildGhostButton('NEW TASK', Icons.add_rounded, onTap: () => _showAddTask(currentBoard)),
              ],
              // 🚀 Mobile-only Bulk Action toggle to save space
              if (isMobile)
                _buildActionIcon(
                  _isSelectMode ? Icons.checklist_rounded : Icons.checklist_rtl_rounded,
                  onTap: () => setState(() { _isSelectMode = !_isSelectMode; if (!_isSelectMode) _selectedTaskIds.clear(); }),
                  color: _isSelectMode ? GlassColors.gold : null,
                  size: 36,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUnifiedBoardMenu(BoardModel board) {
    final bool isOwner = board.ownerUid == AuthService().currentUser?.uid;
    final bool hasActiveZoom = _isOverviewMode;

    return Stack(
      children: [
        PopupMenuButton<String>(
          icon: _buildActionIcon(Icons.settings_outlined, size: 36),
          color: GlassColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), 
            side: BorderSide(color: GlassColors.ghostBorder, width: 0.5),
          ),
          onSelected: (value) {
            if (value == 'toggle_zoom') setState(() => _isOverviewMode = !_isOverviewMode);
            else if (value == 'share') _showBoardInfoDialog(board);
            else if (value == 'rename') _showRenameBoardDialog(context, board);
            else if (value == 'members') _showRoleManager(board);
          },
          itemBuilder: (context) => [
            // --- View Settings ---
            PopupMenuItem(
              value: 'toggle_zoom',
              child: Row(
                children: [
                  Icon(_isOverviewMode ? Icons.zoom_in_map_rounded : Icons.zoom_out_map_rounded, size: 18, color: _isOverviewMode ? GlassColors.gold : GlassColors.primary),
                  const SizedBox(width: 12),
                  Text(_isOverviewMode ? 'FOCUS MODE' : 'EAGLE EYE VIEW', style: GlassText.bodyMD()),
                ],
              ),
            ),
            const PopupMenuDivider(height: 1),
            
            // --- Board Actions ---
            PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  const Icon(Icons.share_rounded, size: 18, color: GlassColors.primary),
                  const SizedBox(width: 12),
                  Text('BOARD INFO / SHARE', style: GlassText.bodyMD()),
                ],
              ),
            ),
            
            // --- Administrative Actions (Owner Only) ---
            if (isOwner) ...[
              const PopupMenuDivider(height: 1),
              PopupMenuItem(
                value: 'rename',
                child: Row(
                  children: [
                    const Icon(Icons.edit_rounded, size: 18, color: GlassColors.gold),
                    const SizedBox(width: 12),
                    Text('RENAME BOARD', style: GlassText.bodyMD().copyWith(color: GlassColors.gold)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'members',
                child: Row(
                  children: [
                    const Icon(Icons.group_rounded, size: 18, color: GlassColors.gold),
                    const SizedBox(width: 12),
                    Text('MANAGE TEAM', style: GlassText.bodyMD().copyWith(color: GlassColors.gold)),
                  ],
                ),
              ),
            ],
          ],
        ),

        // 🚀 Status Badge (Dot for Zoom only now, Filter is separate)
        if (hasActiveZoom)
          Positioned(
            right: 4, top: 4,
            child: Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                color: GlassColors.gold,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }

  void _showOperativeFilterMenu(BuildContext context, BoardModel board) {
    final boardState = context.read<StateBoards>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: GlassDecorations.solidSurface(radius: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('STRATEGIC OPERATIVE FILTER', style: GlassText.labelSM().copyWith(letterSpacing: 2.0, color: GlassColors.gold)),
            const SizedBox(height: 24),
            ListTile(
              leading: Icon(Icons.group_rounded, color: _activeOperativeId == null ? GlassColors.primary : Colors.white30),
              title: Text('ALL OPERATIVES', style: GlassText.bodyMD().copyWith(fontWeight: _activeOperativeId == null ? FontWeight.bold : FontWeight.normal)),
              onTap: () { setState(() => _activeOperativeId = null); Navigator.pop(context); },
            ),
            const Divider(color: Colors.white10),
            ...board.members.map((uid) {
              final profile = boardState.getMemberProfile(uid);
              final name = profile?['name'] ?? 'Operative';
              final color = GlassColors.getMemberColor(uid);
              final isSelected = _activeOperativeId == uid;

              return ListTile(
                leading: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.2)),
                  child: Center(child: Text(name[0].toUpperCase(), style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold))),
                ),
                title: Text(name.toUpperCase(), style: GlassText.bodyMD().copyWith(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: GlassColors.primary, size: 20) : null,
                onTap: () { setState(() => _activeOperativeId = uid); Navigator.pop(context); },
              );
            }).toList(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildClusterOperatives(BoardModel currentBoard) {
    final boardState = context.watch<StateBoards>();
    final members = currentBoard.members;
    final visibleMembers = members.take(3).toList();
    final remainingCount = members.length - visibleMembers.length;

    return Row(
      children: [
        // --- 👥 Avatar Stack (Max 3) ---
        ...visibleMembers.map((uid) {
          final profile = boardState.getMemberProfile(uid);
          final color = GlassColors.getMemberColor(uid);
          final name = profile?['name'] ?? 'Operative';
          final photo = profile?['photo'] ?? '';
          return Padding(
            padding: const EdgeInsets.only(right: 8), 
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle, 
                color: color.withOpacity(0.15),
                border: Border.all(color: GlassColors.ghostBorder, width: 0.5),
              ),
              child: ClipOval(
                child: photo.isNotEmpty 
                  ? Image.network(
                      photo, 
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: TextStyle(fontSize: 12, color: color))
                      ),
                    )
                  : Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: TextStyle(fontSize: 12, color: color))),
              ),
            )
          );
        }).toList(),

        // --- ➕ Remaining Count ---
        if (remainingCount > 0)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: GlassColors.onSurface.withOpacity(0.05),
                border: Border.all(color: GlassColors.ghostBorder, width: 0.5),
              ),
              child: Center(
                child: Text('+$remainingCount', style: GlassText.label().copyWith(fontSize: 10, color: GlassColors.onSurfaceVariant.withOpacity(0.5))),
              ),
            ),
          ),

        const SizedBox(width: 8),
        Container(width: 1, height: 20, color: GlassColors.ghostBorder),
        const SizedBox(width: 16),

        // --- 🚀 Filter Button ---
        Stack(
          children: [
            _buildActionIcon(
              Icons.filter_list_rounded,
              size: 36,
              onTap: () => _showOperativeFilterMenu(context, currentBoard),
              color: _activeOperativeId != null ? GlassColors.primary : null,
            ),
            if (_activeOperativeId != null)
              Positioned(
                right: 4, top: 4,
                child: Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: GlassColors.gold,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
        
        const SizedBox(width: 8),

        // --- 🚀 Gear Settings ---
        _buildUnifiedBoardMenu(currentBoard),
      ],
    );
  }

  Widget _buildNavButton(IconData icon, VoidCallback onTap, {double size = 44}) => GestureDetector(onTap: onTap, child: Container(padding: EdgeInsets.all(size == 32 ? 6 : 12), decoration: BoxDecoration(borderRadius: BorderRadius.circular(ExecutiveRadius.circular), border: Border.all(color: GlassColors.outlineVariant.withOpacity(0.3))), child: Icon(icon, size: size == 32 ? 16 : 18, color: GlassColors.onSurface)));
  Widget _buildGhostButton(String label, IconData icon, {VoidCallback? onTap}) => GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), decoration: BoxDecoration(color: GlassColors.gold.withOpacity(0.1), borderRadius: BorderRadius.circular(ExecutiveRadius.circular), border: Border.all(color: GlassColors.gold.withOpacity(0.3))), child: Row(children: [Icon(icon, size: 18, color: GlassColors.gold), const SizedBox(width: 8), Text(label, style: GlassText.labelSM().copyWith(color: GlassColors.gold, fontSize: 10))])));
  Widget _buildActionIcon(IconData icon, {VoidCallback? onTap, Color? color, double size = 44}) => GestureDetector(onTap: onTap, child: Container(width: size, height: size, alignment: Alignment.center, decoration: BoxDecoration(borderRadius: BorderRadius.circular(ExecutiveRadius.circular), border: Border.all(color: (color ?? GlassColors.outlineVariant).withOpacity(0.3))), child: Icon(icon, size: 18, color: color ?? GlassColors.onSurface)));

  void _showAddTask(BoardModel board, [String? col]) => TaskEditModal.show(context: context, board: board, initialStatus: col, isDark: widget.isDark);
  void _showColumnSettings(BoardModel board, [String? col]) => showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true, builder: (context) => ColumnEditModal(board: board, existingColumn: col));
  void _showTaskDetails(BoardModel board, TaskModel task) => TaskEditModal.show(context: context, board: board, existingTask: task, isDark: widget.isDark);
  void _showRoleManager(BoardModel board) => showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true, builder: (context) => MemberRoleModal(board: board));
  void _showBoardInfoDialog(BoardModel board) => showDialog(context: context, builder: (context) => _BoardInfoDialog(board: board));

  void _showMoveMenu(BuildContext context, BoardModel board) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32), decoration: GlassDecorations.solidSurface(radius: 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('SELECT TARGET PHASE', style: GlassText.labelSM().copyWith(letterSpacing: 2)),
            const SizedBox(height: 24),
            ...board.columns.map((col) => ListTile(
              title: Text(col.toUpperCase(), style: GlassText.bodyMD()),
              leading: const Icon(Icons.subdirectory_arrow_right_rounded, color: GlassColors.primary, size: 20),
              onTap: () { Navigator.pop(context); _moveSelectedTasks(col); },
            )).toList(),
          ],
        ),
      ),
    );
  }

  void _showRenameBoardDialog(BuildContext context, BoardModel board) {
    final controller = TextEditingController(text: board.name);
    showDialog(
      context: context,
      builder: (dialogContext) => Center(
        child: Container(
          width: 400,
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: GlassDecorations.solidSurface(radius: 24, hasShadow: true),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('RENAME BOARD', style: GlassText.labelSM().copyWith(color: GlassColors.primary, letterSpacing: 2)),
                const SizedBox(height: 24),
                ImeSafeTextField(
                  controller: controller,
                  autofocus: true,
                  style: GlassText.bodyLG(),
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
                          if (newName.isEmpty || newName == board.name) return;
                          final boardsState = context.read<StateBoards>();
                          final navigator = Navigator.of(dialogContext);
                          try {
                            await boardsState.updateBoard(board.copyWith(name: newName));
                            navigator.pop();
                            GlassNotifications.show(context, 'Board renamed successfully!');
                          } catch (e) {
                            GlassNotifications.show(context, 'Failed to rename board: $e', isError: true);
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

class _BoardInfoDialog extends StatelessWidget {
  final BoardModel board;
  const _BoardInfoDialog({required this.board});
  @override
  Widget build(BuildContext context) => Center(child: Container(width: 400, padding: const EdgeInsets.all(32), decoration: GlassDecorations.solidSurface(radius: 24), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('BOARD ID', style: GlassText.labelSM()), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]), const SizedBox(height: 24), SelectableText(board.id, style: GlassText.bodyMD().copyWith(fontFamily: 'monospace', color: GlassColors.primary)), const SizedBox(height: 16), IconButton(icon: const Icon(Icons.copy), onPressed: () => Clipboard.setData(ClipboardData(text: board.id)))])));
}
