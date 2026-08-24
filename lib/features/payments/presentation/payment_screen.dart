import 'package:flutter/material.dart';

import '../../../core/config/currency.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../data/payment_service.dart';

class PaymentScreen extends StatefulWidget {
  final String reservationId;
  final double amount;
  final String playerName;

  const PaymentScreen({
    super.key,
    required this.reservationId,
    required this.amount,
    required this.playerName,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _paymentService = PaymentService();
  bool _isProcessing = false;
  bool _isCompleted = false;

  double get _platformFee =>
      widget.amount * (PaymentService.platformFeePercentage / 100);
  double get _totalAmount => widget.amount;

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);

    try {
      final payment = await _paymentService.createPayment(
        reservationId: widget.reservationId,
        amount: widget.amount,
        currency: 'COP',
      );

      final intent = await _paymentService.createPaymentIntent(
        amount: widget.amount,
        currency: 'COP',
      );

      await _paymentService.processPayment(
        paymentId: payment.id,
        stripePaymentIntentId: intent['payment_intent_id'],
      );

      setState(() => _isCompleted = true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Pago exitoso'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error en el pago: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCompleted) {
      return Scaffold(
        backgroundColor: AppColors.darkBackground,
        appBar: AppBar(
          backgroundColor: AppColors.darkSurface,
          title: Text(
            'Pago Completado',
            style: AppTypography.h2.copyWith(
              color: AppColors.darkTextPrimary,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.darkTextPrimary),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
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
                const Icon(Icons.check_circle, size: 64, color: AppColors.success),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Pago exitoso',
                  style: AppTypography.h2.copyWith(
                    color: AppColors.darkTextPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${CurrencyInfo.format(_totalAmount, CurrencyInfo.fromCountryCode('CO'))} COP',
                  style: AppTypography.subtitle1.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.medium,
                      ),
                      elevation: 0,
                    ),
                    child: Text('Volver', style: AppTypography.button),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkSurface,
        title: Text(
          'Realizar Pago',
          style: AppTypography.h2.copyWith(
            color: AppColors.darkTextPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkTextPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.darkSurface,
                borderRadius: AppRadius.medium,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resumen del pago',
                    style: AppTypography.subtitle1.copyWith(
                      color: AppColors.darkTextPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _SummaryRow(label: 'Jugador', value: widget.playerName),
                  const _Divider(),
                  _SummaryRow(
                    label: 'Monto del jugador',
                    value: CurrencyInfo.format(
                      widget.amount,
                      CurrencyInfo.fromCountryCode('CO'),
                    ),
                  ),
                  _SummaryRow(
                    label:
                        'Comision plataforma (${PaymentService.platformFeePercentage.toStringAsFixed(0)}%)',
                    value:
                        '- ${CurrencyInfo.format(_platformFee, CurrencyInfo.fromCountryCode('CO'))}',
                    valueColor: AppColors.error,
                  ),
                  const _Divider(),
                  _SummaryRow(
                    label: 'Total a pagar',
                    value:
                        '${CurrencyInfo.format(_totalAmount, CurrencyInfo.fromCountryCode('CO'))} COP',
                    isBold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.info.withAlpha(25),
                borderRadius: AppRadius.medium,
                border: Border.all(
                  color: AppColors.info.withAlpha(80),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.info),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'En modo demo, el pago se procesa sin tarjeta real. En produccion se integrara Stripe Checkout.',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.info,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.medium,
                  ),
                  elevation: 0,
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Pagar ${CurrencyInfo.format(_totalAmount, CurrencyInfo.fromCountryCode('CO'))}',
                        style: AppTypography.button,
                      ),
              ),
            ),
          ],
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

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.body2.copyWith(
              color: AppColors.darkTextSecondary,
            ),
          ),
          Text(
            value,
            style: isBold
                ? AppTypography.subtitle2.copyWith(
                    color: valueColor ?? AppColors.darkTextPrimary,
                  )
                : AppTypography.body2.copyWith(
                    color: valueColor ?? AppColors.darkTextPrimary,
                  ),
          ),
        ],
      ),
    );
  }
}
