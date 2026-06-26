import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/board_model.dart';
import '../../../services/auth_service.dart';
import '../../../state_managers/state_boards.dart';
import '../../common/responsive_layout.dart';
import '../../common/workspace_chrome.dart';
import '../../theme/glass_theme.dart';

class KanbanWorkspaceHeader extends StatelessWidget {
  final BoardModel board;
  final bool isCalendarMode;
  final bool isSelectMode;
  final bool isOverviewMode;
  final bool filterAllSelected;
  final bool filterMineSelected;
  final bool filterSelectSelected;
  final String selectFilterLabel;
  final VoidCallback onBack;
  final VoidCallback onShowColumnSettings;
  final VoidCallback onToggleSelectMode;
  final VoidCallback onShowAddTask;
  final VoidCallback onShowBoardInfo;
  final VoidCallback onShowRenameBoard;
  final VoidCallback onShowRoleManager;
  final VoidCallback onToggleOverview;
  final VoidCallback onSelectBoardView;
  final VoidCallback onSelectCalendarView;
  final VoidCallback onSetFilterAll;
  final VoidCallback onSetFilterMine;
  final VoidCallback onTapSelectFilter;

  const KanbanWorkspaceHeader({
    super.key,
    required this.board,
    required this.isCalendarMode,
    required this.isSelectMode,
    required this.isOverviewMode,
    required this.filterAllSelected,
    required this.filterMineSelected,
    required this.filterSelectSelected,
    required this.selectFilterLabel,
    required this.onBack,
    required this.onShowColumnSettings,
    required this.onToggleSelectMode,
    required this.onShowAddTask,
    required this.onShowBoardInfo,
    required this.onShowRenameBoard,
    required this.onShowRoleManager,
    required this.onToggleOverview,
    required this.onSelectBoardView,
    required this.onSelectCalendarView,
    required this.onSetFilterAll,
    required this.onSetFilterMine,
    required this.onTapSelectFilter,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);

    return Column(
      children: [
        WorkspaceChromeHeader(
          padding: EdgeInsets.fromLTRB(
            ExecutiveSpacing.containerPadding(context),
            isMobile ? 16 : ExecutiveSpacing.containerPadding(context),
            ExecutiveSpacing.containerPadding(context),
            16,
          ),
          crumbs: [
            WorkspaceCrumb(
              icon: Icons.home_rounded,
              label: 'Workspace HQ',
              onTap: onBack,
            ),
            WorkspaceCrumb(label: board.name),
          ],
          metaText:
              '${board.type.toUpperCase()} PROJECT • ${board.columns.length} STRATEGIC PHASES',
          title: Row(
            children: [
              _ActionOutlineButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: onBack,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        board.name,
                        overflow: TextOverflow.ellipsis,
                        style: GlassText.headlineLG().copyWith(
                          fontSize: isTablet ? 30 : 36,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _KanbanBoardMenu(
                      board: board,
                      isOverviewMode: isOverviewMode,
                      onToggleOverview: onToggleOverview,
                      onShowBoardInfo: onShowBoardInfo,
                      onShowRenameBoard: onShowRenameBoard,
                      onShowRoleManager: onShowRoleManager,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 32,
            vertical: 0,
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.03),
                              borderRadius: BorderRadius.circular(
                                ExecutiveRadius.xl,
                              ),
                              border: Border.all(
                                color: GlassColors.hairlineStrong.withOpacity(
                                  0.65,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _SegmentButton(
                                  label: 'BOARD',
                                  icon: Icons.dashboard_customize_outlined,
                                  isActive: !isCalendarMode,
                                  isMobile: isMobile,
                                  onTap: onSelectBoardView,
                                ),
                                _SegmentButton(
                                  label: 'CALENDAR',
                                  icon: Icons.calendar_month_rounded,
                                  isActive: isCalendarMode,
                                  isMobile: isMobile,
                                  onTap: onSelectCalendarView,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          _KanbanFilterToggleBar(
                            board: board,
                            isMobile: isMobile,
                            allSelected: filterAllSelected,
                            mineSelected: filterMineSelected,
                            selectSelected: filterSelectSelected,
                            selectFilterLabel: selectFilterLabel,
                            onSetFilterAll: onSetFilterAll,
                            onSetFilterMine: onSetFilterMine,
                            onTapSelectFilter: onTapSelectFilter,
                          ),
                          const SizedBox(width: 12),
                          _BoardAvatarStack(board: board),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isMobile) ...[
                        _GhostButton(
                          label: 'ADD PHASE',
                          icon: Icons.view_column_rounded,
                          onTap: onShowColumnSettings,
                        ),
                        const SizedBox(width: 12),
                        _GhostButton(
                          label: isSelectMode ? 'EXIT BULK' : 'BULK ACTION',
                          icon: Icons.checklist_rtl_rounded,
                          onTap: onToggleSelectMode,
                        ),
                        const SizedBox(width: 12),
                        _GhostButton(
                          label: 'NEW TASK',
                          icon: Icons.add_rounded,
                          onTap: onShowAddTask,
                        ),
                      ] else ...[
                        _ActionIconButton(
                          icon: Icons.view_column_rounded,
                          onTap: onShowColumnSettings,
                        ),
                        const SizedBox(width: 8),
                        _ActionIconButton(
                          icon: isSelectMode
                              ? Icons.checklist_rounded
                              : Icons.checklist_rtl_rounded,
                          onTap: onToggleSelectMode,
                          color: isSelectMode ? GlassColors.gold : null,
                        ),
                        const SizedBox(width: 8),
                        _ActionIconButton(
                          icon: Icons.add_rounded,
                          onTap: onShowAddTask,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                height: 1,
                color: GlassColors.hairlineStrong.withOpacity(0.42),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class KanbanBulkToolbar extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onMove;
  final VoidCallback onExport;
  final VoidCallback onClear;

  const KanbanBulkToolbar({
    super.key,
    required this.selectedCount,
    required this.onMove,
    required this.onExport,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24,
        vertical: 16,
      ),
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 0),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        borderRadius: BorderRadius.circular(ExecutiveRadius.circular),
        border: Border.all(
          color: GlassColors.gold.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 40)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$selectedCount ${isMobile ? "" : "SELECTED"}',
            style: GlassText.labelSM().copyWith(
              color: GlassColors.gold,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          SizedBox(width: isMobile ? 16 : 32),
          _BulkToolbarButton(
            label: isMobile ? 'MOVE' : 'MOVE TO',
            icon: Icons.drive_file_move_rtl_rounded,
            onTap: onMove,
          ),
          const SizedBox(width: 12),
          _BulkToolbarButton(
            label: isMobile ? 'EXPORT' : 'EXPORT MD',
            icon: Icons.terminal_rounded,
            onTap: onExport,
          ),
          SizedBox(width: isMobile ? 12 : 24),
          IconButton(
            icon: const Icon(
              Icons.close_rounded,
              color: Colors.white54,
              size: 20,
            ),
            onPressed: onClear,
          ),
        ],
      ),
    );
  }
}

class _BulkToolbarButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _BulkToolbarButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: GlassColors.gold.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: GlassColors.gold.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: GlassColors.gold),
            const SizedBox(width: 8),
            Text(
              label,
              style: GlassText.labelSM().copyWith(
                color: GlassColors.gold,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KanbanBoardMenu extends StatelessWidget {
  final BoardModel board;
  final bool isOverviewMode;
  final VoidCallback onToggleOverview;
  final VoidCallback onShowBoardInfo;
  final VoidCallback onShowRenameBoard;
  final VoidCallback onShowRoleManager;

  const _KanbanBoardMenu({
    required this.board,
    required this.isOverviewMode,
    required this.onToggleOverview,
    required this.onShowBoardInfo,
    required this.onShowRenameBoard,
    required this.onShowRoleManager,
  });

  @override
  Widget build(BuildContext context) {
    final isOwner = board.ownerUid == AuthService().currentUser?.uid;

    return Stack(
      children: [
        PopupMenuButton<String>(
          icon: const _ActionIconButton(icon: Icons.settings_outlined),
          color: GlassColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: GlassColors.ghostBorder, width: 0.5),
          ),
          onSelected: (value) {
            if (value == 'toggle_zoom') {
              onToggleOverview();
            } else if (value == 'share') {
              onShowBoardInfo();
            } else if (value == 'rename') {
              onShowRenameBoard();
            } else if (value == 'members') {
              onShowRoleManager();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'toggle_zoom',
              child: Row(
                children: [
                  Icon(
                    isOverviewMode
                        ? Icons.zoom_in_map_rounded
                        : Icons.zoom_out_map_rounded,
                    size: 18,
                    color: isOverviewMode
                        ? GlassColors.gold
                        : GlassColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isOverviewMode ? 'FOCUS MODE' : 'EAGLE EYE VIEW',
                    style: GlassText.bodyMD(),
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(height: 1),
            PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  const Icon(
                    Icons.share_rounded,
                    size: 18,
                    color: GlassColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Text('BOARD INFO / SHARE', style: GlassText.bodyMD()),
                ],
              ),
            ),
            if (isOwner) ...[
              const PopupMenuDivider(height: 1),
              PopupMenuItem(
                value: 'rename',
                child: Row(
                  children: [
                    const Icon(
                      Icons.edit_rounded,
                      size: 18,
                      color: GlassColors.gold,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'RENAME BOARD',
                      style: GlassText.bodyMD().copyWith(
                        color: GlassColors.gold,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'members',
                child: Row(
                  children: [
                    const Icon(
                      Icons.group_rounded,
                      size: 18,
                      color: GlassColors.gold,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'MANAGE TEAM',
                      style: GlassText.bodyMD().copyWith(
                        color: GlassColors.gold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        if (isOverviewMode)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: GlassColors.gold,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }
}

class _KanbanFilterToggleBar extends StatelessWidget {
  final BoardModel board;
  final bool isMobile;
  final bool allSelected;
  final bool mineSelected;
  final bool selectSelected;
  final String selectFilterLabel;
  final VoidCallback onSetFilterAll;
  final VoidCallback onSetFilterMine;
  final VoidCallback onTapSelectFilter;

  const _KanbanFilterToggleBar({
    required this.board,
    required this.isMobile,
    required this.allSelected,
    required this.mineSelected,
    required this.selectSelected,
    required this.selectFilterLabel,
    required this.onSetFilterAll,
    required this.onSetFilterMine,
    required this.onTapSelectFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: GlassColors.onSurface.withOpacity(0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: GlassColors.ghostBorder, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleItem(
            label: 'ALL',
            isSelected: allSelected,
            icon: Icons.group_rounded,
            isMobile: isMobile,
            onTap: onSetFilterAll,
          ),
          _ToggleItem(
            label: isMobile ? 'MINE' : 'MY TASKS',
            isSelected: mineSelected,
            icon: Icons.person_rounded,
            isMobile: isMobile,
            onTap: onSetFilterMine,
          ),
          _ToggleItem(
            label: selectFilterLabel,
            isSelected: selectSelected,
            icon: Icons.filter_list_rounded,
            showDropdownArrow: true,
            isMobile: isMobile,
            onTap: onTapSelectFilter,
          ),
        ],
      ),
    );
  }
}

class _BoardAvatarStack extends StatelessWidget {
  final BoardModel board;

  const _BoardAvatarStack({required this.board});

  @override
  Widget build(BuildContext context) {
    final boardState = context.watch<StateBoards>();
    final visibleMembers = board.members.take(3).toList();
    final remainingCount = board.members.length - visibleMembers.length;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...visibleMembers.map((uid) {
          final profile = boardState.getMemberProfile(uid);
          final color = GlassColors.getMemberColor(uid);
          final name = profile?['name'] ?? 'Operative';
          final photo = profile?['photo'] ?? '';
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.15),
                border: Border.all(color: GlassColors.ghostBorder, width: 0.5),
              ),
              child: ClipOval(
                child: photo.isNotEmpty
                    ? Image.network(
                        photo,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _AvatarFallback(name: name, color: color),
                      )
                    : _AvatarFallback(name: name, color: color),
              ),
            ),
          );
        }),
        if (remainingCount > 0)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: GlassColors.onSurface.withOpacity(0.05),
                border: Border.all(color: GlassColors.ghostBorder, width: 0.5),
              ),
              child: Center(
                child: Text(
                  '+$remainingCount',
                  style: GlassText.label().copyWith(
                    fontSize: 10,
                    color: GlassColors.onSurfaceVariant.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  final String name;
  final Color color;

  const _AvatarFallback({required this.name, required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final bool isMobile;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.isMobile,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? GlassColors.gold.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive
                  ? GlassColors.gold
                  : GlassColors.onSurface.withOpacity(0.4),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GlassText.labelSM().copyWith(
                fontSize: isMobile ? 9 : 10,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive
                    ? GlassColors.gold
                    : GlassColors.onSurface.withOpacity(0.4),
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData icon;
  final bool showDropdownArrow;
  final bool isMobile;

  const _ToggleItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.icon,
    this.showDropdownArrow = false,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 8 : 12,
            vertical: isMobile ? 6 : 8,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? GlassColors.primary.withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: isMobile ? 12 : 14,
                color: isSelected
                    ? GlassColors.primary
                    : GlassColors.onSurfaceVariant.withOpacity(0.4),
              ),
              const SizedBox(width: 6),
              Text(
                label.toUpperCase(),
                style: GlassText.labelSM().copyWith(
                  color: isSelected
                      ? GlassColors.primary
                      : GlassColors.onSurfaceVariant.withOpacity(0.6),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: isMobile ? 9 : 10,
                  letterSpacing: 0.5,
                ),
              ),
              if (showDropdownArrow) ...[
                const SizedBox(width: 2),
                Icon(
                  Icons.arrow_drop_down_rounded,
                  size: isMobile ? 14 : 16,
                  color: isSelected
                      ? GlassColors.primary
                      : GlassColors.onSurfaceVariant.withOpacity(0.4),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _GhostButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: GlassColors.gold.withOpacity(0.1),
          borderRadius: BorderRadius.circular(ExecutiveRadius.circular),
          border: Border.all(color: GlassColors.gold.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: GlassColors.gold),
            const SizedBox(width: 6),
            Text(
              label,
              style: GlassText.labelSM().copyWith(
                color: GlassColors.gold,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionOutlineButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ActionOutlineButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ExecutiveRadius.circular),
          border: Border.all(
            color: GlassColors.outlineVariant.withOpacity(0.3),
          ),
        ),
        child: Icon(icon, size: 18, color: GlassColors.onSurface),
      ),
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;

  const _ActionIconButton({required this.icon, this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ExecutiveRadius.circular),
          border: Border.all(
            color: (color ?? GlassColors.outlineVariant).withOpacity(0.3),
          ),
        ),
        child: Icon(icon, size: 16, color: color ?? GlassColors.onSurface),
      ),
    );
  }
}
