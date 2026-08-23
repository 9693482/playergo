import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/validators/validators.dart';
import '../../../generated/app_localizations.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _selectedRole = '';
  bool _isLoading = false;
  bool _obscurePassword = true;
  int _currentStep = 1;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
        role: _selectedRole,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.registerSuccess),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorGeneric),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _selectRole(String role) {
    setState(() {
      _selectedRole = role;
      _currentStep = 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: _currentStep == 2
          ? AppBar(
              backgroundColor: AppColors.darkBackground,
              foregroundColor: AppColors.darkTextPrimary,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _currentStep = 1),
              ),
            )
          : null,
      body: SafeArea(
        child: _currentStep == 1
            ? _buildRoleSelection(s)
            : _buildRegistrationForm(s),
      ),
    );
  }

  Widget _buildRoleSelection(AppLocalizations s) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 60),
          // Logo
          Center(
            child: RichText(
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
          ),
          const SizedBox(height: AppSpacing.xxxl),
          Text(
            s.whatDoYouWant,
            textAlign: TextAlign.center,
            style: AppTypography.h2.copyWith(color: AppColors.darkTextPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            s.chooseOption,
            textAlign: TextAlign.center,
            style: AppTypography.body1.copyWith(color: AppColors.darkTextSecondary),
          ),
          const SizedBox(height: AppSpacing.xxxl),
          // TEAM card
          _RoleOptionCard(
            icon: Icons.groups_outlined,
            title: s.needPlayer,
            subtitle: s.needPlayerDesc,
            onTap: () => _selectRole('TEAM'),
          ),
          const SizedBox(height: AppSpacing.lg),
          // PLAYER card
          _RoleOptionCard(
            icon: Icons.sports_soccer_outlined,
            title: s.wantToPlay,
            subtitle: s.wantToPlayDesc,
            onTap: () => _selectRole('PLAYER'),
          ),
          const Spacer(),
          // Login link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                s.hasAccount,
                style: AppTypography.body2.copyWith(color: AppColors.darkTextSecondary),
              ),
              TextButton(
                onPressed: () => context.go('/login'),
                child: Text(
                  s.signIn,
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
    );
  }

  Widget _buildRegistrationForm(AppLocalizations s) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.sm),
            // Progress indicator
            Row(
              children: [
                _ProgressDot(isActive: true),
                const SizedBox(width: 4),
                _ProgressDot(isActive: false),
                const SizedBox(width: 4),
                _ProgressDot(isActive: false),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              s.createYourAccount,
              style: AppTypography.h2.copyWith(color: AppColors.darkTextPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              s.completeInfo,
              style: AppTypography.body2.copyWith(color: AppColors.darkTextSecondary),
            ),
            const SizedBox(height: AppSpacing.xxxl),
            // Name field
            Text(
              _selectedRole == 'PLAYER' ? s.fullName : s.teamName,
              style: AppTypography.subtitle2.copyWith(color: AppColors.darkTextSecondary),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _fullNameController,
              style: AppTypography.body1.copyWith(color: AppColors.darkTextPrimary),
              decoration: InputDecoration(
                hintText: _selectedRole == 'PLAYER' ? s.fullNameHint : s.teamNameHint,
                prefixIcon: const Icon(Icons.person_outlined, color: AppColors.darkTextSecondary),
                filled: true,
                fillColor: AppColors.darkSurfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: AppRadius.medium,
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.medium,
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
              validator: (v) => _selectedRole == 'PLAYER'
                  ? Validators.fullName(v)
                  : Validators.teamName(v),
            ),
            const SizedBox(height: AppSpacing.lg),
            // Email field
            Text(
              s.email,
              style: AppTypography.subtitle2.copyWith(color: AppColors.darkTextSecondary),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: AppTypography.body1.copyWith(color: AppColors.darkTextPrimary),
              decoration: InputDecoration(
                hintText: s.emailHint,
                prefixIcon: const Icon(Icons.email_outlined, color: AppColors.darkTextSecondary),
                filled: true,
                fillColor: AppColors.darkSurfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: AppRadius.medium,
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.medium,
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
              validator: Validators.email,
            ),
            const SizedBox(height: AppSpacing.lg),
            // Password field
            Text(
              s.password,
              style: AppTypography.subtitle2.copyWith(color: AppColors.darkTextSecondary),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: AppTypography.body1.copyWith(color: AppColors.darkTextPrimary),
              decoration: InputDecoration(
                hintText: s.passwordHint,
                prefixIcon: const Icon(Icons.lock_outlined, color: AppColors.darkTextSecondary),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.darkTextSecondary,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                filled: true,
                fillColor: AppColors.darkSurfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: AppRadius.medium,
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.medium,
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
              validator: Validators.password,
            ),
            const SizedBox(height: AppSpacing.lg),
            // Confirm password
            Text(
              s.confirmPassword,
              style: AppTypography.subtitle2.copyWith(color: AppColors.darkTextSecondary),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: true,
              style: AppTypography.body1.copyWith(color: AppColors.darkTextPrimary),
              decoration: InputDecoration(
                hintText: s.confirmPasswordHint,
                prefixIcon: const Icon(Icons.lock_outlined, color: AppColors.darkTextSecondary),
                filled: true,
                fillColor: AppColors.darkSurfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: AppRadius.medium,
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.medium,
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
              validator: (v) {
                if (v != _passwordController.text) {
                  return s.passwordMismatch;
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.xxxl),
            // Register button
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  disabledBackgroundColor: AppColors.primary.withAlpha(128),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.medium,
                  ),
                  elevation: 0,
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
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            s.createAccount.toUpperCase(),
                            style: AppTypography.button,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          const Icon(Icons.arrow_forward, size: 20),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // Terms
            Text(
              s.termsAccept,
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(color: AppColors.darkTextSecondary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {},
                  child: Text(s.termsAndConditions, style: AppTypography.caption.copyWith(color: AppColors.primary)),
                ),
                Text(
                  ' y ',
                  style: AppTypography.caption.copyWith(color: AppColors.darkTextSecondary),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(s.privacyPolicy, style: AppTypography.caption.copyWith(color: AppColors.primary)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }
}

class _RoleOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RoleOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: AppRadius.large,
          border: Border.all(color: AppColors.darkSurfaceVariant, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(25),
                borderRadius: AppRadius.medium,
              ),
              child: Icon(icon, color: AppColors.primary, size: 28),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.subtitle1.copyWith(color: AppColors.darkTextPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTypography.body2.copyWith(color: AppColors.darkTextSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.darkTextSecondary),
          ],
        ),
      ),
    );
  }
}

class _ProgressDot extends StatelessWidget {
  final bool isActive;

  const _ProgressDot({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 4,
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : AppColors.darkSurfaceVariant,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
