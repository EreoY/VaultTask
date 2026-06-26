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
    final grouped = _groupMeetings(filtered);
    final roleOptions = _roleOptions(meetings);

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
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  WorkspaceBackButton(onTap: _exitToWorkspace),
                  const SizedBox(width: 12),
                  Text(
                    'Meetings',
                    style: GlassText.headlineLG().copyWith(
                      fontSize: isMobile ? 34 : 42,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (!isMobile) ...[
                _segmentedToggle(),
                const SizedBox(width: 16),
              ],
              _primaryAction(label: 'New meeting', onTap: _openCreateDraft),
            ],
          ),
          if (isMobile) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: _segmentedToggle(),
              ),
            ),
          ],
          if (roleOptions.isNotEmpty) ...[
            const SizedBox(height: 18),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _roleSelector(null, 'All roles'),
                  const SizedBox(width: 8),
                  ...roleOptions.expand(
                    (role) => [
                      _roleSelector(role, role),
                      const SizedBox(width: 8),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 26),
          Expanded(
            child: grouped.isEmpty
                ? Center(
                    child: Text(
                      'No meetings in this view',
                      style: GlassText.bodyMD().copyWith(
                        color: GlassColors.onSurfaceVariant.withOpacity(0.45),
                      ),
                    ),
                  )
                : ScrollbarGutterFrame(
                    child: ListView.separated(
                      padding: ScrollbarGutter.reserveRight(EdgeInsets.zero),
                      itemCount: grouped.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 28),
                      itemBuilder: (context, index) {
                        final group = grouped[index];
                        return _MeetingSection(
                          label: group.label,
                          meetings: group.meetings,
                          onTapMeeting: (meeting) {
                            context.read<StateMeetings>().openMeetingDetail(
                              widget.board.id,
                              meeting.id,
                            );
                          },
                          boardName: widget.board.name,
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
    return WorkspaceChromeHeader(
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
    return FilledButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.add_rounded, size: 16),
      label: Text(label),
    );
  }

  void _openCreateDraft() {
    setState(() => _isCreatingDraft = true);
  }

  List<_MeetingGroup> _groupMeetings(List<MeetingModel> meetings) {
    final sortedMeetings = List<MeetingModel>.from(meetings)
      ..sort((a, b) => b.startAt.compareTo(a.startAt));

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final lastWeekThreshold = today.subtract(const Duration(days: 7));
    final orderedLabels = <String>[];
    final grouped = <String, List<MeetingModel>>{};

    for (final meeting in sortedMeetings) {
      final date = DateTime(
        meeting.startAt.year,
        meeting.startAt.month,
        meeting.startAt.day,
      );
      late final String label;
      if (date == today) {
        label = 'Today';
      } else if (date == yesterday) {
        label = 'Yesterday';
      } else if (date.isAfter(lastWeekThreshold)) {
        label = 'Last 7 days';
      } else {
        label = DateFormat('MMMM yyyy').format(meeting.startAt);
      }
      if (!grouped.containsKey(label)) {
        orderedLabels.add(label);
        grouped[label] = [];
      }
      grouped[label]!.add(meeting);
    }

    return orderedLabels
        .map((label) => _MeetingGroup(label: label, meetings: grouped[label]!))
        .toList();
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

class _MeetingGroup {
  final String label;
  final List<MeetingModel> meetings;

  const _MeetingGroup({required this.label, required this.meetings});
}

class _MeetingSection extends StatelessWidget {
  final String label;
  final List<MeetingModel> meetings;
  final String boardName;
  final ValueChanged<MeetingModel> onTapMeeting;

  const _MeetingSection({
    required this.label,
    required this.meetings,
    required this.boardName,
    required this.onTapMeeting,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.arrow_drop_down_rounded,
              size: 18,
              color: GlassColors.onSurfaceVariant.withOpacity(0.76),
            ),
            Text(
              '$label (${meetings.length})',
              style: GlassText.bodyLG().copyWith(
                fontWeight: FontWeight.w600,
                color: GlassColors.onSurfaceVariant.withOpacity(0.9),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...meetings.map((meeting) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10, left: 20),
            child: InkWell(
              onTap: () => onTapMeeting(meeting),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            meeting.title,
                            style: GlassText.bodyLG().copyWith(
                              fontWeight: FontWeight.w500,
                              color: GlassColors.onSurface,
                            ),
                          ),
                          if (meeting.description.trim().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              meeting.description.trim(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GlassText.bodyMD().copyWith(
                                color: GlassColors.onSurfaceVariant.withOpacity(
                                  0.54,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          DateFormat(
                            'MMM d, yyyy h:mm a',
                          ).format(meeting.startAt),
                          style: GlassText.bodyMD().copyWith(
                            color: GlassColors.onSurface.withOpacity(0.86),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          boardName,
                          style: GlassText.bodyMD().copyWith(
                            color: GlassColors.onSurfaceVariant.withOpacity(
                              0.58,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
