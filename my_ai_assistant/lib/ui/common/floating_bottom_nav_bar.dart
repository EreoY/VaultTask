import 'package:flutter/material.dart';
import '../theme/glass_theme.dart';

/// Floating Capsule-shaped Bottom Navigation Bar for Mobile (Matched to image.png)
class FloatingBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final bool isDark;
  final VoidCallback? onToggleTheme;

  const FloatingBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.isDark = false,
    this.onToggleTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0F121C), // Deep executive dark black
          borderRadius: BorderRadius.circular(40), // Capsule pill shape
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 24,
              spreadRadius: 2,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              index: 0,
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              label: 'Home',
            ),
            _buildNavItem(
              index: 1,
              icon: Icons.grid_view_rounded,
              activeIcon: Icons.grid_view_rounded,
              label: 'Boards',
            ),
            _buildNavItem(
              index: 2,
              icon: Icons.bar_chart_rounded,
              activeIcon: Icons.bar_chart_rounded,
              label: 'Calendar',
            ),
            _buildNavItem(
              index: 3,
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
              label: 'Profile',
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () => onItemSelected(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        width: isSelected ? 48 : 42,
        height: isSelected ? 48 : 42,
        decoration: isSelected
            ? const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              )
            : const BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
              ),
        child: Center(
          child: Icon(
            isSelected ? activeIcon : icon,
            color: isSelected ? GlassColors.deepBlack : Colors.white.withOpacity(0.7),
            size: isSelected ? 24 : 22,
          ),
        ),
      ),
    );
  }
}
