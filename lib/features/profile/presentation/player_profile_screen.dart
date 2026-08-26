import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/currency.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/animated_entrance.dart';
import '../../../core/widgets/glass_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/models/enums/enums.dart';
import '../../ratings/presentation/rating_summary_widget.dart';

class PlayerProfileScreen extends ConsumerWidget {
  const PlayerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);
    final player = ref.watch(currentPlayerProvider);
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final animate = !reduceMotion;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: profile.when(
          data: (p) {
            if (p == null) {
              return const Center(child: Text('Perfil no encontrado'));
            }

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ResponsiveContainer(
                maxWidth: 600,
                child: Column(
                  children: [
                    AnimatedEntrance(
                      delay: Duration.zero,
                      animate: animate,
                      child: _buildHeader(p, player),
                    ),
                    AnimatedEntrance(
                      delay: const Duration(milliseconds: 40),
                      animate: animate,
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withAlpha(0),
                              AppColors.primary,
                              AppColors.primary.withAlpha(0),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AnimatedEntrance(
                      delay: const Duration(milliseconds: 80),
                      animate: animate,
                      child: _buildInfoSection(context, p, player),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (p.id.isNotEmpty)
                      AnimatedEntrance(
                        delay: const Duration(milliseconds: 160),
                        animate: animate,
                        child: _buildAccountSection(context),
                      ),
                    const SizedBox(height: AppSpacing.lg),
                    if (p.id.isNotEmpty)
                      AnimatedEntrance(
                        delay: const Duration(milliseconds: 240),
                        animate: animate,
                        child: _buildLogoutSection(context, ref),
                      ),
                    if (p.id.isNotEmpty)
                      AnimatedEntrance(
                        delay: const Duration(milliseconds: 320),
                        animate: animate,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                          child: _buildRatingsSection(p),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.xxxl),
                  ],
                ),
              ),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  Widget _buildHeader(dynamic p, AsyncValue<dynamic> player) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      decoration: const BoxDecoration(
        color: AppColors.darkSurface,
        border: Border(
          bottom: BorderSide(color: AppColors.darkSurfaceVariant, width: 0.5),
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: AppColors.primary,
            backgroundImage: p.photoUrl != null
                ? NetworkImage(p.photoUrl!)
                : null,
            child: p.photoUrl == null
                ? Text(
                    (p.fullName ?? 'J')[0].toUpperCase(),
                    style: AppTypography.h1.copyWith(
                      color: AppColors.textOnPrimary,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            p.fullName ?? 'Sin nombre',
            style: AppTypography.h2.copyWith(
              color: AppColors.darkTextPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: p.role == UserRole.player
                  ? AppColors.primary.withAlpha(30)
                  : AppColors.warning.withAlpha(30),
              borderRadius: AppRadius.full,
            ),
            child: Text(
              p.role == UserRole.player ? 'JUGADOR' : 'EQUIPO',
              style: AppTypography.caption.copyWith(
                color: p.role == UserRole.player
                    ? AppColors.primary
                    : AppColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildVerificationBadge(p),
        ],
      ),
    );
  }

  Widget _buildVerificationBadge(dynamic p) {
    final color = _getVerificationColor(p.verificationStatus.name);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: AppRadius.full,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getVerificationIcon(p.verificationStatus.name),
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            _getVerificationText(p.verificationStatus.name),
            style: AppTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(
    BuildContext context,
    dynamic p,
    AsyncValue<dynamic> player,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: player.when(
        data: (pl) {
          if (pl == null) {
            return GlassCard(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                children: [
                  const Icon(
                    Icons.sports_soccer,
                    size: 48,
                    color: AppColors.darkTextSecondary,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Aun no tienes perfil de jugador',
                    style: AppTypography.body1.copyWith(
                      color: AppColors.darkTextSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.medium,
                      ),
                    ),
                    child: Text(
                      'Completar perfil',
                      style: AppTypography.button,
                    ),
                  ),
                ],
              ),
            );
          }

          return GlassCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.email_outlined,
                  label: 'Correo',
                  value: p.email ?? '-',
                ),
                const _Divider(),
                _InfoRow(
                  icon: Icons.phone_outlined,
                  label: 'Telefono',
                  value: p.phone ?? '-',
                ),
                const _Divider(),
                _InfoRow(
                  icon: Icons.star_outline,
                  label: 'Calificacion',
                  value: pl.rating.toStringAsFixed(1),
                  valueColor: AppColors.warning,
                ),
                const _Divider(),
                _InfoRow(
                  icon: Icons.sports_soccer_outlined,
                  label: 'Partidos',
                  value: pl.completedMatches.toString(),
                ),
                const _Divider(),
                _InfoRow(
                  icon: Icons.attach_money,
                  label: 'Precio/partido',
                  value: CurrencyInfo.format(
                    pl.pricePerMatch,
                    CurrencyInfo.fromCountryCode('CO'),
                  ),
                  valueColor: AppColors.primary,
                ),
                const _Divider(),
                _InfoRow(
                  icon: Icons.work_outline,
                  label: 'Experiencia',
                  value: '${pl.experienceYears} anios',
                ),
                const _Divider(),
                _InfoRow(
                  icon: Icons.circle,
                  label: 'Disponible',
                  value: pl.availabilityStatus ? 'Si' : 'No',
                  valueColor: pl.availabilityStatus
                      ? AppColors.success
                      : AppColors.error,
                ),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildLogoutSection(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: ListTile(
          leading: const Icon(Icons.logout, color: AppColors.error),
          title: Text(
            'Cerrar sesión',
            style: AppTypography.subtitle2.copyWith(color: AppColors.error),
          ),
          trailing: const Icon(Icons.chevron_right, color: AppColors.darkTextSecondary),
          onTap: () async {
            await ref.read(authServiceProvider).signOut();
            if (context.mounted) context.go('/login');
          },
        ),
      ),
    );
  }

  Widget _buildRatingsSection(dynamic p) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Calificaciones',
            style: AppTypography.subtitle1.copyWith(
              color: AppColors.darkTextPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          RatingSummaryWidget(userId: p.id),
        ],
      ),
    );
  }

  Widget _buildAccountSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: ListTile(
          leading: const Icon(
            Icons.account_circle_outlined,
            color: AppColors.primary,
          ),
          title: Text(
            'Cuenta y privacidad',
            style: AppTypography.subtitle2.copyWith(
              color: AppColors.darkTextPrimary,
            ),
          ),
          subtitle: Text(
            'Verificación, legales y eliminar cuenta',
            style: AppTypography.caption.copyWith(
              color: AppColors.darkTextSecondary,
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right,
            color: AppColors.darkTextSecondary,
          ),
          onTap: () => context.push('/account'),
        ),
      ),
    );
  }

  Color _getVerificationColor(String? status) {
    switch (status) {
      case 'VERIFIED':
        return AppColors.success;
      case 'PENDING':
        return AppColors.warning;
      case 'REJECTED':
        return AppColors.error;
      case 'SUSPENDED':
        return AppColors.darkTextSecondary;
      default:
        return AppColors.darkTextSecondary;
    }
  }

  IconData _getVerificationIcon(String? status) {
    switch (status) {
      case 'VERIFIED':
        return Icons.verified;
      case 'PENDING':
        return Icons.hourglass_top;
      case 'REJECTED':
        return Icons.cancel;
      case 'SUSPENDED':
        return Icons.block;
      default:
        return Icons.help_outline;
    }
  }

  String _getVerificationText(String? status) {
    switch (status) {
      case 'VERIFIED':
        return 'Verificado';
      case 'PENDING':
        return 'En revision';
      case 'REJECTED':
        return 'Rechazado';
      case 'SUSPENDED':
        return 'Suspendido';
      default:
        return 'Sin verificar';
    }
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Divider(
        color: AppColors.darkSurfaceVariant,
        height: 1,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.darkTextSecondary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label,
              style: AppTypography.body2.copyWith(
                color: AppColors.darkTextSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: AppTypography.body2.copyWith(
              color: valueColor ?? AppColors.darkTextPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
