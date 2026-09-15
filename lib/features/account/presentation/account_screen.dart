import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/feedback/app_feedback.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/account_service.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  final _accountService = AccountService();
  bool _isResending = false;
  bool _isDeleting = false;

  bool get _emailVerified =>
      Supabase.instance.client.auth.currentUser?.emailConfirmedAt != null;

  String? get _email => Supabase.instance.client.auth.currentUser?.email;

  Future<void> _resend() async {
    if (_email == null) return;
    setState(() => _isResending = true);
    try {
      await _accountService.resendEmailConfirmation(_email!);
      if (mounted) {
        AppFeedback.showSuccess(context, 'Correo de verificación reenviado');
      }
    } catch (e) {
      if (mounted) AppFeedback.showError(context, 'No se pudo reenviar: $e');
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Eliminar cuenta y datos'),
            content: const Text(
              'Esta acción borrará permanentemente tu cuenta y todos tus datos '
              'personales (documentos, notificaciones, reservas asociadas). '
              'No se puede deshacer.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Eliminar definitivamente'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    setState(() => _isDeleting = true);
    try {
      await _accountService.deleteAccount();
      await ref.read(authServiceProvider).signOut();
      if (mounted) context.go('/login');
    } catch (e) {
      if (mounted) AppFeedback.showError(context, 'No se pudo eliminar: $e');
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkTextPrimary,
        title: const Text('Mi cuenta y privacidad'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
          tooltip: 'Volver',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _EmailCard(
                  verified: _emailVerified,
                  email: _email ?? '-',
                  isResending: _isResending,
                  onResend: _resend,
                ),
                const SizedBox(height: AppSpacing.lg),
                const Text(
                  'Gestión',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkTextSecondary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _Tile(
                  icon: Icons.verified_user_outlined,
                  title: 'Verificación de identidad (KYC)',
                  subtitle: 'Sube tu documento para verificar tu cuenta',
                  onTap: () => context.push('/verification'),
                ),
                _Tile(
                  icon: Icons.description_outlined,
                  title: 'Términos y Condiciones',
                  onTap: () => context.push('/legal/terms'),
                ),
                _Tile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Política de Privacidad',
                  onTap: () => context.push('/legal/privacy'),
                ),
                const SizedBox(height: AppSpacing.xxl),
                const Text(
                  'Zona de peligro',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.darkSurface,
                    borderRadius: AppRadius.medium,
                    border: Border.all(
                      color: AppColors.error.withAlpha(60),
                    ),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.delete_forever,
                        color: AppColors.error),
                    title: const Text(
                      'Eliminar mi cuenta y datos',
                      style: TextStyle(color: AppColors.error),
                    ),
                    subtitle: const Text(
                      'Borrado permanente (Ley 1581 / GDPR)',
                      style: TextStyle(color: AppColors.darkTextSecondary),
                    ),
                    trailing: _isDeleting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.chevron_right,
                            color: AppColors.darkTextSecondary),
                    onTap: _isDeleting ? null : _deleteAccount,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmailCard extends StatelessWidget {
  final bool verified;
  final String email;
  final bool isResending;
  final VoidCallback onResend;

  const _EmailCard({
    required this.verified,
    required this.email,
    required this.isResending,
    required this.onResend,
  });

  @override
  Widget build(BuildContext context) {
    final color = verified ? AppColors.success : AppColors.warning;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: AppRadius.medium,
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        children: [
          Icon(
            verified ? Icons.mark_email_read : Icons.mark_email_unread,
            color: color,
            size: 28,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  verified ? 'Correo verificado' : 'Correo sin verificar',
                  style: AppTypography.subtitle2.copyWith(
                    color: AppColors.darkTextPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: AppTypography.caption
                      .copyWith(color: AppColors.darkTextSecondary),
                ),
              ],
            ),
          ),
          if (!verified)
            TextButton(
              onPressed: isResending ? null : onResend,
              child: isResending
                  ? const Text('Enviando...')
                  : const Text('Reenviar'),
            ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _Tile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: AppRadius.medium,
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(
          title,
          style: AppTypography.subtitle2
              .copyWith(color: AppColors.darkTextPrimary),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: AppTypography.caption
                    .copyWith(color: AppColors.darkTextSecondary),
              )
            : null,
        trailing: const Icon(Icons.chevron_right,
            color: AppColors.darkTextSecondary),
        onTap: onTap,
      ),
    );
  }
}
