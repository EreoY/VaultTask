import 'package:flutter/material.dart';

import '../../../models/workspace_model.dart';
import '../../common/bouncy_soft_button.dart';
import '../../common/responsive_layout.dart';
import '../../theme/glass_theme.dart';

class BoardsWorkspaceHeader extends StatelessWidget {
  final WorkspaceModel? selectedWorkspace;
  final VoidCallback onJoinWorkspace;
  final VoidCallback onCreateProject;
  final VoidCallback? onRenameWorkspace;
  final VoidCallback? onCopyWorkspaceId;

  const BoardsWorkspaceHeader({
    super.key,
    required this.selectedWorkspace,
    required this.onJoinWorkspace,
    required this.onCreateProject,
    this.onRenameWorkspace,
    this.onCopyWorkspaceId,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = Responsive.isMobile(context);
    final isTeam = selectedWorkspace?.type != 'personal';

    // Dynamic width for text & dynamic size/position for 3D graphic
    final double maxTextWidth = isMobile ? (screenWidth - 88) * 0.52 : 460;
    final double heroImageWidth = isMobile ? 130 : 210;
    final double heroImageRight = isMobile ? 24 : 48; // Shifted inward from right edge
    final double heroImageTop = isMobile ? 12 : -24;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 16 : ExecutiveSpacing.containerPadding(context),
        isMobile ? 12 : 16,
        isMobile ? 16 : ExecutiveSpacing.containerPadding(context),
        12,
      ),
      child: Stack(
        clipBehavior: Clip.none, // 3D Elements popping out effect
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(isMobile ? 18 : 24),
            decoration: BoxDecoration(
              color: GlassColors.bentoLavender,
              borderRadius: BorderRadius.circular(ExecutiveRadius.xxl), // 32px
              boxShadow: [
                BoxShadow(
                  color: GlassColors.bentoLavender.withOpacity(0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: Category Badge & Workspace Actions (Rename & Copy)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isTeam ? Icons.group_outlined : Icons.person_outline_rounded,
                            size: 14,
                            color: GlassColors.deepBlack,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isTeam ? 'TEAM WORKSPACE' : 'PERSONAL WORKSPACE',
                            style: GlassText.labelSM().copyWith(
                              color: GlassColors.deepBlack,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (selectedWorkspace != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (onRenameWorkspace != null)
                            IconButton(
                              icon: const Icon(Icons.edit_rounded, size: 18),
                              color: GlassColors.deepBlack.withOpacity(0.7),
                              onPressed: onRenameWorkspace,
                              tooltip: 'Rename Workspace',
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(6),
                            ),
                          if (onCopyWorkspaceId != null) ...[
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.copy_rounded, size: 18),
                              color: GlassColors.deepBlack.withOpacity(0.7),
                              onPressed: onCopyWorkspaceId,
                              tooltip: 'Copy Workspace ID',
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(6),
                            ),
                          ],
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Row 2: Workspace Name & Subtitle
                SizedBox(
                  width: maxTextWidth,
                  child: Text(
                    selectedWorkspace?.name ?? 'Projects Hub',
                    style: GlassText.headlineMD().copyWith(
                      fontWeight: FontWeight.w800,
                      color: GlassColors.deepBlack,
                      fontSize: isMobile ? 20 : 26,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: maxTextWidth,
                  child: Text(
                    'Organize team boards, docs, and meetings in a unified space.',
                    style: GlassText.secondary().copyWith(
                      color: GlassColors.deepBlack.withOpacity(0.75),
                      fontSize: isMobile ? 12 : 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 16),

                // Row 3: Action Buttons (Join & New Project)
                SizedBox(
                  width: maxTextWidth,
                  child: Row(
                    children: [
                      Expanded(
                        child: BouncySoftButton.orange(
                          text: 'Join Workspace',
                          icon: Icons.group_add_rounded,
                          onPressed: onJoinWorkspace,
                          fontSize: isMobile ? 12 : 13,
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 8 : 16,
                            vertical: isMobile ? 10 : 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: BouncySoftButton.dark(
                          text: 'New Project',
                          icon: Icons.add_rounded,
                          onPressed: onCreateProject,
                          fontSize: isMobile ? 12 : 13,
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 8 : 16,
                            vertical: isMobile ? 10 : 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3D Illustration popping out on the right (shifted inward)
          Positioned(
            right: heroImageRight,
            top: heroImageTop,
            bottom: isMobile ? 12 : -10,
            child: IgnorePointer(
              child: SizedBox(
                width: heroImageWidth,
                child: Image.asset(
                  'assets/images/workspace.png',
                  fit: BoxFit.contain,
                  alignment: Alignment.centerRight,
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
