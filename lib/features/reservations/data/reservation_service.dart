import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/reservation.dart';
import '../../notifications/data/notification_service.dart';
import '../../../core/services/audit_service.dart';

class ReservationService {
  final SupabaseClient _client = Supabase.instance.client;
  final NotificationService _notificationService = NotificationService();
  final AuditService _auditService = AuditService();

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
    await _auditService.log(
      action: 'create_reservation',
      entity: 'reservation',
      details: {'team_id': teamId, 'player_id': playerId, 'date': date},
    );

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

    await _notificationService.sendPushToUser(
      userId: await _getPlayerUserId(playerId),
      title: 'Nueva solicitud de reserva',
      body: 'Un equipo quiere reservarte para el $date',
      type: 'reservation_request',
      data: {'reservation_id': data['id']},
    );

    return Reservation.fromJson(data);
  }

  Future<void> updateStatus({
    required String reservationId,
    required String newStatus,
    String? reason,
  }) async {
    final current = await _client
        .from('reservations')
        .select('status, player_id, team_id')
        .eq('id', reservationId)
        .single();

    await _auditService.log(
      action: 'status_change:$newStatus',
      entity: 'reservation',
      entityId: reservationId,
      details: {'old_status': current['status'], 'new_status': newStatus},
    );

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

    String? notifUserId;
    String title = '';
    String body = '';

    switch (newStatus) {
      case 'ACCEPTED':
        notifUserId = await _getTeamUserId(current['team_id']);
        title = 'Reserva aceptada';
        body = 'Tu solicitud de reserva ha sido aceptada';
        break;
      case 'REJECTED':
        notifUserId = await _getTeamUserId(current['team_id']);
        title = 'Reserva rechazada';
        body = 'Tu solicitud de reserva ha sido rechazada${reason != null ? ': $reason' : ''}';
        break;
      case 'CANCELLED':
        final isTeamCancel = current['status'] == 'ACCEPTED' || current['status'] == 'PENDING';
        if (isTeamCancel) {
          notifUserId = await _getPlayerUserId(current['player_id']);
        } else {
          notifUserId = await _getTeamUserId(current['team_id']);
        }
        title = 'Reserva cancelada';
        body = 'Una reserva ha sido cancelada';
        break;
      case 'COMPLETED':
        notifUserId = await _getTeamUserId(current['team_id']);
        title = 'Reserva completada';
        body = 'El partido ha finalizado. ¡Califica tu experiencia!';
        break;
    }

    if (notifUserId != null) {
      await _notificationService.sendPushToUser(
        userId: notifUserId,
        title: title,
        body: body,
        type: 'reservation_${newStatus.toLowerCase()}',
        data: {'reservation_id': reservationId},
      );
    }
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

  Future<String> _getPlayerUserId(String playerId) async {
    final data = await _client
        .from('players')
        .select('user_id')
        .eq('id', playerId)
        .single();
    return data['user_id'] as String;
  }

  Future<String> _getTeamUserId(String teamId) async {
    final data = await _client
        .from('teams')
        .select('user_id')
        .eq('id', teamId)
        .single();
    return data['user_id'] as String;
  }
}
