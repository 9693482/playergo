import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/animated_entrance.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/responsive/responsive.dart';
import '../../auth/providers/auth_provider.dart';

class TeamProfileScreen extends ConsumerWidget {
  const TeamProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);
    final team = ref.watch(currentTeamProvider);

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
                child: team.when(
                  data: (t) {
                    if (t == null) {
                      return Column(
                        children: [
                          _buildHeader(p, null),
                          const SizedBox(height: AppSpacing.lg),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                            ),
                            child: AnimatedEntrance(
                              delay: const Duration(milliseconds: 100),
                              child: GlassCard(
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.group,
                                      size: 48,
                                      color: AppColors.darkTextSecondary,
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    Text(
                                      'Aun no tienes perfil de equipo',
                                      style: AppTypography.body1.copyWith(
                                        color: AppColors.darkTextSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.lg),
                                    ElevatedButton(
                                      onPressed: () =>
                                          context.push('/create-team'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor:
                                            AppColors.textOnPrimary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: AppRadius.medium,
                                        ),
                                      ),
                                      child: Text(
                                        'Crear equipo',
                                        style: AppTypography.button,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    return Column(
                      children: [
                        _buildHeader(p, t),
                        const _GradientDivider(),
                        const SizedBox(height: AppSpacing.lg),
                        _buildInfoSection(context, p, t),
                        if (t.description != null &&
                            t.description!.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.lg),
                          _buildDescriptionSection(t),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        _buildAccountSection(context),
                        const SizedBox(height: AppSpacing.lg),
                        _buildLogoutSection(context, ref),
                        const SizedBox(height: AppSpacing.xxxl),
                      ],
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  ),
                  error: (e, _) => Center(child: Text('Error: $e')),
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

  Widget _buildHeader(dynamic p, dynamic t) {
    final name = t != null ? t.teamName : (p.fullName ?? 'Sin nombre');
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final photoUrl = p.photoUrl;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      decoration: const BoxDecoration(
        color: AppColors.darkSurface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.darkSurfaceVariant,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: AppColors.primary,
            backgroundImage:
                photoUrl != null ? NetworkImage(photoUrl) : null,
            child: photoUrl == null
                ? Text(
                    initial,
                    style: AppTypography.h1.copyWith(
                      color: AppColors.textOnPrimary,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            name,
            style: AppTypography.h2.copyWith(
              color: AppColors.darkTextPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.warning.withAlpha(30),
              borderRadius: AppRadius.full,
            ),
            child: Text(
              'EQUIPO',
              style: AppTypography.caption.copyWith(
                color: AppColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, dynamic p, dynamic t) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: AnimatedEntrance(
        delay: const Duration(milliseconds: 150),
        child: GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow(
                icon: Icons.group_outlined,
                label: 'Equipo',
                value: t.teamName,
              ),
              const _Divider(),
              _InfoRow(
                icon: Icons.person_outlined,
                label: 'Capitan',
                value: t.captainName ?? '-',
              ),
              const _Divider(),
              _InfoRow(
                icon: Icons.phone_outlined,
                label: 'Telefono',
                value: t.captainPhone ?? '-',
              ),
              const _Divider(),
              _InfoRow(
                icon: Icons.email_outlined,
                label: 'Correo',
                value: p.email ?? '-',
              ),
              const _Divider(),
              _InfoRow(
                icon: Icons.star_outline,
                label: 'Calificacion',
                value: t.rating.toStringAsFixed(1),
                valueColor: AppColors.warning,
              ),
              const _Divider(),
              _InfoRow(
                icon: Icons.sports_soccer_outlined,
                label: 'Partidos jugados',
                value: t.completedMatches.toString(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDescriptionSection(dynamic t) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: AnimatedEntrance(
        delay: const Duration(milliseconds: 250),
        child: GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Descripcion',
                style: AppTypography.subtitle1.copyWith(
                  color: AppColors.darkTextPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                t.description!,
                style: AppTypography.body1.copyWith(
                  color: AppColors.darkTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: AnimatedEntrance(
        delay: const Duration(milliseconds: 350),
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
              'Verificacion, legales y eliminar cuenta',
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
      ),
    );
  }

  Widget _buildLogoutSection(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: AnimatedEntrance(
        delay: const Duration(milliseconds: 450),
        child: GlassCard(
          padding: EdgeInsets.zero,
          child: ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: Text(
              'Cerrar sesion',
              style: AppTypography.subtitle2.copyWith(
                color: AppColors.error,
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right,
              color: AppColors.darkTextSecondary,
            ),
            onTap: () async {
              await ref.read(authServiceProvider).signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ),
      ),
    );
  }
}

class _GradientDivider extends StatelessWidget {
  const _GradientDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.success],
        ),
      ),
    );
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
