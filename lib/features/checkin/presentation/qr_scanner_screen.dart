import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../data/qr_service.dart';
import '../../notifications/data/notification_service.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final _qrService = QRService();
  final _notificationService = NotificationService();
  MobileScannerController? _controller;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final barcode = capture.barcodes.first;
    final token = barcode.rawValue;
    if (token == null || token.isEmpty) return;

    setState(() => _isProcessing = true);
    _controller?.stop();

    try {
      final result = await _qrService.validateToken(token);

      if (!result['valid']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error']),
              backgroundColor: AppColors.error,
            ),
          );
          Navigator.pop(context, false);
        }
        return;
      }

      final qrToken = result['qr_token'] as QRToken;
      final reservation = result['reservation'] as Map<String, dynamic>;

      if (mounted) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.darkSurface,
            title: Text(
              'Confirmar Check-in',
              style: AppTypography.subtitle1.copyWith(
                color: AppColors.darkTextPrimary,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fecha: ${reservation['reservation_date']}',
                  style: AppTypography.body2.copyWith(
                    color: AppColors.darkTextSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Hora: ${reservation['start_time']} - ${reservation['end_time']}',
                  style: AppTypography.body2.copyWith(
                    color: AppColors.darkTextSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Confirmar llegada del jugador?',
                  style: AppTypography.body1.copyWith(
                    color: AppColors.darkTextPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  'Cancelar',
                  style: AppTypography.body2.copyWith(
                    color: AppColors.darkTextSecondary,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.small,
                  ),
                ),
                child: Text('Confirmar', style: AppTypography.button),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          await _qrService.processCheckIn(
            qrTokenId: qrToken.id,
            reservationId: qrToken.reservationId,
            playerId: reservation['player_id'],
            teamId: reservation['team_id'],
          );

          await _notificationService.sendPushToUser(
            userId: reservation['player_id'],
            title: 'Check-in registrado',
            body: 'Tu llegada ha sido confirmada',
            type: 'checkin',
            data: {'reservation_id': qrToken.reservationId},
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Check-in exitoso'),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.pop(context, true);
          }
        } else {
          _controller?.start();
          setState(() => _isProcessing = false);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
        Navigator.pop(context, false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkSurface,
        title: Text(
          'Escanear QR',
          style: AppTypography.h2.copyWith(
            color: AppColors.darkTextPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkTextPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          if (_isProcessing)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          Positioned(
            bottom: 32,
            left: 32,
            right: 32,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.darkSurface.withAlpha(230),
                borderRadius: AppRadius.medium,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.qr_code_scanner, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    _isProcessing ? 'Procesando...' : 'Apunta al QR del jugador',
                    style: AppTypography.body2.copyWith(
                      color: AppColors.darkTextPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
