import 'package:flutter/material.dart';
import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../../models/board_model.dart';
import '../../models/workspace_model.dart';
import '../../state_managers/state_boards.dart';
import '../../databases/api_cloudflare.dart';
import '../theme/glass_theme.dart';
import '../common/glass_widgets.dart';
import '../common/responsive_layout.dart';
import '../common/ime_safe_text_field.dart';
import 'widgets/board_edit_modal.dart';

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
        _buildHeader(context, selectedWorkspace),
        _buildWorkspaceTabs(context, boardsState),
        const SizedBox(height: 16),
        Expanded(
          child: boardsState.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: GlassColors.primary),
                )
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile
                          ? 16
                          : ExecutiveSpacing.containerPadding(context),
                      vertical: 16,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: GlassColors.outlineVariant.withOpacity(0.15),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildTableHeader(),
                          ...boards.map(
                            (board) =>
                                _buildBoardRow(context, board, boardsState),
                          ),
                          _buildNewProjectRow(selectedWorkspace),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildWorkspaceTabs(BuildContext context, StateBoards boardsState) {
    if (boardsState.workspaces.isEmpty) return const SizedBox.shrink();
    final isMobile = Responsive.isMobile(context);

    return Container(
      height: 36,
      margin: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : ExecutiveSpacing.containerPadding(context),
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: GlassColors.outlineVariant.withOpacity(0.15),
            width: 1,
          ),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: boardsState.workspaces.length,
        itemBuilder: (context, index) {
          final workspace = boardsState.workspaces[index];
          final isSelected = boardsState.selectedWorkspace?.id == workspace.id;

          return GestureDetector(
            onTap: () => boardsState.setSelectedWorkspace(workspace),
            child: Container(
              margin: const EdgeInsets.only(right: 24),
              padding: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected
                        ? GlassColors.primary
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    workspace.type == 'personal'
                        ? Icons.person_outline_rounded
                        : Icons.group_outlined,
                    size: 14,
                    color: isSelected
                        ? GlassColors.primary
                        : GlassColors.onSurfaceVariant.withOpacity(0.5),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    workspace.name,
                    style: GlassText.bodyMD().copyWith(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? GlassColors.onSurface
                          : GlassColors.onSurfaceVariant.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WorkspaceModel? selectedWorkspace) {
    final isMobile = Responsive.isMobile(context);

    return Container(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 16 : ExecutiveSpacing.containerPadding(context),
        isMobile ? 16 : ExecutiveSpacing.containerPadding(context),
        isMobile ? 16 : ExecutiveSpacing.containerPadding(context),
        16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumbs
          Row(
            children: [
              Icon(
                Icons.home_rounded,
                size: 12,
                color: GlassColors.onSurfaceVariant.withOpacity(0.3),
              ),
              const SizedBox(width: 4),
              Text(
                'Workspace HQ',
                style: GlassText.bodyMD().copyWith(
                  fontSize: 11,
                  color: GlassColors.onSurfaceVariant.withOpacity(0.5),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '/',
                style: GlassText.bodyMD().copyWith(
                  fontSize: 11,
                  color: GlassColors.onSurfaceVariant.withOpacity(0.2),
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                selectedWorkspace?.type == 'personal'
                    ? Icons.person_outline_rounded
                    : Icons.group_outlined,
                size: 12,
                color: GlassColors.onSurfaceVariant.withOpacity(0.3),
              ),
              const SizedBox(width: 4),
              Text(
                selectedWorkspace?.name ?? 'Workspace',
                style: GlassText.bodyMD().copyWith(
                  fontSize: 11,
                  color: GlassColors.onSurfaceVariant.withOpacity(0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Title and Buttons Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('🎯', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Text(
                    selectedWorkspace?.name ?? 'Projects',
                    style: GlassText.headlineLG().copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: GlassColors.onSurface,
                    ),
                  ),
                  if (selectedWorkspace != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.edit_rounded,
                        size: 16,
                        color: GlassColors.onSurfaceVariant,
                      ),
                      tooltip: 'Rename Workspace',
                      onPressed: () => _showRenameWorkspaceDialog(
                        context,
                        selectedWorkspace,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.copy_rounded,
                        size: 16,
                        color: GlassColors.onSurfaceVariant,
                      ),
                      tooltip: 'Copy Workspace ID',
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: selectedWorkspace.id),
                        );
                        GlassNotifications.show(
                          context,
                          'Workspace ID copied to clipboard',
                        );
                      },
                    ),
                  ],
                ],
              ),
              Row(
                children: [
                  // Join Workspace Button
                  TextButton.icon(
                    onPressed: () => _showJoinWorkspaceDialog(context),
                    icon: const Icon(
                      Icons.group_add_rounded,
                      size: 14,
                      color: GlassColors.gold,
                    ),
                    label: Text(
                      'JOIN WORKSPACE',
                      style: GlassText.labelSM().copyWith(
                        color: GlassColors.gold,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  ElevatedButton.icon(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        isScrollControlled: true,
                        builder: (context) => BoardEditModal(
                          isDark: widget.isDark,
                          workspace: selectedWorkspace,
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.add_rounded,
                      size: 14,
                      color: Colors.black87,
                    ),
                    label: Text(
                      'New project',
                      style: GlassText.labelSM().copyWith(
                        color: Colors.black87,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GlassColors.gold,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showJoinWorkspaceDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => Center(
        child: Container(
          width: 400,
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: GlassDecorations.solidSurface(
            radius: 24,
            hasShadow: true,
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'JOIN TEAM WORKSPACE',
                  style: GlassText.labelSM().copyWith(
                    color: GlassColors.primary,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Enter the Workspace ID shared by your colleague.',
                  style: GlassText.bodyMD().copyWith(
                    color: GlassColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                ImeSafeTextField(
                  controller: controller,
                  autofocus: true,
                  style: GlassText.bodyLG(),
                  decoration: InputDecoration(
                    hintText: 'e.g., default_team_xxxx',
                    hintStyle: GlassText.bodyLG().copyWith(
                      color: GlassColors.onSurfaceVariant.withOpacity(0.3),
                    ),
                    filled: true,
                    fillColor: GlassColors.primary.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: GlassColors.ghostBorder),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'CANCEL',
                          style: GlassText.labelSM().copyWith(
                            color: GlassColors.onSurfaceVariant.withOpacity(
                              0.6,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final id = controller.text.trim();
                          if (id.isEmpty) return;
                          try {
                            await context.read<StateBoards>().joinWorkspaceById(
                              id,
                            );
                            if (context.mounted) {
                              Navigator.pop(context);
                              GlassNotifications.show(
                                context,
                                'Joined workspace successfully!',
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              Navigator.pop(context);
                              GlassNotifications.show(
                                context,
                                'Failed to join workspace: $e',
                                isError: true,
                              );
                            }
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(
                            color: GlassColors.gold,
                            width: 1.5,
                          ),
                          backgroundColor: GlassColors.gold.withOpacity(0.05),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'JOIN WORKSPACE',
                          style: GlassText.labelSM().copyWith(
                            color: GlassColors.gold,
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

  void _showRenameWorkspaceDialog(
    BuildContext context,
    WorkspaceModel workspace,
  ) {
    final controller = TextEditingController(text: workspace.name);
    showDialog(
      context: context,
      builder: (dialogContext) => Center(
        child: Container(
          width: 400,
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: GlassDecorations.solidSurface(
            radius: 24,
            hasShadow: true,
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RENAME WORKSPACE',
                  style: GlassText.labelSM().copyWith(
                    color: GlassColors.primary,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 24),
                ImeSafeTextField(
                  controller: controller,
                  autofocus: true,
                  style: GlassText.bodyLG(),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: GlassColors.primary.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'CANCEL',
                          style: GlassText.labelSM().copyWith(
                            color: GlassColors.onSurfaceVariant.withOpacity(
                              0.6,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final newName = controller.text.trim();
                          if (newName.isEmpty || newName == workspace.name) {
                            return;
                          }
                          final boardsState = context.read<StateBoards>();
                          final scaffoldMessenger = ScaffoldMessenger.of(
                            context,
                          );
                          final navigator = Navigator.of(dialogContext);
                          try {
                            await boardsState.updateWorkspaceName(
                              workspace,
                              newName,
                            );
                            navigator.pop();
                            GlassNotifications.show(
                              context,
                              'Workspace renamed successfully!',
                            );
                          } catch (e) {
                            GlassNotifications.show(
                              context,
                              'Failed to rename workspace: $e',
                              isError: true,
                            );
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(
                            color: GlassColors.gold,
                            width: 1.5,
                          ),
                          backgroundColor: GlassColors.gold.withOpacity(0.05),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'RENAME',
                          style: GlassText.labelSM().copyWith(
                            color: GlassColors.gold,
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

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: GlassColors.surfaceBright.withOpacity(0.03),
        border: Border(
          bottom: BorderSide(
            color: GlassColors.outlineVariant.withOpacity(0.15),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Icon(
                  Icons.text_fields_rounded,
                  size: 14,
                  color: GlassColors.onSurfaceVariant.withOpacity(0.4),
                ),
                const SizedBox(width: 8),
                Text(
                  'PROJECT',
                  style: GlassText.labelSM().copyWith(
                    color: GlassColors.onSurfaceVariant.withOpacity(0.5),
                    fontSize: 11,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: GlassColors.onSurfaceVariant.withOpacity(0.4),
                ),
                const SizedBox(width: 8),
                Text(
                  'STAGE',
                  style: GlassText.labelSM().copyWith(
                    color: GlassColors.onSurfaceVariant.withOpacity(0.5),
                    fontSize: 11,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Icon(
                  Icons.people_outline_rounded,
                  size: 14,
                  color: GlassColors.onSurfaceVariant.withOpacity(0.4),
                ),
                const SizedBox(width: 8),
                Text(
                  'MEMBERS',
                  style: GlassText.labelSM().copyWith(
                    color: GlassColors.onSurfaceVariant.withOpacity(0.5),
                    fontSize: 11,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Icon(
                  Icons.insert_drive_file_outlined,
                  size: 14,
                  color: GlassColors.onSurfaceVariant.withOpacity(0.4),
                ),
                const SizedBox(width: 8),
                Text(
                  'DOCS',
                  style: GlassText.labelSM().copyWith(
                    color: GlassColors.onSurfaceVariant.withOpacity(0.5),
                    fontSize: 11,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                'ACTIONS',
                style: GlassText.labelSM().copyWith(
                  color: GlassColors.onSurfaceVariant.withOpacity(0.5),
                  fontSize: 11,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoardRow(
    BuildContext context,
    BoardModel board,
    StateBoards stateBoards,
  ) {
    final isTeam = board.type == 'team';
    final projectColor = Color(board.color == 0 ? 0xFF0D40A5 : board.color);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: GlassColors.outlineVariant.withOpacity(0.15),
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // Project
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: projectColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => stateBoards.setSelectedBoard(board),
                        child: Text(
                          board.name,
                          style: GlassText.bodyMD().copyWith(
                            fontWeight: FontWeight.w500,
                            color: GlassColors.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => stateBoards.setSelectedBoard(board),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'OPEN',
                            style: GlassText.labelSM().copyWith(
                              fontSize: 9,
                              color: GlassColors.primary.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.open_in_new_rounded,
                            size: 10,
                            color: GlassColors.primary.withOpacity(0.6),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Stage/Type
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isTeam
                        ? GlassColors.primary.withOpacity(0.08)
                        : GlassColors.surfaceBright.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isTeam ? 'Team Project' : 'Personal',
                    style: GlassText.labelSM().copyWith(
                      fontSize: 10,
                      color: isTeam
                          ? GlassColors.primary
                          : GlassColors.onSurfaceVariant.withOpacity(0.7),
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),

            // Members
            Expanded(
              flex: 2,
              child: _buildAvatarStack(context, board, stateBoards),
            ),

            // Docs
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: board.documents
                          .map(
                            (doc) => _buildDocumentChip(
                              context,
                              board,
                              doc,
                              stateBoards,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(width: 4),
                  _buildUploadDocButton(context, board, stateBoards),
                ],
              ),
            ),

            // Actions
            Expanded(
              flex: 1,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_rounded, size: 14),
                    color: GlassColors.onSurfaceVariant.withOpacity(0.4),
                    onPressed: () =>
                        _showEditBoardDialog(context, board, stateBoards),
                    tooltip: 'Rename Board',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 14),
                    color: GlassColors.error.withOpacity(0.5),
                    onPressed: () =>
                        _showDeleteBoardConfirm(context, board, stateBoards),
                    tooltip: 'Delete Board',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewProjectRow(WorkspaceModel? selectedWorkspace) {
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) => BoardEditModal(
            isDark: widget.isDark,
            workspace: selectedWorkspace,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(color: Colors.transparent),
        child: Row(
          children: [
            const Icon(Icons.add_rounded, size: 16, color: GlassColors.gold),
            const SizedBox(width: 8),
            Text(
              'New project',
              style: GlassText.bodyMD().copyWith(
                color: GlassColors.gold,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberAvatar(String uid, StateBoards stateBoards) {
    final profile = stateBoards.getMemberProfile(uid);
    final photoUrl = profile?['photo'];
    final name = profile?['name'] ?? uid;
    final initials = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';

    final textChild = Center(
      child: Text(
        initials,
        style: GlassText.labelSM().copyWith(
          fontSize: 8,
          color: GlassColors.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    return Tooltip(
      message: name,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: GlassColors.background, width: 1.0),
          color: GlassColors.primary.withOpacity(0.2),
        ),
        child: ClipOval(
          child: photoUrl != null && photoUrl.isNotEmpty
              ? Image.network(
                  photoUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => textChild,
                )
              : textChild,
        ),
      ),
    );
  }

  Widget _buildAvatarStack(
    BuildContext context,
    BoardModel board,
    StateBoards stateBoards,
  ) {
    final displayMembers = board.members.take(3).toList();
    final remainingCount = board.members.length - displayMembers.length;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (board.members.isEmpty)
          Text(
            'No members',
            style: GlassText.bodyMD().copyWith(
              color: GlassColors.onSurfaceVariant.withOpacity(0.4),
              fontSize: 11,
            ),
          )
        else
          SizedBox(
            height: 20,
            width: (displayMembers.length * 14.0) + 6,
            child: Stack(
              children: List.generate(displayMembers.length, (idx) {
                return Positioned(
                  left: idx * 14.0,
                  child: _buildMemberAvatar(displayMembers[idx], stateBoards),
                );
              }),
            ),
          ),
        if (remainingCount > 0) ...[
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: GlassColors.surfaceBright.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '+$remainingCount',
              style: GlassText.labelSM().copyWith(
                fontSize: 8,
                color: GlassColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
        const SizedBox(width: 4),
        if (board.type == 'team')
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, size: 14),
            color: GlassColors.gold,
            onPressed: () =>
                _showManageMembersDialog(context, board, stateBoards),
            tooltip: 'Manage Members',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            splashRadius: 12,
          ),
      ],
    );
  }

  Widget _buildDocumentChip(
    BuildContext context,
    BoardModel board,
    Map<String, dynamic> doc,
    StateBoards stateBoards,
  ) {
    final name = doc['name'] as String? ?? 'Document';
    final url = doc['url'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: GlassColors.surfaceBright.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GlassColors.ghostBorder.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.insert_drive_file_outlined,
            size: 10,
            color: GlassColors.primary,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: InkWell(
              onTap: () async {
                if (url.isNotEmpty) {
                  final uri = Uri.parse(url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                }
              },
              child: Text(
                name,
                style: GlassText.bodyMD().copyWith(
                  fontSize: 10,
                  color: GlassColors.onSurface.withOpacity(0.9),
                  decoration: TextDecoration.underline,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () =>
                _showDeleteDocumentConfirm(context, board, doc, stateBoards),
            child: const Icon(
              Icons.close_rounded,
              size: 10,
              color: GlassColors.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadDocButton(
    BuildContext context,
    BoardModel board,
    StateBoards stateBoards,
  ) {
    return TextButton.icon(
      onPressed: () => _pickAndUploadDocument(context, board, stateBoards),
      icon: const Icon(
        Icons.cloud_upload_outlined,
        size: 12,
        color: GlassColors.gold,
      ),
      label: Text(
        'UPLOAD',
        style: GlassText.labelSM().copyWith(
          color: GlassColors.gold,
          fontSize: 9,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  void _showEditBoardDialog(
    BuildContext context,
    BoardModel board,
    StateBoards stateBoards,
  ) {
    final controller = TextEditingController(text: board.name);
    showDialog(
      context: context,
      builder: (context) => Center(
        child: Container(
          width: 400,
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: GlassDecorations.solidSurface(
            radius: 24,
            hasShadow: true,
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RENAME BOARD',
                  style: GlassText.labelSM().copyWith(
                    color: GlassColors.primary,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 24),
                ImeSafeTextField(
                  controller: controller,
                  autofocus: true,
                  style: GlassText.bodyLG(),
                  decoration: InputDecoration(
                    hintText: 'Board Name',
                    hintStyle: GlassText.bodyLG().copyWith(
                      color: GlassColors.onSurfaceVariant.withOpacity(0.3),
                    ),
                    filled: true,
                    fillColor: GlassColors.primary.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: GlassColors.ghostBorder),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'CANCEL',
                          style: GlassText.labelSM().copyWith(
                            color: GlassColors.onSurfaceVariant.withOpacity(
                              0.6,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final name = controller.text.trim();
                          if (name.isEmpty) return;
                          try {
                            await stateBoards.updateBoard(
                              board.copyWith(name: name),
                            );
                            if (context.mounted) Navigator.pop(context);
                          } catch (e) {
                            if (context.mounted) {
                              GlassNotifications.show(
                                context,
                                'Failed to update board: $e',
                                isError: true,
                              );
                            }
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(
                            color: GlassColors.gold,
                            width: 1.5,
                          ),
                          backgroundColor: GlassColors.gold.withOpacity(0.05),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'SAVE',
                          style: GlassText.labelSM().copyWith(
                            color: GlassColors.gold,
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

  void _showDeleteBoardConfirm(
    BuildContext context,
    BoardModel board,
    StateBoards stateBoards,
  ) {
    showDialog(
      context: context,
      builder: (context) => Center(
        child: Container(
          width: 400,
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: GlassDecorations.solidSurface(
            radius: 24,
            hasShadow: true,
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DELETE BOARD',
                  style: GlassText.labelSM().copyWith(
                    color: GlassColors.error,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Are you sure you want to delete "${board.name}"? This action is permanent and cannot be undone.',
                  style: GlassText.bodyMD().copyWith(
                    color: GlassColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: GlassColors.ghostBorder),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'CANCEL',
                          style: GlassText.labelSM().copyWith(
                            color: GlassColors.onSurfaceVariant.withOpacity(
                              0.6,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          try {
                            await stateBoards.deleteBoard(board);
                            if (context.mounted) Navigator.pop(context);
                          } catch (e) {
                            if (context.mounted) {
                              GlassNotifications.show(
                                context,
                                'Failed to delete board: $e',
                                isError: true,
                              );
                            }
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(
                            color: GlassColors.error,
                            width: 1.5,
                          ),
                          backgroundColor: GlassColors.error.withOpacity(0.05),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'DELETE',
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

  void _showManageMembersDialog(
    BuildContext context,
    BoardModel board,
    StateBoards stateBoards,
  ) {
    final uidController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Center(
            child: Container(
              width: 450,
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(32),
              decoration: GlassDecorations.solidSurface(
                radius: 24,
                hasShadow: true,
              ),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MANAGE BOARD MEMBERS',
                      style: GlassText.labelSM().copyWith(
                        color: GlassColors.primary,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'CURRENT MEMBERS',
                      style: GlassText.labelSM().copyWith(
                        color: GlassColors.onSurfaceVariant.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 180),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: board.members.length,
                        itemBuilder: (context, index) {
                          final memberUid = board.members[index];
                          final profile = stateBoards.getMemberProfile(
                            memberUid,
                          );
                          final name = profile?['name'] ?? memberUid;
                          final isOwner = board.ownerUid == memberUid;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                _buildMemberAvatar(memberUid, stateBoards),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    name + (isOwner ? ' (Owner)' : ''),
                                    style: GlassText.bodyMD(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (!isOwner &&
                                    memberUid !=
                                        FirebaseAuth.instance.currentUser?.uid)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle_outline_rounded,
                                      size: 18,
                                      color: GlassColors.error,
                                    ),
                                    onPressed: () async {
                                      try {
                                        await stateBoards.removeMember(
                                          board,
                                          memberUid,
                                        );
                                        setState(() {});
                                      } catch (e) {
                                        if (context.mounted) {
                                          GlassNotifications.show(
                                            context,
                                            'Error: $e',
                                            isError: true,
                                          );
                                        }
                                      }
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'ADD MEMBER BY UID',
                      style: GlassText.labelSM().copyWith(
                        color: GlassColors.onSurfaceVariant.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ImeSafeTextField(
                            controller: uidController,
                            style: GlassText.bodyMD(),
                            decoration: InputDecoration(
                              hintText: 'Enter Firebase User UID',
                              hintStyle: GlassText.bodyMD().copyWith(
                                color: GlassColors.onSurfaceVariant.withOpacity(
                                  0.3,
                                ),
                              ),
                              filled: true,
                              fillColor: GlassColors.primary.withOpacity(0.05),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.all(12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () async {
                            final newUid = uidController.text.trim();
                            if (newUid.isEmpty) return;
                            if (board.members.contains(newUid)) {
                              GlassNotifications.show(
                                context,
                                'User is already a member',
                                isError: true,
                              );
                              return;
                            }
                            try {
                              final updatedMembers = [...board.members, newUid];
                              final updatedBoard = board.copyWith(
                                members: updatedMembers,
                              );
                              await stateBoards.updateBoard(updatedBoard);
                              uidController.clear();
                              setState(() {});
                              await stateBoards.fetchAllBoards();
                              setState(() {});
                            } catch (e) {
                              if (context.mounted) {
                                GlassNotifications.show(
                                  context,
                                  'Failed to add member: $e',
                                  isError: true,
                                );
                              }
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            side: const BorderSide(
                              color: GlassColors.gold,
                              width: 1.5,
                            ),
                            backgroundColor: GlassColors.gold.withOpacity(0.05),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'ADD',
                            style: GlassText.labelSM().copyWith(
                              color: GlassColors.gold,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'CLOSE',
                            style: GlassText.labelSM().copyWith(
                              color: GlassColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
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

  void _showDeleteDocumentConfirm(
    BuildContext context,
    BoardModel board,
    Map<String, dynamic> doc,
    StateBoards stateBoards,
  ) {
    final name = doc['name'] as String? ?? 'this document';
    showDialog(
      context: context,
      builder: (context) => Center(
        child: Container(
          width: 400,
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: GlassDecorations.solidSurface(
            radius: 24,
            hasShadow: true,
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DELETE DOCUMENT',
                  style: GlassText.labelSM().copyWith(
                    color: GlassColors.error,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Are you sure you want to delete "$name" from attached documents?',
                  style: GlassText.bodyMD().copyWith(
                    color: GlassColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: GlassColors.ghostBorder),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'CANCEL',
                          style: GlassText.labelSM().copyWith(
                            color: GlassColors.onSurfaceVariant.withOpacity(
                              0.6,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          try {
                            final updatedDocs =
                                List<Map<String, dynamic>>.from(board.documents)
                                  ..removeWhere(
                                    (d) =>
                                        d['url'] == doc['url'] &&
                                        d['name'] == doc['name'],
                                  );
                            await stateBoards.updateBoard(
                              board.copyWith(documents: updatedDocs),
                            );
                            if (context.mounted) Navigator.pop(context);
                          } catch (e) {
                            if (context.mounted) {
                              GlassNotifications.show(
                                context,
                                'Failed to delete document: $e',
                                isError: true,
                              );
                            }
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(
                            color: GlassColors.error,
                            width: 1.5,
                          ),
                          backgroundColor: GlassColors.error.withOpacity(0.05),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'DELETE',
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
}
