import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/reservation.dart';

class ReservationService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Reservation>> getTeamReservations(String teamId) async {
    final data = await _client
        .from('reservations')
        .select()
        .eq('team_id', teamId)
        .order('reservation_date', ascending: false);

    return data.map((json) => Reservation.fromJson(json)).toList();
  }

  Future<List<Reservation>> getPlayerReservations(String playerId) async {
    final data = await _client
        .from('reservations')
        .select()
        .eq('player_id', playerId)
        .order('reservation_date', ascending: false);

    return data.map((json) => Reservation.fromJson(json)).toList();
  }

  Future<Reservation> createReservation({
    required String teamId,
    required String playerId,
    required String sportId,
    required String positionId,
    String? venueId,
    required String date,
    required String startTime,
    required String endTime,
    required double durationHours,
    required double totalPrice,
    String? notes,
  }) async {
    final data = await _client
        .from('reservations')
        .insert({
          'team_id': teamId,
          'player_id': playerId,
          'venue_id': venueId,
          'sport_id': sportId,
          'position_id': positionId,
          'reservation_date': date,
          'start_time': startTime,
          'end_time': endTime,
          'duration_hours': durationHours,
          'total_price': totalPrice,
          'notes': notes,
          'status': 'PENDING',
        })
        .select()
        .single();

    await _client.from('reservation_status_history').insert({
      'reservation_id': data['id'],
      'new_status': 'PENDING',
    });

    return Reservation.fromJson(data);
  }

  Future<void> updateStatus({
    required String reservationId,
    required String newStatus,
    String? reason,
  }) async {
    final current = await _client
        .from('reservations')
        .select('status')
        .eq('id', reservationId)
        .single();

    await _client.from('reservations').update({
      'status': newStatus,
      if (newStatus == 'CANCELLED') 'cancellation_reason': reason,
    }).eq('id', reservationId);

    await _client.from('reservation_status_history').insert({
      'reservation_id': reservationId,
      'old_status': current['status'],
      'new_status': newStatus,
      'reason': reason,
    });
  }

  Future<void> acceptReservation(String reservationId) async {
    await updateStatus(
      reservationId: reservationId,
      newStatus: 'ACCEPTED',
    );
  }

  Future<void> rejectReservation(String reservationId, {String? reason}) async {
    await updateStatus(
      reservationId: reservationId,
      newStatus: 'REJECTED',
      reason: reason,
    );
  }

  Future<void> cancelReservation(String reservationId, {String? reason}) async {
    await updateStatus(
      reservationId: reservationId,
      newStatus: 'CANCELLED',
      reason: reason,
    );
  }

  Future<void> confirmPayment(String reservationId) async {
    await updateStatus(
      reservationId: reservationId,
      newStatus: 'PAID',
    );
  }

  Future<void> completeReservation(String reservationId) async {
    await updateStatus(
      reservationId: reservationId,
      newStatus: 'COMPLETED',
    );
  }
}
