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
      height: 42,
      margin: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : ExecutiveSpacing.containerPadding(context),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: workspaces.length,
        itemBuilder: (context, index) {
          final workspace = workspaces[index];
          final isSelected = selectedWorkspaceId == workspace.id;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onSelectWorkspace(workspace),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? GlassColors.deepBlack : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? GlassColors.deepBlack
                            : GlassColors.outlineVariant,
                        width: 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: GlassColors.deepBlack.withOpacity(0.12),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          workspace.type == 'personal'
                              ? Icons.person_outline_rounded
                              : Icons.group_outlined,
                          size: 15,
                          color: isSelected
                              ? Colors.white
                              : GlassColors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          workspace.name,
                          style: GlassText.bodyMD().copyWith(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : GlassColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

