import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../databases/api_cloudflare.dart';
import '../../models/board_model.dart';
import '../../models/meeting_model.dart';
import '../../models/task_model.dart';
import '../../state_managers/state_meetings.dart';
import '../../state_managers/state_tasks.dart';
import '../common/ime_safe_text_field.dart';
import '../common/responsive_layout.dart';
import '../common/scroll_gutter.dart';
import '../common/glass_widgets.dart';
import 'package:my_ai_assistant/ui/common/defer_pointer.dart';
import '../theme/glass_theme.dart';
import 'widgets/markdown_block_editor.dart';
import '../../services/stt_stream_service.dart';
import '../../services/meeting_transcription_service.dart';
import '../../config/env_config.dart';
import '../../utils/web_download_stub.dart'
    if (dart.library.html) '../../utils/web_download_web.dart';

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
  late final SttStreamService _sttService;
  bool _includeMic = true;
  bool _includeSystem = false;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  final _roleInputController = TextEditingController();
  final _editorScrollController = ScrollController();
  ScrollPhysics? _editorScrollPhysics;

  MeetingModel? _selectedMeeting;
  MeetingFilter _filter = MeetingFilter.upcoming;
  _MeetingDocTab _activeTab = _MeetingDocTab.summary;
  DateTime _startAt = DateTime.now().add(const Duration(hours: 1));
  List<String> _roleTags = [];
  List<Map<String, String>> _attachments = [];
  bool _isSaving = false;
  bool _isUploading = false;
  bool _isTranscribing = false;
  bool _isSummarizing = false;
  String? _transcribeStatus; // 'Uploading...', 'Transcribing...', etc.
  bool _draftInitialized = false;
  final Set<String> _expandedTakeIds = {};
  // Attachment URLs currently being extracted to text (PDF/DOCX) in the
  // background, used to show inline spinners and guard duplicate runs.
  final Set<String> _extractingAttachments = {};

  Timer? _autoSaveTimer;
  bool _isAutoSaving = false;
  String? _autoSaveStatus; // 'Saving...', 'Saved', or null
  bool _isSuppressingAutoSave = false;

  void _onTitleChanged() {
    _scheduleAutoSave();
  }

  void _onSttServiceChanged() {
    if (!mounted) return;
    if (_sttService.isRecording) {
      if (_selectedMeeting != null) {
        final newTranscript = _sttService.getJsonTranscript();
        setState(() {
          _selectedMeeting = _selectedMeeting!.copyWith(
            transcript: newTranscript,
          );
        });
        _scheduleAutoSave();
      }
    }
    setState(() {});
  }

  void _scheduleAutoSave() {
    if (_isSuppressingAutoSave) return;
    _autoSaveTimer?.cancel();
    // Only rebuild the (heavy) sheet when the status actually changes.
    // During a continuous typing burst the status is already 'Saving...',
    // so we skip setState entirely — keeping typing smooth on large docs.
    if (_autoSaveStatus != 'Saving...') {
      setState(() {
        _autoSaveStatus = 'Saving...';
      });
    }
    _autoSaveTimer = Timer(const Duration(milliseconds: 1500), () {
      _performAutoSave();
    });
  }

  Future<void> _performAutoSave() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() {
        _autoSaveStatus = null;
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      _isAutoSaving = true;
      _autoSaveStatus = 'Saving...';
    });
    try {
      final base = MeetingModel(
        id: _selectedMeeting?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
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

      setState(() {
        _selectedMeeting = saved;
        _autoSaveStatus = 'Saved';
      });

      widget.onSaved?.call(saved);

      Timer(const Duration(seconds: 3), () {
        if (mounted && _autoSaveStatus == 'Saved') {
          setState(() {
            _autoSaveStatus = null;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _autoSaveStatus = 'Error saving';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAutoSaving = false;
        });
      }
    }
  }

  Widget _buildAutoSaveStatusIndicator() {
    if (_autoSaveStatus == null) return const SizedBox.shrink();

    IconData icon;
    Color color;
    String text;
    bool animate = false;

    if (_autoSaveStatus == 'Saving...') {
      icon = Icons.sync_rounded;
      color = GlassColors.primary.withOpacity(0.8);
      text = 'Saving...';
      animate = true;
    } else if (_autoSaveStatus == 'Saved') {
      icon = Icons.cloud_done_rounded;
      color = Colors.greenAccent.withOpacity(0.8);
      text = 'Saved';
    } else {
      icon = Icons.error_outline_rounded;
      color = GlassColors.error.withOpacity(0.8);
      text = 'Error';
    }

    Widget iconWidget = animate
        ? SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          )
        : Icon(icon, size: 14, color: color);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withOpacity(0.12),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          iconWidget,
          const SizedBox(width: 6),
          Text(
            text,
            style: GlassText.bodyMD().copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _sttService = SttStreamService();
    _sttService.addListener(_onSttServiceChanged);
    _titleController.addListener(_onTitleChanged);
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
    _sttService.removeListener(_onSttServiceChanged);
    _sttService.stopSession();
    _sttService.dispose();
    _titleController.removeListener(_onTitleChanged);
    _autoSaveTimer?.cancel();
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
    _isSuppressingAutoSave = true;
    _titleController.clear();
    _descriptionController.clear();
    _notesController.clear();
    _roleInputController.clear();
    _selectedMeeting = null;
    _startAt = DateTime.now().add(const Duration(hours: 1));
    _roleTags = List<String>.from(widget.initialRoleTags);
    _attachments = [];
    _activeTab = _MeetingDocTab.summary;
    _isSuppressingAutoSave = false;
  }

  void _loadMeeting(MeetingModel meeting) {
    _isSuppressingAutoSave = true;
    setState(() {
      _selectedMeeting = meeting;
      _titleController.text = meeting.title;
      _descriptionController.text = meeting.description;
      _notesController.text = meeting.notes;
      _startAt = meeting.startAt;
      _roleTags = List<String>.from(meeting.roleTags);
      _attachments = List<Map<String, String>>.from(meeting.attachments);
      _activeTab = _MeetingDocTab.summary;
      _autoSaveStatus = null;
    });
    _sttService.loadExistingTranscript(meeting.transcript);
    _isSuppressingAutoSave = false;
    _scheduleLegacyExtraction();
  }

  void _startNewMeeting() {
    _isSuppressingAutoSave = true;
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
      _autoSaveStatus = null;
    });
    _sttService.clearSession();
    _isSuppressingAutoSave = false;
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
    _autoSaveTimer?.cancel();
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    setState(() {
      _isSaving = true;
      _autoSaveStatus = 'Saving...';
    });
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
      setState(() {
        _autoSaveStatus = 'Saved';
      });
      Timer(const Duration(seconds: 3), () {
        if (mounted && _autoSaveStatus == 'Saved') {
          setState(() {
            _autoSaveStatus = null;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _autoSaveStatus = 'Error saving';
        });
      }
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
    _scheduleAutoSave();
  }

  void _addRoleTag() {
    final value = _roleInputController.text.trim();
    if (value.isEmpty || _roleTags.contains(value)) return;
    setState(() {
      _roleTags = [..._roleTags, value];
      _roleInputController.clear();
    });
    _scheduleAutoSave();
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
      final newAttachment = {
        'name': file.name,
        'url': uploadRes['url']?.toString() ?? '',
        'mime': file.extension ?? '',
      };
      setState(() {
        _attachments = [..._attachments, newAttachment];
      });
      _scheduleAutoSave();
      // Fire-and-forget: extract PDF/DOCX text in the background (cached
      // once) so the summarizer finds it pre-extracted. UI is not blocked.
      _extractAttachmentInBackground(newAttachment);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  bool _isExtractableFile(Map<String, String> att) {
    final name = (att['name'] ?? '').toLowerCase();
    final url = (att['url'] ?? '').toLowerCase();
    final mime = (att['mime'] ?? att['mimeType'] ?? '').toLowerCase();
    return name.endsWith('.pdf') ||
        name.endsWith('.docx') ||
        url.endsWith('.pdf') ||
        url.endsWith('.docx') ||
        mime.contains('pdf') ||
        mime.contains('wordprocessingml');
  }

  Future<void> _extractAttachmentInBackground(Map<String, String> att) async {
    if ((att['extractedText'] ?? '').isNotEmpty) return;
    if (att['type'] == 'recording') return; // never touch recording takes
    if (!_isExtractableFile(att)) return;
    final url = att['url'] ?? '';
    if (url.isEmpty) return;
    if (_extractingAttachments.contains(url)) return; // guard duplicate runs
    if (!mounted) return;
    setState(() => _extractingAttachments.add(url));
    try {
      debugPrint('[UI][Extract] Reading ${att['name']}...');
      final t = await ApiCloudflare.extractAttachmentText(
        Map<String, dynamic>.from(att),
      );
      if (t.isNotEmpty) att['extractedText'] = t;
    } catch (e) {
      debugPrint('[UI][Extract][Error] ${att['name']}: $e');
    } finally {
      if (mounted) {
        setState(() => _extractingAttachments.remove(url));
        _scheduleAutoSave();
      } else {
        _extractingAttachments.remove(url);
      }
    }
  }

  // Lazily extract any PDF/DOCX file attachments (NON-recording) that don't
  // yet have cached text (legacy files). Guarded against duplicate runs.
  void _scheduleLegacyExtraction() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (final att in List<Map<String, String>>.from(_attachments)) {
        if (att['type'] == 'recording') continue;
        if ((att['extractedText'] ?? '').isNotEmpty) continue;
        if (!_isExtractableFile(att)) continue;
        _extractAttachmentInBackground(att);
      }
    });
  }

  void _deleteAttachment(Map<String, String> att) {
    final url = att['url'];
    final name = att['name'];
    setState(() {
      _attachments = _attachments
          .where((a) => !(a['url'] == url && a['name'] == name))
          .toList();
    });
    _scheduleAutoSave();
  }

  void _showExtractedTextDialog(Map<String, String> att) {
    showDialog(
      context: context,
      builder: (ctx) {
        final url = att['url'] ?? '';
        final extracting = _extractingAttachments.contains(url);
        final text = (att['extractedText'] ?? '').toString();

        Widget body;
        if (extracting) {
          body = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Text('กำลังแกะข้อความ...', style: GlassText.bodyMD()),
            ],
          );
        } else if (text.isEmpty) {
          body = Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ยังไม่มีข้อความที่แกะได้',
                style: GlassText.bodyMD().copyWith(
                  color: GlassColors.onSurfaceVariant.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _extractAttachmentInBackground(att);
                },
                icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                label: const Text('แกะเนื้อหาตอนนี้'),
              ),
            ],
          );
        } else {
          body = SelectableText(text, style: GlassText.bodyMD());
        }

        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(ctx).size.width < 600
                ? MediaQuery.of(ctx).size.width - 48
                : 560,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.7,
            ),
            padding: const EdgeInsets.all(20),
            decoration: GlassDecorations.solidSurface(
              radius: 16,
              hasShadow: true,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.article_outlined,
                      size: 18,
                      color: GlassColors.primary.withOpacity(0.85),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'เนื้อหาที่แกะได้',
                        style: GlassText.bodyMD().copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                Text(
                  att['name'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GlassText.bodyMD().copyWith(
                    color: GlassColors.onSurfaceVariant.withOpacity(0.55),
                  ),
                ),
                const SizedBox(height: 14),
                Flexible(child: SingleChildScrollView(child: body)),
              ],
            ),
          ),
        );
      },
    );
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

    return DeferredPointerHandler(
      child: Scrollbar(
        controller: _editorScrollController,
        thumbVisibility: true,
        child: ScrollbarGutterFrame(
          child: SingleChildScrollView(
            controller: _editorScrollController,
            physics: _editorScrollPhysics,
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
                      const SizedBox(height: 20),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(ExecutiveRadius.l),
                          border: Border.all(
                            color: GlassColors.ghostBorder,
                            width: 1.0,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 20,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.description_outlined,
                                  size: 16,
                                  color: GlassColors.onSurfaceVariant.withOpacity(0.85),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Meeting Workspace',
                                  style: GlassText.bodyMD().copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: GlassColors.onSurface.withOpacity(0.95),
                                  ),
                                ),
                                const Spacer(),
                                _buildExportMdButton(),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Divider(
                              color: GlassColors.outlineVariant.withOpacity(0.12),
                              height: 1,
                              thickness: 1,
                            ),
                            const SizedBox(height: 12),
                            _buildTabBar(),
                            const SizedBox(height: 16),
                            _buildActiveTabContent(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      _sectionTitle('Attachments'),
                      const SizedBox(height: 8),
                      _buildAttachments(),
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
        if (_autoSaveStatus != null) ...[
          _buildAutoSaveStatusIndicator(),
          const SizedBox(width: 12),
        ],
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
      maxLines: null,
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
        filled: false,
        fillColor: Colors.transparent,
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
    final hasRoles = _roleTags.isNotEmpty;

    if (!hasRoles) {
      return InkWell(
        onTap: _showRolesEditorDialog,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add roles...',
                style: GlassText.bodyLG().copyWith(
                  color: GlassColors.onSurfaceVariant.withOpacity(0.35),
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.add_circle_outline_rounded,
                size: 16,
                color: GlassColors.onSurfaceVariant.withOpacity(0.4),
              ),
            ],
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ..._roleTags.map((tag) {
          return Container(
            padding: const EdgeInsets.only(left: 10, right: 6, top: 4, bottom: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: GlassColors.outlineVariant.withOpacity(0.12),
              ),
              color: Colors.white.withOpacity(0.02),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tag,
                  style: GlassText.bodyMD().copyWith(
                    color: GlassColors.onSurface.withOpacity(0.88),
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _roleTags = _roleTags.where((item) => item != tag).toList();
                    });
                    _scheduleAutoSave();
                  },
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: Icon(
                        Icons.close_rounded,
                        size: 14,
                        color: GlassColors.onSurfaceVariant.withOpacity(0.6),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        GestureDetector(
          onTap: _showRolesEditorDialog,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: GlassColors.primary.withOpacity(0.35),
                ),
                color: GlassColors.primary.withOpacity(0.08),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add_rounded,
                    size: 14,
                    color: GlassColors.primary.withOpacity(0.9),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    'Add',
                    style: GlassText.bodyMD().copyWith(
                      color: GlassColors.primary.withOpacity(0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showRolesEditorDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: GlassContainer(
                isDark: true,
                radius: 16,
                padding: const EdgeInsets.all(20),
                decoration: GlassDecorations.solidSurface(
                  radius: 16,
                  hasShadow: true,
                ),
                child: SizedBox(
                  width: 380,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Edit Roles'.toUpperCase(),
                            style: GlassText.label(true).copyWith(fontSize: 14),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            color: GlassColors.onSurfaceVariant.withOpacity(0.6),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (widget.suggestedRoleTags.isNotEmpty) ...[
                        Text(
                          'Suggested Roles',
                          style: GlassText.bodyMD().copyWith(
                            color: GlassColors.onSurfaceVariant.withOpacity(0.5),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
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
                                _scheduleAutoSave();
                                setDialogState(() {});
                              },
                              showCheckmark: false,
                              backgroundColor: Colors.transparent,
                              selectedColor: GlassColors.primary.withOpacity(0.08),
                              side: BorderSide(
                                color: selected
                                    ? GlassColors.primary.withOpacity(0.18)
                                    : GlassColors.outlineVariant.withOpacity(0.12),
                              ),
                              labelStyle: GlassText.bodyMD().copyWith(
                                color: selected
                                    ? GlassColors.primary.withOpacity(0.9)
                                    : GlassColors.onSurfaceVariant.withOpacity(0.68),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Text(
                        'Custom Role',
                        style: GlassText.bodyMD().copyWith(
                          color: GlassColors.onSurfaceVariant.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: GlassColors.outlineVariant.withOpacity(0.12),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _roleInputController,
                                style: GlassText.bodyMD().copyWith(
                                  color: GlassColors.onSurface,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Add a role tag',
                                  hintStyle: GlassText.bodyMD().copyWith(
                                    color: GlassColors.onSurfaceVariant.withOpacity(0.3),
                                  ),
                                  filled: false,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                 onSubmitted: (_) {
                                  final newTag = _roleInputController.text.trim();
                                  if (newTag.isNotEmpty && !_roleTags.contains(newTag)) {
                                    setState(() {
                                      _roleTags = [..._roleTags, newTag];
                                    });
                                    _scheduleAutoSave();
                                    _roleInputController.clear();
                                    setDialogState(() {});
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () {
                                final newTag = _roleInputController.text.trim();
                                if (newTag.isNotEmpty && !_roleTags.contains(newTag)) {
                                  setState(() {
                                    _roleTags = [..._roleTags, newTag];
                                  });
                                  _scheduleAutoSave();
                                  _roleInputController.clear();
                                  setDialogState(() {});
                                }
                              },
                              child: const Text('Add'),
                            ),
                            const SizedBox(width: 4),
                          ],
                        ),
                      ),
                      // Selected roles are managed directly in the inline view above
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.only(left: 0),
      child: Row(
        children: [
          _docTab(_MeetingDocTab.summary, 'Summary'),
          const SizedBox(width: 10),
          _docTab(_MeetingDocTab.notes, 'Notes'),
          const SizedBox(width: 10),
          _docTab(_MeetingDocTab.transcript, 'Transcript'),
        ],
      ),
    );
  }

  Widget _buildActiveTabContent() {
    switch (_activeTab) {
      case _MeetingDocTab.summary:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSummaryAiControls(),
            const SizedBox(height: 12),
            MarkdownBlockEditor(
              initialMarkdown: _descriptionController.text,
              onChanged: (val) {
                _descriptionController.text = val;
                _scheduleAutoSave();
              },
              onDragStateChanged: (isDragging) {
                setState(() {
                  _editorScrollPhysics = isDragging
                      ? const NeverScrollableScrollPhysics()
                      : null;
                });
              },
            ),
          ],
        );
      case _MeetingDocTab.notes:
        return MarkdownBlockEditor(
          initialMarkdown: _notesController.text,
          onChanged: (val) {
            _notesController.text = val;
            _scheduleAutoSave();
          },
          onDragStateChanged: (isDragging) {
            setState(() {
              _editorScrollPhysics = isDragging
                  ? const NeverScrollableScrollPhysics()
                  : null;
            });
          },
        );
      case _MeetingDocTab.transcript:
        return Padding(
          padding: const EdgeInsets.only(left: 4, right: 4),
          child: _buildTranscriptPane(),
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
          if (_attachments.where((a) => a['type'] != 'recording').isEmpty)
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
            ..._attachments.where((a) => a['type'] != 'recording').map((attachment) {
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
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_extractingAttachments.contains(
                            attachment['url'],
                          ))
                            const Padding(
                              padding: EdgeInsets.only(right: 4),
                              child: SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                ),
                              ),
                            ),
                          if (_isExtractableFile(attachment))
                            IconButton(
                              tooltip: 'ดูเนื้อหาที่แกะได้',
                              icon: const Icon(Icons.article_outlined, size: 16),
                              color: GlassColors.onSurfaceVariant.withOpacity(
                                0.7,
                              ),
                              visualDensity: VisualDensity.compact,
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(6),
                              onPressed: () =>
                                  _showExtractedTextDialog(attachment),
                            ),
                          IconButton(
                            tooltip: 'เปิดไฟล์',
                            icon: const Icon(
                              Icons.open_in_new_rounded,
                              size: 16,
                            ),
                            color: GlassColors.onSurfaceVariant.withOpacity(
                              0.55,
                            ),
                            visualDensity: VisualDensity.compact,
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(6),
                            onPressed: () async {
                              final url = attachment['url'];
                              if (url == null || url.isEmpty) return;
                              await launchUrl(Uri.parse(url));
                            },
                          ),
                          IconButton(
                            tooltip: 'ลบไฟล์แนบ',
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 16,
                            ),
                            color: GlassColors.error.withOpacity(0.8),
                            visualDensity: VisualDensity.compact,
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(6),
                            onPressed: () => _deleteAttachment(attachment),
                          ),
                        ],
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

  Widget _buildTranscriptPane() {
    if (_selectedMeeting == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: GlassColors.surface.withOpacity(0.05),
            border: Border.all(
              color: GlassColors.outlineVariant.withOpacity(0.12),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: GlassColors.onSurfaceVariant.withOpacity(0.4),
                size: 28,
              ),
              const SizedBox(height: 12),
              Text(
                'Please name and save this meeting first to enable live transcription.',
                textAlign: TextAlign.center,
                style: GlassText.bodyMD().copyWith(
                  color: GlassColors.onSurfaceVariant.withOpacity(0.65),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final utterances = _sttService.utterances;
    final interim = _sttService.interimUtterance;
    final isRecording = _sttService.isRecording;
    final errorMsg = _sttService.errorMessage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSttControls(),
        _buildRecordingTakesList(),
        if (errorMsg != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    errorMsg,
                    style: GlassText.secondary().copyWith(color: Colors.redAccent),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (utterances.isEmpty && interim == null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: GlassColors.outlineVariant.withOpacity(0.12),
              ),
            ),
            child: Text(
              'No transcript yet. Press "Start Live Transcription" to begin recording.',
              style: GlassText.bodyMD().copyWith(
                color: GlassColors.onSurfaceVariant.withOpacity(0.45),
              ),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: GlassColors.surface.withOpacity(0.03),
              border: Border.all(
                color: GlassColors.outlineVariant.withOpacity(0.12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...utterances.map((u) => _buildUtteranceBlock(u, false)),
                if (interim != null) _buildUtteranceBlock(interim, true),
              ],
            ),
          ),
      ],
    );
  }

  void _showClearTranscriptConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Center(
        child: Container(
          width: 380,
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: GlassDecorations.solidSurface(
            radius: 20,
            hasShadow: true,
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CLEAR TRANSCRIPT',
                  style: GlassText.labelSM().copyWith(
                    color: GlassColors.error,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'คุณต้องการล้างข้อมูลทรานสคริปต์สดทั้งหมดหรือไม่? การดำเนินการนี้ไม่สามารถย้อนกลับได้',
                  style: GlassText.bodyMD().copyWith(
                    color: GlassColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: GlassColors.ghostBorder),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'ยกเลิก',
                          style: GlassText.labelSM().copyWith(
                            color: GlassColors.onSurfaceVariant.withOpacity(0.6),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _sttService.clearSession();
                          if (_selectedMeeting != null) {
                            setState(() {
                              _selectedMeeting = _selectedMeeting!.copyWith(
                                transcript: '',
                              );
                            });
                            _scheduleAutoSave();
                          }
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(
                            color: GlassColors.error,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'ล้างข้อมูล',
                          style: GlassText.labelSM().copyWith(
                            color: GlassColors.error,
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

  Widget _buildSttControls() {
    final isRecording = _sttService.isRecording;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: GlassColors.surface.withOpacity(0.05),
        border: Border.all(
          color: GlassColors.outlineVariant.withOpacity(0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
          if (!isRecording) ...[
            _buildSourceToggle(
              label: 'Microphone',
              icon: Icons.mic,
              value: _includeMic,
              onChanged: (val) {
                setState(() => _includeMic = val);
              },
            ),
            const SizedBox(width: 12),
            _buildSourceToggle(
              label: 'System Audio',
              icon: Icons.screen_share,
              value: _includeSystem,
              onChanged: (val) {
                setState(() => _includeSystem = val);
              },
            ),
          ] else ...[
            const _PulsingRecordDot(),
            const SizedBox(width: 8),
            Text(
              'Recording live...',
              style: GlassText.bodyMD().copyWith(
                color: GlassColors.gold,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const Spacer(),
          if (!isRecording && _sttService.utterances.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
              tooltip: 'ล้างทรานสคริปต์หลัก',
              onPressed: () => _showClearTranscriptConfirmDialog(context),
            ),
            const SizedBox(width: 8),
          ],
          if (!isRecording)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: GlassColors.gold,
                foregroundColor: Colors.black,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              icon: const Icon(Icons.play_arrow_rounded, size: 20),
              label: Text(
                'Start Live Transcription',
                style: GlassText.bodyMD().copyWith(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                _sttService.startSession(
                  backendBaseUrl: EnvConfig.backendUrl,
                  includeMic: _includeMic,
                  includeSystem: _includeSystem,
                );
              },
            )
          else
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent.withOpacity(0.8),
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              icon: const Icon(Icons.stop_rounded, size: 20),
              label: Text(
                'Stop Transcription',
                style: GlassText.bodyMD().copyWith(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                _sttService.stopSession();
                _saveMeeting();
              },
            ),
          ],
          ),
          if (!isRecording) _buildUploadTranscribeSection(),
        ],
      ),
    );
  }

  Widget _buildUploadTranscribeSection() {
    final busy = _isTranscribing;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: GlassColors.gold,
              side: BorderSide(color: GlassColors.gold.withOpacity(0.5)),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
            ),
            icon: busy
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.6,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        GlassColors.gold,
                      ),
                    ),
                  )
                : const Icon(Icons.upload_file_rounded, size: 18),
            label: Text(
              busy
                  ? (_transcribeStatus ?? 'Processing...')
                  : 'Upload audio/video',
              style: GlassText.bodyMD().copyWith(fontWeight: FontWeight.w600),
            ),
            onPressed: busy ? null : _handleUploadTranscribe,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Transcribe an existing recording into this meeting.',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GlassText.secondary().copyWith(
                color: GlassColors.onSurfaceVariant.withOpacity(0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleUploadTranscribe() async {
    if (_sttService.isRecording || _isTranscribing) return;
    if (_selectedMeeting == null) {
      GlassNotifications.show(
        context,
        'Please save the meeting before transcribing a file.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isTranscribing = true;
      _transcribeStatus = 'Preparing...';
    });

    try {
      final result = await MeetingTranscriptionService.pickAndTranscribe(
        meetingId: _selectedMeeting!.id,
        onProgress: (stage, {message}) {
          if (!mounted) return;
          setState(() => _transcribeStatus = message ?? _stageLabel(stage));
        },
      );

      if (!mounted) return;

      // User cancelled the file picker.
      if (result == null) return;

      if (result.takeMap != null) {
        setState(() {
          _attachments = [
            ..._attachments,
            result.takeMap!,
          ];
          _activeTab = _MeetingDocTab.transcript;
        });
        _scheduleAutoSave();
      }
    } catch (e) {
      debugPrint('[UI] Upload transcription failed: $e');
      if (mounted) {
        GlassNotifications.show(
          context,
          'Transcription failed: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTranscribing = false;
          _transcribeStatus = null;
        });
      }
    }
  }

  String _stageLabel(MeetingTranscriptionStage stage) {
    switch (stage) {
      case MeetingTranscriptionStage.picking:
        return 'เลือกไฟล์เสียง...';
      case MeetingTranscriptionStage.uploading:
        return 'อัปโหลดเสียง...';
      case MeetingTranscriptionStage.transcribing:
        return 'กำลังถอดความ...';
      case MeetingTranscriptionStage.ingesting:
        return 'กำลังบันทึกข้อมูล...';
      case MeetingTranscriptionStage.done:
        return 'เสร็จสิ้น';
      case MeetingTranscriptionStage.cancelled:
        return 'ยกเลิก';
      case MeetingTranscriptionStage.error:
        return 'เกิดข้อผิดพลาด';
    }
  }

  Widget _buildRecordingTakesList() {
    final recordingTakes = _attachments.where((a) => a['type'] == 'recording').toList();
    if (recordingTakes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'ไฟล์บันทึกเสียง (${recordingTakes.length})',
          style: GlassText.bodyMD().copyWith(
            fontWeight: FontWeight.w700,
            color: GlassColors.onSurface.withOpacity(0.85),
          ),
        ),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recordingTakes.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final take = recordingTakes[index];
            final takeId = take['id'] ?? '';
            final isExpanded = _expandedTakeIds.contains(takeId);
            
            List<SpeakerUtterance> utterances = [];
            if (isExpanded && take['transcript'] != null) {
              try {
                final List<dynamic> parsed = jsonDecode(take['transcript']!);
                for (final item in parsed) {
                  if (item is Map) {
                    utterances.add(SpeakerUtterance.fromJson(Map<String, dynamic>.from(item)));
                  }
                }
              } catch (_) {}
            }

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: GlassColors.surface.withOpacity(0.04),
                border: Border.all(
                  color: GlassColors.outlineVariant.withOpacity(0.08),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.audiotrack_rounded,
                        color: GlassColors.primary.withOpacity(0.8),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          take['name'] ?? 'Recording Take',
                          style: GlassText.bodyMD().copyWith(
                            fontWeight: FontWeight.w500,
                            color: GlassColors.onSurface.withOpacity(0.9),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (take['url'] != null && take['url']!.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.play_arrow_rounded, size: 20),
                          tooltip: 'เล่นเสียง',
                          onPressed: () async {
                            final uri = Uri.parse(take['url']!);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            } else {
                              GlassNotifications.show(
                                context,
                                'ไม่สามารถเปิดลิงก์ไฟล์เสียงได้',
                                isError: true,
                              );
                            }
                          },
                        ),
                      IconButton(
                        icon: Icon(
                          isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                          size: 20,
                        ),
                        tooltip: 'ดูทรานสคริปต์',
                        onPressed: () {
                          setState(() {
                            if (takeId.isNotEmpty) {
                              if (_expandedTakeIds.contains(takeId)) {
                                _expandedTakeIds.remove(takeId);
                              } else {
                                _expandedTakeIds.add(takeId);
                              }
                            }
                          });
                        },
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded, size: 20),
                        onSelected: (action) async {
                          if (action == 'create_task') {
                            final buffer = StringBuffer();
                            try {
                              final List<dynamic> parsed = jsonDecode(take['transcript'] ?? '[]');
                              for (final item in parsed) {
                                if (item is Map) {
                                  final u = SpeakerUtterance.fromJson(Map<String, dynamic>.from(item));
                                  buffer.writeln('**Speaker ${u.speaker}:** ${u.text} _(${u.timestamp.toLocal().toString().substring(11, 19)})_');
                                  buffer.writeln();
                                }
                              }
                            } catch (e) {
                              buffer.writeln('Error parsing transcript: $e');
                            }
                            final transcriptText = buffer.toString();
                            
                            final newTask = TaskModel(
                              id: const Uuid().v4(),
                              boardId: widget.board.id,
                              title: 'บันทึกเสียง: ${take['name']}',
                              description: transcriptText,
                              dueDate: DateTime.now().add(const Duration(days: 7)),
                              type: widget.board.type,
                              status: widget.board.columns.firstOrNull ?? 'todo',
                            );
                            await Provider.of<StateTasks>(context, listen: false).addTask(widget.board, newTask);
                            GlassNotifications.show(context, 'สร้างงานใหม่เรียบร้อยแล้ว');
                          } else if (action == 'append_notes') {
                            final buffer = StringBuffer();
                            try {
                              final List<dynamic> parsed = jsonDecode(take['transcript'] ?? '[]');
                              for (final item in parsed) {
                                if (item is Map) {
                                  final u = SpeakerUtterance.fromJson(Map<String, dynamic>.from(item));
                                  buffer.writeln('**Speaker ${u.speaker}:** ${u.text} _(${u.timestamp.toLocal().toString().substring(11, 19)})_');
                                  buffer.writeln();
                                }
                              }
                            } catch (e) {
                              buffer.writeln('Error parsing transcript: $e');
                            }
                            final transcriptText = buffer.toString();

                            _notesController.text = '${_notesController.text}\n\n### Transcript: ${take['name']}\n$transcriptText';
                            _scheduleAutoSave();
                            GlassNotifications.show(context, 'บันทึกความคืบหน้าเข้าบันทึกประชุมแล้ว');
                          } else if (action == 'clear_take_transcript') {
                            setState(() {
                              take['transcript'] = '[]';
                              if (takeId.isNotEmpty) {
                                _expandedTakeIds.remove(takeId);
                              }
                            });
                            _scheduleAutoSave();
                            GlassNotifications.show(context, 'ล้างข้อมูลทรานสคริปต์ของ Take นี้สำเร็จ');
                          } else if (action == 'delete') {
                            setState(() {
                              _attachments.removeWhere((a) => a['id'] == take['id']);
                            });
                            _scheduleAutoSave();
                            GlassNotifications.show(context, 'ลบไฟล์อัดเสียงสำเร็จ');
                          }
                        },
                        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'create_task',
                            child: Row(
                              children: [
                                Icon(Icons.add_task_rounded, size: 18),
                                SizedBox(width: 8),
                                Text('สร้างบันทึก/งานใหม่'),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'append_notes',
                            child: Row(
                              children: [
                                Icon(Icons.note_add_rounded, size: 18),
                                SizedBox(width: 8),
                                Text('เขียนลงบันทึกประชุม (Append)'),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'clear_take_transcript',
                            child: Row(
                              children: [
                                Icon(Icons.clear_all_rounded, size: 18),
                                SizedBox(width: 8),
                                Text('ล้างทรานสคริปต์ของ Take นี้'),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                                SizedBox(width: 8),
                                Text('ลบไฟล์อัดเสียงนี้', style: TextStyle(color: Colors.redAccent)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (isExpanded) ...[
                    const Divider(height: 16, color: Colors.white10),
                    if (utterances.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'ไม่มีข้อมูลทรานสคริปต์',
                          style: GlassText.secondary().copyWith(
                            color: GlassColors.onSurfaceVariant.withOpacity(0.5),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: utterances.map((u) => _buildUtteranceBlock(u, false)).toList(),
                        ),
                      ),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSourceToggle({
    required String label,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: value ? GlassColors.gold.withOpacity(0.15) : Colors.transparent,
          border: Border.all(
            color: value ? GlassColors.gold.withOpacity(0.5) : GlassColors.outlineVariant.withOpacity(0.12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: value ? GlassColors.gold : GlassColors.onSurfaceVariant.withOpacity(0.6),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GlassText.secondary().copyWith(
                color: value ? GlassColors.gold : GlassColors.onSurfaceVariant,
                fontWeight: value ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUtteranceBlock(SpeakerUtterance utterance, bool isInterim) {
    final colors = [
      GlassColors.gold,
      Colors.purpleAccent,
      Colors.tealAccent,
      Colors.lightBlueAccent,
      Colors.orangeAccent,
      Colors.pinkAccent,
    ];

    final speakerColor = colors[utterance.speaker % colors.length];

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: speakerColor.withOpacity(0.12),
                  border: Border.all(
                    color: speakerColor.withOpacity(0.4),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  'Speaker ${utterance.speaker}',
                  style: GlassText.labelSM().copyWith(
                    color: speakerColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (isInterim)
                Text(
                  'typing...',
                  style: GlassText.secondary().copyWith(
                    color: GlassColors.onSurfaceVariant.withOpacity(0.35),
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              utterance.text,
              style: GlassText.bodyMD().copyWith(
                color: isInterim ? GlassColors.onSurfaceVariant.withOpacity(0.5) : GlassColors.onSurface,
                fontStyle: isInterim ? FontStyle.italic : null,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportMdButton() {
    return Tooltip(
      message: 'ส่งออก / คัดลอกเป็นไฟล์ .md',
      child: TextButton.icon(
        style: TextButton.styleFrom(
          foregroundColor: GlassColors.onSurfaceVariant,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: const Icon(Icons.download_rounded, size: 16),
        label: Text(
          'Export .md',
          style: GlassText.secondary().copyWith(fontWeight: FontWeight.w600),
        ),
        onPressed: _exportMarkdown,
      ),
    );
  }

  String _buildMarkdownDocument() {
    final title = _titleController.text.trim();
    final summary = _descriptionController.text.trim();
    final notes = _notesController.text.trim();
    final buffer = StringBuffer();
    buffer.writeln('# ${title.isEmpty ? 'Untitled' : title}');
    if (summary.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('## Summary');
      buffer.writeln();
      buffer.writeln(summary);
    }
    if (notes.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('## Notes');
      buffer.writeln();
      buffer.writeln(notes);
    }
    return buffer.toString().trim();
  }

  Future<void> _exportMarkdown() async {
    final content = _buildMarkdownDocument();
    if (content.isEmpty) {
      GlassNotifications.show(context, 'ยังไม่มีเนื้อหาให้ส่งออก', isError: true);
      return;
    }

    final rawTitle = _titleController.text.trim();
    final safe = rawTitle
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .trim();
    final filename = '${safe.isEmpty ? 'document' : safe}.md';

    // Always copy to clipboard; on web also trigger a file download.
    await Clipboard.setData(ClipboardData(text: content));
    await downloadMarkdownFile(filename, content);

    if (!mounted) return;
    GlassNotifications.show(
      context,
      kIsWeb ? 'ดาวน์โหลด .md และคัดลอกแล้ว' : 'คัดลอกเป็น Markdown แล้ว',
    );
  }

  Widget _buildSummaryAiControls() {
    return Align(
      alignment: Alignment.centerRight,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: GlassColors.gold,
          side: BorderSide(color: GlassColors.gold.withOpacity(0.5)),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
        icon: _isSummarizing
            ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 1.6,
                  valueColor: AlwaysStoppedAnimation<Color>(GlassColors.gold),
                ),
              )
            : const Icon(Icons.psychology_rounded, size: 18),
        label: Text(
          _isSummarizing ? 'กำลังสรุปการประชุม...' : 'สรุปการประชุมด้วย AI',
          style: GlassText.bodyMD().copyWith(fontWeight: FontWeight.w600),
        ),
        onPressed: _isSummarizing ? null : _handleAiSummarize,
      ),
    );
  }

  Future<void> _handleAiSummarize() async {
    if (_selectedMeeting == null) return;

    final recordingTakes = _attachments.where((a) => a['type'] == 'recording').toList();

    bool includeNotes = _notesController.text.isNotEmpty;
    bool includeMainTranscript = _selectedMeeting!.transcript.isNotEmpty || _sttService.utterances.isNotEmpty;
    
    final Map<String, bool> includeTakes = {};
    for (final take in recordingTakes) {
      final id = take['id'];
      if (id != null) {
        final trans = take['transcript'];
        if (trans != null && trans.isNotEmpty && trans != '[]') {
          includeTakes[id] = true;
        }
      }
    }

    // Uploaded document attachments (PDF/DOCX) that can be extracted to text.
    final fileAttachments =
        _attachments.where((a) => a['type'] != 'recording').toList();
    final Map<int, bool> includeFiles = {};
    for (var i = 0; i < fileAttachments.length; i++) {
      final name = (fileAttachments[i]['name'] ?? '').toLowerCase();
      final url = (fileAttachments[i]['url'] ?? '').toLowerCase();
      if (name.endsWith('.pdf') ||
          name.endsWith('.docx') ||
          url.endsWith('.pdf') ||
          url.endsWith('.docx')) {
        includeFiles[i] = true;
      }
    }

    if (!includeNotes &&
        !includeMainTranscript &&
        includeTakes.isEmpty &&
        includeFiles.isEmpty) {
      GlassNotifications.show(
        context,
        'ไม่พบข้อมูล Notes หรือ Transcript สำหรับนำมาใช้สรุปการประชุม',
        isError: true,
      );
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.grey[900]?.withOpacity(0.95),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                'เลือกแหล่งข้อมูลสำหรับสรุปประชุม',
                style: GlassText.bodyMD().copyWith(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_notesController.text.isNotEmpty)
                      CheckboxListTile(
                        title: const Text('บันทึกข้อความ (Notes)', style: TextStyle(color: Colors.white)),
                        value: includeNotes,
                        activeColor: GlassColors.gold,
                        onChanged: (val) => setDialogState(() => includeNotes = val ?? false),
                      ),
                    if (_selectedMeeting!.transcript.isNotEmpty || _sttService.utterances.isNotEmpty)
                      CheckboxListTile(
                        title: const Text('ทรานสคริปต์หลัก (Live Transcript)', style: TextStyle(color: Colors.white)),
                        value: includeMainTranscript,
                        activeColor: GlassColors.gold,
                        onChanged: (val) => setDialogState(() => includeMainTranscript = val ?? false),
                      ),
                    if (includeTakes.isNotEmpty) ...[
                      const Divider(color: Colors.white24),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'ไฟล์บันทึกเสียง (Recording Takes)',
                            style: GlassText.secondary().copyWith(color: Colors.white70, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      ...recordingTakes.where((t) => includeTakes.containsKey(t['id'])).map((take) {
                        final takeId = take['id']!;
                        return CheckboxListTile(
                          title: Text(take['name'] ?? 'Recording Take', style: const TextStyle(color: Colors.white70)),
                          value: includeTakes[takeId],
                          activeColor: GlassColors.gold,
                          onChanged: (val) => setDialogState(() => includeTakes[takeId] = val ?? false),
                        );
                      }),
                    ],
                    if (includeFiles.isNotEmpty) ...[
                      const Divider(color: Colors.white24),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'ไฟล์เอกสาร (PDF / DOCX)',
                            style: GlassText.secondary().copyWith(
                                color: Colors.white70,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      ...includeFiles.keys.map((i) {
                        return CheckboxListTile(
                          title: Text(
                            fileAttachments[i]['name'] ?? 'Document',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          value: includeFiles[i],
                          activeColor: GlassColors.gold,
                          onChanged: (val) => setDialogState(
                              () => includeFiles[i] = val ?? false),
                        );
                      }),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('ยกเลิก', style: GlassText.bodyMD().copyWith(color: Colors.white.withOpacity(0.5))),
                ),
                TextButton(
                  onPressed: () {
                    final anySelected = includeNotes ||
                        includeMainTranscript ||
                        includeTakes.values.contains(true) ||
                        includeFiles.values.contains(true);
                    if (!anySelected) {
                      GlassNotifications.show(context, 'กรุณาเลือกแหล่งข้อมูลอย่างน้อย 1 แหล่ง', isError: true);
                      return;
                    }
                    Navigator.pop(context, true);
                  },
                  style: TextButton.styleFrom(foregroundColor: GlassColors.gold),
                  child: Text('เริ่มสรุปด้วย AI', style: GlassText.bodyMD().copyWith(color: GlassColors.gold, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirm != true) return;

    final buffer = StringBuffer();

    if (includeNotes) {
      buffer.writeln('=== MEETING NOTES ===');
      buffer.writeln(_notesController.text);
      buffer.writeln();
    }

    if (includeMainTranscript) {
      buffer.writeln('=== MAIN TRANSCRIPT ===');
      final mainText = _sttService.utterances.isNotEmpty 
          ? _sttService.getFormattedTranscript() 
          : _selectedMeeting!.transcript;
      buffer.writeln(mainText);
      buffer.writeln();
    }

    for (final take in recordingTakes) {
      final takeId = take['id']!;
      if (includeTakes[takeId] == true) {
        buffer.writeln('=== TRANSCRIPT FOR TAKE: ${take['name']} ===');
        try {
          final List<dynamic> parsed = jsonDecode(take['transcript'] ?? '[]');
          for (final item in parsed) {
            if (item is Map) {
              final u = SpeakerUtterance.fromJson(Map<String, dynamic>.from(item));
              buffer.writeln('Speaker ${u.speaker}: ${u.text}');
            }
          }
        } catch (e) {
          buffer.writeln('(Error parsing transcript: $e)');
        }
        buffer.writeln();
      }
    }

    setState(() => _isSummarizing = true);

    try {
      // Extract selected PDF/DOCX attachments to text (lazy + cached).
      for (final i in includeFiles.keys) {
        if (includeFiles[i] != true) continue;
        final att = fileAttachments[i];
        var fileText = att['extractedText'] ?? '';
        if (fileText.isEmpty) {
          fileText = await ApiCloudflare.extractAttachmentText(
            Map<String, dynamic>.from(att),
          );
          if (fileText.isNotEmpty) att['extractedText'] = fileText;
        }
        if (fileText.isNotEmpty) {
          buffer.writeln('=== FILE: ${att['name'] ?? 'document'} ===');
          buffer.writeln(fileText);
          buffer.writeln();
        }
      }

      final combinedText = buffer.toString().trim();
      if (combinedText.isEmpty) return;

      final systemInstruction = 
          'คุณคือผู้ช่วยเลขานุการ HR มืออาชีพที่มีหน้าที่สรุปการประชุม '
          'กรุณาเขียนบันทึกสรุปการประชุมจากข้อมูลที่ได้รับให้ออกมาเป็นเอกสารทางการ (Official Meeting Minutes) ในรูปแบบ Markdown '
          'ที่อ่านเข้าใจง่ายที่สุด แบ่งหัวข้อแยกประเด็นชัดเจนและสรุปประเด็นเป็นข้อๆ '
          'โดยต้องครอบคลุม: หัวข้อการประชุม, วันเวลา (ถ้าระบุ), รายการผู้เข้าร่วม (ถ้ามี), ประเด็นสำคัญที่พูดคุย, มติหรือข้อตกลงร่วมกัน, และ Action Items (สิ่งที่ต้องทำต่อไปพร้อมคนรับผิดชอบและกำหนดส่ง) '
          'ข้อกำหนดที่สำคัญที่สุด:\n'
          '1. ห้ามใส่อิโมจิ (Emoji) หรือสติกเกอร์สัญลักษณ์พิเศษใดๆ ในเอกสารเด็ดขาด (No emojis allowed at all)\n'
          '2. เขียนสรุปเป็นภาษาไทยอย่างเป็นทางการและกระชับ สละสลวย เข้าใจง่ายสำหรับผู้บริหารและเลขา HR\n'
          '3. รูปแบบ Markdown ที่อนุญาตให้ใช้มีเพียง 4 แบบเท่านั้น: หัวข้อใหญ่ขึ้นต้นด้วย "# " (มีเว้นวรรค), หัวข้อย่อยขึ้นต้นด้วย "## " (มีเว้นวรรค), รายการขึ้นต้นด้วย "- " (มีเว้นวรรค), และรายการสิ่งที่ต้องทำขึ้นต้นด้วย "- [ ] " หรือ "- [x] "\n'
          '4. ห้ามใช้ตัวหนา (**), ตัวเอียง (*), อินไลน์โค้ด (`), หัวข้อระดับ "###" ขึ้นไป, เลขลำดับ (1. 2. 3.), หรือเส้นคั่น (---) โดยเด็ดขาด เพราะระบบแสดงผลรองรับเฉพาะ 4 รูปแบบในข้อ 3 เท่านั้น';

      final userPrompt = '$systemInstruction\\n\\nนี่คือข้อมูลการประชุม (Notes และ Transcript):\\n\\n$combinedText';

      final summaryResult = await ApiCloudflare.summarizeMeeting(prompt: userPrompt);

      if (summaryResult.isNotEmpty) {
        // Normalize the AI output through the block parser/serializer so the
        // stored summary contains ONLY the markdown subset the editor renders
        // (strips stray **bold**, ###, numbered lists, ---, etc.).
        final normalized =
            serializeBlocksToMarkdown(parseMarkdownToBlocks(summaryResult));
        setState(() {
          _descriptionController.text = normalized;
        });
        _scheduleAutoSave();
        GlassNotifications.show(context, 'สรุปการประชุมด้วย AI เรียบร้อยแล้ว');
      } else {
        GlassNotifications.show(context, 'ไม่สามารถสรุปข้อมูลได้ กรุณาลองใหม่อีกครั้ง', isError: true);
      }
    } catch (e) {
      debugPrint('[UI] AI Summary failed: $e');
      GlassNotifications.show(context, 'เกิดข้อผิดพลาดในการสรุปข้อมูล: $e', isError: true);
    } finally {
      setState(() => _isSummarizing = false);
    }
  }
}

class _PulsingRecordDot extends StatefulWidget {
  const _PulsingRecordDot();

  @override
  __PulsingRecordDotState createState() => __PulsingRecordDotState();
}

class __PulsingRecordDotState extends State<_PulsingRecordDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.redAccent.withOpacity(0.3 + 0.7 * _controller.value),
            boxShadow: [
              BoxShadow(
                color: Colors.redAccent.withOpacity(0.4 * _controller.value),
                blurRadius: 6,
                spreadRadius: 2,
              )
            ],
          ),
        );
      },
    );
  }
}

