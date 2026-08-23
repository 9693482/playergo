import 'enums/enums.dart';

class Reservation {
  final String id;
  final String teamId;
  final String playerId;
  final String? venueId;
  final String sportId;
  final String positionId;
  final DateTime reservationDate;
  final String startTime;
  final String endTime;
  final double durationHours;
  final double totalPrice;
  final ReservationStatus status;
  final String? notes;
  final String? cancellationReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Reservation({
    required this.id,
    required this.teamId,
    required this.playerId,
    this.venueId,
    required this.sportId,
    required this.positionId,
    required this.reservationDate,
    required this.startTime,
    required this.endTime,
    required this.durationHours,
    required this.totalPrice,
    this.status = ReservationStatus.pending,
    this.notes,
    this.cancellationReason,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: json['id'] as String,
      teamId: json['team_id'] as String,
      playerId: json['player_id'] as String,
      venueId: json['venue_id'] as String?,
      sportId: json['sport_id'] as String,
      positionId: json['position_id'] as String,
      reservationDate: DateTime.parse(json['reservation_date'] as String),
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      durationHours: (json['duration_hours'] as num).toDouble(),
      totalPrice: (json['total_price'] as num).toDouble(),
      status: _parseStatus(json['status'] as String?),
      notes: json['notes'] as String?,
      cancellationReason: json['cancellation_reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'team_id': teamId,
      'player_id': playerId,
      'venue_id': venueId,
      'sport_id': sportId,
      'position_id': positionId,
      'reservation_date': reservationDate.toIso8601String().split('T')[0],
      'start_time': startTime,
      'end_time': endTime,
      'duration_hours': durationHours,
      'total_price': totalPrice,
      'status': status.name.toUpperCase(),
      'notes': notes,
    };
  }

  static ReservationStatus _parseStatus(String? value) {
    switch (value) {
      case 'PENDING':
        return ReservationStatus.pending;
      case 'ACCEPTED':
        return ReservationStatus.accepted;
      case 'REJECTED':
        return ReservationStatus.rejected;
      case 'PAYMENT_PENDING':
        return ReservationStatus.paymentPending;
      case 'PAID':
        return ReservationStatus.paid;
      case 'CONFIRMED':
        return ReservationStatus.confirmed;
      case 'ARRIVED':
        return ReservationStatus.arrived;
      case 'COMPLETED':
        return ReservationStatus.completed;
      case 'CANCELLED':
        return ReservationStatus.cancelled;
      case 'DISPUTED':
        return ReservationStatus.disputed;
      case 'REFUNDED':
        return ReservationStatus.refunded;
      default:
        return ReservationStatus.pending;
    }
  }
}
