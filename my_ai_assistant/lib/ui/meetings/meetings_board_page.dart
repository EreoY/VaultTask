import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/board_model.dart';
import '../../models/meeting_model.dart';
import '../../state_managers/state_boards.dart';
import '../../state_managers/state_meetings.dart';
import '../common/responsive_layout.dart';
import '../common/scroll_gutter.dart';
import '../common/workspace_chrome.dart';
import '../theme/glass_theme.dart';
import 'meetings_board_sheet.dart';

import 'widgets/bento_meeting_widgets.dart';

enum _MeetingsTimeFilter { all, upcoming, past }

class MeetingsBoardPage extends StatefulWidget {
  final BoardModel board;

  const MeetingsBoardPage({super.key, required this.board});

  @override
  State<MeetingsBoardPage> createState() => _MeetingsBoardPageState();
}

class _MeetingsBoardPageState extends State<MeetingsBoardPage> {
  _MeetingsTimeFilter _timeFilter = _MeetingsTimeFilter.all;
  String? _selectedRole;
  bool _isCreatingDraft = false;
  String _activeQuickSection = 'all';

  List<String> get _boardRolePresets {
    final roles = <String>{};
    roles.addAll(
      widget.board.memberRoles.values
          .map((role) => role.trim())
          .where((role) => role.isNotEmpty),
    );
    return roles.toList()..sort();
  }

  void _exitToWorkspace() {
    context.read<StateMeetings>().clearActiveBoard(widget.board.id);
    context.read<StateBoards>().setSelectedBoard(null);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<StateMeetings>().fetchMeetingsForBoard(widget.board);
      if (!mounted) return;
      context.read<StateMeetings>().openBoardHome(widget.board.id);
    });
  }

  @override
  void didUpdateWidget(covariant MeetingsBoardPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.board.id != widget.board.id) {
      _timeFilter = _MeetingsTimeFilter.all;
      _selectedRole = null;
      _isCreatingDraft = false;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await context.read<StateMeetings>().fetchMeetingsForBoard(widget.board);
        if (!mounted) return;
        context.read<StateMeetings>().openBoardHome(widget.board.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final meetingsState = context.watch<StateMeetings>();
    final meetings = meetingsState.meetingsForBoard(widget.board.id);
    final roleOptions = _roleOptions(meetings);
    final selectedMeeting = meetingsState.selectedMeetingForBoard(
      widget.board.id,
    );

    return selectedMeeting == null
        ? (_isCreatingDraft
              ? _buildCreateSurface(context, roleOptions)
              : _buildListSurface(context, meetings))
        : _buildDetailSurface(context, selectedMeeting, roleOptions);
  }

  Widget _buildListSurface(BuildContext context, List<MeetingModel> meetings) {
    final isMobile = Responsive.isMobile(context);
    final filtered = _applyFilters(meetings);
    final grouped = _groupMeetingsByDate(filtered);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 16 : ExecutiveSpacing.containerPadding(context),
        isMobile ? 16 : ExecutiveSpacing.containerPadding(context),
        isMobile ? 16 : ExecutiveSpacing.containerPadding(context),
        isMobile ? 20 : 28,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNavBar(metaText: 'Board meetings'),
          const SizedBox(height: 14),

          Row(
            children: [
              WorkspaceBackButton(onTap: _exitToWorkspace),
            ],
          ),
          const SizedBox(height: 14),

          // Bento Meeting Hero Banner
          BentoMeetingHeroHeader(
            board: widget.board,
            totalMeetings: meetings.length,
            onCreateMeeting: _openCreateDraft,
          ),

          const SizedBox(height: 14),

          // Bento Quick Jump & Filter Section Chips
          BentoMeetingQuickChips(
            activeSection: _activeQuickSection,
            onSectionChanged: (secId) {
              setState(() {
                _activeQuickSection = secId;
                if (secId == 'all') {
                  _timeFilter = _MeetingsTimeFilter.all;
                } else if (secId == 'summary') {
                  _timeFilter = _MeetingsTimeFilter.past;
                } else if (secId == 'actions') {
                  _timeFilter = _MeetingsTimeFilter.upcoming;
                }
              });
            },
          ),

          const SizedBox(height: 14),

          Expanded(
            child: grouped.isEmpty
                ? Center(
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: const Color(0x80161926),
                        borderRadius: BorderRadius.circular(ExecutiveRadius.xl),
                        border: Border.all(color: GlassColors.outlineVariant),
                      ),
                      child: Text(
                        'No meetings in this view',
                        style: GlassText.secondary(),
                      ),
                    ),
                  )
                : ScrollbarGutterFrame(
                    child: ListView.builder(
                      padding: ScrollbarGutter.reserveRight(EdgeInsets.zero),
                      itemCount: grouped.length,
                      itemBuilder: (context, groupIndex) {
                        final group = grouped[groupIndex];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(
                                top: groupIndex == 0 ? 0 : 16,
                                bottom: 10,
                                left: 4,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    size: 14,
                                    color: GlassColors.onSurfaceVariant
                                        .withOpacity(0.7),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    group.label,
                                    style: GlassText.bodyMD().copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: GlassColors.onSurfaceVariant
                                          .withOpacity(0.9),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: GlassColors.onSurfaceVariant
                                          .withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${group.meetings.length}',
                                      style: GlassText.labelSM().copyWith(
                                        color: GlassColors.onSurfaceVariant
                                            .withOpacity(0.8),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ...group.meetings.map((meeting) {
                              return BentoMeetingCard(
                                meeting: meeting,
                                onTap: () {
                                  context
                                      .read<StateMeetings>()
                                      .openMeetingDetail(
                                        widget.board.id,
                                        meeting.id,
                                      );
                                },
                                onDelete: () async {
                                  await context
                                      .read<StateMeetings>()
                                      .deleteMeeting(
                                        widget.board,
                                        meeting.id,
                                      );
                                },
                              );
                            }),
                          ],
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSurface(
    BuildContext context,
    MeetingModel selectedMeeting,
    List<String> roleOptions,
  ) {
    final isMobile = Responsive.isMobile(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 16 : ExecutiveSpacing.containerPadding(context),
        isMobile ? 16 : ExecutiveSpacing.containerPadding(context),
        0,
        isMobile ? 20 : 28,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(
              right: isMobile ? 16 : ExecutiveSpacing.containerPadding(context),
            ),
            child: _buildNavBar(
              metaText:
                  'Edited ${DateFormat('MMM d').format(selectedMeeting.createdAt)}',
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: MeetingsBoardSheet(
              board: widget.board,
              initialMeetingId: selectedMeeting.id,
              embeddedInPage: true,
              showListPane: false,
              suggestedRoleTags: roleOptions,
              onBack: () => context.read<StateMeetings>().closeMeetingDetail(),
              onOpenBoard: () => context.read<StateBoards>().setBoardSurface(
                BoardSurfaceMode.kanban,
              ),
              showTopMeta: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateSurface(BuildContext context, List<String> roleOptions) {
    final isMobile = Responsive.isMobile(context);
    final initialRoles = _selectedRole == null
        ? const <String>[]
        : [_selectedRole!];

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 16 : ExecutiveSpacing.containerPadding(context),
        isMobile ? 16 : ExecutiveSpacing.containerPadding(context),
        0,
        isMobile ? 20 : 28,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(
              right: isMobile ? 16 : ExecutiveSpacing.containerPadding(context),
            ),
            child: _buildNavBar(metaText: 'New draft'),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: MeetingsBoardSheet(
              board: widget.board,
              embeddedInPage: true,
              showListPane: false,
              suggestedRoleTags: roleOptions,
              initialRoleTags: initialRoles,
              autoLoadFirstMeeting: false,
              isCreateMode: true,
              onBack: () => setState(() => _isCreatingDraft = false),
              onSaved: (meeting) {
                if (!mounted) return;
                setState(() => _isCreatingDraft = false);
                context.read<StateMeetings>().openMeetingDetail(
                  widget.board.id,
                  meeting.id,
                );
              },
              onOpenBoard: () => context.read<StateBoards>().setBoardSurface(
                BoardSurfaceMode.kanban,
              ),
              showTopMeta: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavBar({required String metaText}) {
    return Row(
      children: [
        Expanded(
          child: WorkspaceChromeHeader(
            padding: EdgeInsets.zero,
            gapAfterMeta: 0,
            crumbs: [
        WorkspaceCrumb(
          icon: Icons.home_rounded,
          label: 'Workspace HQ',
          onTap: _exitToWorkspace,
        ),
        WorkspaceCrumb(
          icon: Icons.calendar_today_rounded,
          label: 'Meetings',
          color: GlassColors.onSurfaceVariant.withOpacity(0.72),
          onTap: _returnToMeetingsList,
        ),
        WorkspaceCrumb(label: widget.board.name),
      ],
      metaText: metaText,
      title: const SizedBox.shrink(),
    ),
  ),
  ],
);
  }

  void _returnToMeetingsList() {
    if (_isCreatingDraft) {
      setState(() => _isCreatingDraft = false);
    }
    context.read<StateMeetings>().closeMeetingDetail();
  }

  Widget _pillToggle({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? Colors.white.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? GlassColors.onSurface.withOpacity(0.08)
                : GlassColors.outlineVariant.withOpacity(0.12),
          ),
        ),
        child: Text(
          label,
          style: GlassText.bodyMD().copyWith(
            fontWeight: FontWeight.w600,
            color: selected
                ? GlassColors.onSurface
                : GlassColors.onSurfaceVariant.withOpacity(0.68),
          ),
        ),
      ),
    );
  }

  Widget _segmentedToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: GlassColors.ghostBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _segmentedTab(
            label: 'ALL MEETINGS',
            selected: _timeFilter == _MeetingsTimeFilter.all,
            onTap: () => setState(() => _timeFilter = _MeetingsTimeFilter.all),
          ),
          _segmentedTab(
            label: 'UPCOMING',
            selected: _timeFilter == _MeetingsTimeFilter.upcoming,
            onTap: () => setState(() => _timeFilter = _MeetingsTimeFilter.upcoming),
          ),
          _segmentedTab(
            label: 'PAST',
            selected: _timeFilter == _MeetingsTimeFilter.past,
            onTap: () => setState(() => _timeFilter = _MeetingsTimeFilter.past),
          ),
        ],
      ),
    );
  }

  Widget _segmentedTab({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? GlassColors.gold.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? GlassColors.gold.withOpacity(0.3) : Colors.transparent,
            width: 1.0,
          ),
        ),
        child: Text(
          label,
          style: GlassText.labelSM().copyWith(
            color: selected ? GlassColors.gold : GlassColors.onSurfaceVariant.withOpacity(0.6),
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 10.5,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }

  Widget _roleSelector(String? role, String label) {
    final selected = _selectedRole == role;
    return InkWell(
      onTap: () => setState(() => _selectedRole = role),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? GlassColors.primary.withOpacity(0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? GlassColors.primary.withOpacity(0.16)
                : GlassColors.outlineVariant.withOpacity(0.12),
          ),
        ),
        child: Text(
          label,
          style: GlassText.labelSM().copyWith(
            color: selected
                ? GlassColors.primary.withOpacity(0.92)
                : GlassColors.onSurfaceVariant.withOpacity(0.66),
          ),
        ),
      ),
    );
  }

  Widget _iconAction({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: GlassColors.outlineVariant.withOpacity(0.14),
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: GlassColors.onSurfaceVariant.withOpacity(0.7),
        ),
      ),
    );
  }

  Widget _primaryAction({required String label, required VoidCallback onTap}) {
    if (Responsive.isMobile(context)) {
      return IconButton(
        icon: const Icon(Icons.add_rounded),
        onPressed: onTap,
      );
    }
    return FilledButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.add_rounded, size: 16),
      label: Text(label),
    );
  }

  void _openCreateDraft() {
    setState(() => _isCreatingDraft = true);
  }

  List<String> _roleOptions(List<MeetingModel> meetings) {
    final roles = <String>{..._boardRolePresets};
    for (final meeting in meetings) {
      roles.addAll(meeting.roleTags.map((tag) => tag.trim()));
    }
    final clean = roles.where((role) => role.isNotEmpty).toList()..sort();
    return clean;
  }

  List<MeetingModel> _applyFilters(List<MeetingModel> meetings) {
    final timeFiltered = switch (_timeFilter) {
      _MeetingsTimeFilter.all => meetings,
      _MeetingsTimeFilter.upcoming =>
        meetings.where((meeting) => !meeting.isPast).toList(),
      _MeetingsTimeFilter.past =>
        meetings.where((meeting) => meeting.isPast).toList(),
    };
    if (_selectedRole == null) return timeFiltered;
    return timeFiltered
        .where((meeting) => meeting.roleTags.contains(_selectedRole))
        .toList();
  }
}

class _MeetingDateGroup {
  final String label;
  final List<MeetingModel> meetings;

  const _MeetingDateGroup({required this.label, required this.meetings});
}

List<_MeetingDateGroup> _groupMeetingsByDate(List<MeetingModel> meetings) {
  final sorted = List<MeetingModel>.from(meetings);
  sorted.sort((a, b) => b.startAt.compareTo(a.startAt));

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = DateTime(now.year, now.month, now.day - 1);

  final groups = <DateTime, List<MeetingModel>>{};
  final order = <DateTime>[];

  for (final m in sorted) {
    final date = DateTime(m.startAt.year, m.startAt.month, m.startAt.day);
    if (!groups.containsKey(date)) {
      groups[date] = [];
      order.add(date);
    }
    groups[date]!.add(m);
  }

  return order.map((date) {
    late final String label;
    if (date == today) {
      label = 'Today (${DateFormat('d MMM').format(date)})';
    } else if (date == yesterday) {
      label = 'Yesterday (${DateFormat('d MMM').format(date)})';
    } else {
      label = DateFormat('EEEE, d MMM yyyy').format(date);
    }
    return _MeetingDateGroup(label: label, meetings: groups[date]!);
  }).toList();
}
