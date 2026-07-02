import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../../models/board_model.dart';
import '../../models/workspace_model.dart';
import '../../state_managers/state_boards.dart';
import '../../state_managers/state_meetings.dart';
import '../../state_managers/state_documents.dart';
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
  final bool isActive;
  const BoardsPage({
    super.key,
    required this.isDark,
    this.isActive = true,
  });

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
        AetherStaggeredFadeIn(
          index: 0,
          isActive: widget.isActive,
          child: BoardsWorkspaceHeader(
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
        ),
        AetherStaggeredFadeIn(
          index: 1,
          isActive: widget.isActive,
          child: BoardsWorkspaceTabs(
            workspaces: boardsState.workspaces,
            selectedWorkspaceId: boardsState.selectedWorkspace?.id,
            onSelectWorkspace: boardsState.setSelectedWorkspace,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: AetherStaggeredFadeIn(
            index: 2,
            isActive: widget.isActive,
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
}
