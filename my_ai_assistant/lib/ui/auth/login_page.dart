import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../theme/glass_theme.dart';
import '../common/glass_widgets.dart';

class LoginPage extends StatefulWidget {
  final bool isDark;
  const LoginPage({super.key, this.isDark = false});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    try {
      final cred = await AuthService().signInWithGoogle();
      if (cred == null && mounted) {
        GlassNotifications.show(context, 'Login cancelled or failed', isError: true);
      }
    } catch (e) {
      if (mounted) {
        GlassNotifications.show(context, 'Login failed: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return Scaffold(
      backgroundColor: GlassColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 24.0 : 48.0,
              vertical: 32.0,
            ),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 460),
              padding: EdgeInsets.all(isMobile ? 28.0 : 40.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(ExecutiveRadius.xxl), // 32px
                boxShadow: [
                  BoxShadow(
                    color: GlassColors.deepBlack.withOpacity(0.06),
                    blurRadius: 30,
                    spreadRadius: 2,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Top Hero Bento Pastel Logo Badge
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: GlassColors.bentoLavender,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: GlassColors.bentoLavender.withOpacity(0.6),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        size: 38,
                        color: GlassColors.deepBlack,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Brand Title
                  Text(
                    'Calenda AI',
                    style: GlassText.headlineLG().copyWith(
                      fontWeight: FontWeight.w800,
                      color: GlassColors.deepBlack,
                      fontSize: 30,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Your Executive AI Assistant & Hybrid Workspace',
                    textAlign: TextAlign.center,
                    style: GlassText.secondary().copyWith(
                      color: GlassColors.onSurfaceVariant,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Soft Orange Bento Feature Highlight Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: GlassColors.bentoOrange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.verified_user_rounded,
                          size: 18,
                          color: GlassColors.deepBlack,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Secure One-Tap Authentication',
                          style: GlassText.labelSM().copyWith(
                            color: GlassColors.deepBlack,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Google Sign-In Primary Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleGoogleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GlassColors.deepBlack,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(ExecutiveRadius.circular),
                        ),
                        shadowColor: GlassColors.deepBlack.withOpacity(0.2),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Google Logo Icon Placeholder / G-Icon
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.g_mobiledata_rounded,
                                    color: GlassColors.deepBlack,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Continue with Google',
                                  style: GlassText.bodyLG().copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Footer Security Note
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 14,
                        color: GlassColors.onSurfaceVariant.withOpacity(0.6),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Local-First SQLite & End-to-End Encrypted',
                        style: GlassText.secondary().copyWith(
                          fontSize: 12,
                          color: GlassColors.onSurfaceVariant.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
