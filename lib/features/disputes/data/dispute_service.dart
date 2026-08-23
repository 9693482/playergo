import 'package:supabase_flutter/supabase_flutter.dart';

class Dispute {
  final String id;
  final String reservationId;
  final String openedBy;
  final String reason;
  final String? description;
  final String status;
  final String? resolution;
  final String? resolvedBy;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? openerName;

  Dispute({
    required this.id,
    required this.reservationId,
    required this.openedBy,
    required this.reason,
    this.description,
    required this.status,
    this.resolution,
    this.resolvedBy,
    required this.createdAt,
    this.resolvedAt,
    this.openerName,
  });

  factory Dispute.fromMap(Map<String, dynamic> map) {
    return Dispute(
      id: map['id'] as String,
      reservationId: map['reservation_id'] as String,
      openedBy: map['opened_by'] as String,
      reason: map['reason'] as String,
      description: map['description'] as String?,
      status: map['status'] as String,
      resolution: map['resolution'] as String?,
      resolvedBy: map['resolved_by'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      resolvedAt: map['resolved_at'] != null ? DateTime.parse(map['resolved_at'] as String) : null,
      openerName: map['opener_profile']?['full_name'] as String?,
    );
  }
}

class DisputeService {
  final SupabaseClient _client = Supabase.instance.client;

  static const List<String> disputeReasons = [
    'Jugador no se presentó',
    'Jugador llegó tarde',
    'Jugador no corresponde al perfil',
    'Problema con el pago',
    'Problema con la cancha',
    'Conducta inapropiada',
    'Otro',
  ];

  Future<void> openDispute({
    required String reservationId,
    required String openedBy,
    required String reason,
    String? description,
  }) async {
    await _client.from('disputes').insert({
      'reservation_id': reservationId,
      'opened_by': openedBy,
      'reason': reason,
      'description': description,
      'status': 'OPEN',
    });
  }

  Future<List<Dispute>> getDisputesForReservation(String reservationId) async {
    final data = await _client
        .from('disputes')
        .select('''
          *,
          opener_profile:profiles!disputes_opened_by_fkey(full_name)
        ''')
        .eq('reservation_id', reservationId)
        .order('created_at', ascending: false);

    return (data as List).map((d) => Dispute.fromMap(d)).toList();
  }

  Future<List<Dispute>> getAllOpenDisputes() async {
    final data = await _client
        .from('disputes')
        .select('''
          *,
          opener_profile:profiles!disputes_opened_by_fkey(full_name)
        ''')
        .eq('status', 'OPEN')
        .order('created_at', ascending: false);

    return (data as List).map((d) => Dispute.fromMap(d)).toList();
  }

  Future<void> resolveDispute({
    required String disputeId,
    required String resolvedBy,
    required String resolution,
  }) async {
    await _client.from('disputes').update({
      'status': 'RESOLVED',
      'resolution': resolution,
      'resolved_by': resolvedBy,
      'resolved_at': DateTime.now().toIso8601String(),
    }).eq('id', disputeId);
  }

  Future<void> closeDispute(String disputeId) async {
    await _client.from('disputes').update({
      'status': 'CLOSED',
    }).eq('id', disputeId);
  }
}
