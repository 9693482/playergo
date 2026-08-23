import 'package:flutter/material.dart';

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

  double get _platformFee => widget.amount * (PaymentService.platformFeePercentage / 100);
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
          const SnackBar(
            content: Text('Pago exitoso'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error en el pago: $e'),
            backgroundColor: Colors.red,
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
        appBar: AppBar(title: const Text('Pago Completado')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 80, color: Colors.green),
              const SizedBox(height: 24),
              const Text(
                'Pago exitoso',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '\$${_totalAmount.toStringAsFixed(0)} COP',
                style: const TextStyle(
                  fontSize: 20,
                  color: Color(0xFF1B5E20),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Volver'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Realizar Pago')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Resumen del pago',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _SummaryRow(label: 'Jugador', value: widget.playerName),
                    const Divider(),
                    _SummaryRow(
                      label: 'Monto del jugador',
                      value: '\$${widget.amount.toStringAsFixed(0)}',
                    ),
                    _SummaryRow(
                      label: 'Comisión plataforma (${PaymentService.platformFeePercentage.toStringAsFixed(0)}%)',
                      value: '- \$${_platformFee.toStringAsFixed(0)}',
                      valueColor: Colors.red,
                    ),
                    const Divider(),
                    _SummaryRow(
                      label: 'Total a pagar',
                      value: '\$${_totalAmount.toStringAsFixed(0)} COP',
                      isBold: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'En modo demo, el pago se procesa sin tarjeta real. En producción se integrará Stripe Checkout.',
                        style: TextStyle(color: Colors.blue[700], fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Pagar \$${_totalAmount.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
