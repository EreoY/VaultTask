import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/glass_theme.dart';
import 'glass_widgets.dart';

class AetherSideNav extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final bool isDark;

  const AetherSideNav({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? user?.email?.split('@').first ?? 'Commander';

    return Container(
      width: 260,
      height: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 128, 24, 32),
      decoration: BoxDecoration(
        color: GlassColors.background.withOpacity(0.4),
        border: Border(
          right: BorderSide(color: GlassColors.ghostBorder, width: 1.0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand Title (Top Left)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Aether AI',
                style: GlassText.headlineLG().copyWith(
                  color: GlassColors.primary,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Hello, $displayName',
                style: GlassText.bodyMD().copyWith(
                  color: GlassColors.onSurfaceVariant.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          
          SizedBox(height: ExecutiveSpacing.sectionGap(context) / 2),
          
          // Navigation Menu

          Expanded(
            child: Column(
              children: [
                _NavItem(
                  icon: Icons.dashboard_outlined,
                  label: 'Dashboard',
                  isActive: selectedIndex == 0,
                  onTap: () => onItemSelected(0),
                ),
                _NavItem(
                  icon: Icons.grid_view_rounded,
                  label: 'Boards',
                  isActive: selectedIndex == 1,
                  onTap: () => onItemSelected(1),
                ),
                _NavItem(
                  icon: Icons.calendar_today_outlined,
                  label: 'Calendar',
                  isActive: selectedIndex == 2,
                  onTap: () => onItemSelected(2),
                ),
                _NavItem(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Chat',
                  isActive: selectedIndex == 3,
                  onTap: () => onItemSelected(3),
                ),
                _NavItem(
                  icon: Icons.person_outline_rounded,
                  label: 'Profile',
                  isActive: selectedIndex == 4,
                  onTap: () => onItemSelected(4),
                ),
              ],
            ),
          ),
          
          // Profile Avatar at Bottom
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: GlassColors.outlineVariant.withOpacity(0.2), width: 1),
              image: user?.photoURL != null 
                ? DecorationImage(
                    image: NetworkImage(user!.photoURL!),
                    fit: BoxFit.cover,
                  )
                : null,
            ),
            child: user?.photoURL == null 
              ? const Icon(Icons.person_outline_rounded, size: 24, color: GlassColors.primary)
              : null,
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ExecutiveRadius.xl),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: isActive
              ? BoxDecoration(
                  color: GlassColors.primary.withOpacity(0.1),
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(ExecutiveRadius.xl)),
                  border: const Border(
                    left: BorderSide(color: GlassColors.primary, width: 2),
                  ),
                )
              : null,
          child: Row(
            children: [
              Icon(
                icon,
                color: isActive ? GlassColors.primary : GlassColors.onSurfaceVariant.withOpacity(0.6),
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: GlassText.bodyMD().copyWith(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                  color: isActive ? GlassColors.primary : GlassColors.onSurfaceVariant.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
