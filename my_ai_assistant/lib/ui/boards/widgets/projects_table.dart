import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/board_model.dart';
import '../../theme/glass_theme.dart';

typedef MemberProfileResolver = Map<String, dynamic>? Function(String uid);
typedef BoardAction = void Function(BoardModel board);
typedef BoardDocumentAction =
    void Function(BoardModel board, Map<String, dynamic> doc);

class ProjectsTable extends StatelessWidget {
  final List<BoardModel> boards;
  final bool isMobile;
  final MemberProfileResolver resolveMemberProfile;
  final BoardAction onOpenBoard;
  final BoardAction onOpenMeetings;
  final BoardAction onEditBoard;
  final BoardAction onDeleteBoard;
  final BoardAction onManageMembers;
  final BoardAction onUploadDocument;
  final BoardDocumentAction onDeleteDocument;
  final VoidCallback onCreateProject;

  const ProjectsTable({
    super.key,
    required this.boards,
    required this.isMobile,
    required this.resolveMemberProfile,
    required this.onOpenBoard,
    required this.onOpenMeetings,
    required this.onEditBoard,
    required this.onDeleteBoard,
    required this.onManageMembers,
    required this.onUploadDocument,
    required this.onDeleteDocument,
    required this.onCreateProject,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : ExecutiveSpacing.containerPadding(context),
        vertical: 16,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ExecutiveRadius.xl),
          border: Border.all(
            color: GlassColors.hairlineStrong.withOpacity(0.6),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _ProjectsTableHeader(),
            ...boards.map(
              (board) => _BoardRow(
                board: board,
                resolveMemberProfile: resolveMemberProfile,
                onOpenBoard: onOpenBoard,
                onOpenMeetings: onOpenMeetings,
                onEditBoard: onEditBoard,
                onDeleteBoard: onDeleteBoard,
                onManageMembers: onManageMembers,
                onUploadDocument: onUploadDocument,
                onDeleteDocument: onDeleteDocument,
              ),
            ),
            _NewProjectRow(onCreateProject: onCreateProject),
          ],
        ),
      ),
    );
  }
}

class _ProjectsTableHeader extends StatelessWidget {
  const _ProjectsTableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: GlassColors.surfaceBright.withOpacity(0.03),
        border: Border(
          bottom: BorderSide(
            color: GlassColors.hairlineStrong.withOpacity(0.42),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: const [
          _HeaderCell(
            flex: 4,
            icon: Icons.text_fields_rounded,
            label: 'PROJECT',
          ),
          _HeaderCell(
            flex: 2,
            icon: Icons.info_outline_rounded,
            label: 'STAGE',
          ),
          _HeaderCell(
            flex: 2,
            icon: Icons.people_outline_rounded,
            label: 'MEMBERS',
          ),
          _HeaderCell(
            flex: 4,
            icon: Icons.insert_drive_file_outlined,
            label: 'DOCS',
          ),
          _HeaderCell(
            flex: 2,
            icon: Icons.calendar_month_rounded,
            label: 'MEETINGS',
          ),
          _ActionsHeaderCell(),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final int flex;
  final IconData icon;
  final String label;

  const _HeaderCell({
    required this.flex,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: GlassColors.onSurfaceVariant.withOpacity(0.4),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GlassText.labelSM().copyWith(
              color: GlassColors.onSurfaceVariant.withOpacity(0.5),
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionsHeaderCell extends StatelessWidget {
  const _ActionsHeaderCell();

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 1,
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          'ACTIONS',
          style: GlassText.labelSM().copyWith(
            color: GlassColors.onSurfaceVariant.withOpacity(0.5),
            fontSize: 11,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}

class _BoardRow extends StatelessWidget {
  final BoardModel board;
  final MemberProfileResolver resolveMemberProfile;
  final BoardAction onOpenBoard;
  final BoardAction onOpenMeetings;
  final BoardAction onEditBoard;
  final BoardAction onDeleteBoard;
  final BoardAction onManageMembers;
  final BoardAction onUploadDocument;
  final BoardDocumentAction onDeleteDocument;

  const _BoardRow({
    required this.board,
    required this.resolveMemberProfile,
    required this.onOpenBoard,
    required this.onOpenMeetings,
    required this.onEditBoard,
    required this.onDeleteBoard,
    required this.onManageMembers,
    required this.onUploadDocument,
    required this.onDeleteDocument,
  });

  @override
  Widget build(BuildContext context) {
    final isTeam = board.type == 'team';
    final projectColor = Color(board.color == 0 ? 0xFF0D40A5 : board.color);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: GlassColors.hairlineStrong.withOpacity(0.42),
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
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
                        onTap: () => onOpenBoard(board),
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
                  _OpenInlineButton(onTap: () => onOpenBoard(board)),
                ],
              ),
            ),
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
                    borderRadius: BorderRadius.circular(ExecutiveRadius.m),
                    border: Border.all(
                      color: GlassColors.hairlineStrong.withOpacity(0.45),
                    ),
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
            Expanded(
              flex: 2,
              child: _MembersCell(
                board: board,
                resolveMemberProfile: resolveMemberProfile,
                onManageMembers: onManageMembers,
              ),
            ),
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
                            (doc) => _DocumentChip(
                              board: board,
                              doc: doc,
                              onDeleteDocument: onDeleteDocument,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(width: 4),
                  _UploadDocButton(onTap: () => onUploadDocument(board)),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _OpenInlineButton(onTap: () => onOpenMeetings(board)),
              ),
            ),
            Expanded(
              flex: 1,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_rounded, size: 14),
                    color: GlassColors.onSurfaceVariant.withOpacity(0.4),
                    onPressed: () => onEditBoard(board),
                    tooltip: 'Rename Board',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 14),
                    color: GlassColors.error.withOpacity(0.5),
                    onPressed: () => onDeleteBoard(board),
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
}

class _OpenInlineButton extends StatelessWidget {
  final VoidCallback onTap;

  const _OpenInlineButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
    );
  }
}

class _MembersCell extends StatelessWidget {
  final BoardModel board;
  final MemberProfileResolver resolveMemberProfile;
  final BoardAction onManageMembers;

  const _MembersCell({
    required this.board,
    required this.resolveMemberProfile,
    required this.onManageMembers,
  });

  @override
  Widget build(BuildContext context) {
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
                  child: _MemberAvatar(
                    uid: displayMembers[idx],
                    resolveMemberProfile: resolveMemberProfile,
                  ),
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
            onPressed: () => onManageMembers(board),
            tooltip: 'Manage Members',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            splashRadius: 12,
          ),
      ],
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  final String uid;
  final MemberProfileResolver resolveMemberProfile;

  const _MemberAvatar({required this.uid, required this.resolveMemberProfile});

  @override
  Widget build(BuildContext context) {
    final profile = resolveMemberProfile(uid);
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
          border: Border.all(color: GlassColors.background, width: 1),
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
}

class _DocumentChip extends StatelessWidget {
  final BoardModel board;
  final Map<String, dynamic> doc;
  final BoardDocumentAction onDeleteDocument;

  const _DocumentChip({
    required this.board,
    required this.doc,
    required this.onDeleteDocument,
  });

  @override
  Widget build(BuildContext context) {
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
                if (url.isEmpty) return;
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
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
            onTap: () => onDeleteDocument(board, doc),
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
}

class _UploadDocButton extends StatelessWidget {
  final VoidCallback onTap;

  const _UploadDocButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
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
}

class _NewProjectRow extends StatelessWidget {
  final VoidCallback onCreateProject;

  const _NewProjectRow({required this.onCreateProject});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onCreateProject,
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
}
