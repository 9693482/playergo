import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../data/qr_service.dart';

class QRDisplayScreen extends StatefulWidget {
  final String reservationId;
  final String playerId;
  final String teamId;

  const QRDisplayScreen({
    super.key,
    required this.reservationId,
    required this.playerId,
    required this.teamId,
  });

  @override
  State<QRDisplayScreen> createState() => _QRDisplayScreenState();
}

class _QRDisplayScreenState extends State<QRDisplayScreen> {
  final _qrService = QRService();
  QRToken? _token;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _generateToken();
  }

  Future<void> _generateToken() async {
    try {
      final token = await _qrService.generateQRToken(
        reservationId: widget.reservationId,
        playerId: widget.playerId,
        teamId: widget.teamId,
      );
      setState(() {
        _token = token;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkSurface,
        title: Text(
          'Mi QR de Check-in',
          style: AppTypography.h2.copyWith(
            color: AppColors.darkTextPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkTextPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _hasError
              ? _buildErrorState()
              : _token!.isUsed
                  ? _buildUsedState()
                  : _buildActiveState(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.xxl),
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: AppRadius.medium,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: AppColors.error),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Error al generar QR',
              style: AppTypography.subtitle1.copyWith(
                color: AppColors.darkTextPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: _generateToken,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.medium,
                ),
              ),
              child: Text('Reintentar', style: AppTypography.button),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsedState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.xxl),
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: AppRadius.medium,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 56, color: AppColors.success),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'QR ya fue escaneado',
              style: AppTypography.subtitle1.copyWith(
                color: AppColors.darkTextPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Check-in registrado a las ${_formatTime(_token!.usedAt!)}',
              style: AppTypography.body2.copyWith(
                color: AppColors.darkTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveState() {
    final minutesLeft = _token!.expiresAt.difference(DateTime.now()).inMinutes;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        children: [
          Icon(
            Icons.qr_code_2,
            size: 48,
            color: AppColors.primary,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Muestra este codigo al equipo',
            style: AppTypography.body1.copyWith(
              color: AppColors.darkTextSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
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
              data: _token!.token,
              version: QrVersions.auto,
              size: 240,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: AppRadius.medium,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Expira en:',
                      style: AppTypography.body2.copyWith(
                        color: AppColors.darkTextSecondary,
                      ),
                    ),
                    Text(
                      '$minutesLeft minutos',
                      style: AppTypography.subtitle2.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Divider(
                    color: AppColors.darkSurfaceVariant,
                    height: 1,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Estado:',
                      style: AppTypography.body2.copyWith(
                        color: AppColors.darkTextSecondary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withAlpha(30),
                        borderRadius: AppRadius.full,
                      ),
                      child: Text(
                        'Activo',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.warning.withAlpha(25),
              borderRadius: AppRadius.medium,
              border: Border.all(
                color: AppColors.warning.withAlpha(80),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber, color: AppColors.warning),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'No cierres esta pantalla. El QR expira en ${60} minutos.',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
