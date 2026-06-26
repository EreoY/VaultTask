import 'package:flutter/material.dart';
import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../../models/board_model.dart';
import '../../models/workspace_model.dart';
import '../../state_managers/state_boards.dart';
import '../../state_managers/state_meetings.dart';
import '../../state_managers/state_documents.dart';
import '../../databases/api_cloudflare.dart';
import '../theme/glass_theme.dart';
import '../common/glass_widgets.dart';
import '../common/responsive_layout.dart';
import 'widgets/board_edit_modal.dart';
import 'widgets/boards_dialogs.dart';
import 'widgets/boards_workspace_header.dart';
import 'widgets/boards_workspace_tabs.dart';
import 'widgets/projects_table.dart';

class BoardsPage extends StatefulWidget {
  final bool isDark;
  const BoardsPage({super.key, required this.isDark});

  @override
  State<BoardsPage> createState() => _BoardsPageState();
}

class _BoardsPageState extends State<BoardsPage> {
  @override
  Widget build(BuildContext context) {
    final boardsState = context.watch<StateBoards>();
    final selectedWorkspace = boardsState.selectedWorkspace;
    final boards = selectedWorkspace != null
        ? boardsState.boards
              .where((b) => b.workspaceId == selectedWorkspace.id)
              .toList()
        : <BoardModel>[];
    final isMobile = Responsive.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BoardsWorkspaceHeader(
          selectedWorkspace: selectedWorkspace,
          onJoinWorkspace: () => BoardsDialogs.showJoinWorkspaceDialog(context),
          onCreateProject: () => _openCreateProjectSheet(selectedWorkspace),
          onRenameWorkspace: selectedWorkspace == null
              ? null
              : () => BoardsDialogs.showRenameWorkspaceDialog(
                  context,
                  selectedWorkspace,
                ),
          onCopyWorkspaceId: selectedWorkspace == null
              ? null
              : () {
                  Clipboard.setData(ClipboardData(text: selectedWorkspace.id));
                  GlassNotifications.show(
                    context,
                    'Workspace ID copied to clipboard',
                  );
                },
        ),
        BoardsWorkspaceTabs(
          workspaces: boardsState.workspaces,
          selectedWorkspaceId: boardsState.selectedWorkspace?.id,
          onSelectWorkspace: boardsState.setSelectedWorkspace,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: boardsState.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: GlassColors.primary),
                )
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ProjectsTable(
                    boards: boards,
                    isMobile: isMobile,
                    onCreateProject: () =>
                        _openCreateProjectSheet(selectedWorkspace),
                    resolveMemberProfile: boardsState.getMemberProfile,
                    onOpenBoard: boardsState.setSelectedBoard,
                    onOpenMeetings: (board) {
                      context.read<StateMeetings>().openBoardHome(board.id);
                      boardsState.openBoardMeetings(board);
                    },
                    onOpenDocs: (board) {
                      context.read<StateDocuments>().openBoardHome(board.id);
                      boardsState.openBoardDocs(board);
                    },
                    onEditBoard: (board) =>
                        BoardsDialogs.showEditBoardDialog(context, board),
                    onDeleteBoard: (board) =>
                        BoardsDialogs.showDeleteBoardConfirm(context, board),
                    onManageMembers: (board) =>
                        BoardsDialogs.showManageMembersDialog(context, board),
                    onUploadDocument: (board) =>
                        _pickAndUploadDocument(context, board, boardsState),
                    onDeleteDocument: (board, doc) =>
                        BoardsDialogs.showDeleteDocumentConfirm(
                          context,
                          board,
                          doc,
                        ),
                  ),
                ),
        ),
      ],
    );
  }

  void _openCreateProjectSheet(WorkspaceModel? selectedWorkspace) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) =>
          BoardEditModal(isDark: widget.isDark, workspace: selectedWorkspace),
    );
  }

  Future<void> _pickAndUploadDocument(
    BuildContext context,
    BoardModel board,
    StateBoards stateBoards,
  ) async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles();
      if (result != null) {
        final filename = result.files.single.name;
        final bytes =
            result.files.single.bytes ??
            (kIsWeb
                ? null
                : await io.File(result.files.single.path!).readAsBytes());

        if (bytes != null) {
          if (context.mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const Center(
                child: CircularProgressIndicator(color: GlassColors.primary),
              ),
            );
          }

          final uploadRes = await ApiCloudflare.uploadImage(
            bytes,
            filename,
            path: 'documents',
          );
          final fileUrl = uploadRes['url'] as String;

          final newDoc = {
            'name': filename,
            'url': fileUrl,
            'uploadedAt': DateTime.now().millisecondsSinceEpoch,
          };
          final updatedDocs = List<Map<String, dynamic>>.from(board.documents)
            ..add(newDoc);
          await stateBoards.updateBoard(board.copyWith(documents: updatedDocs));

          if (context.mounted) {
            Navigator.pop(context);
            GlassNotifications.show(
              context,
              'Uploaded "$filename" successfully!',
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        GlassNotifications.show(context, 'Failed to upload: $e', isError: true);
      }
    }
  }
}
