import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/board_model.dart';
import '../../../state_managers/state_documents.dart';
import '../../../state_managers/state_meetings.dart';
import '../../theme/glass_theme.dart';

typedef MemberProfileResolver = Map<String, dynamic>? Function(String uid);
typedef BoardAction = void Function(BoardModel board);

class ProjectsTable extends StatelessWidget {
  final List<BoardModel> boards;
  final bool isMobile;
  final MemberProfileResolver resolveMemberProfile;
  final BoardAction onOpenBoard;
  final BoardAction onOpenMeetings;
  final BoardAction onOpenDocs;
  final BoardAction onEditBoard;
  final BoardAction onDeleteBoard;
  final BoardAction onManageMembers;
  final VoidCallback onCreateProject;

  const ProjectsTable({
    super.key,
    required this.boards,
    required this.isMobile,
    required this.resolveMemberProfile,
    required this.onOpenBoard,
    required this.onOpenMeetings,
    required this.onOpenDocs,
    required this.onEditBoard,
    required this.onDeleteBoard,
    required this.onManageMembers,
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
            if (!isMobile) const _ProjectsTableHeader(),
            ...boards.map(
              (board) => _BoardRow(
                board: board,
                isMobile: isMobile,
                resolveMemberProfile: resolveMemberProfile,
                onOpenBoard: onOpenBoard,
                onOpenMeetings: onOpenMeetings,
                onOpenDocs: onOpenDocs,
                onEditBoard: onEditBoard,
                onDeleteBoard: onDeleteBoard,
                onManageMembers: onManageMembers,
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
            flex: 6,
            icon: Icons.text_fields_rounded,
            label: 'PROJECT',
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
  final bool isMobile;
  final MemberProfileResolver resolveMemberProfile;
  final BoardAction onOpenBoard;
  final BoardAction onOpenMeetings;
  final BoardAction onOpenDocs;
  final BoardAction onEditBoard;
  final BoardAction onDeleteBoard;
  final BoardAction onManageMembers;

  const _BoardRow({
    required this.board,
    required this.isMobile,
    required this.resolveMemberProfile,
    required this.onOpenBoard,
    required this.onOpenMeetings,
    required this.onOpenDocs,
    required this.onEditBoard,
    required this.onDeleteBoard,
    required this.onManageMembers,
  });

  @override
  Widget build(BuildContext context) {
    final isTeam = board.type == 'team';
    final projectColor = Color(board.color == 0 ? 0xFF0D40A5 : board.color);
    final mtgCount = context.select<StateMeetings, int>(
      (s) => s.meetingCountForBoard(board.id),
    );
    final docCount = context.select<StateDocuments, int>(
      (s) => s.documentCountForBoard(board.id),
    );

    if (isMobile) {
      return _ProjectMobileCard(
        board: board,
        isTeam: isTeam,
        projectColor: projectColor,
        mtgCount: mtgCount,
        docCount: docCount,
        resolveMemberProfile: resolveMemberProfile,
        onOpenBoard: onOpenBoard,
        onOpenMeetings: onOpenMeetings,
        onOpenDocs: onOpenDocs,
        onEditBoard: onEditBoard,
        onDeleteBoard: onDeleteBoard,
        onManageMembers: onManageMembers,
      );
    }

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
              flex: 6,
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
                  _OpenInlineButton(
                    onTap: () => onOpenBoard(board),
                    labelText: isTeam ? 'OPEN | TEAM' : 'OPEN | PERSONAL',
                  ),
                ],
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
              child: Align(
                alignment: Alignment.centerLeft,
                child: _OpenInlineButton(
                  onTap: () => onOpenDocs(board),
                  count: docCount,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _OpenInlineButton(
                  onTap: () => onOpenMeetings(board),
                  count: mtgCount,
                ),
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

class _OpenInlineButton extends StatefulWidget {
  final VoidCallback onTap;
  final int? count;
  final String? labelText;

  const _OpenInlineButton({
    required this.onTap,
    this.count,
    this.labelText,
  });

  @override
  State<_OpenInlineButton> createState() => _OpenInlineButtonState();
}

class _OpenInlineButtonState extends State<_OpenInlineButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final accent = GlassColors.primary;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: accent.withOpacity(_hovered ? 0.18 : 0.08),
            borderRadius: BorderRadius.circular(ExecutiveRadius.circular),
            border: Border.all(
              color: accent.withOpacity(_hovered ? 0.5 : 0.28),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.labelText ?? 'OPEN',
                style: GlassText.labelSM().copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: accent,
                ),
              ),
              const SizedBox(width: 5),
              Icon(
                Icons.open_in_new_rounded,
                size: 12,
                color: accent,
              ),
              if (widget.count != null) ...[
                const SizedBox(width: 8),
                _CountBadge(count: widget.count!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;

  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final isEmpty = count <= 0;
    return Container(
      constraints: const BoxConstraints(minWidth: 16),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: isEmpty
            ? GlassColors.surfaceBright.withOpacity(0.08)
            : GlassColors.primary.withOpacity(0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isEmpty
              ? GlassColors.hairlineStrong.withOpacity(0.4)
              : GlassColors.primary.withOpacity(0.3),
          width: 0.8,
        ),
      ),
      child: Text(
        isEmpty ? '–' : '$count',
        textAlign: TextAlign.center,
        style: GlassText.labelSM().copyWith(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: isEmpty
              ? GlassColors.onSurfaceVariant.withOpacity(0.5)
              : GlassColors.primary,
        ),
      ),
    );
  }
}

class _ProjectMobileCard extends StatelessWidget {
  final BoardModel board;
  final bool isTeam;
  final Color projectColor;
  final int mtgCount;
  final int docCount;
  final MemberProfileResolver resolveMemberProfile;
  final BoardAction onOpenBoard;
  final BoardAction onOpenMeetings;
  final BoardAction onOpenDocs;
  final BoardAction onEditBoard;
  final BoardAction onDeleteBoard;
  final BoardAction onManageMembers;

  const _ProjectMobileCard({
    required this.board,
    required this.isTeam,
    required this.projectColor,
    required this.mtgCount,
    required this.docCount,
    required this.resolveMemberProfile,
    required this.onOpenBoard,
    required this.onOpenMeetings,
    required this.onOpenDocs,
    required this.onEditBoard,
    required this.onDeleteBoard,
    required this.onManageMembers,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GlassColors.surfaceBright.withOpacity(0.03),
        borderRadius: BorderRadius.circular(ExecutiveRadius.l),
        border: Border.all(
          color: GlassColors.hairlineStrong.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: dot + name + edit/delete
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: projectColor,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => onOpenBoard(board),
                  child: Text(
                    board.name,
                    style: GlassText.bodyMD().copyWith(
                      fontWeight: FontWeight.w700,
                      color: GlassColors.onSurface,
                      fontSize: 15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.edit_rounded, size: 18),
                color: GlassColors.onSurfaceVariant.withOpacity(0.55),
                onPressed: () => onEditBoard(board),
                tooltip: 'Rename Board',
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                color: GlassColors.error.withOpacity(0.6),
                onPressed: () => onDeleteBoard(board),
                tooltip: 'Delete Board',
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Members
          _MembersCell(
            board: board,
            resolveMemberProfile: resolveMemberProfile,
            onManageMembers: onManageMembers,
          ),
          const SizedBox(height: 14),
          // Open board button (enter Kanban)
          InkWell(
            onTap: () => onOpenBoard(board),
            borderRadius: BorderRadius.circular(ExecutiveRadius.m),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 44),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: GlassColors.gold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(ExecutiveRadius.m),
                border: Border.all(
                  color: GlassColors.gold.withOpacity(0.4),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.dashboard_customize_rounded,
                    size: 17,
                    color: GlassColors.gold,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isTeam ? 'OPEN BOARD | TEAM' : 'OPEN BOARD | PERSONAL',
                    style: GlassText.labelSM().copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: GlassColors.gold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Docs + Meetings open tiles
          Row(
            children: [
              Expanded(
                child: _MobileOpenTile(
                  icon: Icons.insert_drive_file_outlined,
                  label: 'DOCS',
                  count: docCount,
                  onTap: () => onOpenDocs(board),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MobileOpenTile(
                  icon: Icons.calendar_month_rounded,
                  label: 'MEETINGS',
                  count: mtgCount,
                  onTap: () => onOpenMeetings(board),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MobileOpenTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final VoidCallback onTap;

  const _MobileOpenTile({
    required this.icon,
    required this.label,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ExecutiveRadius.m),
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: GlassColors.primary.withOpacity(0.06),
          borderRadius: BorderRadius.circular(ExecutiveRadius.m),
          border: Border.all(
            color: GlassColors.primary.withOpacity(0.25),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: GlassColors.primary.withOpacity(0.75)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GlassText.labelSM().copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: GlassColors.primary.withOpacity(0.85),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _CountBadge(count: count),
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
