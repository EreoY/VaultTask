import 'package:flutter/material.dart';

import '../../../models/board_model.dart';
import '../../theme/glass_theme.dart';
import 'package:provider/provider.dart';
import '../../../state_managers/state_tasks.dart';
import '../../../state_managers/state_documents.dart';
import '../../../state_managers/state_meetings.dart';

typedef MemberProfileResolver = Map<String, dynamic>? Function(String uid);
typedef BoardAction = void Function(BoardModel board);

class BentoProjectCard extends StatelessWidget {
  final BoardModel board;
  final int index;
  final MemberProfileResolver resolveMemberProfile;
  final BoardAction onOpenBoard;
  final BoardAction onOpenMeetings;
  final BoardAction onOpenDocs;
  final BoardAction onEditBoard;
  final BoardAction onDeleteBoard;
  final BoardAction onManageMembers;

  static const List<Color> pastelPalette = [
    GlassColors.bentoLavender,
    GlassColors.bentoOrange,
    GlassColors.bentoBlue,
    GlassColors.bentoPink,
  ];

  const BentoProjectCard({
    super.key,
    required this.board,
    required this.index,
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
    final tasksCount = context.watch<StateTasks>().tasksForBoard(board.id).length;
    final docsCount = context.watch<StateDocuments>().documentCountForBoard(board.id);
    final meetingsCount = context.watch<StateMeetings>().meetingCountForBoard(board.id);

    final cardColor = pastelPalette[index % pastelPalette.length];
    final isTeam = board.type == 'team';
    final dotColor = Color(board.color == 0 ? 0xFF0D40A5 : board.color);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(ExecutiveRadius.xl), // 24px
        boxShadow: [
          BoxShadow(
            color: cardColor.withOpacity(0.6),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Header Row: Color Dot + Title + Type Pill + Actions Popup
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotColor,
                    boxShadow: [
                      BoxShadow(
                        color: dotColor.withOpacity(0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    board.name,
                    style: GlassText.headlineMD().copyWith(
                      fontWeight: FontWeight.w800,
                      color: GlassColors.deepBlack,
                      fontSize: 18,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isTeam ? 'Team' : 'Personal',
                    style: GlassText.labelSM().copyWith(
                      fontSize: 11,
                      color: GlassColors.deepBlack,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    size: 20,
                    color: GlassColors.deepBlack,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  onSelected: (value) {
                    if (value == 'edit') onEditBoard(board);
                    if (value == 'members') onManageMembers(board);
                    if (value == 'delete') onDeleteBoard(board);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded, size: 16, color: GlassColors.deepBlack),
                          SizedBox(width: 8),
                          Text('Edit Name'),
                        ],
                      ),
                    ),
                    if (isTeam)
                      const PopupMenuItem(
                        value: 'members',
                        child: Row(
                          children: [
                            Icon(Icons.people_outline_rounded, size: 16, color: GlassColors.deepBlack),
                            SizedBox(width: 8),
                            Text('Manage Members'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, size: 16, color: GlassColors.error),
                          SizedBox(width: 8),
                          Text('Delete Project', style: TextStyle(color: GlassColors.error)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Members Row
            _BentoMembersRow(
              board: board,
              resolveMemberProfile: resolveMemberProfile,
              onManageMembers: onManageMembers,
            ),
            const SizedBox(height: 16),

            // Bottom Actions Row (3 Soft White Pill Buttons)
            Row(
              children: [
                Expanded(
                  child: _BentoActionButton(
                    label: tasksCount > 0 ? '$tasksCount Tasks' : 'Board',
                    icon: Icons.dashboard_rounded,
                    onTap: () => onOpenBoard(board),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _BentoActionButton(
                    label: docsCount > 0 ? '$docsCount Docs' : 'Docs',
                    icon: Icons.insert_drive_file_outlined,
                    onTap: () => onOpenDocs(board),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _BentoActionButton(
                    label: meetingsCount > 0 ? '$meetingsCount Meetings' : 'Meetings',
                    icon: Icons.mic_rounded,
                    onTap: () => onOpenMeetings(board),
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

class _BentoActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _BentoActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: GlassColors.deepBlack),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: GlassText.bodyMD().copyWith(
                    fontWeight: FontWeight.w700,
                    color: GlassColors.deepBlack,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BentoMembersRow extends StatelessWidget {
  final BoardModel board;
  final MemberProfileResolver resolveMemberProfile;
  final BoardAction onManageMembers;

  const _BentoMembersRow({
    required this.board,
    required this.resolveMemberProfile,
    required this.onManageMembers,
  });

  @override
  Widget build(BuildContext context) {
    final members = board.members;

    if (members.isEmpty) {
      return GestureDetector(
        onTap: () => onManageMembers(board),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.add_rounded,
                size: 14,
                color: GlassColors.deepBlack,
              ),
              const SizedBox(width: 4),
              Text(
                'Add Member',
                style: GlassText.labelSM().copyWith(
                  color: GlassColors.deepBlack,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => onManageMembers(board),
      child: Row(
        children: [
          SizedBox(
            height: 24,
            width: (members.length > 4 ? 4 : members.length) * 16.0 + 8,
            child: Stack(
              children: List.generate(
                members.length > 4 ? 4 : members.length,
                (index) => Positioned(
                  left: index * 16.0,
                  child: _BentoMemberAvatar(
                    uid: members[index],
                    resolveMemberProfile: resolveMemberProfile,
                  ),
                ),
              ),
            ),
          ),
          if (members.length > 4) ...[
            const SizedBox(width: 6),
            Text(
              '+${members.length - 4}',
              style: GlassText.labelSM().copyWith(
                fontSize: 11,
                color: GlassColors.deepBlack.withOpacity(0.8),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BentoMemberAvatar extends StatelessWidget {
  final String uid;
  final MemberProfileResolver resolveMemberProfile;

  const _BentoMemberAvatar({
    required this.uid,
    required this.resolveMemberProfile,
  });

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
          fontSize: 9,
          color: GlassColors.deepBlack,
          fontWeight: FontWeight.w800,
        ),
      ),
    );

    return Tooltip(
      message: name,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1.5),
          color: GlassColors.bentoLavender,
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
