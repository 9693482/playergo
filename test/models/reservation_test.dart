import 'package:flutter_test/flutter_test.dart';
import 'package:playergo/shared/models/reservation.dart';
import 'package:playergo/shared/models/enums/enums.dart';

void main() {
  group('Reservation.fromJson', () {
    test('parses PENDING status', () {
      final json = _baseJson('PENDING');
      final r = Reservation.fromJson(json);
      expect(r.status, ReservationStatus.pending);
    });

    test('parses ACCEPTED status', () {
      final r = Reservation.fromJson(_baseJson('ACCEPTED'));
      expect(r.status, ReservationStatus.accepted);
    });

    test('parses REJECTED status', () {
      final r = Reservation.fromJson(_baseJson('REJECTED'));
      expect(r.status, ReservationStatus.rejected);
    });

    test('parses PAYMENT_PENDING status', () {
      final r = Reservation.fromJson(_baseJson('PAYMENT_PENDING'));
      expect(r.status, ReservationStatus.paymentPending);
    });

    test('parses PAID status', () {
      final r = Reservation.fromJson(_baseJson('PAID'));
      expect(r.status, ReservationStatus.paid);
    });

    test('parses CONFIRMED status', () {
      final r = Reservation.fromJson(_baseJson('CONFIRMED'));
      expect(r.status, ReservationStatus.confirmed);
    });

    test('parses COMPLETED status', () {
      final r = Reservation.fromJson(_baseJson('COMPLETED'));
      expect(r.status, ReservationStatus.completed);
    });

    test('parses CANCELLED status', () {
      final r = Reservation.fromJson(_baseJson('CANCELLED'));
      expect(r.status, ReservationStatus.cancelled);
    });

    test('parses DISPUTED status', () {
      final r = Reservation.fromJson(_baseJson('DISPUTED'));
      expect(r.status, ReservationStatus.disputed);
    });

    test('defaults to PENDING for unknown', () {
      final r = Reservation.fromJson(_baseJson('UNKNOWN'));
      expect(r.status, ReservationStatus.pending);
    });

    test('parses numeric fields correctly', () {
      final json = _baseJson('PENDING');
      json['duration_hours'] = 2.5;
      json['total_price'] = 150000;
      final r = Reservation.fromJson(json);
      expect(r.durationHours, 2.5);
      expect(r.totalPrice, 150000.0);
    });

    test('parses nullable fields', () {
      final json = _baseJson('PENDING');
      json['venue_id'] = null;
      json['notes'] = null;
      json['cancellation_reason'] = null;
      final r = Reservation.fromJson(json);
      expect(r.venueId, isNull);
      expect(r.notes, isNull);
      expect(r.cancellationReason, isNull);
    });

    test('parses date fields', () {
      final r = Reservation.fromJson(_baseJson('PENDING'));
      expect(r.reservationDate, isA<DateTime>());
      expect(r.createdAt, isA<DateTime>());
      expect(r.startTime, '18:00');
      expect(r.endTime, '20:00');
    });
  });

  group('Reservation.toJson', () {
    test('serializes correctly', () {
      final r = Reservation(
        id: 'id',
        teamId: 'team',
        playerId: 'player',
        sportId: 'sport',
        positionId: 'pos',
        reservationDate: DateTime(2026, 8, 30),
        startTime: '18:00',
        endTime: '20:00',
        durationHours: 2,
        totalPrice: 100000,
        status: ReservationStatus.accepted,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      final json = r.toJson();
      expect(json['status'], 'ACCEPTED');
      expect(json['team_id'], 'team');
      expect(json['total_price'], 100000);
    });
  });
}

Map<String, dynamic> _baseJson(String status) {
  return {
    'id': 'res-id',
    'team_id': 'team-id',
    'player_id': 'player-id',
    'venue_id': null,
    'sport_id': 'sport-id',
    'position_id': 'pos-id',
    'reservation_date': '2026-08-30',
    'start_time': '18:00',
    'end_time': '20:00',
    'duration_hours': 2,
    'total_price': 100000,
    'status': status,
    'notes': null,
    'cancellation_reason': null,
    'created_at': '2026-08-20T10:00:00Z',
    'updated_at': '2026-08-20T10:00:00Z',
  };
}
