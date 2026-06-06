import 'package:flutter/material.dart';
import '../../common/ime_safe_text_field.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/task_model.dart';
import '../../../models/board_model.dart';
import '../../../models/chat_model.dart';
import '../../../state_managers/state_tasks.dart';
import '../../../state_managers/state_boards.dart';
import '../../../state_managers/state_chat.dart';
import '../../../databases/api_cloudflare.dart';
import '../../../services/auth_service.dart';
import '../../theme/glass_theme.dart';
import '../../common/glass_widgets.dart';

class TaskEditModal extends StatefulWidget {
  final BoardModel board;
  final String? initialStatus;
  final TaskModel? existingTask;
  final DateTime? initialDate;
  final bool isDark;

  const TaskEditModal({
    super.key,
    required this.board,
    this.initialStatus,
    this.existingTask,
    this.initialDate,
    required this.isDark,
  });

  static Future<void> show({
    required BuildContext context,
    required BoardModel board,
    TaskModel? existingTask,
    String? initialStatus,
    DateTime? initialDate,
    required bool isDark,
  }) async {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    if (isDesktop) {
      await showDialog(
        context: context,
        barrierColor: Colors.black.withOpacity(0.6),
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          child: TaskEditModal(
            board: board,
            existingTask: existingTask,
            initialStatus: initialStatus,
            initialDate: initialDate,
            isDark: isDark,
          ),
        ),
      );
    } else {
      await showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) => TaskEditModal(
          board: board,
          existingTask: existingTask,
          initialStatus: initialStatus,
          initialDate: initialDate,
          isDark: isDark,
        ),
      );
    }
  }

  @override
  State<TaskEditModal> createState() => _TaskEditModalState();
}

class _TaskEditModalState extends State<TaskEditModal> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _descFocusNode = FocusNode();
  final _commentController = TextEditingController();
  
  // Persistent Controllers for Asset Names
  final Map<String, TextEditingController> _assetNameControllers = {};
  
  late DateTime _dueDate;
  late String _status;
  List<TaskImage> _images = [];
  List<String> _members = [];
  List<String> _labelIds = [];
  List<TaskComment> _comments = [];
  bool _isSaving = false;
  bool _isUploading = false;
  int _activeTab = 0;
  final _taskChatController = TextEditingController();

  Map<String, Map<String, String>> _availableMembers = {};
  
  // 🔄 Real-time listener for task updates while popup is open
  ValueNotifier<TaskModel>? _taskNotifier;

  @override
  void initState() {
    super.initState();
    if (widget.existingTask != null) {
      _titleController.text = widget.existingTask!.title;
      _descController.text = widget.existingTask!.description;
      _dueDate = widget.existingTask!.dueDate;
      _status = widget.existingTask!.status;
      _images = List.from(widget.existingTask!.images);
      _members = List.from(widget.existingTask!.members);
      _labelIds = List.from(widget.existingTask!.labelIds);
      _comments = List.from(widget.existingTask!.comments);
    } else {
      _dueDate = widget.initialDate ?? DateTime.now().add(const Duration(days: 1));
      _status = widget.initialStatus ?? (widget.board.columns.isNotEmpty ? widget.board.columns.first : 'todo');
    }

    _descFocusNode.addListener(() {
      if (!_descFocusNode.hasFocus) {
        _autoSaveTask();
      }
    });

    _loadBoardMembers();

    // 🔄 Fetch fresh task data when opening edit modal
    if (widget.existingTask != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _refreshTaskData();
        context.read<StateChat>().selectTaskSession(widget.existingTask!.id);
      });
      
      // 🔄 Listen to real-time task updates while popup is open
      final taskState = context.read<StateTasks>();
      _taskNotifier = taskState.getTaskNotifier(widget.existingTask!.id);
      _taskNotifier?.addListener(_onTaskUpdated);
    }
  }

  void _onTaskUpdated() {
    final updated = _taskNotifier?.value;
    if (updated == null || !mounted) return;
    // Only update if data actually changed
    if (_titleController.text != updated.title ||
        _descController.text != updated.description ||
        _status != updated.status ||
        !_dueDate.isAtSameMomentAs(updated.dueDate)) {
      setState(() {
        _titleController.text = updated.title;
        _descController.text = updated.description;
        _dueDate = updated.dueDate;
        _status = updated.status;
        _images = List.from(updated.images);
        _members = List.from(updated.members);
        _labelIds = List.from(updated.labelIds);
        _comments = List.from(updated.comments);
      });
    }
  }

  @override
  void dispose() {
    _taskNotifier?.removeListener(_onTaskUpdated);
    _titleController.dispose();
    _descController.dispose();
    _descFocusNode.dispose();
    _commentController.dispose();
    _taskChatController.dispose();
    for (final c in _assetNameControllers.values) {
      c.dispose();
    }
    context.read<StateChat>().switchToGlobalContext();
    super.dispose();
  }

  Future<void> _loadBoardMembers() async {
    if (widget.board.members.isEmpty) return;
    try {
      final members = await ApiCloudflare.getUsersByUids(widget.board.members);
      if (mounted) setState(() => _availableMembers = members);
    } catch (e) {
      debugPrint('Error loading members: $e');
    }
  }

  Future<void> _refreshTaskData() async {
    if (widget.existingTask == null) return;
    try {
      final taskState = context.read<StateTasks>();
      await taskState.fetchTasksForBoard(widget.board, silent: true);
      final tasks = taskState.tasksForBoard(widget.board.id);
      final updated = tasks.firstWhere(
        (t) => t.id == widget.existingTask!.id,
        orElse: () => widget.existingTask!,
      );
      if (mounted && updated.id == widget.existingTask!.id) {
        setState(() {
          _titleController.text = updated.title;
          _descController.text = updated.description;
          _dueDate = updated.dueDate;
          _status = updated.status;
          _images = List.from(updated.images);
          _members = List.from(updated.members);
          _labelIds = List.from(updated.labelIds);
          _comments = List.from(updated.comments);
        });
      }
    } catch (e) {
      debugPrint('Error refreshing task data: $e');
    }
  }

  Future<void> _autoSaveTask() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    try {
      final task = widget.existingTask?.copyWith(
            title: title,
            description: _descController.text.trim(),
            dueDate: _dueDate,
            status: _status,
            images: _images,
            members: _members,
            labelIds: _labelIds,
            comments: _comments,
          ) ??
          TaskModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            boardId: widget.board.id,
            title: title,
            description: _descController.text.trim(),
            dueDate: _dueDate,
            type: widget.board.type,
            status: _status,
            images: _images,
            members: _members,
            labelIds: _labelIds,
            comments: _comments,
          );

      if (widget.existingTask != null) {
        await context.read<StateTasks>().updateTask(widget.board, task);
      } else {
        // If it's a new task, we only save explicitly via button to avoid duplicate spam on typing
      }
    } catch (e) {
      debugPrint('Auto-save Error: $e');
    }
  }

  Future<void> _handleExplicitSave() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    setState(() => _isSaving = true);
    try {
      if (widget.existingTask == null) {
        // CREATE NEW TASK (Fix for Task 7.1.1)
        final task = TaskModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          boardId: widget.board.id,
          title: title,
          description: _descController.text.trim(),
          dueDate: _dueDate,
          type: widget.board.type,
          status: _status,
          images: _images,
          members: _members,
          labelIds: _labelIds,
        );
        await context.read<StateTasks>().addTask(widget.board, task);
      } else {
        await _autoSaveTask();
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('Explicit Save Error: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (xFile == null) return;

    setState(() => _isUploading = true);
    try {
      final bytes = await xFile.readAsBytes();
      final result = await ApiCloudflare.uploadImage(bytes, xFile.name);
      
      final newImage = TaskImage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        url: result['url'],
        r2Key: result['key'] ?? '',
        isCover: _images.isEmpty,
      );

      setState(() => _images.add(newImage));
      await _autoSaveTask();
    } catch (e) {
      debugPrint('Upload Error: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    if (isDesktop) {
      return Consumer2<StateBoards, StateTasks>(
        builder: (context, boardState, taskState, _) {
          final currentBoard = boardState.boards.firstWhere((b) => b.id == widget.board.id, orElse: () => widget.board);
          
          if (widget.existingTask != null) {
            final tasks = taskState.tasksForBoard(widget.board.id);
            final updatedTask = tasks.firstWhere((t) => t.id == widget.existingTask!.id, orElse: () => widget.existingTask!);
            
            _labelIds = updatedTask.labelIds;
            _members = updatedTask.members;
            _images = updatedTask.images;
            _status = updatedTask.status;
            _dueDate = updatedTask.dueDate;
          }

          final mainBody = Padding(
            padding: const EdgeInsets.all(48),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column (Task Edit Form)
                Expanded(
                  flex: 5,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 48),
                        _buildTextField(
                          controller: _titleController,
                          hint: 'Task Title',
                          style: GlassText.headlineLG().copyWith(fontSize: 38),
                          maxLines: 1,
                        ),
                        const SizedBox(height: 16),
                        _buildMetadataStrip(currentBoard),
                        const SizedBox(height: 32),
                        _buildTextField(
                          controller: _descController,
                          focusNode: _descFocusNode,
                          hint: 'Add a strategic description...',
                          style: GlassText.bodyLG().copyWith(fontSize: 18, color: GlassColors.onSurface.withOpacity(0.7)),
                          maxLines: 12,
                        ),
                        const SizedBox(height: 48),
                        _buildSectionTitle('OPERATIONAL ASSETS'),
                        const SizedBox(height: 24),
                        _buildVerticalAssetList(),
                        const SizedBox(height: 80),
                        if (widget.existingTask == null)
                           _buildGhostButton('CREATE STRATEGIC TASK', _handleExplicitSave, isPrimary: true),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 48),
                // Vertical Divider
                Container(
                  width: 1,
                  height: double.infinity,
                  color: GlassColors.ghostBorder,
                ),
                const SizedBox(width: 48),
                // Right Column (Comments / Chat)
                Expanded(
                  flex: 4,
                  child: widget.existingTask != null
                      ? _buildRightTabSection(isDesktop: true)
                      : Center(
                          child: Text(
                            'บันทึกงานนี้ก่อนเพื่อเริ่มการสนทนาและเขียนคอมเม้น',
                            style: GlassText.bodyMD().copyWith(
                              color: GlassColors.onSurfaceVariant.withOpacity(0.5),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          );

          return Material(
            color: Colors.transparent,
            child: Center(
              child: Container(
                width: 1100,
                height: MediaQuery.of(context).size.height * 0.85,
                decoration: GlassDecorations.solidSurface(radius: 32, hasShadow: true),
                child: mainBody,
              ),
            ),
          );
        },
      );
    } else {
      return DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return Consumer2<StateBoards, StateTasks>(
            builder: (context, boardState, taskState, _) {
              final currentBoard = boardState.boards.firstWhere((b) => b.id == widget.board.id, orElse: () => widget.board);
              
              if (widget.existingTask != null) {
                final tasks = taskState.tasksForBoard(widget.board.id);
                final updatedTask = tasks.firstWhere((t) => t.id == widget.existingTask!.id, orElse: () => widget.existingTask!);
                
                _labelIds = updatedTask.labelIds;
                _members = updatedTask.members;
                _images = updatedTask.images;
                _status = updatedTask.status;
                _dueDate = updatedTask.dueDate;
              }

              final coverImage = _images.isEmpty 
                  ? null 
                  : _images.firstWhere((img) => img.isCover, orElse: () => _images.first);
              final hasCover = coverImage != null && coverImage.url.isNotEmpty;

              final mainBody = ListView(
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
                                coverImage.url,
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
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 32),
                        _buildTextField(
                          controller: _titleController,
                          hint: 'Task Title',
                          style: GlassText.headlineLG().copyWith(fontSize: 32),
                          maxLines: 1,
                        ),
                        const SizedBox(height: 16),
                        _buildMetadataStrip(currentBoard),
                        const SizedBox(height: 24),
                        _buildTextField(
                          controller: _descController,
                          hint: 'Add a strategic description...',
                          style: GlassText.bodyLG().copyWith(fontSize: 16, color: GlassColors.onSurface.withOpacity(0.7)),
                          maxLines: 8,
                        ),
                        const SizedBox(height: 32),
                        _buildSectionTitle('OPERATIONAL ASSETS'),
                        const SizedBox(height: 16),
                        _buildVerticalAssetList(),
                        if (widget.existingTask != null) ...[
                          const SizedBox(height: 32),
                          _buildRightTabSection(isDesktop: false),
                        ],
                        const SizedBox(height: 48),
                        if (widget.existingTask == null)
                           _buildGhostButton('CREATE STRATEGIC TASK', _handleExplicitSave, isPrimary: true),
                      ],
                    ),
                  ),
                ],
              );

              return Container(
                decoration: GlassDecorations.solidSurface(radius: 32, hasShadow: true),
                child: mainBody,
              );
            },
          );
        },
      );
    }
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          widget.existingTask != null ? 'STRATEGIC TASK' : 'NEW STRATEGIC TASK',
          style: GlassText.labelSM().copyWith(letterSpacing: 2.0, color: GlassColors.primary),
        ),
        Row(
          children: [
            if (widget.existingTask != null)
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: GlassColors.error, size: 20),
                onPressed: () async {
                  await context.read<StateTasks>().deleteTask(widget.board, widget.existingTask!);
                  if (mounted) Navigator.pop(context);
                },
              ),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 24),
              onPressed: () => Navigator.pop(context),
              color: GlassColors.onSurfaceVariant.withOpacity(0.5),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetadataStrip(BoardModel currentBoard) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GlassColors.onSurface.withOpacity(0.03),
        borderRadius: BorderRadius.circular(ExecutiveRadius.m),
        border: Border.all(color: GlassColors.ghostBorder),
      ),
      child: Wrap(
        spacing: 24,
        runSpacing: 16,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _buildMetadataItem(icon: Icons.layers_outlined, label: _status.toUpperCase(), onTap: () => _pickStatus(currentBoard)),
          _buildMetadataItem(icon: Icons.calendar_today_rounded, label: DateFormat('MMM d').format(_dueDate).toUpperCase(), onTap: _pickDate),
          _buildMetadataItem(icon: Icons.label_outline_rounded, label: '${_labelIds.length} LABELS', onTap: () => _pickLabels(currentBoard)),
          _buildMetadataItem(icon: Icons.group_outlined, label: '${_members.length} OPERATIVES', onTap: () => _pickMembers(currentBoard)),
        ],
      ),
    );
  }

  Widget _buildMetadataItem({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ExecutiveRadius.s),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: GlassColors.primary.withOpacity(0.5)),
          const SizedBox(width: 8),
          Text(label, style: GlassText.labelSM().copyWith(fontSize: 10, color: GlassColors.primary)),
        ],
      ),
    );
  }

  Widget _buildVerticalAssetList() {
    return Column(
      children: [
        ..._images.map((img) => _buildAssetRow(img)).toList(),
        const SizedBox(height: 16),
        _buildGhostButton('UPLOAD MEDIA ASSET', _pickAndUploadImage, icon: Icons.add_photo_alternate_outlined),
      ],
    );
  }

  Widget _buildAssetRow(TaskImage img) {
    // Task 36.2: Persistent Controller Implementation
    if (!_assetNameControllers.containsKey(img.id)) {
      _assetNameControllers[img.id] = TextEditingController(text: img.aiDescription.isEmpty ? 'ASSET_${img.id.substring(img.id.length - 4)}' : img.aiDescription);
    }
    final nameController = _assetNameControllers[img.id]!;

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
          GestureDetector(
            onTap: () => _showFullImage(img.url),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(ExecutiveRadius.s),
                color: GlassColors.surfaceHighest.withOpacity(0.1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(ExecutiveRadius.s),
                child: Image.network(
                  img.url,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Icon(Icons.broken_image_outlined, size: 16, color: GlassColors.primary.withOpacity(0.3)),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: nameController,
              style: GlassText.bodyMD().copyWith(fontWeight: FontWeight.w600),
              onSubmitted: (v) {
                setState(() {
                   _images = _images.map((i) => i.id == img.id ? i.copyWith(aiDescription: v) : i).toList();
                });
                _autoSaveTask();
              },
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          IconButton(
            icon: Icon(img.isCover ? Icons.star_rounded : Icons.star_border_rounded, color: img.isCover ? GlassColors.gold : GlassColors.onSurfaceVariant.withOpacity(0.3), size: 20),
            onPressed: () {
              setState(() {
                _images = _images.map((i) => i.copyWith(isCover: i.id == img.id)).toList();
              });
              _autoSaveTask();
            },
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: GlassColors.error, size: 20),
            onPressed: () {
              setState(() => _images.removeWhere((i) => i.id == img.id));
              _autoSaveTask();
            },
          ),
        ],
      ),
    );
  }

  void _showFullImage(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: GlassDecorations.surface(radius: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ),
               Flexible(child: Image.network(url, fit: BoxFit.contain)),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GlassText.labelSM().copyWith(fontSize: 10, color: GlassColors.onSurfaceVariant.withOpacity(0.5), letterSpacing: 1.5),
    );
  }

  Widget _buildTextField({required TextEditingController controller, FocusNode? focusNode, required String hint, required TextStyle style, required int maxLines}) {
    return ImeSafeTextField(
      controller: controller,
      focusNode: focusNode,
      style: style,
      maxLines: maxLines,
      minLines: 1,
      onSubmitted: (_) => _autoSaveTask(),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: style.copyWith(color: GlassColors.onSurfaceVariant.withOpacity(0.2)),
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildGhostButton(String label, VoidCallback onTap, {bool isPrimary = false, IconData? icon}) {
    final color = isPrimary ? GlassColors.gold : GlassColors.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ExecutiveRadius.circular),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        decoration: BoxDecoration(
          color: isPrimary ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(ExecutiveRadius.circular),
          border: Border.all(color: color.withOpacity(isPrimary ? 0.3 : 0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 18, color: color), const SizedBox(width: 12)],
            Text(label, style: GlassText.labelSM().copyWith(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: GlassColors.primary,
            onPrimary: Colors.black,
            surface: GlassColors.background,
            onSurface: GlassColors.onSurface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
      await _autoSaveTask();
    }
  }

  void _pickStatus(BoardModel currentBoard) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: GlassDecorations.surface(radius: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: currentBoard.columns.map((col) => ListTile(
            title: Text(col.toUpperCase(), style: GlassText.bodyMD()),
            onTap: () async {
              setState(() => _status = col);
              await _autoSaveTask();
              if (mounted) Navigator.pop(context);
            },
          )).toList(),
        ),
      ),
    );
  }

  void _pickLabels(BoardModel currentBoard) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(32),
            decoration: GlassDecorations.surface(radius: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionTitle('BOARD LABELS'),
                    TextButton.icon(
                      icon: const Icon(Icons.add, size: 16),
                      label: Text('CREATE NEW', style: GlassText.labelSM().copyWith(fontSize: 10)),
                      onPressed: () => _createNewBoardLabel(currentBoard, setModalState),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...currentBoard.labels.map((l) {
                  final id = l['id'] as String;
                  final name = l['name'] as String;
                  final color = l['color'] as int;
                  final isSelected = _labelIds.contains(id);
                  return CheckboxListTile(
                    title: Row(
                      children: [
                        Container(width: 12, height: 12, decoration: BoxDecoration(color: Color(color), shape: BoxShape.circle)),
                        const SizedBox(width: 12),
                        Text(name, style: GlassText.bodyMD()),
                      ],
                    ),
                    value: isSelected,
                    activeColor: Color(color),
                    onChanged: (v) async {
                      setModalState(() {
                        if (v == true) _labelIds.add(id);
                        else _labelIds.remove(id);
                      });
                      setState(() {});
                      await _autoSaveTask();
                    },
                  );
                }).toList(),
              ],
            ),
          );
        }
      ),
    );
  }

  void _createNewBoardLabel(BoardModel currentBoard, Function setModalState) {
    final controller = TextEditingController();
    int selectedColor = GlassColors.primary.value;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: GlassColors.background,
            title: Text('CREATE NEW LABEL', style: GlassText.headlineLG().copyWith(fontSize: 24)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  autofocus: true,
                  style: GlassText.bodyMD(),
                  decoration: const InputDecoration(hintText: 'Label Name'),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  children: GlassColors.memberPalette.map((color) {
                    final isSelected = selectedColor == color.value;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedColor = color.value),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(color: isSelected ? Colors.white : Colors.transparent, width: 2),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text('CANCEL', style: GlassText.label())),
              TextButton(
                onPressed: () async {
                  if (controller.text.isNotEmpty) {
                    await context.read<StateBoards>().addLabel(currentBoard, controller.text, selectedColor);
                    setModalState(() {}); // Refresh label list
                    Navigator.pop(context);
                  }
                },
                child: Text('CREATE', style: GlassText.label().copyWith(color: GlassColors.gold)),
              ),
            ],
          );
        }
      ),
    );
  }

  void _pickMembers(BoardModel currentBoard) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(32),
            decoration: GlassDecorations.surface(radius: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('BOARD OPERATIVES'),
                const SizedBox(height: 16),
                ..._availableMembers.entries.map((entry) {
                  final isSelected = _members.contains(entry.key);
                  final name = entry.value['name'] ?? entry.key;
                  final photo = entry.value['photo'] ?? '';
                  final role = currentBoard.memberRoles[entry.key] ?? 'Operative';
                  
                  return CheckboxListTile(
                    title: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          foregroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                          onForegroundImageError: photo.isNotEmpty
                              ? (exception, stackTrace) { /* CORS/network fallback */ }
                              : null,
                          backgroundColor: GlassColors.getMemberColor(entry.key).withOpacity(0.2),
                          child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: GlassText.labelSM().copyWith(fontSize: 10, color: GlassColors.getMemberColor(entry.key))),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: GlassText.bodyMD()),
                            Text(role.toUpperCase(), style: GlassText.labelSM().copyWith(fontSize: 8, color: GlassColors.onSurfaceVariant.withOpacity(0.5))),
                          ],
                        ),
                      ],
                    ),
                    value: isSelected,
                    activeColor: GlassColors.primary,
                    onChanged: (v) async {
                      setModalState(() {
                        if (v == true) _members.add(entry.key);
                        else _members.remove(entry.key);
                      });
                      setState(() {});
                      await _autoSaveTask();
                    },
                  );
                }).toList(),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildRightTabSection({required bool isDesktop}) {
    final tabContent = AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: _activeTab == 0
          ? _buildCommentsSection(isDesktop: isDesktop)
          : _buildTaskChatSection(isDesktop: isDesktop),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tab Header
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _buildTabHeaderItem(0, 'ประวัติคอมเม้น', Icons.comment_outlined),
            _buildTabHeaderItem(1, 'แชทถามเกี่ยวกับงานนี้', Icons.chat_bubble_outline_rounded),
            if (_activeTab == 1)
              TextButton.icon(
                onPressed: () {
                  if (widget.existingTask != null) {
                    context.read<StateChat>().startNewTaskSession(widget.existingTask!.id);
                  }
                },
                icon: const Icon(Icons.refresh_rounded, size: 16, color: GlassColors.primary),
                label: Text(
                  'เริ่มเสสชันใหม่',
                  style: GlassText.labelSM().copyWith(color: GlassColors.primary),
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),
        // Tab Content
        isDesktop ? Expanded(child: tabContent) : tabContent,
      ],
    );
  }

  Widget _buildTabHeaderItem(int index, String title, IconData icon) {
    final isSelected = _activeTab == index;
    return InkWell(
      onTap: () {
        setState(() {
          _activeTab = index;
        });
      },
      borderRadius: BorderRadius.circular(ExecutiveRadius.m),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? GlassColors.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(ExecutiveRadius.m),
          border: Border.all(
            color: isSelected ? GlassColors.primary.withOpacity(0.3) : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? GlassColors.primary : GlassColors.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: GlassText.labelSM().copyWith(
                color: isSelected ? GlassColors.primary : GlassColors.onSurfaceVariant.withOpacity(0.7),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskChatSection({bool isDesktop = false}) {
    return Consumer<StateChat>(
      builder: (context, chatState, _) {
        final messages = chatState.messages;
        final isTyping = chatState.isTyping;

        final listWidget = ListView.builder(
          reverse: true,
          padding: const EdgeInsets.symmetric(vertical: 16),
          itemCount: messages.length,
          itemBuilder: (context, idx) {
            final msg = messages[idx];
            return _buildTaskChatMessageBubble(msg);
          },
        );

        final chatBoxContainer = Container(
          height: isDesktop ? null : 350,
          decoration: BoxDecoration(
            color: GlassColors.onSurface.withOpacity(0.02),
            borderRadius: BorderRadius.circular(ExecutiveRadius.l),
            border: Border.all(color: GlassColors.ghostBorder),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(ExecutiveRadius.l),
            child: messages.isEmpty
                ? Center(
                    child: Text(
                      'ไม่มีประวัติการพูดคุยในงานนี้\nพิมพ์แชทด้านล่างเพื่อเริ่มถาม AI เกี่ยวกับงานนี้',
                      textAlign: TextAlign.center,
                      style: GlassText.caption().copyWith(
                        color: GlassColors.onSurfaceVariant.withOpacity(0.5),
                      ),
                    ),
                  )
                : listWidget,
          ),
        );

        return Column(
          children: [
            isDesktop ? Expanded(child: chatBoxContainer) : chatBoxContainer,
            if (isTyping) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2, color: GlassColors.primary),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Misty AI กำลังพิมพ์...',
                    style: GlassText.caption().copyWith(
                      color: GlassColors.primary.withOpacity(0.7),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            _buildTaskChatInput(chatState),
          ],
        );
      },
    );
  }

  Widget _buildTaskChatMessageBubble(ChatMessage msg) {
    final isMe = msg.isUser;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMe 
              ? GlassColors.primary.withOpacity(0.15) 
              : GlassColors.onSurface.withOpacity(0.05),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          border: Border.all(
            color: isMe 
                ? GlassColors.primary.withOpacity(0.3) 
                : GlassColors.ghostBorder,
          ),
        ),
        constraints: const BoxConstraints(maxWidth: 280),
        child: Text(
          msg.text,
          style: GlassText.bodyMD().copyWith(
            color: GlassColors.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildTaskChatInput(StateChat chatState) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: GlassColors.onSurface.withOpacity(0.04),
              borderRadius: BorderRadius.circular(ExecutiveRadius.m),
              border: Border.all(color: GlassColors.ghostBorder),
            ),
            child: TextField(
              controller: _taskChatController,
              decoration: InputDecoration(
                hintText: 'ถามเกี่ยวกับงานนี้...',
                hintStyle: GlassText.bodyMD().copyWith(
                  color: GlassColors.onSurfaceVariant.withOpacity(0.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: InputBorder.none,
              ),
              style: GlassText.bodyMD(),
              onSubmitted: (_) => _sendTaskChatMessage(chatState),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.send_rounded, color: GlassColors.primary),
          onPressed: () => _sendTaskChatMessage(chatState),
        ),
      ],
    );
  }

  void _sendTaskChatMessage(StateChat chatState) {
    final text = _taskChatController.text.trim();
    if (text.isEmpty) return;
    _taskChatController.clear();
    
    _autoSaveTask();
    
    final activeTask = widget.existingTask?.copyWith(
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      dueDate: _dueDate,
      status: _status,
      images: _images,
      members: _members,
      labelIds: _labelIds,
      comments: _comments,
    ) ?? TaskModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      boardId: widget.board.id,
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      dueDate: _dueDate,
      type: widget.board.type,
      status: _status,
      images: _images,
      members: _members,
      labelIds: _labelIds,
      comments: _comments,
    );
    
    chatState.sendMessageToAI(text, activeTask: activeTask);
  }

  Widget _buildCommentsSection({required bool isDesktop}) {
    final currentUid = AuthService().currentUser?.uid ?? '';
    final currentUserName = AuthService().currentUser?.displayName ?? 'Anonymous';

    final listWidget = _comments.isEmpty
        ? Center(
            child: Text(
              'No discussion points logged yet.',
              style: GlassText.bodyMD().copyWith(
                color: GlassColors.onSurfaceVariant.withOpacity(0.4),
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        : ListView.separated(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: _comments.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final comment = _comments[index];
              final isMe = comment.userId == currentUid;
              final memberColor = GlassColors.getMemberColor(comment.userId);

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: memberColor.withOpacity(0.1),
                    child: Text(
                      comment.userName.isNotEmpty ? comment.userName[0].toUpperCase() : '?',
                      style: GlassText.labelSM().copyWith(color: memberColor, fontSize: 11),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              comment.userName.isNotEmpty ? comment.userName : 'Unknown',
                              style: GlassText.bodyMD().copyWith(fontWeight: FontWeight.w600, fontSize: 13),
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
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isMe ? GlassColors.primary.withOpacity(0.05) : GlassColors.onSurface.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: GlassColors.ghostBorder),
                          ),
                          child: Text(
                            comment.text,
                            style: GlassText.bodyMD().copyWith(fontSize: 13, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );

    final inputWidget = Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: GlassColors.onSurface.withOpacity(0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: GlassColors.ghostBorder),
            ),
            child: ImeSafeTextField(
              controller: _commentController,
              style: GlassText.bodyMD(),
              decoration: InputDecoration(
                hintText: 'Add a comment or progress update...',
                hintStyle: GlassText.bodyMD().copyWith(
                  color: GlassColors.onSurfaceVariant.withOpacity(0.3),
                ),
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _handleAddComment(currentUid, currentUserName),
            ),
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          icon: const Icon(Icons.send_rounded, color: GlassColors.primary),
          onPressed: () => _handleAddComment(currentUid, currentUserName),
        ),
      ],
    );

    if (isDesktop) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: listWidget,
          ),
          const SizedBox(height: 16),
          inputWidget,
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _comments.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No discussion points logged yet.',
                    style: GlassText.bodyMD().copyWith(
                      color: GlassColors.onSurfaceVariant.withOpacity(0.4),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _comments.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final comment = _comments[index];
                    final isMe = comment.userId == currentUid;
                    final memberColor = GlassColors.getMemberColor(comment.userId);
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: memberColor.withOpacity(0.1),
                          child: Text(
                            comment.userName.isNotEmpty ? comment.userName[0].toUpperCase() : '?',
                            style: GlassText.labelSM().copyWith(color: memberColor, fontSize: 11),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    comment.userName.isNotEmpty ? comment.userName : 'Unknown',
                                    style: GlassText.bodyMD().copyWith(fontWeight: FontWeight.w600, fontSize: 13),
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
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isMe ? GlassColors.primary.withOpacity(0.05) : GlassColors.onSurface.withOpacity(0.03),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: GlassColors.ghostBorder),
                                ),
                                child: Text(
                                  comment.text,
                                  style: GlassText.bodyMD().copyWith(fontSize: 13, height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
          const SizedBox(height: 24),
          inputWidget,
        ],
      );
    }
  }

  void _handleAddComment(String currentUid, String currentUserName) {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final newComment = TaskComment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: currentUid,
      userName: currentUserName,
      text: text,
      time: DateTime.now(),
    );

    setState(() {
      _comments.add(newComment);
      _commentController.clear();
    });

    _autoSaveTask();
  }
}

