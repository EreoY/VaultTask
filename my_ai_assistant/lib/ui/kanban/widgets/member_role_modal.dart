import 'package:flutter/material.dart';
import '../../common/ime_safe_text_field.dart';
import 'package:provider/provider.dart';
import '../../../models/board_model.dart';
import '../../../state_managers/state_boards.dart';
import '../../../services/auth_service.dart';
import '../../theme/glass_theme.dart';
import '../../common/glass_widgets.dart';

class MemberRoleModal extends StatefulWidget {
  final BoardModel board;
  const MemberRoleModal({super.key, required this.board});

  @override
  State<MemberRoleModal> createState() => _MemberRoleModalState();
}

class _MemberRoleModalState extends State<MemberRoleModal> {
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    for (final uid in widget.board.members) {
      _controllers[uid] = TextEditingController(text: widget.board.memberRoles[uid] ?? '');
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _saveRole(String uid, String role) async {
    final updatedRoles = Map<String, String>.from(widget.board.memberRoles);
    updatedRoles[uid] = role;
    final updatedBoard = widget.board.copyWith(memberRoles: updatedRoles);
    await context.read<StateBoards>().updateBoard(updatedBoard);
  }

  @override
  Widget build(BuildContext context) {
    final boardState = context.watch<StateBoards>();
    final currentUid = AuthService().currentUser?.uid;
    final isOwner = widget.board.ownerUid == currentUid;
    
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: GlassDecorations.surface(radius: 32, hasShadow: true),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 48),
          _buildSectionTitle('CLUSTER OPERATIVES & DESIGNATIONS'),
          const SizedBox(height: 24),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: widget.board.members.map((uid) {
                final profile = boardState.getMemberProfile(uid);
                final name = profile?['name'] ?? uid;
                final photo = profile?['photo'] ?? '';
                final color = GlassColors.getMemberColor(uid);
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: color.withOpacity(0.15),
                        backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                        child: photo.isEmpty ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: GlassText.labelSM().copyWith(color: color)) : null,
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: GlassText.bodyMD().copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            ImeSafeTextField(
                              controller: _controllers[uid],
                              style: GlassText.labelSM().copyWith(color: GlassColors.primary),
                              onSubmitted: (v) => _saveRole(uid, v),
                              decoration: InputDecoration(
                                hintText: 'Set Designation (e.g. Lead Developer)',
                                hintStyle: GlassText.labelSM().copyWith(color: GlassColors.onSurfaceVariant.withOpacity(0.3)),
                                isDense: true,
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isOwner && uid != widget.board.ownerUid)
                        IconButton(
                          icon: const Icon(Icons.person_remove_rounded, color: GlassColors.error, size: 20),
                          onPressed: () => _confirmRemoveMember(context, uid, name),
                          tooltip: 'Remove Operative',
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 48),
          Center(
            child: _buildGhostButton('DONE', () => Navigator.pop(context), isPrimary: true),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'BOARD GOVERNANCE',
          style: GlassText.labelSM().copyWith(letterSpacing: 2.0, color: GlassColors.gold),
        ),
        IconButton(
          icon: const Icon(Icons.close_rounded, size: 24),
          onPressed: () => Navigator.pop(context),
          color: GlassColors.onSurfaceVariant.withOpacity(0.5),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GlassText.labelSM().copyWith(fontSize: 10, color: GlassColors.onSurfaceVariant.withOpacity(0.5), letterSpacing: 1.5),
    );
  }

  void _confirmRemoveMember(BuildContext context, String uid, String name) {
    showDialog(
      context: context,
      builder: (context) => Center(
        child: Container(
          width: 400,
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: GlassDecorations.surface(radius: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('REMOVE OPERATIVE', style: GlassText.labelSM().copyWith(color: GlassColors.error, letterSpacing: 2)),
              const SizedBox(height: 24),
              Text('Are you sure you want to remove $name from this board?', style: GlassText.bodyMD()),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: GlassColors.ghostBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('CANCEL', style: GlassText.labelSM().copyWith(color: GlassColors.onSurfaceVariant)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          await context.read<StateBoards>().removeMember(widget.board, uid);
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to remove member: $e')),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GlassColors.error,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('REMOVE', style: GlassText.labelSM().copyWith(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGhostButton(String label, VoidCallback onTap, {bool isPrimary = false}) {
    final color = isPrimary ? GlassColors.gold : GlassColors.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ExecutiveRadius.circular),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
        decoration: BoxDecoration(
          color: isPrimary ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(ExecutiveRadius.circular),
          border: Border.all(color: color.withOpacity(isPrimary ? 0.3 : 0.1)),
        ),
        child: Text(
          label,
          style: GlassText.labelSM().copyWith(
            color: color.withOpacity(isPrimary ? 1.0 : 0.6),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
