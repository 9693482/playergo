import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_card.dart';
import '../../auth/providers/auth_provider.dart';

class PlayerQRScreen extends ConsumerWidget {
  const PlayerQRScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);
    final player = ref.watch(currentPlayerProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkSurface,
        title: Text(
          'Mi QR',
          style: AppTypography.h2.copyWith(
            color: AppColors.darkTextPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkTextPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: profile.when(
        data: (p) {
          if (p == null) {
            return Center(
              child: GlassCard(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_off, size: 48, color: AppColors.darkTextSecondary),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Perfil no encontrado',
                      style: AppTypography.subtitle1.copyWith(color: AppColors.darkTextPrimary),
                    ),
                  ],
                ),
              ),
            );
          }

          final playerId = player.valueOrNull?.id ?? p.id;
          final playerName = p.fullName ?? 'Jugador';
          final qrData = 'https://playergo.app/player/$playerId';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.lg),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppRadius.medium,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(40),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 220,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                GlassCard(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          playerName[0].toUpperCase(),
                          style: AppTypography.h2.copyWith(color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        playerName,
                        style: AppTypography.h3.copyWith(
                          color: AppColors.darkTextPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'ID: ${playerId.substring(0, 8)}...',
                        style: AppTypography.body2.copyWith(
                          color: AppColors.darkTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: qrData));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Link copiado al portapapeles'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copiar link'),
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
                const SizedBox(height: AppSpacing.lg),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.info.withAlpha(20),
                    borderRadius: AppRadius.medium,
                    border: Border.all(color: AppColors.info.withAlpha(60)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.info, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Muestra este QR o comparte el link para que el equipo te identifique.',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.info,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Text('Error: $e', style: const TextStyle(color: AppColors.darkTextSecondary)),
        ),
      ),
    );
  }
}
