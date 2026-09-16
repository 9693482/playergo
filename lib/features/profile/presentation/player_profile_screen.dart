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
import '../../auth/data/auth_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/models/enums/enums.dart';
import '../../ratings/presentation/rating_summary_widget.dart';

class PlayerProfileScreen extends ConsumerStatefulWidget {
  const PlayerProfileScreen({super.key});

  @override
  ConsumerState<PlayerProfileScreen> createState() => _PlayerProfileScreenState();
}

class _PlayerProfileScreenState extends ConsumerState<PlayerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isSaving = false;
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _initControllers(dynamic profile) {
    if (_initialized || profile == null) return;
    _nameController.text = profile.fullName ?? '';
    _phoneController.text = profile.phone ?? '';
    _initialized = true;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final profile = ref.read(currentProfileProvider).valueOrNull;
    if (profile == null) return;

    setState(() => _isSaving = true);

    try {
      final updated = profile.copyWith(
        fullName: _nameController.text.trim().isNotEmpty
            ? _nameController.text.trim()
            : null,
        phone: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
      );
      await AuthService().updateProfile(updated);
      ref.invalidate(currentProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil actualizado'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.person_off, size: 64, color: AppColors.darkTextSecondary),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Perfil no encontrado',
                        style: AppTypography.h3.copyWith(color: AppColors.darkTextPrimary),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Cierra sesión y vuelve a registrarte.',
                        style: AppTypography.body2.copyWith(color: AppColors.darkTextSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            _initControllers(p);

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ResponsiveContainer(
                maxWidth: 600,
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: AppSpacing.lg),
                      AnimatedEntrance(
                        animate: animate,
                        delay: Duration.zero,
                        child: _buildAvatar(p),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      AnimatedEntrance(
                        animate: animate,
                        delay: const Duration(milliseconds: 60),
                        child: _buildFormSection(p),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AnimatedEntrance(
                        animate: animate,
                        delay: const Duration(milliseconds: 120),
                        child: _buildPlayerStats(player),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AnimatedEntrance(
                        animate: animate,
                        delay: const Duration(milliseconds: 180),
                        child: _buildRatingsSection(p),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AnimatedEntrance(
                        animate: animate,
                        delay: const Duration(milliseconds: 240),
                        child: _buildAccountSection(context),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AnimatedEntrance(
                        animate: animate,
                        delay: const Duration(milliseconds: 300),
                        child: _buildLogoutSection(context),
                      ),
                      const SizedBox(height: AppSpacing.xxxl),
                    ],
                  ),
                ),
              ),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Error al cargar perfil',
                    style: AppTypography.subtitle1.copyWith(color: AppColors.darkTextPrimary),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '$e',
                    style: AppTypography.body2.copyWith(color: AppColors.darkTextSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(currentProfileProvider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                    ),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(dynamic p) {
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
            backgroundImage: p.photoUrl != null ? NetworkImage(p.photoUrl!) : null,
            child: p.photoUrl == null
                ? Text(
                    (p.fullName ?? 'J')[0].toUpperCase(),
                    style: AppTypography.h1.copyWith(color: AppColors.textOnPrimary),
                  )
                : null,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildVerificationBadge(p),
        ],
      ),
    );
  }

  Widget _buildFormSection(dynamic p) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Información personal',
                  style: AppTypography.subtitle1.copyWith(
                    color: AppColors.darkTextPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildField(
              controller: _nameController,
              label: 'Nombre completo',
              icon: Icons.person_outline,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildField(
              controller: _phoneController,
              label: 'Teléfono',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: AppSpacing.md),
            _InfoRow(
              icon: Icons.email_outlined,
              label: 'Correo',
              value: p.email ?? '-',
            ),
            const _Divider(),
            _InfoRow(
              icon: Icons.badge_outlined,
              label: 'Rol',
              value: p.role == UserRole.player ? 'JUGADOR' : 'EQUIPO',
              valueColor: p.role == UserRole.player ? AppColors.primary : AppColors.warning,
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveProfile,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textOnPrimary,
                        ),
                      )
                    : const Icon(Icons.save_outlined, size: 18),
                label: Text(_isSaving ? 'Guardando...' : 'Guardar cambios'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.medium,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: AppTypography.body1.copyWith(color: AppColors.darkTextPrimary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.darkTextSecondary, size: 20),
        labelStyle: AppTypography.body2.copyWith(color: AppColors.darkTextSecondary),
        filled: true,
        fillColor: AppColors.darkSurfaceVariant.withAlpha(80),
        border: OutlineInputBorder(
          borderRadius: AppRadius.small,
          borderSide: const BorderSide(color: AppColors.darkSurfaceVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.small,
          borderSide: const BorderSide(color: AppColors.darkSurfaceVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.small,
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.small,
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildPlayerStats(AsyncValue<dynamic> player) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: player.when(
        data: (pl) {
          if (pl == null) {
            return GlassCard(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                children: [
                  const Icon(Icons.sports_soccer, size: 40, color: AppColors.darkTextSecondary),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Sin perfil de jugador',
                    style: AppTypography.body1.copyWith(color: AppColors.darkTextSecondary),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Los datos de juego se completarán automáticamente.',
                    style: AppTypography.caption.copyWith(color: AppColors.darkTextSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return GlassCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.sports_soccer_outlined, size: 20, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Datos de juego',
                      style: AppTypography.subtitle1.copyWith(
                        color: AppColors.darkTextPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _InfoRow(
                  icon: Icons.star_outline,
                  label: 'Calificación',
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
                  value: '${pl.experienceYears} años',
                ),
                const _Divider(),
                _InfoRow(
                  icon: Icons.circle,
                  label: 'Disponible',
                  value: pl.availabilityStatus ? 'Sí' : 'No',
                  valueColor: pl.availabilityStatus ? AppColors.success : AppColors.error,
                ),
              ],
            ),
          );
        },
        loading: () => const SizedBox(
          height: 80,
          child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
        ),
        error: (e, _) => GlassCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            'Error cargando datos: $e',
            style: AppTypography.body2.copyWith(color: AppColors.error),
          ),
        ),
      ),
    );
  }

  Widget _buildRatingsSection(dynamic p) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: GlassCard(
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
      ),
    );
  }

  Widget _buildAccountSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: ListTile(
          leading: const Icon(Icons.account_circle_outlined, color: AppColors.primary),
          title: Text(
            'Cuenta y privacidad',
            style: AppTypography.subtitle2.copyWith(color: AppColors.darkTextPrimary),
          ),
          subtitle: Text(
            'Verificación, legales y eliminar cuenta',
            style: AppTypography.caption.copyWith(color: AppColors.darkTextSecondary),
          ),
          trailing: const Icon(Icons.chevron_right, color: AppColors.darkTextSecondary),
          onTap: () => context.push('/account'),
        ),
      ),
    );
  }

  Widget _buildLogoutSection(BuildContext context) {
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

  Widget _buildVerificationBadge(dynamic p) {
    final color = _getVerificationColor(p.verificationStatus.name);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: AppRadius.full,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getVerificationIcon(p.verificationStatus.name), size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            _getVerificationText(p.verificationStatus.name),
            style: AppTypography.caption.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Color _getVerificationColor(String? status) {
    switch (status) {
      case 'VERIFIED': return AppColors.success;
      case 'PENDING': return AppColors.warning;
      case 'REJECTED': return AppColors.error;
      case 'SUSPENDED': return AppColors.darkTextSecondary;
      default: return AppColors.darkTextSecondary;
    }
  }

  IconData _getVerificationIcon(String? status) {
    switch (status) {
      case 'VERIFIED': return Icons.verified;
      case 'PENDING': return Icons.hourglass_top;
      case 'REJECTED': return Icons.cancel;
      case 'SUSPENDED': return Icons.block;
      default: return Icons.help_outline;
    }
  }

  String _getVerificationText(String? status) {
    switch (status) {
      case 'VERIFIED': return 'Verificado';
      case 'PENDING': return 'En revisión';
      case 'REJECTED': return 'Rechazado';
      case 'SUSPENDED': return 'Suspendido';
      default: return 'Sin verificar';
    }
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Divider(color: AppColors.darkSurfaceVariant, height: 1),
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
              style: AppTypography.body2.copyWith(color: AppColors.darkTextSecondary),
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
