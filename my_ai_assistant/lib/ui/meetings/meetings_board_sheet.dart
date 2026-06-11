import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../databases/api_cloudflare.dart';
import '../../models/board_model.dart';
import '../../models/meeting_model.dart';
import '../../state_managers/state_meetings.dart';
import '../common/ime_safe_text_field.dart';
import '../common/responsive_layout.dart';
import '../common/scroll_gutter.dart';
import '../theme/glass_theme.dart';

enum MeetingFilter { upcoming, all, past }

enum _MeetingDocTab { summary, notes, transcript }

class MeetingsBoardSheet extends StatefulWidget {
  final BoardModel board;
  final String? initialMeetingId;
  final bool embeddedInPage;
  final bool showListPane;
  final List<String> suggestedRoleTags;
  final List<String> initialRoleTags;
  final bool autoLoadFirstMeeting;
  final bool isCreateMode;
  final VoidCallback? onBack;
  final VoidCallback? onOpenBoard;
  final ValueChanged<MeetingModel>? onSaved;
  final bool showTopMeta;

  const MeetingsBoardSheet({
    super.key,
    required this.board,
    this.initialMeetingId,
    this.embeddedInPage = false,
    this.showListPane = true,
    this.suggestedRoleTags = const [],
    this.initialRoleTags = const [],
    this.autoLoadFirstMeeting = true,
    this.isCreateMode = false,
    this.onBack,
    this.onOpenBoard,
    this.onSaved,
    this.showTopMeta = true,
  });

  static Future<void> show({
    required BuildContext context,
    required BoardModel board,
    String? initialMeetingId,
  }) async {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    if (isDesktop) {
      await showDialog(
        context: context,
        barrierColor: Colors.black.withOpacity(0.62),
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 32,
            vertical: 20,
          ),
          child: MeetingsBoardSheet(
            board: board,
            initialMeetingId: initialMeetingId,
          ),
        ),
      );
      return;
    }
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) =>
          MeetingsBoardSheet(board: board, initialMeetingId: initialMeetingId),
    );
  }

  @override
  State<MeetingsBoardSheet> createState() => _MeetingsBoardSheetState();
}

class _MeetingsBoardSheetState extends State<MeetingsBoardSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  final _roleInputController = TextEditingController();
  final _editorScrollController = ScrollController();

  MeetingModel? _selectedMeeting;
  MeetingFilter _filter = MeetingFilter.upcoming;
  _MeetingDocTab _activeTab = _MeetingDocTab.summary;
  DateTime _startAt = DateTime.now().add(const Duration(hours: 1));
  List<String> _roleTags = [];
  List<Map<String, String>> _attachments = [];
  bool _isSaving = false;
  bool _isUploading = false;
  bool _draftInitialized = false;

  @override
  void initState() {
    super.initState();
    _ensureDraftInitialized();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<StateMeetings>().fetchMeetingsForBoard(widget.board);
      if (!mounted) return;
      if (widget.initialMeetingId == null && !widget.autoLoadFirstMeeting) {
        return;
      }
      final meetings = context.read<StateMeetings>().meetingsForBoard(
        widget.board.id,
      );
      if (meetings.isEmpty) return;
      if (widget.initialMeetingId != null) {
        _loadMeeting(
          meetings.firstWhere(
            (meeting) => meeting.id == widget.initialMeetingId,
            orElse: () => meetings.first,
          ),
        );
      } else {
        _loadMeeting(meetings.first);
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    _roleInputController.dispose();
    _editorScrollController.dispose();
    super.dispose();
  }

  void _ensureDraftInitialized() {
    if (_draftInitialized) return;
    _draftInitialized = true;
    _titleController.clear();
    _descriptionController.clear();
    _notesController.clear();
    _roleInputController.clear();
    _selectedMeeting = null;
    _startAt = DateTime.now().add(const Duration(hours: 1));
    _roleTags = List<String>.from(widget.initialRoleTags);
    _attachments = [];
    _activeTab = _MeetingDocTab.summary;
  }

  void _loadMeeting(MeetingModel meeting) {
    setState(() {
      _selectedMeeting = meeting;
      _titleController.text = meeting.title;
      _descriptionController.text = meeting.description;
      _notesController.text = meeting.notes;
      _startAt = meeting.startAt;
      _roleTags = List<String>.from(meeting.roleTags);
      _attachments = List<Map<String, String>>.from(meeting.attachments);
      _activeTab = _MeetingDocTab.summary;
    });
  }

  void _startNewMeeting() {
    setState(() {
      _selectedMeeting = null;
      _titleController.clear();
      _descriptionController.clear();
      _notesController.clear();
      _roleInputController.clear();
      _startAt = DateTime.now().add(const Duration(hours: 1));
      _roleTags = List<String>.from(widget.initialRoleTags);
      _attachments = [];
      _activeTab = _MeetingDocTab.summary;
    });
  }

  List<MeetingModel> _filteredMeetings(List<MeetingModel> meetings) {
    switch (_filter) {
      case MeetingFilter.upcoming:
        return meetings.where((meeting) => meeting.isUpcoming).toList();
      case MeetingFilter.past:
        return meetings.where((meeting) => meeting.isPast).toList();
      case MeetingFilter.all:
        return meetings;
    }
  }

  Future<void> _saveMeeting() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    setState(() => _isSaving = true);
    try {
      final base = MeetingModel(
        id:
            _selectedMeeting?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        boardId: widget.board.id,
        title: title,
        description: _descriptionController.text.trim(),
        notes: _notesController.text.trim(),
        startAt: _startAt,
        endAt: null,
        roleTags: _roleTags,
        attachments: _attachments,
        transcript: _selectedMeeting?.transcript ?? '',
        summary: _selectedMeeting?.summary ?? '',
        createdAt: _selectedMeeting?.createdAt,
      );
      if (_selectedMeeting == null) {
        await context.read<StateMeetings>().addMeeting(widget.board, base);
      } else {
        await context.read<StateMeetings>().updateMeeting(widget.board, base);
      }
      if (!mounted) return;
      await context.read<StateMeetings>().fetchMeetingsForBoard(
        widget.board,
        silent: true,
      );
      final all = context.read<StateMeetings>().meetingsForBoard(
        widget.board.id,
      );
      final saved = all.firstWhere(
        (meeting) => meeting.id == base.id,
        orElse: () => base,
      );
      _loadMeeting(saved);
      widget.onSaved?.call(saved);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteMeeting() async {
    final meeting = _selectedMeeting;
    if (meeting == null) return;
    await context.read<StateMeetings>().deleteMeeting(widget.board, meeting.id);
    if (!mounted) return;
    final meetings = context.read<StateMeetings>().meetingsForBoard(
      widget.board.id,
    );
    if (meetings.isNotEmpty) {
      _loadMeeting(meetings.first);
      return;
    }
    _startNewMeeting();
    widget.onBack?.call();
  }

  Future<void> _pickStartDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startAt,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startAt),
    );
    if (time == null) return;
    setState(() {
      _startAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _addRoleTag() {
    final value = _roleInputController.text.trim();
    if (value.isEmpty || _roleTags.contains(value)) return;
    setState(() {
      _roleTags = [..._roleTags, value];
      _roleInputController.clear();
    });
  }

  Future<void> _uploadAttachment() async {
    final result = await FilePicker.pickFiles(withData: true);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) return;
    setState(() => _isUploading = true);
    try {
      final uploadRes = await ApiCloudflare.uploadImage(
        Uint8List.fromList(bytes),
        file.name,
        path: 'meetings',
      );
      setState(() {
        _attachments = [
          ..._attachments,
          {
            'name': file.name,
            'url': uploadRes['url']?.toString() ?? '',
            'mime': file.extension ?? '',
          },
        ];
      });
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final shell = Container(
      width: widget.embeddedInPage
          ? double.infinity
          : (isDesktop ? 1220 : double.infinity),
      height: widget.embeddedInPage
          ? double.infinity
          : isDesktop
          ? MediaQuery.of(context).size.height * 0.88
          : MediaQuery.of(context).size.height * 0.92,
      decoration: widget.embeddedInPage
          ? null
          : GlassDecorations.solidSurface(radius: 20, hasShadow: true),
      child: Consumer<StateMeetings>(
        builder: (context, meetingsState, _) {
          final meetings = meetingsState.meetingsForBoard(widget.board.id);
          final filtered = _filteredMeetings(meetings);

          if (!widget.showListPane) {
            return _buildEditorPane();
          }

          return isDesktop
              ? Row(
                  children: [
                    SizedBox(width: 320, child: _buildListPane(filtered)),
                    Expanded(child: _buildEditorPane()),
                  ],
                )
              : Column(
                  children: [
                    SizedBox(height: 280, child: _buildListPane(filtered)),
                    Expanded(child: _buildEditorPane()),
                  ],
                );
        },
      ),
    );

    return widget.embeddedInPage
        ? shell
        : Material(color: Colors.transparent, child: shell);
  }

  Widget _buildListPane(List<MeetingModel> filtered) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: GlassColors.outlineVariant.withOpacity(0.12),
          ),
          bottom: BorderSide(
            color: GlassColors.outlineVariant.withOpacity(0.12),
          ),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Meetings',
                  style: GlassText.headlineLG().copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (!widget.embeddedInPage)
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            widget.board.name,
            style: GlassText.bodyMD().copyWith(
              color: GlassColors.onSurfaceVariant.withOpacity(0.58),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _filterChip(MeetingFilter.upcoming, 'Upcoming'),
              _filterChip(MeetingFilter.all, 'All'),
              _filterChip(MeetingFilter.past, 'Past'),
            ],
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _startNewMeeting,
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('New meeting'),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'No meetings in this view',
                      style: GlassText.bodyMD().copyWith(
                        color: GlassColors.onSurfaceVariant.withOpacity(0.45),
                      ),
                    ),
                  )
                : ScrollbarGutterFrame(
                    child: ListView.separated(
                      padding: ScrollbarGutter.reserveRight(EdgeInsets.zero),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => Divider(
                        color: GlassColors.outlineVariant.withOpacity(0.1),
                        height: 1,
                      ),
                      itemBuilder: (context, index) {
                        final meeting = filtered[index];
                        final isSelected = _selectedMeeting?.id == meeting.id;
                        return InkWell(
                          onTap: () => _loadMeeting(meeting),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    meeting.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GlassText.bodyMD().copyWith(
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  DateFormat('MMM d').format(meeting.startAt),
                                  style: GlassText.bodyMD().copyWith(
                                    color: GlassColors.onSurfaceVariant
                                        .withOpacity(0.58),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorPane() {
    final isMobile = Responsive.isMobile(context);
    final contentWidth = widget.embeddedInPage
        ? (isMobile ? double.infinity : 720.0)
        : double.infinity;
    final titleHint = widget.isCreateMode ? 'Untitled meeting' : 'Meeting';

    return Scrollbar(
      controller: _editorScrollController,
      thumbVisibility: true,
      child: ScrollbarGutterFrame(
        child: SingleChildScrollView(
          controller: _editorScrollController,
          padding: EdgeInsets.fromLTRB(
            isMobile ? 0 : 8,
            widget.embeddedInPage ? 0 : 20,
            0,
            32,
          ),
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: contentWidth,
              child: Padding(
                padding: const EdgeInsets.only(
                  right: ScrollbarGutter.reservedSpace,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.showTopMeta) ...[
                      _buildBreadcrumb(),
                      const SizedBox(height: 10),
                      _buildHistoryLine(),
                      const SizedBox(height: 18),
                    ],
                    _buildTopActions(),
                    const SizedBox(height: 18),
                    _buildTitleField(titleHint),
                    const SizedBox(height: 18),
                    _propertyRow(
                      icon: Icons.schedule_outlined,
                      label: 'Scheduled',
                      child: _linkButton(
                        DateFormat('MMM d, yyyy h:mm a').format(_startAt),
                        onTap: _pickStartDateTime,
                      ),
                    ),
                    _propertyRow(
                      icon: Icons.folder_open_outlined,
                      label: 'Project',
                      child: Text(
                        widget.board.name,
                        style: GlassText.bodyLG().copyWith(
                          color: GlassColors.onSurface.withOpacity(0.92),
                        ),
                      ),
                    ),
                    _propertyRow(
                      icon: Icons.groups_2_outlined,
                      label: 'Roles',
                      child: _buildRolesInline(),
                    ),
                    _propertyRow(
                      icon: Icons.access_time_rounded,
                      label: 'Created',
                      child: Text(
                        DateFormat(
                          'MMM d, yyyy h:mm a',
                        ).format(_selectedMeeting?.createdAt ?? DateTime.now()),
                        style: GlassText.bodyLG().copyWith(
                          color: GlassColors.onSurface.withOpacity(0.92),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Divider(
                      color: GlassColors.outlineVariant.withOpacity(0.12),
                    ),
                    const SizedBox(height: 20),
                    _buildTabBar(),
                    const SizedBox(height: 16),
                    _buildActiveTabContent(),
                    const SizedBox(height: 22),
                    _sectionTitle('Attachments'),
                    const SizedBox(height: 8),
                    _buildAttachments(),
                    const SizedBox(height: 22),
                    _sectionTitle('Meeting roles'),
                    const SizedBox(height: 12),
                    if (widget.suggestedRoleTags.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.suggestedRoleTags.map((tag) {
                          final selected = _roleTags.contains(tag);
                          return FilterChip(
                            label: Text(tag),
                            selected: selected,
                            onSelected: (_) {
                              setState(() {
                                if (selected) {
                                  _roleTags = _roleTags
                                      .where((item) => item != tag)
                                      .toList();
                                } else {
                                  _roleTags = [..._roleTags, tag];
                                }
                              });
                            },
                            showCheckmark: false,
                            backgroundColor: Colors.transparent,
                            selectedColor: GlassColors.primary.withOpacity(
                              0.08,
                            ),
                            side: BorderSide(
                              color: selected
                                  ? GlassColors.primary.withOpacity(0.18)
                                  : GlassColors.outlineVariant.withOpacity(
                                      0.12,
                                    ),
                            ),
                            labelStyle: GlassText.bodyMD().copyWith(
                              color: selected
                                  ? GlassColors.primary.withOpacity(0.9)
                                  : GlassColors.onSurfaceVariant.withOpacity(
                                      0.68,
                                    ),
                            ),
                          );
                        }).toList(),
                      ),
                    if (widget.suggestedRoleTags.isNotEmpty)
                      const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _softTextField(
                            controller: _roleInputController,
                            hint: 'Add a role tag',
                          ),
                        ),
                        const SizedBox(width: 10),
                        TextButton(
                          onPressed: _addRoleTag,
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_selectedMeeting != null)
                      TextButton.icon(
                        onPressed: _deleteMeeting,
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: GlassColors.error,
                          size: 16,
                        ),
                        label: const Text(
                          'Delete meeting',
                          style: TextStyle(color: GlassColors.error),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBreadcrumb() {
    final meetingTitle = _titleController.text.trim();
    final label = meetingTitle.isEmpty
        ? (widget.isCreateMode ? 'New meeting' : 'Meeting')
        : meetingTitle;

    return Row(
      children: [
        Icon(
          Icons.home_rounded,
          size: 12,
          color: GlassColors.onSurfaceVariant.withOpacity(0.32),
        ),
        const SizedBox(width: 6),
        Text(
          'Workspace HQ',
          style: GlassText.bodyMD().copyWith(
            fontSize: 12,
            color: GlassColors.onSurfaceVariant.withOpacity(0.52),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '/',
          style: GlassText.bodyMD().copyWith(
            fontSize: 12,
            color: GlassColors.onSurfaceVariant.withOpacity(0.24),
          ),
        ),
        const SizedBox(width: 8),
        Icon(
          Icons.calendar_today_rounded,
          size: 12,
          color: GlassColors.primary.withOpacity(0.7),
        ),
        const SizedBox(width: 6),
        Text(
          'Meetings',
          style: GlassText.bodyMD().copyWith(
            fontSize: 12,
            color: GlassColors.onSurfaceVariant.withOpacity(0.7),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '/',
          style: GlassText.bodyMD().copyWith(
            fontSize: 12,
            color: GlassColors.onSurfaceVariant.withOpacity(0.24),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GlassText.bodyMD().copyWith(
              fontSize: 12,
              color: GlassColors.onSurfaceVariant.withOpacity(0.52),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopActions() {
    return Row(
      children: [
        if (widget.onBack != null)
          _roundIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: widget.onBack!,
          ),
        if (widget.onBack != null) const SizedBox(width: 10),
        if (widget.onOpenBoard != null)
          TextButton.icon(
            onPressed: widget.onOpenBoard,
            icon: const Icon(Icons.open_in_new_rounded, size: 15),
            label: const Text('Open board'),
          ),
        const Spacer(),
        FilledButton(
          onPressed: _isSaving ? null : _saveMeeting,
          child: Text(_isSaving ? 'Saving...' : 'Save'),
        ),
      ],
    );
  }

  Widget _buildHistoryLine() {
    final label = _selectedMeeting != null && !widget.isCreateMode
        ? 'Edited ${DateFormat('MMM d').format(_selectedMeeting!.createdAt)}'
        : (widget.isCreateMode ? 'New draft' : 'Meeting detail');
    return Text(
      label,
      style: GlassText.bodyMD().copyWith(
        color: GlassColors.onSurfaceVariant.withOpacity(0.48),
      ),
    );
  }

  Widget _buildTitleField(String hint) {
    return ImeSafeTextField(
      controller: _titleController,
      maxLines: 2,
      style: GlassText.headlineLG().copyWith(
        fontSize: Responsive.isMobile(context) ? 34 : 42,
        fontWeight: FontWeight.w800,
        height: 1.05,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GlassText.headlineLG().copyWith(
          fontSize: Responsive.isMobile(context) ? 34 : 42,
          fontWeight: FontWeight.w800,
          color: GlassColors.onSurfaceVariant.withOpacity(0.22),
          height: 1.05,
        ),
        isDense: true,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _propertyRow({
    required IconData icon,
    required String label,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 170,
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: GlassColors.onSurfaceVariant.withOpacity(0.56),
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: GlassText.bodyLG().copyWith(
                    color: GlassColors.onSurfaceVariant.withOpacity(0.72),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildRolesInline() {
    if (_roleTags.isEmpty) {
      return Text(
        'Empty',
        style: GlassText.bodyLG().copyWith(
          color: GlassColors.onSurfaceVariant.withOpacity(0.5),
        ),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _roleTags.map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: GlassColors.outlineVariant.withOpacity(0.12),
            ),
          ),
          child: Text(
            tag,
            style: GlassText.bodyMD().copyWith(
              color: GlassColors.onSurface.withOpacity(0.88),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTabBar() {
    return Row(
      children: [
        _docTab(_MeetingDocTab.summary, 'Summary'),
        const SizedBox(width: 10),
        _docTab(_MeetingDocTab.notes, 'Notes'),
        const SizedBox(width: 10),
        _docTab(_MeetingDocTab.transcript, 'Transcript'),
      ],
    );
  }

  Widget _buildActiveTabContent() {
    switch (_activeTab) {
      case _MeetingDocTab.summary:
        return _softTextField(
          controller: _descriptionController,
          hint: 'Add the meeting purpose, agenda, or summary...',
          maxLines: 8,
        );
      case _MeetingDocTab.notes:
        return _softTextField(
          controller: _notesController,
          hint: 'Write meeting notes here...',
          maxLines: 10,
        );
      case _MeetingDocTab.transcript:
        final transcript = _selectedMeeting?.transcript.trim() ?? '';
        if (transcript.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: GlassColors.outlineVariant.withOpacity(0.12),
              ),
            ),
            child: Text(
              'No transcript yet',
              style: GlassText.bodyMD().copyWith(
                color: GlassColors.onSurfaceVariant.withOpacity(0.45),
              ),
            ),
          );
        }
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: GlassColors.outlineVariant.withOpacity(0.12),
            ),
          ),
          child: Text(
            transcript,
            style: GlassText.bodyMD().copyWith(height: 1.55),
          ),
        );
    }
  }

  Widget _buildAttachments() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GlassColors.outlineVariant.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TextButton.icon(
                onPressed: _isUploading ? null : _uploadAttachment,
                icon: _isUploading
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 1.5),
                      )
                    : const Icon(Icons.attach_file_rounded, size: 16),
                label: const Text('Upload'),
              ),
            ],
          ),
          if (_attachments.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'No attachments yet',
                style: GlassText.bodyMD().copyWith(
                  color: GlassColors.onSurfaceVariant.withOpacity(0.45),
                ),
              ),
            )
          else
            ..._attachments.map((attachment) {
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: InkWell(
                  onTap: () async {
                    final url = attachment['url'];
                    if (url == null || url.isEmpty) return;
                    await launchUrl(Uri.parse(url));
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white.withOpacity(0.03),
                        ),
                        child: const Icon(
                          Icons.insert_drive_file_outlined,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              attachment['name'] ?? 'Attachment',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GlassText.bodyMD().copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if ((attachment['mime'] ?? '').isNotEmpty)
                              Text(
                                attachment['mime'] ?? '',
                                style: GlassText.bodyMD().copyWith(
                                  color: GlassColors.onSurfaceVariant
                                      .withOpacity(0.48),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.open_in_new_rounded,
                        size: 16,
                        color: GlassColors.onSurfaceVariant.withOpacity(0.55),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GlassText.bodyLG().copyWith(
        fontWeight: FontWeight.w700,
        color: GlassColors.onSurface,
      ),
    );
  }

  Widget _docTab(_MeetingDocTab tab, String label) {
    final selected = _activeTab == tab;
    return InkWell(
      onTap: () => setState(() => _activeTab = tab),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? Colors.white.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? GlassColors.onSurface.withOpacity(0.08)
                : GlassColors.outlineVariant.withOpacity(0.12),
          ),
        ),
        child: Text(
          label,
          style: GlassText.bodyMD().copyWith(
            fontWeight: FontWeight.w600,
            color: selected
                ? GlassColors.onSurface
                : GlassColors.onSurfaceVariant.withOpacity(0.62),
          ),
        ),
      ),
    );
  }

  Widget _filterChip(MeetingFilter filter, String label) {
    final selected = _filter == filter;
    return InkWell(
      onTap: () => setState(() => _filter = filter),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.white.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? GlassColors.onSurface.withOpacity(0.08)
                : GlassColors.outlineVariant.withOpacity(0.12),
          ),
        ),
        child: Text(
          label,
          style: GlassText.labelSM().copyWith(
            color: selected
                ? GlassColors.onSurface
                : GlassColors.onSurfaceVariant.withOpacity(0.68),
          ),
        ),
      ),
    );
  }

  Widget _roundIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: GlassColors.outlineVariant.withOpacity(0.14),
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: GlassColors.onSurfaceVariant.withOpacity(0.72),
        ),
      ),
    );
  }

  Widget _linkButton(String label, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Text(
        label,
        style: GlassText.bodyLG().copyWith(
          color: GlassColors.onSurface.withOpacity(0.92),
          decoration: TextDecoration.underline,
          decorationColor: GlassColors.onSurfaceVariant.withOpacity(0.22),
        ),
      ),
    );
  }

  Widget _softTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return ImeSafeTextField(
      controller: controller,
      maxLines: maxLines,
      style: GlassText.bodyMD().copyWith(height: 1.55),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GlassText.bodyMD().copyWith(
          color: GlassColors.onSurfaceVariant.withOpacity(0.34),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}
