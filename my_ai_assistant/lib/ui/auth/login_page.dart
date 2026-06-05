import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../theme/glass_theme.dart';
import '../common/glass_widgets.dart';

class LoginPage extends StatefulWidget {
  final bool isDark;
  const LoginPage({super.key, this.isDark = true});

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
    return Scaffold(
      backgroundColor: GlassColors.background,
      body: Stack(
        children: [
          // Background Aura
          Center(
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [GlassColors.primary.withOpacity(0.05), Colors.transparent],
                ),
              ),
            ),
          ),
          
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo Section
                    Text(
                      'CALENDA',
                      style: GlassText.headline().copyWith(
                        fontSize: 48,
                        letterSpacing: 12,
                        fontWeight: FontWeight.w200,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'AETHER AI ASSISTANT',
                      style: GlassText.label().copyWith(
                        letterSpacing: 4.0,
                        color: GlassColors.primary.withOpacity(0.4),
                      ),
                    ),
                    const SizedBox(height: 80),
                    
                    // Executive Prompt
                    Text(
                      'SECURE ACCESS REQUIRED',
                      style: GlassText.label().copyWith(
                        color: GlassColors.primary.withOpacity(0.6),
                        fontSize: 11,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Google Login Button
                    _isLoading
                      ? const CircularProgressIndicator(color: GlassColors.primary)
                      : GlassButton(
                          label: 'CONTINUE WITH GOOGLE',
                          width: double.infinity,
                          isDark: widget.isDark,
                          isGold: true,
                          onPressed: _handleGoogleLogin,
                        ),
                    
                    const SizedBox(height: 64),
                    Text(
                      'STRICTLY FOR EXECUTIVE USE',
                      style: GlassText.label().copyWith(
                        fontSize: 9,
                        color: GlassColors.onSurfaceVariant.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
