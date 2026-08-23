import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

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
              backgroundColor: Colors.red,
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
            title: const Text('Confirmar Check-in'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Fecha: ${reservation['reservation_date']}'),
                Text('Hora: ${reservation['start_time']} - ${reservation['end_time']}'),
                const SizedBox(height: 16),
                const Text(
                  '¿Confirmar llegada del jugador?',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Confirmar'),
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
              const SnackBar(
                content: Text('Check-in exitoso'),
                backgroundColor: Colors.green,
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
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context, false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear QR'),
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
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.qr_code_scanner, color: Color(0xFF1B5E20)),
                    const SizedBox(width: 8),
                    Text(
                      _isProcessing ? 'Procesando...' : 'Apunta al QR del jugador',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
