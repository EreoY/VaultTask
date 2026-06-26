import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../databases/api_cloudflare.dart';
import '../../models/board_model.dart';
import '../../models/document_model.dart';
import '../../state_managers/state_documents.dart';
import '../common/ime_safe_text_field.dart';
import '../common/responsive_layout.dart';
import '../common/scroll_gutter.dart';
import '../common/glass_widgets.dart';
import 'package:my_ai_assistant/ui/common/defer_pointer.dart';
import '../theme/glass_theme.dart';
import '../meetings/widgets/markdown_block_editor.dart';
import '../../utils/web_download_stub.dart'
    if (dart.library.html) '../../utils/web_download_web.dart';

enum _DocsTab { summary, notes, attachments }

class DocsBoardSheet extends StatefulWidget {
  final BoardModel board;
  final String? initialDocumentId;
  final bool embeddedInPage;
  final bool autoLoadFirstDocument;
  final bool isCreateMode;
  final VoidCallback? onBack;
  final VoidCallback? onOpenBoard;
  final ValueChanged<DocumentModel>? onSaved;
  final bool showTopMeta;

  const DocsBoardSheet({
    super.key,
    required this.board,
    this.initialDocumentId,
    this.embeddedInPage = false,
    this.autoLoadFirstDocument = true,
    this.isCreateMode = false,
    this.onBack,
    this.onOpenBoard,
    this.onSaved,
    this.showTopMeta = true,
  });

  @override
  State<DocsBoardSheet> createState() => _DocsBoardSheetState();
}

class _DocsBoardSheetState extends State<DocsBoardSheet> {
  final _titleController = TextEditingController();
  final _summaryController = TextEditingController();
  final _notesController = TextEditingController();
  final _editorScrollController = ScrollController();
  ScrollPhysics? _editorScrollPhysics;

  DocumentModel? _selectedDocument;
  _DocsTab _activeTab = _DocsTab.summary;
  List<Map<String, String>> _attachments = [];
  bool _isSaving = false;
  bool _isUploading = false;
  bool _isSummarizing = false;
  bool _draftInitialized = false;

  Timer? _autoSaveTimer;
  bool _isAutoSaving = false;
  String? _autoSaveStatus; // 'Saving...', 'Saved', or null
  bool _isSuppressingAutoSave = false;

  void _onTitleChanged() {
    _scheduleAutoSave();
  }

  void _scheduleAutoSave() {
    if (_isSuppressingAutoSave) return;
    _autoSaveTimer?.cancel();
    // Only rebuild the (heavy) sheet when the status actually changes — keeps
    // typing smooth on large documents during a continuous typing burst.
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
      final base = DocumentModel(
        id:
            _selectedDocument?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        boardId: widget.board.id,
        title: title,
        notes: _notesController.text.trim(),
        summary: _summaryController.text.trim(),
        attachments: _attachments,
        createdAt: _selectedDocument?.createdAt,
      );

      if (_selectedDocument == null) {
        await context.read<StateDocuments>().addDocument(widget.board, base);
      } else {
        await context.read<StateDocuments>().updateDocument(widget.board, base);
      }

      if (!mounted) return;

      await context.read<StateDocuments>().fetchDocumentsForBoard(
        widget.board,
        silent: true,
      );

      final all = context.read<StateDocuments>().documentsForBoard(
        widget.board.id,
      );
      final saved = all.firstWhere(
        (document) => document.id == base.id,
        orElse: () => base,
      );

      setState(() {
        _selectedDocument = saved;
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
        border: Border.all(color: color.withOpacity(0.12), width: 0.8),
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
    _titleController.addListener(_onTitleChanged);
    _ensureDraftInitialized();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<StateDocuments>().fetchDocumentsForBoard(
        widget.board,
      );
      if (!mounted) return;
      if (widget.initialDocumentId == null && !widget.autoLoadFirstDocument) {
        return;
      }
      final documents = context.read<StateDocuments>().documentsForBoard(
        widget.board.id,
      );
      if (documents.isEmpty) return;
      if (widget.initialDocumentId != null) {
        _loadDocument(
          documents.firstWhere(
            (document) => document.id == widget.initialDocumentId,
            orElse: () => documents.first,
          ),
        );
      } else {
        _loadDocument(documents.first);
      }
    });
  }

  @override
  void dispose() {
    _titleController.removeListener(_onTitleChanged);
    _autoSaveTimer?.cancel();
    _titleController.dispose();
    _summaryController.dispose();
    _notesController.dispose();
    _editorScrollController.dispose();
    super.dispose();
  }

  void _ensureDraftInitialized() {
    if (_draftInitialized) return;
    _draftInitialized = true;
    _isSuppressingAutoSave = true;
    _titleController.clear();
    _summaryController.clear();
    _notesController.clear();
    _selectedDocument = null;
    _attachments = [];
    _activeTab = _DocsTab.summary;
    _isSuppressingAutoSave = false;
  }

  void _loadDocument(DocumentModel document) {
    _isSuppressingAutoSave = true;
    setState(() {
      _selectedDocument = document;
      _titleController.text = document.title;
      _summaryController.text = document.summary;
      _notesController.text = document.notes;
      _attachments = List<Map<String, String>>.from(document.attachments);
      _activeTab = _DocsTab.summary;
      _autoSaveStatus = null;
    });
    _isSuppressingAutoSave = false;
  }

  void _startNewDocument() {
    _isSuppressingAutoSave = true;
    setState(() {
      _selectedDocument = null;
      _titleController.clear();
      _summaryController.clear();
      _notesController.clear();
      _attachments = [];
      _activeTab = _DocsTab.summary;
      _autoSaveStatus = null;
    });
    _isSuppressingAutoSave = false;
  }

  Future<void> _saveDocument() async {
    _autoSaveTimer?.cancel();
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    setState(() {
      _isSaving = true;
      _autoSaveStatus = 'Saving...';
    });
    try {
      final base = DocumentModel(
        id:
            _selectedDocument?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        boardId: widget.board.id,
        title: title,
        notes: _notesController.text.trim(),
        summary: _summaryController.text.trim(),
        attachments: _attachments,
        createdAt: _selectedDocument?.createdAt,
      );
      if (_selectedDocument == null) {
        await context.read<StateDocuments>().addDocument(widget.board, base);
      } else {
        await context.read<StateDocuments>().updateDocument(widget.board, base);
      }
      if (!mounted) return;
      await context.read<StateDocuments>().fetchDocumentsForBoard(
        widget.board,
        silent: true,
      );
      final all = context.read<StateDocuments>().documentsForBoard(
        widget.board.id,
      );
      final saved = all.firstWhere(
        (document) => document.id == base.id,
        orElse: () => base,
      );
      _loadDocument(saved);
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

  Future<void> _deleteDocument() async {
    final document = _selectedDocument;
    if (document == null) return;
    await context.read<StateDocuments>().deleteDocument(
      widget.board,
      document.id,
    );
    if (!mounted) return;
    final documents = context.read<StateDocuments>().documentsForBoard(
      widget.board.id,
    );
    if (documents.isNotEmpty) {
      _loadDocument(documents.first);
      return;
    }
    _startNewDocument();
    widget.onBack?.call();
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
        path: 'documents',
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
      _scheduleAutoSave();
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
      child: _buildEditorPane(),
    );

    return widget.embeddedInPage
        ? shell
        : Material(color: Colors.transparent, child: shell);
  }

  Widget _buildEditorPane() {
    final isMobile = Responsive.isMobile(context);
    final contentWidth = widget.embeddedInPage
        ? (isMobile ? double.infinity : 720.0)
        : double.infinity;
    final titleHint = widget.isCreateMode ? 'Untitled document' : 'Document';

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
                        icon: Icons.access_time_rounded,
                        label: 'Created',
                        child: Text(
                          DateFormat('MMM d, yyyy h:mm a').format(
                            _selectedDocument?.createdAt ?? DateTime.now(),
                          ),
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
                                  color: GlassColors.onSurfaceVariant
                                      .withOpacity(0.85),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Document Workspace',
                                  style: GlassText.bodyMD().copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: GlassColors.onSurface.withOpacity(
                                      0.95,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                _buildExportMdButton(),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Divider(
                              color: GlassColors.outlineVariant.withOpacity(
                                0.12,
                              ),
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
                      const SizedBox(height: 16),
                      if (_selectedDocument != null)
                        TextButton.icon(
                          onPressed: _deleteDocument,
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: GlassColors.error,
                            size: 16,
                          ),
                          label: const Text(
                            'Delete document',
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
    final docTitle = _titleController.text.trim();
    final label = docTitle.isEmpty
        ? (widget.isCreateMode ? 'New document' : 'Document')
        : docTitle;

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
          Icons.description_rounded,
          size: 12,
          color: GlassColors.primary.withOpacity(0.7),
        ),
        const SizedBox(width: 6),
        Text(
          'Documents',
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
          onPressed: _isSaving ? null : _saveDocument,
          child: Text(_isSaving ? 'Saving...' : 'Save'),
        ),
      ],
    );
  }

  Widget _buildHistoryLine() {
    final label = _selectedDocument != null && !widget.isCreateMode
        ? 'Edited ${DateFormat('MMM d').format(_selectedDocument!.createdAt)}'
        : (widget.isCreateMode ? 'New draft' : 'Document detail');
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

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.only(left: 0),
      child: Row(
        children: [
          _docTab(_DocsTab.summary, 'Summary'),
          const SizedBox(width: 10),
          _docTab(_DocsTab.notes, 'Notes'),
          const SizedBox(width: 10),
          _docTab(_DocsTab.attachments, 'Attachments'),
        ],
      ),
    );
  }

  Widget _buildActiveTabContent() {
    switch (_activeTab) {
      case _DocsTab.summary:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSummaryAiControls(),
            const SizedBox(height: 12),
            MarkdownBlockEditor(
              initialMarkdown: _summaryController.text,
              onChanged: (val) {
                _summaryController.text = val;
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
      case _DocsTab.notes:
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
      case _DocsTab.attachments:
        return Padding(
          padding: const EdgeInsets.only(left: 4, right: 4),
          child: _buildAttachments(),
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

  Widget _docTab(_DocsTab tab, String label) {
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
    final summary = _summaryController.text.trim();
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
      GlassNotifications.show(
        context,
        'ยังไม่มีเนื้อหาให้ส่งออก',
        isError: true,
      );
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
          _isSummarizing ? 'กำลังสรุปด้วย AI...' : 'สรุปด้วย AI',
          style: GlassText.bodyMD().copyWith(fontWeight: FontWeight.w600),
        ),
        onPressed: _isSummarizing ? null : _handleAiSummarize,
      ),
    );
  }

  Future<void> _handleAiSummarize() async {
    if (_selectedDocument == null) return;

    bool includeNotes = _notesController.text.trim().isNotEmpty;
    final Map<int, bool> includeAttachments = {};
    for (var i = 0; i < _attachments.length; i++) {
      final name = _attachments[i]['name'] ?? '';
      if (name.isNotEmpty) includeAttachments[i] = true;
    }

    if (!includeNotes && includeAttachments.isEmpty) {
      GlassNotifications.show(
        context,
        'ไม่พบ Notes หรือไฟล์แนบสำหรับนำมาใช้สรุปเอกสาร',
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'เลือกแหล่งข้อมูลสำหรับสรุปเอกสาร',
                style: GlassText.bodyMD().copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_notesController.text.trim().isNotEmpty)
                      CheckboxListTile(
                        title: const Text(
                          'บันทึกข้อความ (Notes)',
                          style: TextStyle(color: Colors.white),
                        ),
                        value: includeNotes,
                        activeColor: GlassColors.gold,
                        onChanged: (val) =>
                            setDialogState(() => includeNotes = val ?? false),
                      ),
                    if (includeAttachments.isNotEmpty) ...[
                      const Divider(color: Colors.white24),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'ไฟล์แนบ (Attachments)',
                            style: GlassText.secondary().copyWith(
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      ...includeAttachments.keys.map((i) {
                        return CheckboxListTile(
                          title: Text(
                            _attachments[i]['name'] ?? 'Attachment',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          value: includeAttachments[i],
                          activeColor: GlassColors.gold,
                          onChanged: (val) => setDialogState(
                            () => includeAttachments[i] = val ?? false,
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    'ยกเลิก',
                    style: GlassText.bodyMD().copyWith(
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    final anySelected =
                        includeNotes ||
                        includeAttachments.values.contains(true);
                    if (!anySelected) {
                      GlassNotifications.show(
                        context,
                        'กรุณาเลือกแหล่งข้อมูลอย่างน้อย 1 แหล่ง',
                        isError: true,
                      );
                      return;
                    }
                    Navigator.pop(context, true);
                  },
                  style: TextButton.styleFrom(foregroundColor: GlassColors.gold),
                  child: Text(
                    'เริ่มสรุปด้วย AI',
                    style: GlassText.bodyMD().copyWith(
                      color: GlassColors.gold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
      buffer.writeln('=== DOCUMENT NOTES ===');
      buffer.writeln(_notesController.text.trim());
      buffer.writeln();
    }

    final selectedAttachments = includeAttachments.entries
        .where((entry) => entry.value)
        .map((entry) => _attachments[entry.key])
        .toList();
    if (selectedAttachments.isNotEmpty) {
      buffer.writeln('=== REFERENCE ATTACHMENTS ===');
      for (final attachment in selectedAttachments) {
        final name = attachment['name'] ?? 'Attachment';
        final url = attachment['url'] ?? '';
        buffer.writeln('Reference attachment: $name (${url.isEmpty ? 'no link' : url})');
      }
      buffer.writeln();
    }

    final combinedText = buffer.toString().trim();
    if (combinedText.isEmpty) return;

    setState(() => _isSummarizing = true);

    try {
      final systemInstruction =
          'คุณคือผู้ช่วยเลขานุการ HR มืออาชีพที่มีหน้าที่สรุปเอกสาร '
          'กรุณาเขียนบันทึกสรุปจากข้อมูลที่ได้รับให้ออกมาเป็นเอกสารทางการในรูปแบบ Markdown '
          'ที่อ่านเข้าใจง่ายที่สุด แบ่งหัวข้อแยกประเด็นชัดเจนและสรุปประเด็นเป็นข้อๆ '
          'โดยต้องครอบคลุม: หัวข้อเอกสาร, ประเด็นสำคัญ, ข้อสรุปหรือข้อตกลง, และ Action Items (สิ่งที่ต้องทำต่อไปพร้อมคนรับผิดชอบและกำหนดส่ง ถ้ามี) '
          'ข้อกำหนดที่สำคัญที่สุด:\n'
          '1. ห้ามใส่อิโมจิ (Emoji) หรือสติกเกอร์สัญลักษณ์พิเศษใดๆ ในเอกสารเด็ดขาด (No emojis allowed at all)\n'
          '2. เขียนสรุปเป็นภาษาไทยอย่างเป็นทางการและกระชับ สละสลวย เข้าใจง่ายสำหรับผู้บริหารและเลขา HR\n'
          '3. รูปแบบ Markdown ที่อนุญาตให้ใช้มีเพียง 4 แบบเท่านั้น: หัวข้อใหญ่ขึ้นต้นด้วย "# " (มีเว้นวรรค), หัวข้อย่อยขึ้นต้นด้วย "## " (มีเว้นวรรค), รายการขึ้นต้นด้วย "- " (มีเว้นวรรค), และรายการสิ่งที่ต้องทำขึ้นต้นด้วย "- [ ] " หรือ "- [x] "\n'
          '4. ห้ามใช้ตัวหนา (**), ตัวเอียง (*), อินไลน์โค้ด (`), หัวข้อระดับ "###" ขึ้นไป, เลขลำดับ (1. 2. 3.), หรือเส้นคั่น (---) โดยเด็ดขาด เพราะระบบแสดงผลรองรับเฉพาะ 4 รูปแบบในข้อ 3 เท่านั้น';

      final userPrompt =
          '$systemInstruction\\n\\nนี่คือข้อมูลเอกสาร (Notes และไฟล์อ้างอิง):\\n\\n$combinedText';

      final summaryResult = await ApiCloudflare.summarizeMeeting(
        prompt: userPrompt,
      );

      if (summaryResult.isNotEmpty) {
        // Normalize the AI output through the block parser/serializer so the
        // stored summary contains ONLY the markdown subset the editor renders.
        final normalized = serializeBlocksToMarkdown(
          parseMarkdownToBlocks(summaryResult),
        );
        setState(() {
          _summaryController.text = normalized;
        });
        _scheduleAutoSave();
        GlassNotifications.show(context, 'สรุปเอกสารด้วย AI เรียบร้อยแล้ว');
      } else {
        GlassNotifications.show(
          context,
          'ไม่สามารถสรุปข้อมูลได้ กรุณาลองใหม่อีกครั้ง',
          isError: true,
        );
      }
    } catch (e) {
      debugPrint('[UI] AI Document Summary failed: $e');
      GlassNotifications.show(
        context,
        'เกิดข้อผิดพลาดในการสรุปข้อมูล: $e',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isSummarizing = false);
    }
  }
}
