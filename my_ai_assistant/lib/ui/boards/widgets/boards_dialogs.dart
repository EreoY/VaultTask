import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/board_model.dart';
import '../../../models/workspace_model.dart';
import '../../../state_managers/state_boards.dart';
import '../../common/glass_widgets.dart';
import '../../common/ime_safe_text_field.dart';
import '../../theme/glass_theme.dart';

class BoardsDialogs {
  static void showJoinWorkspaceDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => _ModalShell(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _kicker('JOIN TEAM WORKSPACE', GlassColors.primary),
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
                  child: _secondaryAction(
                    label: 'CANCEL',
                    onPressed: () => Navigator.pop(dialogContext),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _accentAction(
                    label: 'JOIN WORKSPACE',
                    color: GlassColors.gold,
                    onPressed: () async {
                      final id = controller.text.trim();
                      if (id.isEmpty) return;
                      try {
                        await context.read<StateBoards>().joinWorkspaceById(id);
                        if (context.mounted) {
                          Navigator.pop(dialogContext);
                          GlassNotifications.show(
                            context,
                            'Joined workspace successfully!',
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          Navigator.pop(dialogContext);
                          GlassNotifications.show(
                            context,
                            'Failed to join workspace: $e',
                            isError: true,
                          );
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static void showRenameWorkspaceDialog(
    BuildContext context,
    WorkspaceModel workspace,
  ) {
    final controller = TextEditingController(text: workspace.name);
    showDialog(
      context: context,
      builder: (dialogContext) => _ModalShell(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _kicker('RENAME WORKSPACE', GlassColors.primary),
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
                  child: _secondaryAction(
                    label: 'CANCEL',
                    onPressed: () => Navigator.pop(dialogContext),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _accentAction(
                    label: 'RENAME',
                    color: GlassColors.gold,
                    onPressed: () async {
                      final newName = controller.text.trim();
                      if (newName.isEmpty || newName == workspace.name) return;
                      final boardsState = context.read<StateBoards>();
                      try {
                        await boardsState.updateWorkspaceName(
                          workspace,
                          newName,
                        );
                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                        if (context.mounted) {
                          GlassNotifications.show(
                            context,
                            'Workspace renamed successfully!',
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          GlassNotifications.show(
                            context,
                            'Failed to rename workspace: $e',
                            isError: true,
                          );
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static void showEditBoardDialog(BuildContext context, BoardModel board) {
    final controller = TextEditingController(text: board.name);
    showDialog(
      context: context,
      builder: (dialogContext) => _ModalShell(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _kicker('RENAME BOARD', GlassColors.primary),
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
                  child: _secondaryAction(
                    label: 'CANCEL',
                    onPressed: () => Navigator.pop(dialogContext),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _accentAction(
                    label: 'SAVE',
                    color: GlassColors.gold,
                    onPressed: () async {
                      final name = controller.text.trim();
                      if (name.isEmpty) return;
                      try {
                        await context.read<StateBoards>().updateBoard(
                          board.copyWith(name: name),
                        );
                        if (dialogContext.mounted) Navigator.pop(dialogContext);
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
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static void showDeleteBoardConfirm(BuildContext context, BoardModel board) {
    showDialog(
      context: context,
      builder: (dialogContext) => _ModalShell(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _kicker('DELETE BOARD', GlassColors.error),
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
                  child: _secondaryAction(
                    label: 'CANCEL',
                    onPressed: () => Navigator.pop(dialogContext),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _accentAction(
                    label: 'DELETE',
                    color: GlassColors.error,
                    onPressed: () async {
                      try {
                        await context.read<StateBoards>().deleteBoard(board);
                        if (dialogContext.mounted) Navigator.pop(dialogContext);
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
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static void showManageMembersDialog(BuildContext context, BoardModel board) {
    final uidController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setLocalState) {
          return Consumer<StateBoards>(
            builder: (context, stateBoards, _) {
              final currentBoard = stateBoards.boards
                  .cast<BoardModel?>()
                  .firstWhere((b) => b?.id == board.id, orElse: () => board)!;

              return _ModalShell(
                width: 450,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _kicker('MANAGE BOARD MEMBERS', GlassColors.primary),
                    const SizedBox(height: 24),
                    Text(
                      'CURRENT MEMBERS',
                      style: GlassText.labelSM().copyWith(
                        color: GlassColors.onSurfaceVariant.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 180),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: currentBoard.members.length,
                        itemBuilder: (context, index) {
                          final memberUid = currentBoard.members[index];
                          final profile = stateBoards.getMemberProfile(
                            memberUid,
                          );
                          final name = profile?['name'] ?? memberUid;
                          final isOwner = currentBoard.ownerUid == memberUid;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                _MemberAvatar(
                                  uid: memberUid,
                                  name: name,
                                  photoUrl: profile?['photo'],
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '$name${isOwner ? ' (Owner)' : ''}',
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
                                          currentBoard,
                                          memberUid,
                                        );
                                        setLocalState(() {});
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
                        _accentAction(
                          label: 'ADD',
                          color: GlassColors.gold,
                          onPressed: () async {
                            final newUid = uidController.text.trim();
                            if (newUid.isEmpty) return;
                            if (currentBoard.members.contains(newUid)) {
                              GlassNotifications.show(
                                context,
                                'User is already a member',
                                isError: true,
                              );
                              return;
                            }
                            try {
                              final updatedBoard = currentBoard.copyWith(
                                members: [...currentBoard.members, newUid],
                              );
                              await stateBoards.updateBoard(updatedBoard);
                              uidController.clear();
                              await stateBoards.fetchAllBoards();
                              setLocalState(() {});
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
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
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
              );
            },
          );
        },
      ),
    );
  }

  static void showDeleteDocumentConfirm(
    BuildContext context,
    BoardModel board,
    Map<String, dynamic> doc,
  ) {
    final name = doc['name'] as String? ?? 'this document';
    showDialog(
      context: context,
      builder: (dialogContext) => _ModalShell(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _kicker('DELETE DOCUMENT', GlassColors.error),
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
                  child: _secondaryAction(
                    label: 'CANCEL',
                    onPressed: () => Navigator.pop(dialogContext),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _accentAction(
                    label: 'DELETE',
                    color: GlassColors.error,
                    onPressed: () async {
                      try {
                        final updatedDocs =
                            List<Map<String, dynamic>>.from(board.documents)
                              ..removeWhere(
                                (d) =>
                                    d['url'] == doc['url'] &&
                                    d['name'] == doc['name'],
                              );
                        await context.read<StateBoards>().updateBoard(
                          board.copyWith(documents: updatedDocs),
                        );
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
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
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _kicker(String text, Color color) {
    return Text(
      text,
      style: GlassText.labelSM().copyWith(color: color, letterSpacing: 2),
    );
  }

  static Widget _secondaryAction({
    required String label,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: BorderSide(color: GlassColors.ghostBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        label,
        style: GlassText.labelSM().copyWith(
          color: GlassColors.onSurfaceVariant.withOpacity(0.6),
        ),
      ),
    );
  }

  static Widget _accentAction({
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        side: BorderSide(color: color, width: 1.5),
        backgroundColor: color.withOpacity(0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        label,
        style: GlassText.labelSM().copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  final String uid;
  final String name;
  final String? photoUrl;

  const _MemberAvatar({
    required this.uid,
    required this.name,
    required this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
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
          border: Border.all(color: GlassColors.background, width: 1),
          color: GlassColors.primary.withOpacity(0.2),
        ),
        child: ClipOval(
          child: photoUrl != null && photoUrl!.isNotEmpty
              ? Image.network(
                  photoUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => textChild,
                )
              : textChild,
        ),
      ),
    );
  }
}

class _ModalShell extends StatelessWidget {
  final double width;
  final Widget child;

  const _ModalShell({required this.width, required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: width,
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: GlassDecorations.solidSurface(radius: 24, hasShadow: true),
        child: Material(color: Colors.transparent, child: child),
      ),
    );
  }
}
