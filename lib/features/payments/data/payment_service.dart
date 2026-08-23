import 'package:supabase_flutter/supabase_flutter.dart';

class Payment {
  final String id;
  final String reservationId;
  final String? stripePaymentIntentId;
  final double amount;
  final String currency;
  final String status;
  final double? platformFee;
  final double? providerAmount;
  final DateTime createdAt;

  Payment({
    required this.id,
    required this.reservationId,
    this.stripePaymentIntentId,
    required this.amount,
    required this.currency,
    required this.status,
    this.platformFee,
    this.providerAmount,
    required this.createdAt,
  });

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] as String,
      reservationId: map['reservation_id'] as String,
      stripePaymentIntentId: map['stripe_payment_intent_id'] as String?,
      amount: (map['amount'] as num).toDouble(),
      currency: map['currency'] as String,
      status: map['status'] as String,
      platformFee: (map['platform_fee'] as num?)?.toDouble(),
      providerAmount: (map['provider_amount'] as num?)?.toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class PaymentService {
  final SupabaseClient _client = Supabase.instance.client;

  static const double platformFeePercentage = 15.0;

  Future<Payment> createPayment({
    required String reservationId,
    required double amount,
    required String currency,
  }) async {
    final platformFee = amount * (platformFeePercentage / 100);
    final providerAmount = amount - platformFee;

    final data = await _client
        .from('payments')
        .insert({
          'reservation_id': reservationId,
          'amount': amount,
          'currency': currency,
          'status': 'PENDING',
          'platform_fee': platformFee,
          'provider_amount': providerAmount,
        })
        .select()
        .single();

    return Payment.fromMap(data);
  }

  Future<Map<String, dynamic>> createPaymentIntent({
    required double amount,
    required String currency,
  }) async {
    final amountInCents = (amount * 100).toInt();

    return {
      'client_secret': 'demo_secret_${DateTime.now().millisecondsSinceEpoch}',
      'payment_intent_id': 'pi_demo_${DateTime.now().millisecondsSinceEpoch}',
      'amount': amountInCents,
      'currency': currency,
    };
  }

  Future<void> processPayment({
    required String paymentId,
    required String stripePaymentIntentId,
  }) async {
    await _client.from('payments').update({
      'stripe_payment_intent_id': stripePaymentIntentId,
      'status': 'COMPLETED',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', paymentId);
  }

  Future<void> failPayment(String paymentId) async {
    await _client.from('payments').update({
      'status': 'FAILED',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', paymentId);
  }

  Future<Payment?> getPaymentByReservation(String reservationId) async {
    final data = await _client
        .from('payments')
        .select()
        .eq('reservation_id', reservationId)
        .maybeSingle();

    return data != null ? Payment.fromMap(data) : null;
  }

  Future<List<Payment>> getPlayerPayments(String playerId) async {
    final data = await _client
        .from('payments')
        .select()
        .order('created_at', ascending: false);

    return (data as List).map((p) => Payment.fromMap(p)).toList();
  }

  Future<double> getPlayerEarnings(String playerId) async {
    final payments = await getPlayerPayments(playerId);
    double total = 0;
    for (final p in payments) {
      if (p.status == 'COMPLETED' && p.providerAmount != null) {
        total += p.providerAmount!;
      }
    }
    return total;
  }
}
