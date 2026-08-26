import 'package:flutter/material.dart';

import '../../../core/config/currency.dart';
import '../../../core/feedback/app_feedback.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/animated_entrance.dart';
import '../../../core/widgets/glass_card.dart';
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
        AppFeedback.showSuccess(context, 'Pago exitoso');
      }
    } catch (e) {
      AppLogger.error('Error procesando pago', e);
      if (mounted) {
        AppFeedback.showError(
          context,
          'No se pudo completar el pago. Inténtalo de nuevo.',
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final animate = !reduceMotion;

    if (_isCompleted) {
      return Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: SafeArea(
          child: ResponsiveContainer(
            maxWidth: 600,
            child: Column(
              children: [
                AnimatedEntrance(
                  delay: Duration.zero,
                  animate: animate,
                  child: _buildHeader('Pago Completado'),
                ),
                Expanded(
                  child: Center(
                    child: AnimatedEntrance(
                      delay: const Duration(milliseconds: 160),
                      animate: animate,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xxl),
                        child: GlassCard(
                          padding: const EdgeInsets.all(AppSpacing.xxxl),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle,
                                size: 64,
                                color: AppColors.success,
                              ),
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
                    ),
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
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: 600,
          child: Column(
            children: [
              AnimatedEntrance(
                delay: Duration.zero,
                animate: animate,
                child: _buildHeader('Realizar Pago'),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedEntrance(
                        delay: const Duration(milliseconds: 40),
                        animate: animate,
                        child: GlassCard(
                          padding: const EdgeInsets.all(AppSpacing.lg),
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
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AnimatedEntrance(
                        delay: const Duration(milliseconds: 120),
                        animate: animate,
                        child: GlassCard(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          borderColor: AppColors.info,
                          glow: AppColors.info,
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
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      AnimatedEntrance(
                        delay: const Duration(milliseconds: 200),
                        animate: animate,
                        child: SizedBox(
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
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Text(
                'PlayerGO',
                style: AppTypography.h2.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                title,
                style: AppTypography.body2.copyWith(
                  color: AppColors.darkTextSecondary,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: AppColors.darkTextPrimary,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 2,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.primary.withAlpha(0),
              ],
            ),
          ),
        ),
      ],
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
