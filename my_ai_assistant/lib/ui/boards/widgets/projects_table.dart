import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/board_model.dart';
import '../../common/bouncy_soft_button.dart';
import '../../theme/glass_theme.dart';
import 'bento_project_card.dart';

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
    final paddingHorizontal = isMobile ? 16.0 : ExecutiveSpacing.containerPadding(context);

    if (boards.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: paddingHorizontal, vertical: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: GlassColors.surface,
            borderRadius: BorderRadius.circular(ExecutiveRadius.xxl),
            border: Border.all(color: GlassColors.outlineVariant),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: GlassColors.bentoLavender,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.folder_open_rounded,
                  size: 36,
                  color: GlassColors.deepBlack,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No Projects In Workspace',
                style: GlassText.headlineMD().copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Get started by creating your first project board.',
                style: GlassText.secondary(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              BouncySoftButton.dark(
                text: 'Create New Project',
                icon: Icons.add_rounded,
                onPressed: onCreateProject,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ],
          ),
        ),
      );
    }

    if (isMobile) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            ...List.generate(
              boards.length,
              (index) => BentoProjectCard(
                board: boards[index],
                index: index,
                resolveMemberProfile: resolveMemberProfile,
                onOpenBoard: onOpenBoard,
                onOpenMeetings: onOpenMeetings,
                onOpenDocs: onOpenDocs,
                onEditBoard: onEditBoard,
                onDeleteBoard: onDeleteBoard,
                onManageMembers: onManageMembers,
              ),
            ),
            _MobileNewProjectButton(onCreateProject: onCreateProject),
          ],
        ),
      );
    }

    // Desktop Layout: Responsive Bento Grid Layout (2 Columns)
    final crossAxisCount = MediaQuery.of(context).size.width > 1200 ? 3 : 2;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ExecutiveSpacing.containerPadding(context),
        vertical: 8,
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          mainAxisExtent: 185,
        ),
        itemCount: boards.length + 1, // +1 for New Project Card
        itemBuilder: (context, index) {
          if (index == boards.length) {
            return _DesktopNewProjectCard(onCreateProject: onCreateProject);
          }
          return BentoProjectCard(
            board: boards[index],
            index: index,
            resolveMemberProfile: resolveMemberProfile,
            onOpenBoard: onOpenBoard,
            onOpenMeetings: onOpenMeetings,
            onOpenDocs: onOpenDocs,
            onEditBoard: onEditBoard,
            onDeleteBoard: onDeleteBoard,
            onManageMembers: onManageMembers,
          );
        },
      ),
    );
  }
}

class _DesktopNewProjectCard extends StatelessWidget {
  final VoidCallback onCreateProject;

  const _DesktopNewProjectCard({required this.onCreateProject});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onCreateProject,
        borderRadius: BorderRadius.circular(ExecutiveRadius.xl),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(ExecutiveRadius.xl),
            border: Border.all(
              color: GlassColors.outlineVariant,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: GlassColors.bentoOrange,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_rounded,
                  size: 24,
                  color: GlassColors.deepBlack,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'New Project',
                style: GlassText.bodyLG().copyWith(
                  fontWeight: FontWeight.w800,
                  color: GlassColors.deepBlack,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Add board to workspace',
                style: GlassText.secondary().copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileNewProjectButton extends StatelessWidget {
  final VoidCallback onCreateProject;

  const _MobileNewProjectButton({required this.onCreateProject});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 16),
      child: BouncySoftButton.lavender(
        text: 'Create New Project',
        icon: Icons.add_circle_outline_rounded,
        onPressed: onCreateProject,
        width: double.infinity,
        fontSize: 15,
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}
