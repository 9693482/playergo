import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QRToken {
  final String id;
  final String reservationId;
  final String token;
  final String signature;
  final DateTime expiresAt;
  final bool isUsed;
  final DateTime? usedAt;
  final DateTime createdAt;

  QRToken({
    required this.id,
    required this.reservationId,
    required this.token,
    required this.signature,
    required this.expiresAt,
    this.isUsed = false,
    this.usedAt,
    required this.createdAt,
  });

  factory QRToken.fromMap(Map<String, dynamic> map) {
    return QRToken(
      id: map['id'] as String,
      reservationId: map['reservation_id'] as String,
      token: map['token'] as String,
      signature: map['signature'] as String,
      expiresAt: DateTime.parse(map['expires_at'] as String),
      isUsed: map['is_used'] as bool? ?? false,
      usedAt: map['used_at'] != null ? DateTime.parse(map['used_at'] as String) : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class CheckIn {
  final String id;
  final String reservationId;
  final String qrTokenId;
  final String playerId;
  final String teamId;
  final DateTime checkedInAt;

  CheckIn({
    required this.id,
    required this.reservationId,
    required this.qrTokenId,
    required this.playerId,
    required this.teamId,
    required this.checkedInAt,
  });

  factory CheckIn.fromMap(Map<String, dynamic> map) {
    return CheckIn(
      id: map['id'] as String,
      reservationId: map['reservation_id'] as String,
      qrTokenId: map['qr_token_id'] as String,
      playerId: map['player_id'] as String,
      teamId: map['team_id'] as String,
      checkedInAt: DateTime.parse(map['checked_in_at'] as String),
    );
  }
}

class QRService {
  final SupabaseClient _client = Supabase.instance.client;

  static const String _secretKey = 'playergo_qr_secret_2024';
  static const int _tokenLength = 32;
  static const int _expiryMinutes = 60;

  String _generateToken() {
    final random = Random.secure();
    final values = List<int>.generate(_tokenLength, (_) => random.nextInt(256));
    return base64Url.encode(values).substring(0, _tokenLength);
  }

  String _generateSignature(String token) {
    final hmac = Hmac(sha256, utf8.encode(_secretKey));
    final digest = hmac.convert(utf8.encode(token));
    return digest.toString();
  }

  bool _verifySignature(String token, String signature) {
    return _generateSignature(token) == signature;
  }

  Future<QRToken> generateQRToken({
    required String reservationId,
    required String playerId,
    required String teamId,
  }) async {
    await _client.from('qr_tokens').update({
      'is_used': true,
      'used_at': DateTime.now().toIso8601String(),
    }).eq('reservation_id', reservationId).eq('is_used', false);

    final token = _generateToken();
    final signature = _generateSignature(token);
    final expiresAt = DateTime.now().add(const Duration(minutes: _expiryMinutes));

    final data = await _client
        .from('qr_tokens')
        .insert({
          'reservation_id': reservationId,
          'token': token,
          'signature': signature,
          'expires_at': expiresAt.toIso8601String(),
        })
        .select()
        .single();

    return QRToken.fromMap(data);
  }

  Future<QRToken?> getActiveToken(String reservationId) async {
    final data = await _client
        .from('qr_tokens')
        .select()
        .eq('reservation_id', reservationId)
        .eq('is_used', false)
        .gt('expires_at', DateTime.now().toIso8601String())
        .order('created_at', ascending: false)
        .maybeSingle();

    return data != null ? QRToken.fromMap(data) : null;
  }

  Future<Map<String, dynamic>> validateToken(String token) async {
    final data = await _client
        .from('qr_tokens')
        .select()
        .eq('token', token)
        .maybeSingle();

    if (data == null) {
      return {'valid': false, 'error': 'Token no encontrado'};
    }

    final qrToken = QRToken.fromMap(data);

    if (qrToken.isUsed) {
      return {'valid': false, 'error': 'QR ya fue escaneado'};
    }

    if (qrToken.expiresAt.isBefore(DateTime.now())) {
      return {'valid': false, 'error': 'QR expirado'};
    }

    if (!_verifySignature(qrToken.token, qrToken.signature)) {
      return {'valid': false, 'error': 'Firma inválida'};
    }

    final reservation = await _client
        .from('reservations')
        .select()
        .eq('id', qrToken.reservationId)
        .single();

    return {
      'valid': true,
      'qr_token': qrToken,
      'reservation': reservation,
    };
  }

  Future<CheckIn> processCheckIn({
    required String qrTokenId,
    required String reservationId,
    required String playerId,
    required String teamId,
    double? latitude,
    double? longitude,
    String? deviceId,
  }) async {
    final existing = await _client
        .from('check_ins')
        .select()
        .eq('reservation_id', reservationId)
        .maybeSingle();

    if (existing != null) {
      return CheckIn.fromMap(existing);
    }

    await _client.from('qr_tokens').update({
      'is_used': true,
      'used_at': DateTime.now().toIso8601String(),
    }).eq('id', qrTokenId);

    final data = await _client
        .from('check_ins')
        .insert({
          'reservation_id': reservationId,
          'qr_token_id': qrTokenId,
          'player_id': playerId,
          'team_id': teamId,
          'latitude': latitude,
          'longitude': longitude,
          'device_id': deviceId,
        })
        .select()
        .single();

    await _client.from('reservations').update({
      'status': 'CONFIRMED',
    }).eq('id', reservationId);

    return CheckIn.fromMap(data);
  }

  Future<CheckIn?> getCheckIn(String reservationId) async {
    final data = await _client
        .from('check_ins')
        .select()
        .eq('reservation_id', reservationId)
        .maybeSingle();

    return data != null ? CheckIn.fromMap(data) : null;
  }
}
