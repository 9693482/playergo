import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/feedback/app_feedback.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/validators/validators.dart';
import '../../../core/widgets/animated_entrance.dart';
import '../../../core/widgets/auth_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/progress_ring.dart';
import '../../../generated/app_localizations.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _btnHover = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      AppLogger.debug('LOGIN: intentando signIn');
      final authService = ref.read(authServiceProvider);
      await authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      AppLogger.debug('LOGIN: signIn OK, navegando');

      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      AppLogger.error('LOGIN fallido', e);
      if (mounted) {
        AppFeedback.showError(
          context,
          e is AuthException
              ? e.message
              : 'No pudimos iniciar sesión. Revisa tus credenciales.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final animate = !MediaQuery.of(context).disableAnimations;

    final inputBorder = OutlineInputBorder(
      borderRadius: AppRadius.medium,
      borderSide: BorderSide(color: Colors.white.withAlpha(18)),
    );
    final focusBorder = OutlineInputBorder(
      borderRadius: AppRadius.medium,
      borderSide: const BorderSide(color: AppColors.primary, width: 2),
    );

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Stack(
        children: [
          const AuthBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xxl,
                vertical: AppSpacing.lg,
              ),
              child: ResponsiveContainer(
                maxWidth: 440,
                child: AnimatedEntrance(
                  animate: animate,
                  duration: const Duration(milliseconds: 600),
                  child: GlassCard(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Column(
                              children: [
                                ProgressRing(
                                  size: 84,
                                  strokeWidth: 8,
                                  progress: 0.75,
                                  color: AppColors.primary,
                                  animate: animate,
                                  center: const Icon(
                                    Icons.sports_soccer,
                                    color: AppColors.primary,
                                    size: 34,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'Player',
                                        style: AppTypography.h1.copyWith(
                                          color: AppColors.darkTextPrimary,
                                          fontSize: 32,
                                        ),
                                      ),
                                      TextSpan(
                                        text: 'GO',
                                        style: AppTypography.h1.copyWith(
                                          color: AppColors.primary,
                                          fontSize: 32,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  s.loginSubtitle,
                                  textAlign: TextAlign.center,
                                  style: AppTypography.body1.copyWith(
                                    color: AppColors.darkTextSecondary,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Container(
                                  height: 2,
                                  width: 64,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(2),
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.primary.withAlpha(0),
                                        AppColors.primary,
                                        AppColors.primary.withAlpha(0),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxl),

                          // Email
                          Text(
                            s.email,
                            style: AppTypography.subtitle2.copyWith(
                              color: AppColors.darkTextSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: AppTypography.body1
                                .copyWith(color: AppColors.darkTextPrimary),
                            decoration: InputDecoration(
                              hintText: s.emailHint,
                              prefixIcon: const Icon(Icons.email_outlined,
                                  color: AppColors.darkTextSecondary),
                              filled: true,
                              fillColor: AppColors.darkSurfaceVariant,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.md,
                              ),
                              border: inputBorder,
                              enabledBorder: inputBorder,
                              focusedBorder: focusBorder,
                            ),
                            validator: Validators.email,
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // Password
                          Text(
                            s.password,
                            style: AppTypography.subtitle2.copyWith(
                              color: AppColors.darkTextSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: AppTypography.body1
                                .copyWith(color: AppColors.darkTextPrimary),
                            decoration: InputDecoration(
                              hintText: s.passwordHint,
                              prefixIcon: const Icon(Icons.lock_outlined,
                                  color: AppColors.darkTextSecondary),
                              suffixIcon: IconButton(
                                tooltip: _obscurePassword
                                    ? 'Mostrar contraseña'
                                    : 'Ocultar contraseña',
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: AppColors.darkTextSecondary,
                                ),
                                onPressed: () {
                                  setState(() =>
                                      _obscurePassword = !_obscurePassword);
                                },
                              ),
                              filled: true,
                              fillColor: AppColors.darkSurfaceVariant,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.md,
                              ),
                              border: inputBorder,
                              enabledBorder: inputBorder,
                              focusedBorder: focusBorder,
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Ingresa tu contraseña';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.sm),

                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {},
                              child: Text(
                                s.forgotPassword,
                                style: AppTypography.body2
                                    .copyWith(color: AppColors.primary),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // Login button
                          MouseRegion(
                            onEnter: (_) => setState(() => _btnHover = true),
                            onExit: (_) => setState(() => _btnHover = false),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOut,
                              transform: _btnHover && animate
                                  ? Matrix4.translationValues(0.0, -2.0, 0.0)
                                  : Matrix4.identity(),
                              child: SizedBox(
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: AppColors.textOnPrimary,
                                    disabledBackgroundColor:
                                        AppColors.primary.withAlpha(128),
                                    shadowColor: AppColors.primary,
                                    elevation: _isLoading
                                        ? 0
                                        : (_btnHover ? 8 : 2),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: AppRadius.medium,
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              s.signIn.toUpperCase(),
                                              style: AppTypography.button,
                                            ),
                                            const SizedBox(
                                                width: AppSpacing.sm),
                                            const Icon(Icons.arrow_forward,
                                                size: 20),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxl),

                          // Divider
                          Row(
                            children: [
                              const Expanded(
                                  child: Divider(
                                      color: AppColors.darkSurfaceVariant)),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.lg),
                                child: Text(
                                  s.orContinueWith,
                                  style: AppTypography.caption.copyWith(
                                      color: AppColors.darkTextSecondary),
                                ),
                              ),
                              const Expanded(
                                  child: Divider(
                                      color: AppColors.darkSurfaceVariant)),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xxl),

                          // Social buttons
                          Row(
                            children: [
                              Expanded(
                                child: _SocialButton(
                                  icon: Icons.g_mobiledata,
                                  label: 'Google',
                                  onTap: () {},
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: _SocialButton(
                                  icon: Icons.apple,
                                  label: 'Apple',
                                  onTap: () {},
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: _SocialButton(
                                  icon: Icons.facebook,
                                  label: 'Facebook',
                                  onTap: () {},
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xxxl),

                          // Register link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                s.noAccount,
                                style: AppTypography.body2.copyWith(
                                    color: AppColors.darkTextSecondary),
                              ),
                              TextButton(
                                onPressed: () => context.go('/register'),
                                child: Text(
                                  s.createAccount,
                                  style: AppTypography.body2.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                        ],
                      ),
                    ),
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

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.darkSurfaceVariant.withAlpha(180),
          foregroundColor: AppColors.darkTextPrimary,
          side: BorderSide(color: Colors.white.withAlpha(20)),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.medium,
          ),
        ),
        child: Icon(icon, size: 24),
      ),
    );
  }
}
