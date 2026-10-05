import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env.dart';
import '../../../core/logging/app_logger.dart';

class StripeService {
  final SupabaseClient _client = Supabase.instance.client;

  bool _initialized = false;

  bool get isConfigured => Env.stripePublishableKey.isNotEmpty;

  Future<void> initialize() async {
    if (_initialized || !isConfigured) return;

    try {
      Stripe.publishableKey = Env.stripePublishableKey;
      await Stripe.instance.applySettings();
      _initialized = true;
      AppLogger.info('Stripe initialized');
    } catch (e) {
      AppLogger.error('Stripe init failed', e);
    }
  }

  Future<Map<String, dynamic>> createPaymentIntent({
    required double amount,
    required String currency,
    String? reservationId,
  }) async {
    final amountInCents = (amount * 100).round();

    try {
      final response = await _client.functions.invoke(
        'create-payment-intent',
        body: {
          'amount': amountInCents,
          'currency': currency.toLowerCase(),
          'reservation_id': reservationId,
        },
      );

      if (response.status != 200) {
        throw Exception('Failed to create payment intent');
      }

      return response.data as Map<String, dynamic>;
    } on FunctionException catch (e) {
      AppLogger.warning('Payment intent function error: ${e.details}');
      return _createDemoPaymentIntent(amountInCents, currency);
    } catch (e) {
      AppLogger.error('Payment intent error', e);
      rethrow;
    }
  }

  Map<String, dynamic> _createDemoPaymentIntent(int amount, String currency) {
    final id = 'pi_demo_${DateTime.now().millisecondsSinceEpoch}';
    return {
      'id': id,
      'client_secret': 'demo_secret_$id',
      'amount': amount,
      'currency': currency,
    };
  }

  Future<void> presentPaymentSheet({
    required String clientSecret,
    required double amount,
    required String currency,
  }) async {
    if (!isConfigured) {
      AppLogger.info('Stripe not configured, using demo mode');
      return;
    }

    await initialize();

    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          style: ThemeMode.dark,
          merchantDisplayName: 'PlayerGO',
        ),
      );

      await Stripe.instance.presentPaymentSheet();
      AppLogger.info('Payment sheet completed');
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        AppLogger.info('Payment canceled by user');
        rethrow;
      }
      AppLogger.error('Stripe payment error', e);
      rethrow;
    }
  }

  Future<bool> confirmPayment({
    required String clientSecret,
    required double amount,
    required String currency,
    String? reservationId,
  }) async {
    try {
      if (isConfigured) {
        await presentPaymentSheet(
          clientSecret: clientSecret,
          amount: amount,
          currency: currency,
        );
        return true;
      } else {
        AppLogger.info('Demo mode: payment simulated for $amount $currency');
        await Future.delayed(const Duration(milliseconds: 800));
        return true;
      }
    } catch (e) {
      AppLogger.error('Payment confirmation failed', e);
      return false;
    }
  }
}
