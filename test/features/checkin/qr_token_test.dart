import 'package:flutter_test/flutter_test.dart';
import 'package:playergo/features/checkin/data/qr_service.dart';

void main() {
  group('QRToken.fromMap', () {
    test('parses valid token', () {
      final map = {
        'id': 'qr-1',
        'reservation_id': 'res-1',
        'token': 'abc123',
        'signature': 'sig456',
        'expires_at': '2026-12-31T23:59:59Z',
        'is_used': false,
        'used_at': null,
        'created_at': '2026-01-01T00:00:00Z',
      };
      final t = QRToken.fromMap(map);
      expect(t.id, 'qr-1');
      expect(t.reservationId, 'res-1');
      expect(t.token, 'abc123');
      expect(t.signature, 'sig456');
      expect(t.isUsed, false);
      expect(t.usedAt, isNull);
    });

    test('parses used token with usedAt', () {
      final map = {
        'id': 'qr-2',
        'reservation_id': 'res-2',
        'token': 'def456',
        'signature': 'sig789',
        'expires_at': '2026-12-31T23:59:59Z',
        'is_used': true,
        'used_at': '2026-06-15T14:30:00Z',
        'created_at': '2026-06-15T10:00:00Z',
      };
      final t = QRToken.fromMap(map);
      expect(t.isUsed, true);
      expect(t.usedAt, isA<DateTime>());
    });

    test('defaults is_used to false when null', () {
      final map = {
        'id': 'qr-3',
        'reservation_id': 'res-3',
        'token': 'ghi789',
        'signature': 'sig012',
        'expires_at': '2026-12-31T23:59:59Z',
        'is_used': null,
        'created_at': '2026-01-01T00:00:00Z',
      };
      final t = QRToken.fromMap(map);
      expect(t.isUsed, false);
    });
  });

  group('CheckIn.fromMap', () {
    test('parses valid check-in', () {
      final map = {
        'id': 'ci-1',
        'reservation_id': 'res-1',
        'qr_token_id': 'qr-1',
        'player_id': 'player-1',
        'team_id': 'team-1',
        'checked_in_at': '2026-06-15T14:30:00Z',
      };
      final ci = CheckIn.fromMap(map);
      expect(ci.id, 'ci-1');
      expect(ci.reservationId, 'res-1');
      expect(ci.qrTokenId, 'qr-1');
      expect(ci.playerId, 'player-1');
      expect(ci.teamId, 'team-1');
      expect(ci.checkedInAt, isA<DateTime>());
    });
  });
}
