import 'package:flutter/material.dart';

import '../../../models/workspace_model.dart';
import '../../common/responsive_layout.dart';
import '../../theme/glass_theme.dart';

class BoardsWorkspaceTabs extends StatelessWidget {
  final List<WorkspaceModel> workspaces;
  final String? selectedWorkspaceId;
  final ValueChanged<WorkspaceModel> onSelectWorkspace;

  const BoardsWorkspaceTabs({
    super.key,
    required this.workspaces,
    required this.selectedWorkspaceId,
    required this.onSelectWorkspace,
  });

  @override
  Widget build(BuildContext context) {
    if (workspaces.isEmpty) return const SizedBox.shrink();
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
        itemCount: workspaces.length,
        itemBuilder: (context, index) {
          final workspace = workspaces[index];
          final isSelected = selectedWorkspaceId == workspace.id;

          return GestureDetector(
            onTap: () => onSelectWorkspace(workspace),
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
}
