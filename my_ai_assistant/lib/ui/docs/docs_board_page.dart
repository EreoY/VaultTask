import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/board_model.dart';
import '../../models/document_model.dart';
import '../../state_managers/state_boards.dart';
import '../../state_managers/state_documents.dart';
import '../common/responsive_layout.dart';
import '../common/scroll_gutter.dart';
import '../common/workspace_chrome.dart';
import '../theme/glass_theme.dart';
import 'docs_board_sheet.dart';

class DocsBoardPage extends StatefulWidget {
  final BoardModel board;

  const DocsBoardPage({super.key, required this.board});

  @override
  State<DocsBoardPage> createState() => _DocsBoardPageState();
}

class _DocsBoardPageState extends State<DocsBoardPage> {
  bool _isCreatingDraft = false;

  void _exitToWorkspace() {
    context.read<StateDocuments>().clearActiveBoard(widget.board.id);
    context.read<StateBoards>().setSelectedBoard(null);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<StateDocuments>().fetchDocumentsForBoard(
        widget.board,
      );
      if (!mounted) return;
      context.read<StateDocuments>().openBoardHome(widget.board.id);
    });
  }

  @override
  void didUpdateWidget(covariant DocsBoardPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.board.id != widget.board.id) {
      _isCreatingDraft = false;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await context.read<StateDocuments>().fetchDocumentsForBoard(
          widget.board,
        );
        if (!mounted) return;
        context.read<StateDocuments>().openBoardHome(widget.board.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final documentsState = context.watch<StateDocuments>();
    final documents = documentsState.documentsForBoard(widget.board.id);
    final selectedDocument = documentsState.selectedDocumentForBoard(
      widget.board.id,
    );

    return selectedDocument == null
        ? (_isCreatingDraft
              ? _buildCreateSurface(context)
              : _buildListSurface(context, documents))
        : _buildDetailSurface(context, selectedDocument);
  }

  Widget _buildListSurface(
    BuildContext context,
    List<DocumentModel> documents,
  ) {
    final isMobile = Responsive.isMobile(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 16 : ExecutiveSpacing.containerPadding(context),
        isMobile ? 16 : ExecutiveSpacing.containerPadding(context),
        isMobile ? 16 : ExecutiveSpacing.containerPadding(context),
        isMobile ? 20 : 28,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNavBar(metaText: 'Board documents'),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  WorkspaceBackButton(onTap: _exitToWorkspace),
                  const SizedBox(width: 12),
                  Text(
                    'Documents',
                    style: GlassText.headlineLG().copyWith(
                      fontSize: isMobile ? 34 : 42,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              _primaryAction(label: 'New document', onTap: _openCreateDraft),
            ],
          ),
          const SizedBox(height: 26),
          Expanded(
            child: documents.isEmpty
                ? Center(
                    child: Text(
                      'No documents yet',
                      style: GlassText.bodyMD().copyWith(
                        color: GlassColors.onSurfaceVariant.withOpacity(0.45),
                      ),
                    ),
                  )
                : ScrollbarGutterFrame(
                    child: ListView.separated(
                      padding: ScrollbarGutter.reserveRight(EdgeInsets.zero),
                      itemCount: documents.length,
                      separatorBuilder: (_, _) => Divider(
                        color: GlassColors.outlineVariant.withOpacity(0.1),
                        height: 1,
                      ),
                      itemBuilder: (context, index) {
                        final document = documents[index];
                        return _DocumentRow(
                          document: document,
                          boardName: widget.board.name,
                          onTap: () {
                            context.read<StateDocuments>().openDocumentDetail(
                              widget.board.id,
                              document.id,
                            );
                          },
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSurface(
    BuildContext context,
    DocumentModel selectedDocument,
  ) {
    final isMobile = Responsive.isMobile(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 16 : ExecutiveSpacing.containerPadding(context),
        isMobile ? 16 : ExecutiveSpacing.containerPadding(context),
        0,
        isMobile ? 20 : 28,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(
              right: isMobile ? 16 : ExecutiveSpacing.containerPadding(context),
            ),
            child: _buildNavBar(
              metaText:
                  'Edited ${DateFormat('MMM d').format(selectedDocument.createdAt)}',
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: DocsBoardSheet(
              board: widget.board,
              initialDocumentId: selectedDocument.id,
              embeddedInPage: true,
              onBack: () =>
                  context.read<StateDocuments>().closeDocumentDetail(),
              onOpenBoard: () => context.read<StateBoards>().setBoardSurface(
                BoardSurfaceMode.kanban,
              ),
              showTopMeta: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateSurface(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 16 : ExecutiveSpacing.containerPadding(context),
        isMobile ? 16 : ExecutiveSpacing.containerPadding(context),
        0,
        isMobile ? 20 : 28,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(
              right: isMobile ? 16 : ExecutiveSpacing.containerPadding(context),
            ),
            child: _buildNavBar(metaText: 'New draft'),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: DocsBoardSheet(
              board: widget.board,
              embeddedInPage: true,
              autoLoadFirstDocument: false,
              isCreateMode: true,
              onBack: () => setState(() => _isCreatingDraft = false),
              onSaved: (document) {
                if (!mounted) return;
                setState(() => _isCreatingDraft = false);
                context.read<StateDocuments>().openDocumentDetail(
                  widget.board.id,
                  document.id,
                );
              },
              onOpenBoard: () => context.read<StateBoards>().setBoardSurface(
                BoardSurfaceMode.kanban,
              ),
              showTopMeta: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavBar({required String metaText}) {
    return WorkspaceChromeHeader(
      padding: EdgeInsets.zero,
      gapAfterMeta: 0,
      crumbs: [
        WorkspaceCrumb(
          icon: Icons.home_rounded,
          label: 'Workspace HQ',
          onTap: _exitToWorkspace,
        ),
        WorkspaceCrumb(
          icon: Icons.description_rounded,
          label: 'Documents',
          color: GlassColors.onSurfaceVariant.withOpacity(0.72),
          onTap: _returnToDocsList,
        ),
        WorkspaceCrumb(label: widget.board.name),
      ],
      metaText: metaText,
      title: const SizedBox.shrink(),
    );
  }

  void _returnToDocsList() {
    if (_isCreatingDraft) {
      setState(() => _isCreatingDraft = false);
    }
    context.read<StateDocuments>().closeDocumentDetail();
  }

  Widget _primaryAction({required String label, required VoidCallback onTap}) {
    return FilledButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.add_rounded, size: 16),
      label: Text(label),
    );
  }

  void _openCreateDraft() {
    setState(() => _isCreatingDraft = true);
  }
}

class _DocumentRow extends StatelessWidget {
  final DocumentModel document;
  final String boardName;
  final VoidCallback onTap;

  const _DocumentRow({
    required this.document,
    required this.boardName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final preview = document.summary.trim().isNotEmpty
        ? document.summary.trim()
        : document.notes.trim();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document.title.trim().isEmpty
                        ? 'Untitled document'
                        : document.title.trim(),
                    style: GlassText.bodyLG().copyWith(
                      fontWeight: FontWeight.w500,
                      color: GlassColors.onSurface,
                    ),
                  ),
                  if (preview.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GlassText.bodyMD().copyWith(
                        color: GlassColors.onSurfaceVariant.withOpacity(0.54),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  DateFormat('MMM d, yyyy').format(document.createdAt),
                  style: GlassText.bodyMD().copyWith(
                    color: GlassColors.onSurface.withOpacity(0.86),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  boardName,
                  style: GlassText.bodyMD().copyWith(
                    color: GlassColors.onSurfaceVariant.withOpacity(0.58),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
