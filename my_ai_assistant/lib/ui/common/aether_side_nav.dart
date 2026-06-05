import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../state_managers/state_boards.dart';
import '../../models/workspace_model.dart';
import '../boards/widgets/board_edit_modal.dart';
import '../theme/glass_theme.dart';
import 'ime_safe_text_field.dart';

class AetherSideNav extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final bool isDark;

  const AetherSideNav({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? user?.email?.split('@').first ?? 'Commander';
    final stateBoards = context.watch<StateBoards>();

    return Container(
      width: 260,
      height: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 64, 24, 32),
      decoration: BoxDecoration(
        color: GlassColors.surface,
        border: Border(
          right: BorderSide(color: GlassColors.ghostBorder, width: 1.0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand Title (Top Left)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Aether AI',
                style: GlassText.headlineMD().copyWith(
                  color: GlassColors.onSurface,
                  fontWeight: FontWeight.w700,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Hello, $displayName',
                style: GlassText.bodyMD().copyWith(
                  color: GlassColors.onSurfaceVariant.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Navigation & Workspaces Section
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main Navigation Menu
                  Column(
                    children: [
                      _NavItem(
                        icon: Icons.dashboard_outlined,
                        label: 'Dashboard',
                        isActive: selectedIndex == 0,
                        onTap: () => onItemSelected(0),
                      ),
                      _NavItem(
                        icon: Icons.grid_view_rounded,
                        label: 'Boards',
                        isActive: selectedIndex == 1,
                        onTap: () => onItemSelected(1),
                      ),
                      _NavItem(
                        icon: Icons.calendar_today_outlined,
                        label: 'Calendar',
                        isActive: selectedIndex == 2,
                        onTap: () => onItemSelected(2),
                      ),
                      _NavItem(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: 'Chat',
                        isActive: selectedIndex == 3,
                        onTap: () => onItemSelected(3),
                      ),
                      _NavItem(
                        icon: Icons.person_outline_rounded,
                        label: 'Profile',
                        isActive: selectedIndex == 4,
                        onTap: () => onItemSelected(4),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Divider(color: GlassColors.ghostBorder, height: 1),
                  const SizedBox(height: 16),
                  
                  // Workspaces Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'WORKSPACES',
                        style: GlassText.labelSM().copyWith(
                          color: GlassColors.onSurfaceVariant.withOpacity(0.4),
                          fontSize: 11,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_rounded, size: 16),
                        onPressed: () => _showAddWorkspaceDialog(context, stateBoards),
                        color: GlassColors.gold,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        splashRadius: 16,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Workspaces & Projects Hierarchy List
                  ...stateBoards.workspaces.map((workspace) {
                    final isSelected = stateBoards.selectedWorkspace?.id == workspace.id;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Workspace Header Row
                        InkWell(
                          onTap: () {
                            stateBoards.setSelectedWorkspace(workspace);
                            onItemSelected(1); // Navigates to Boards Page
                          },
                          borderRadius: BorderRadius.circular(ExecutiveRadius.l),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            child: Row(
                              children: [
                                Icon(
                                  workspace.type == 'personal' ? Icons.person_rounded : Icons.group_rounded,
                                  size: 16,
                                  color: isSelected ? GlassColors.primary : GlassColors.onSurfaceVariant.withOpacity(0.5),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    workspace.name,
                                    style: GlassText.bodyMD().copyWith(
                                      fontSize: 13,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                      color: isSelected ? GlassColors.onSurface : GlassColors.onSurfaceVariant.withOpacity(0.8),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                // Action Button: Add Board
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline_rounded, size: 14),
                                  onPressed: () {
                                    showModalBottomSheet(
                                      context: context,
                                      backgroundColor: Colors.transparent,
                                      isScrollControlled: true,
                                      builder: (context) => BoardEditModal(isDark: isDark, workspace: workspace),
                                    );
                                  },
                                  color: GlassColors.gold.withOpacity(0.6),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  splashRadius: 12,
                                ),
                                const SizedBox(width: 6),
                                // Delete Workspace Button (if not default)
                                if (workspace.id != 'default_personal' && !workspace.id.startsWith('default_team_'))
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, size: 14),
                                    onPressed: () => _showDeleteWorkspaceConfirmDialog(context, stateBoards, workspace),
                                    color: GlassColors.error.withOpacity(0.6),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    splashRadius: 12,
                                  ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Profile Avatar at Bottom
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: GlassColors.outlineVariant.withOpacity(0.2), width: 1),
              image: user?.photoURL != null 
                ? DecorationImage(
                    image: NetworkImage(user!.photoURL!),
                    fit: BoxFit.cover,
                  )
                : null,
            ),
            child: user?.photoURL == null 
              ? const Icon(Icons.person_outline_rounded, size: 24, color: GlassColors.primary)
              : null,
          ),
        ],
      ),
    );
  }

  void _showAddWorkspaceDialog(BuildContext context, StateBoards stateBoards) {
    final nameController = TextEditingController();
    String type = 'personal';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Center(
          child: Container(
            width: 400,
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(32),
            decoration: GlassDecorations.solidSurface(radius: 24, hasShadow: true),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CREATE NEW WORKSPACE', style: GlassText.labelSM().copyWith(color: GlassColors.primary, letterSpacing: 2)),
                  const SizedBox(height: 24),
                  ImeSafeTextField(
                    controller: nameController,
                    autofocus: true,
                    style: GlassText.bodyLG(),
                    decoration: InputDecoration(
                      hintText: 'Workspace Name',
                      hintStyle: GlassText.bodyLG().copyWith(color: GlassColors.onSurfaceVariant.withOpacity(0.3)),
                      filled: true,
                      fillColor: GlassColors.primary.withOpacity(0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('TYPE', style: GlassText.labelSM().copyWith(color: GlassColors.onSurfaceVariant.withOpacity(0.5))),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => type = 'personal'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: type == 'personal' ? GlassColors.primary.withOpacity(0.1) : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: type == 'personal' ? GlassColors.primary : GlassColors.ghostBorder),
                            ),
                            child: Column(
                              children: [
                                const Icon(Icons.person_rounded, size: 20, color: GlassColors.onSurface),
                                const SizedBox(height: 4),
                                Text('Personal', style: GlassText.bodyMD()),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => type = 'team'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: type == 'team' ? GlassColors.primary.withOpacity(0.1) : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: type == 'team' ? GlassColors.primary : GlassColors.ghostBorder),
                            ),
                            child: Column(
                              children: [
                                const Icon(Icons.group_rounded, size: 20, color: GlassColors.onSurface),
                                const SizedBox(height: 4),
                                Text('Team', style: GlassText.bodyMD()),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('CANCEL', style: GlassText.labelSM().copyWith(color: GlassColors.onSurfaceVariant)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final name = nameController.text.trim();
                            if (name.isEmpty) return;
                            try {
                              await stateBoards.addWorkspace(name, type);
                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to add workspace: $e')),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GlassColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('CREATE', style: GlassText.labelSM().copyWith(color: GlassColors.onPrimary, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteWorkspaceConfirmDialog(BuildContext context, StateBoards stateBoards, WorkspaceModel workspace) {
    showDialog(
      context: context,
      builder: (context) => Center(
        child: Container(
          width: 400,
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: GlassDecorations.solidSurface(radius: 24, hasShadow: true),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DELETE WORKSPACE', style: GlassText.labelSM().copyWith(color: GlassColors.error, letterSpacing: 2)),
                const SizedBox(height: 24),
                Text(
                  'Are you sure you want to delete workspace "${workspace.name}"? All projects within it will be deleted/dissociated.',
                  style: GlassText.bodyMD().copyWith(color: GlassColors.onSurfaceVariant),
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
                            await stateBoards.deleteWorkspace(workspace);
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to delete workspace: $e')),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GlassColors.error,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('DELETE', style: GlassText.labelSM().copyWith(color: Colors.black, fontWeight: FontWeight.bold)),
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

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ExecutiveRadius.xl),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: isActive
              ? BoxDecoration(
                  color: GlassColors.surfaceBright,
                  borderRadius: BorderRadius.circular(ExecutiveRadius.xl),
                )
              : null,
          child: Row(
            children: [
              Icon(
                icon,
                color: isActive ? GlassColors.onSurface : GlassColors.onSurfaceVariant.withOpacity(0.6),
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: GlassText.bodyMD().copyWith(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive ? GlassColors.onSurface : GlassColors.onSurfaceVariant.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
