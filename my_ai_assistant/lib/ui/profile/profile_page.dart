import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/glass_theme.dart';
import '../common/glass_widgets.dart';

class ProfilePage extends StatelessWidget {
  final bool isDark;
  final bool isActive;
  const ProfilePage({super.key, required this.isDark, this.isActive = true});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return SingleChildScrollView(
      padding: EdgeInsets.all(ExecutiveSpacing.containerPadding(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AetherStaggeredFadeIn(
            index: 0,
            isActive: isActive,
            child: _buildHeader(user),
          ),
          SizedBox(height: ExecutiveSpacing.sectionGap(context)),
          AetherStaggeredFadeIn(
            index: 1,
            isActive: isActive,
            child: _buildSettingsSection(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(User? user) {
    return Row(
      children: [
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: GlassColors.primary.withOpacity(0.1),
              width: 1,
            ),
            color: GlassColors.primary.withOpacity(0.05),
          ),
          child: ClipOval(
            child: user?.photoURL != null
                ? Image.network(
                    user!.photoURL!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.person_outline_rounded,
                      size: 64,
                      color: GlassColors.primary,
                    ),
                  )
                : const Icon(
                    Icons.person_outline_rounded,
                    size: 64,
                    color: GlassColors.primary,
                  ),
          ),
        ),
        const SizedBox(width: 64),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user?.displayName ??
                  user?.email?.split('@').first.toUpperCase() ??
                  'COMMANDER',
              style: GlassText.headlineXL().copyWith(fontSize: 48),
            ),
            const SizedBox(height: 8),
            Text(
              user?.email?.toUpperCase() ?? 'STRATEGIC OPERATOR',
              style: GlassText.labelSM().copyWith(
                color: GlassColors.onSurfaceVariant.withOpacity(0.6),
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 24),
            _buildGhostButton('EDIT PROFILE'),
          ],
        ),
      ],
    );
  }

  Widget _buildGhostButton(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ExecutiveRadius.circular),
        border: Border.all(color: GlassColors.outlineVariant.withOpacity(0.3)),
      ),
      child: Text(label, style: GlassText.labelSM().copyWith(fontSize: 10)),
    );
  }

  Widget _buildSettingsSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'System Settings',
          style: GlassText.headlineLG().copyWith(fontSize: 28),
        ),
        const SizedBox(height: 32),
        Wrap(
          spacing: 24,
          runSpacing: 24,
          children: [
            _buildSettingCard(
              'SECURITY',
              'Manage biometric & keys',
              Icons.security_rounded,
              isDark,
            ),
            _buildSettingCard(
              'AI MODEL',
              'Saturn Neural Engine 4.0',
              Icons.auto_awesome_rounded,
              isDark,
            ),
            _buildSettingCard(
              'SYNC',
              'Cloudflare D1 Storage',
              Icons.cloud_done_outlined,
              isDark,
            ),
            _buildSettingCard(
              'THEME',
              'Abyssal Dark Mode',
              Icons.dark_mode_outlined,
              isDark,
            ),
          ],
        ),
        const SizedBox(height: 80),
        GestureDetector(
          onTap: () => FirebaseAuth.instance.signOut(),
          child: Text(
            'LOGOUT SESSION',
            style: GlassText.labelSM().copyWith(
              color: Colors.red.shade300,
              letterSpacing: 2.0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingCard(
    String title,
    String desc,
    IconData icon,
    bool isDark,
  ) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(32),
      decoration: GlassDecorations.surface(radius: ExecutiveRadius.xl),
      child: Row(
        children: [
          Icon(icon, color: GlassColors.primary.withOpacity(0.5), size: 24),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GlassText.labelSM().copyWith(
                    fontSize: 10,
                    color: GlassColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: GlassText.bodyMD().copyWith(
                    fontSize: 13,
                    color: GlassColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
