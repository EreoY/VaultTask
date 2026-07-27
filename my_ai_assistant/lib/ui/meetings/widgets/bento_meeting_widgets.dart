import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/glass_theme.dart';
import '../../../models/meeting_model.dart';
import '../../../models/board_model.dart';

/// Bento Meeting Hero Header Banner
class BentoMeetingHeroHeader extends StatelessWidget {
  final BoardModel board;
  final int totalMeetings;
  final VoidCallback? onCreateMeeting;
  final VoidCallback? onSearchPressed;

  const BentoMeetingHeroHeader({
    super.key,
    required this.board,
    required this.totalMeetings,
    this.onCreateMeeting,
    this.onSearchPressed,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 18 : 24),
      decoration: BoxDecoration(
        color: GlassColors.bentoLavender, // #B3A0FF
        borderRadius: BorderRadius.circular(ExecutiveRadius.xxl), // 32px
        boxShadow: [
          BoxShadow(
            color: GlassColors.bentoLavender.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.groups_rounded, size: 14, color: GlassColors.deepBlack),
                    const SizedBox(width: 6),
                    Text(
                      'MEETING HUB • ${board.name.toUpperCase()}',
                      style: GlassText.labelSM().copyWith(
                        color: GlassColors.deepBlack,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: GlassColors.deepBlack,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '$totalMeetings Sessions',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Meeting Notes & Audio AI Summaries',
            style: GlassText.headlineMD().copyWith(
              color: GlassColors.deepBlack,
              fontWeight: FontWeight.w800,
              fontSize: isMobile ? 18 : 24,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Record, transcribe, and extract action items seamlessly with AI.',
            style: GlassText.secondary().copyWith(
              color: GlassColors.deepBlack.withOpacity(0.75),
              fontSize: isMobile ? 12 : 14,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: onCreateMeeting,
                style: ElevatedButton.styleFrom(
                  backgroundColor: GlassColors.deepBlack,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 16 : 20,
                    vertical: isMobile ? 10 : 12,
                  ),
                  shape: const StadiumBorder(),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(
                  'New Meeting',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: isMobile ? 12 : 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Bento Quick Section Jump Chips Bar for Mobile & Desktop
class BentoMeetingQuickChips extends StatelessWidget {
  final String activeSection;
  final ValueChanged<String> onSectionChanged;

  const BentoMeetingQuickChips({
    super.key,
    required this.activeSection,
    required this.onSectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    final sections = [
      {'id': 'all', 'label': 'All Meetings', 'icon': Icons.space_dashboard_rounded},
      {'id': 'summary', 'label': '✨ AI Summaries', 'icon': Icons.auto_awesome_rounded},
      {'id': 'actions', 'label': '📌 Action Items', 'icon': Icons.check_box_outlined},
      {'id': 'notes', 'label': '📝 Notes', 'icon': Icons.description_outlined},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 20, vertical: 8),
      child: Row(
        children: sections.map((sec) {
          final isSelected = activeSection == sec['id'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSectionChanged(sec['id'] as String),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? GlassColors.deepBlack : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? GlassColors.deepBlack : GlassColors.outlineVariant,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? GlassColors.deepBlack.withOpacity(0.2)
                          : Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  sec['label'] as String,
                  style: TextStyle(
                    fontSize: isMobile ? 11 : 12,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? Colors.white : GlassColors.deepBlack,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Bento Collapsible Text Component for Mobile Long Text Optimization
class BentoCollapsibleText extends StatefulWidget {
  final String text;
  final int maxCollapsedLines;
  final TextStyle? style;
  final String title;

  const BentoCollapsibleText({
    super.key,
    required this.text,
    this.maxCollapsedLines = 3,
    this.style,
    this.title = 'Notes Summary',
  });

  @override
  State<BentoCollapsibleText> createState() => _BentoCollapsibleTextState();
}

class _BentoCollapsibleTextState extends State<BentoCollapsibleText> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isLongText = widget.text.length > 120;

    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ExecutiveRadius.xl),
        border: Border.all(color: GlassColors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                style: GlassText.bodyLG().copyWith(
                  fontWeight: FontWeight.w800,
                  color: GlassColors.deepBlack,
                  fontSize: isMobile ? 14 : 16,
                ),
              ),
              if (isLongText && isMobile)
                InkWell(
                  onTap: () => setState(() => _isExpanded = !_isExpanded),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isExpanded ? 'Show Less ▲' : 'Read More ▼',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: GlassColors.deepBlack.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedCrossFade(
            firstChild: Text(
              widget.text,
              maxLines: isMobile ? widget.maxCollapsedLines : 10,
              overflow: TextOverflow.ellipsis,
              style: widget.style ??
                  GlassText.secondary().copyWith(
                    color: GlassColors.deepBlack.withOpacity(0.8),
                    fontSize: isMobile ? 12 : 14,
                    height: 1.35,
                  ),
            ),
            secondChild: Text(
              widget.text,
              style: widget.style ??
                  GlassText.secondary().copyWith(
                    color: GlassColors.deepBlack.withOpacity(0.8),
                    fontSize: isMobile ? 12 : 14,
                    height: 1.35,
                  ),
            ),
            crossFadeState: (isMobile && !_isExpanded && isLongText)
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

/// Bento Card for Individual Meeting item
class BentoMeetingCard extends StatelessWidget {
  final MeetingModel meeting;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const BentoMeetingCard({
    super.key,
    required this.meeting,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    final dateStr = DateFormat('EEE, d MMM • h:mm a').format(meeting.startAt);
    final hasSummary = meeting.summary.trim().isNotEmpty;
    final hasNotes = meeting.notes.trim().isNotEmpty || meeting.transcript.trim().isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(isMobile ? 14 : 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(ExecutiveRadius.xl), // 24px
          border: Border.all(color: GlassColors.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: GlassColors.bentoOrange.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: isMobile ? 10 : 11,
                      fontWeight: FontWeight.w700,
                      color: GlassColors.deepBlack,
                    ),
                  ),
                ),
                Row(
                  children: [
                    if (hasSummary)
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: GlassColors.bentoBlue,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          '✨ AI Summary',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                        ),
                      ),
                    if (onDelete != null)
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.grey),
                        onPressed: onDelete,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              meeting.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GlassText.bodyLG().copyWith(
                fontWeight: FontWeight.w800,
                color: GlassColors.deepBlack,
                fontSize: isMobile ? 15 : 18,
              ),
            ),
            if (hasSummary) ...[
              const SizedBox(height: 6),
              Text(
                meeting.summary,
                maxLines: isMobile ? 2 : 3,
                overflow: TextOverflow.ellipsis,
                style: GlassText.secondary().copyWith(
                  fontSize: isMobile ? 11 : 12,
                  color: GlassColors.deepBlack.withOpacity(0.7),
                ),
              ),
            ],
            if (hasNotes) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.description_outlined, size: 14, color: GlassColors.deepBlack),
                  const SizedBox(width: 4),
                  const Text(
                    'Notes & Transcripts included',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: GlassColors.deepBlack,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
