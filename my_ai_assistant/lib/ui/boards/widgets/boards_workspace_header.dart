import 'package:flutter/material.dart';

import '../../../models/workspace_model.dart';
import '../../common/responsive_layout.dart';
import '../../common/workspace_chrome.dart';
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
    final isMobile = Responsive.isMobile(context);

    return WorkspaceChromeHeader(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 16 : ExecutiveSpacing.containerPadding(context),
        isMobile ? 16 : ExecutiveSpacing.containerPadding(context),
        isMobile ? 16 : ExecutiveSpacing.containerPadding(context),
        16,
      ),
      crumbs: [
        const WorkspaceCrumb(icon: Icons.home_rounded, label: 'Workspace HQ'),
        WorkspaceCrumb(
          icon: selectedWorkspace?.type == 'personal'
              ? Icons.person_outline_rounded
              : Icons.group_outlined,
          label: selectedWorkspace?.name ?? 'Workspace',
        ),
      ],
      metaText: 'Project index',
      title: Row(
        children: [
          Text(
            selectedWorkspace?.name ?? 'Projects',
            style: GlassText.headlineMD().copyWith(
              fontWeight: FontWeight.w600,
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
              onPressed: onRenameWorkspace,
            ),
            IconButton(
              icon: const Icon(
                Icons.copy_rounded,
                size: 16,
                color: GlassColors.onSurfaceVariant,
              ),
              tooltip: 'Copy Workspace ID',
              onPressed: onCopyWorkspaceId,
            ),
          ],
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton.icon(
            onPressed: onJoinWorkspace,
            icon: const Icon(
              Icons.group_add_rounded,
              size: 14,
              color: GlassColors.gold,
            ),
            label: Text(
              'Join workspace',
              style: GlassText.bodyMD().copyWith(
                color: GlassColors.gold,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: onCreateProject,
            icon: const Icon(Icons.add_rounded, size: 14),
            label: Text(
              'New project',
              style: GlassText.bodyMD().copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
