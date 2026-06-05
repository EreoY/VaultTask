import 'package:flutter/material.dart';
import '../../common/ime_safe_text_field.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/task_model.dart';
import '../../../models/board_model.dart';
import '../../../state_managers/state_tasks.dart';
import '../../../state_managers/state_boards.dart';
import '../../../databases/api_cloudflare.dart';
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

  @override
  State<TaskEditModal> createState() => _TaskEditModalState();
}

class _TaskEditModalState extends State<TaskEditModal> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _descFocusNode = FocusNode();
  
  // Persistent Controllers for Asset Names
  final Map<String, TextEditingController> _assetNameControllers = {};
  
  late DateTime _dueDate;
  late String _status;
  List<TaskImage> _images = [];
  List<String> _members = [];
  List<String> _labelIds = [];
  bool _isSaving = false;
  bool _isUploading = false;

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
      WidgetsBinding.instance.addPostFrameCallback((_) => _refreshTaskData());
      
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
      });
    }
  }

  @override
  void dispose() {
    _taskNotifier?.removeListener(_onTaskUpdated);
    _titleController.dispose();
    _descController.dispose();
    _descFocusNode.dispose();
    for (final c in _assetNameControllers.values) {
      c.dispose();
    }
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
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        // Task 36.5: Universal Reactive Modal
        return Consumer2<StateBoards, StateTasks>(
          builder: (context, boardState, taskState, _) {
            final currentBoard = boardState.boards.firstWhere((b) => b.id == widget.board.id, orElse: () => widget.board);
            
            // Task 36.2: Live State Reconciliation
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

            return Container(
              decoration: GlassDecorations.surface(radius: 32, hasShadow: true),
              child: ListView(
                controller: scrollController,
                padding: EdgeInsets.zero, // Zero padding for cover bleed
                children: [
                  if (hasCover)
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                        image: DecorationImage(image: NetworkImage(coverImage.url), fit: BoxFit.cover),
                      ),
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
                  Padding(
                    padding: const EdgeInsets.all(48),
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
                ],
              ),
            );
          }
        );
      },
    );
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
                image: DecorationImage(image: NetworkImage(img.url), fit: BoxFit.cover),
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
                          backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                          backgroundColor: GlassColors.getMemberColor(entry.key).withOpacity(0.2),
                          child: photo.isEmpty ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: GlassText.labelSM().copyWith(fontSize: 10, color: GlassColors.getMemberColor(entry.key))) : null,
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
}
