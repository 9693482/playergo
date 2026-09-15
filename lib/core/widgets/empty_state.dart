import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Estado vacío con ilustración (icono en círculo tintado), título,
/// mensaje guía y una acción opcional. Reemplaza los "No hay X" planos.
class EmptyState extends StatelessWidget {
  final IconData illustration;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final double? maxWidth;

  const EmptyState({
    super.key,
    required this.illustration,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth ?? 360),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Illustration(icon: illustration),
              const SizedBox(height: AppSpacing.xl),
              Text(
                title,
                style: AppTypography.h3.copyWith(
                  color: AppColors.darkTextPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              if (message != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  message!,
                  style: AppTypography.body2.copyWith(
                    color: AppColors.darkTextSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onAction,
                    icon: const Icon(Icons.arrow_forward),
                    label: Text(actionLabel!),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.medium,
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Illustration extends StatelessWidget {
  final IconData icon;

  const _Illustration({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(20),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 56,
        color: AppColors.primary,
      ),
    );
  }
}
