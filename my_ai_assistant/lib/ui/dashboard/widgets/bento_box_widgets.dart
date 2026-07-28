import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/glass_theme.dart';

/// Bento Box Header Section (Section A)
class BentoHeaderSection extends StatelessWidget {
  final String userName;
  final VoidCallback? onSearchPressed;
  final VoidCallback? onProfilePressed;

  const BentoHeaderSection({
    super.key,
    required this.userName,
    this.onSearchPressed,
    this.onProfilePressed,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('EEEE, d MMMM').format(DateTime.now());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello $userName 👋',
                style: GlassText.headlineLG().copyWith(
                  fontWeight: FontWeight.w800,
                  color: GlassColors.deepBlack,
                  fontSize: 28,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                today,
                style: GlassText.secondary().copyWith(
                  color: GlassColors.onSurfaceVariant,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Row(
            children: [
              // Search Button
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.all(12),
                  elevation: 2,
                  shadowColor: Colors.black12,
                ),
                icon: const Icon(Icons.search_rounded, color: GlassColors.deepBlack),
                onPressed: onSearchPressed != null ? () => onSearchPressed!() : null,
              ),
              const SizedBox(width: 12),
              // Circular Profile Avatar
              GestureDetector(
                onTap: onProfilePressed != null ? () => onProfilePressed!() : null,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: GlassColors.bentoOrange,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.person_rounded, color: GlassColors.deepBlack),
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

/// Bento Box Hero Card - Lavender (Section B)
class BentoHeroCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? description;
  final String buttonText;
  final VoidCallback? onTap;
  final String? imageAssetPath;

  const BentoHeroCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.description,
    required this.buttonText,
    this.onTap,
    this.imageAssetPath,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    // Dynamic calculations for responsive text & image width:
    final double maxTextWidth = isMobile ? (screenWidth - 88) * 0.52 : 360;
    final double heroImageWidth = isMobile ? 150 : 250;
    final double heroImageRight = isMobile ? 8 : 24;
    final double heroImageTop = isMobile ? 12 : -36;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: isMobile ? 32 : 56,
        bottom: 16,
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
                  color: GlassColors.bentoLavender.withOpacity(0.6),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'DAILY CHALLENGE',
                    style: GlassText.labelSM().copyWith(
                      color: GlassColors.deepBlack,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: maxTextWidth,
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GlassText.headlineMD().copyWith(
                      color: GlassColors.deepBlack,
                      fontWeight: FontWeight.w800,
                      fontSize: isMobile ? 17 : 22,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: maxTextWidth,
                  child: Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GlassText.secondary().copyWith(
                      color: GlassColors.deepBlack.withOpacity(0.75),
                      fontSize: isMobile ? 12 : 14,
                    ),
                  ),
                ),
                if (description != null) ...[
                  const SizedBox(height: 6),
                  SizedBox(
                    width: maxTextWidth,
                    child: Text(
                      description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GlassText.secondary().copyWith(
                        color: GlassColors.deepBlack.withOpacity(0.6),
                        fontSize: isMobile ? 11 : 12,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: onTap != null ? () => onTap!() : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GlassColors.deepBlack,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 18 : 22,
                      vertical: isMobile ? 10 : 12,
                    ),
                    shape: const StadiumBorder(),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(buttonText, style: TextStyle(fontWeight: FontWeight.w600, fontSize: isMobile ? 13 : 14)),
                      const SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: isMobile ? 16 : 18),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 3D Illustration popping out cleanly vertically centered on the right
          Positioned(
            right: heroImageRight,
            top: heroImageTop,
            bottom: isMobile ? 12 : -10,
            child: IgnorePointer(
              child: SizedBox(
                width: heroImageWidth,
                child: imageAssetPath != null
                    ? Image.asset(
                        imageAssetPath!,
                        fit: BoxFit.contain,
                        alignment: Alignment.centerRight,
                        errorBuilder: (context, error, stackTrace) => _buildDefault3DGraphic(),
                      )
                    : _buildDefault3DGraphic(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefault3DGraphic() {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Colors.white.withOpacity(0.8), Colors.white.withOpacity(0.2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.auto_awesome_rounded,
          size: 54,
          color: GlassColors.deepBlack,
        ),
      ),
    );
  }
}

/// Bento Box Weekly Date Strip Widget (Section B.5)
class BentoWeeklyDateStrip extends StatelessWidget {
  const BentoWeeklyDateStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final now = DateTime.now();

    final double netWidth = screenWidth - 40.0;
    final double targetCapsuleWidth = isMobile ? 42.0 : 48.0;
    final double targetGap = isMobile ? 8.0 : 10.0;
    final double unitWidth = targetCapsuleWidth + targetGap;

    int count = ((netWidth + targetGap) / unitWidth).floor();
    count = count.clamp(6, 28);

    // Place today at a comfortable offset (e.g. 3rd item)
    final int daysBeforeToday = (count > 7) ? 3 : 2;
    final days = List.generate(count, (i) => now.subtract(Duration(days: daysBeforeToday - i)));

    final double exactGap = (count > 1) ? (netWidth - (count * targetCapsuleWidth)) / (count - 1) : targetGap;
    final double capsuleWidth = exactGap < 4.0 ? (netWidth - (targetGap * (count - 1))) / count : targetCapsuleWidth;
    final double actualGap = exactGap < 4.0 ? targetGap : exactGap;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month & Year Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_month_rounded,
                    size: isMobile ? 16 : 18,
                    color: GlassColors.deepBlack,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('MMMM yyyy').format(now),
                    style: GlassText.headlineMD().copyWith(
                      fontWeight: FontWeight.w800,
                      color: GlassColors.deepBlack,
                      fontSize: isMobile ? 15 : 18,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: GlassColors.deepBlack.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Today • ${DateFormat('d MMM').format(now)}',
                  style: GlassText.secondary().copyWith(
                    fontSize: isMobile ? 11 : 12,
                    fontWeight: FontWeight.w700,
                    color: GlassColors.deepBlack,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Dynamic Fill Capsule Strip
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: days.map((day) {
                final isToday = day.year == now.year && day.month == now.month && day.day == now.day;
                final dayName = DateFormat('EEE').format(day);
                final dayNum = DateFormat('d').format(day);

                return Container(
                  width: capsuleWidth,
                  height: isMobile ? 62 : 68,
                  margin: EdgeInsets.only(
                    right: day == days.last ? 0 : actualGap.clamp(4.0, 16.0),
                  ),
                  decoration: BoxDecoration(
                    color: isToday ? GlassColors.deepBlack : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isToday ? GlassColors.deepBlack : GlassColors.outlineVariant,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isToday
                            ? GlassColors.deepBlack.withOpacity(0.25)
                            : Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Top indicator dot matching reference screenshot
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isToday
                              ? Colors.white
                              : (day.day % 2 == 1
                                  ? GlassColors.deepBlack.withOpacity(0.5)
                                  : Colors.transparent),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dayName,
                        style: TextStyle(
                          fontSize: isMobile ? 11 : 12,
                          fontWeight: FontWeight.w600,
                          color: isToday
                              ? Colors.white.withOpacity(0.8)
                              : GlassColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dayNum,
                        style: TextStyle(
                          fontSize: isMobile ? 13 : 15,
                          fontWeight: FontWeight.w800,
                          color: isToday ? Colors.white : GlassColors.deepBlack,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bento Box Grid Section - "Your plan" (Section C)
class BentoPlanGrid extends StatelessWidget {
  final VoidCallback? onLeftCardTap;
  final VoidCallback? onTopRightTap;
  final VoidCallback? onBottomRightTap;

  const BentoPlanGrid({
    super.key,
    this.onLeftCardTap,
    this.onTopRightTap,
    this.onBottomRightTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your plan',
                style: GlassText.headlineMD().copyWith(
                  fontWeight: FontWeight.w800,
                  color: GlassColors.deepBlack,
                  fontSize: 22,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_horiz_rounded, color: GlassColors.deepBlack),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Split screen into two main columns
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left Column: Tall Soft Orange card (Meeting / Audio)
                Expanded(
                  child: _buildBentoCard(
                    context: context,
                    color: GlassColors.bentoOrange,
                    title: 'Meeting',
                    subtitle: '10:00 AM • Voice & AI Notes',
                    description: 'Record & summarize audio sessions automatically',
                    badge: 'Audio',
                    icon: Icons.mic_rounded,
                    onTap: onLeftCardTap,
                    isTall: true,
                    imageAssetPath: 'assets/images/speaker.png',
                    imageSize: isMobile ? 115 : 150,
                    topOffset: isMobile ? 54 : 68,
                    rightOffset: isMobile ? 6 : 12,
                  ),
                ),
                const SizedBox(width: 14),
                // Right Column: Two smaller cards stacked vertically
                Expanded(
                  child: Column(
                    children: [
                      // Top Card: Baby Blue card (Message with AI)
                      Expanded(
                        child: _buildBentoCard(
                          context: context,
                          color: GlassColors.bentoBlue,
                          title: 'Message with AI',
                          subtitle: 'Instant AI Assistant',
                          description: 'Chat with AI anytime',
                          badge: 'AI Chat',
                          icon: Icons.chat_bubble_outline_rounded,
                          onTap: onTopRightTap,
                          isTall: false,
                          imageAssetPath: 'assets/images/chat.png',
                          imageSize: isMobile ? 54 : 88,
                          topOffset: isMobile ? null : 42,
                          bottomOffset: isMobile ? 2 : null,
                          rightOffset: isMobile ? 2 : 8,
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Bottom Card: Pink card (Profile & Team Sync)
                      Expanded(
                        child: _buildBentoCard(
                          context: context,
                          color: GlassColors.bentoPink,
                          title: 'Profile & Sync',
                          subtitle: '04:00 PM • 8 Members',
                          description: 'Sync avatars & team roles',
                          badge: 'Profile',
                          icon: Icons.person_outline_rounded,
                          onTap: onBottomRightTap,
                          isTall: false,
                          imageAssetPath: 'assets/images/profile.png',
                          imageSize: isMobile ? 52 : 86,
                          topOffset: isMobile ? null : 42,
                          bottomOffset: isMobile ? 2 : null,
                          rightOffset: isMobile ? 2 : 8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBentoCard({
    required BuildContext context,
    required Color color,
    required String title,
    required String subtitle,
    String? description,
    required String badge,
    required IconData icon,
    VoidCallback? onTap,
    required bool isTall,
    String? imageAssetPath,
    double imageSize = 90,
    double? topOffset,
    double? bottomOffset,
    double rightOffset = -8,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return GestureDetector(
      onTap: onTap != null ? () => onTap() : null,
      child: Stack(
        clipBehavior: Clip.none, // Allow 3D image overflow
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 14 : 18),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(ExecutiveRadius.xl), // 24px
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.5),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment:
                  isTall ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.all(isMobile ? 7 : 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: isMobile ? 16 : 20, color: GlassColors.deepBlack),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        badge,
                        style: GlassText.secondary().copyWith(
                          fontSize: isMobile ? 10 : 11,
                          fontWeight: FontWeight.w700,
                          color: GlassColors.deepBlack,
                        ),
                      ),
                    ),
                  ],
                ),
                if (isTall) SizedBox(height: isMobile ? 90 : 110),
                Padding(
                  padding: EdgeInsets.only(
                    right: (imageAssetPath != null && !isTall)
                        ? (isMobile ? imageSize * 0.55 : 36.0)
                        : 0.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GlassText.bodyLG().copyWith(
                          fontWeight: FontWeight.w800,
                          color: GlassColors.deepBlack,
                          fontSize: isMobile ? 13 : 16,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GlassText.secondary().copyWith(
                          color: GlassColors.deepBlack.withOpacity(0.8),
                          fontSize: isMobile ? 11 : 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (description != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          description,
                          maxLines: isTall ? (isMobile ? 2 : 3) : (isMobile ? 1 : 2),
                          overflow: TextOverflow.ellipsis,
                          style: GlassText.secondary().copyWith(
                            color: GlassColors.deepBlack.withOpacity(0.65),
                            fontSize: isMobile ? 10 : 11,
                            height: 1.15,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (imageAssetPath != null)
            Positioned(
              right: rightOffset,
              top: topOffset,
              bottom: bottomOffset,
              child: IgnorePointer(
                child: Opacity(
                  opacity: isMobile ? 0.9 : 1.0,
                  child: SizedBox(
                    width: imageSize,
                    height: imageSize,
                    child: Image.asset(
                      imageAssetPath,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const SizedBox(),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
