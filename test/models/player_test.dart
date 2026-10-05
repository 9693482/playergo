import 'package:flutter_test/flutter_test.dart';
import 'package:playergo/shared/models/player.dart';

void main() {
  group('Player.fromJson', () {
    test('parses valid player with all fields', () {
      final json = {
        'id': 'p1',
        'user_id': 'u1',
        'sport_id': 's1',
        'position_id': 'pos1',
        'bio': 'Mediocampista',
        'experience_years': 5,
        'price_per_match': 200000,
        'rating': 4.2,
        'completed_matches': 8,
        'availability_status': true,
        'latitude': 4.711,
        'longitude': -74.072,
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-06-01T00:00:00Z',
      };
      final p = Player.fromJson(json);
      expect(p.id, 'p1');
      expect(p.userId, 'u1');
      expect(p.sportId, 's1');
      expect(p.positionId, 'pos1');
      expect(p.bio, 'Mediocampista');
      expect(p.experienceYears, 5);
      expect(p.pricePerMatch, 200000);
      expect(p.rating, 4.2);
      expect(p.completedMatches, 8);
      expect(p.availabilityStatus, true);
      expect(p.latitude, 4.711);
      expect(p.longitude, -74.072);
    });

    test('defaults for nullable/optional fields', () {
      final json = {
        'id': 'p2',
        'user_id': 'u2',
        'sport_id': 's2',
        'position_id': 'pos2',
        'price_per_match': 100000,
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
      };
      final p = Player.fromJson(json);
      expect(p.bio, isNull);
      expect(p.experienceYears, 0);
      expect(p.rating, 0);
      expect(p.completedMatches, 0);
      expect(p.availabilityStatus, true);
      expect(p.latitude, isNull);
      expect(p.longitude, isNull);
    });

    test('handles integer price_per_match', () {
      final json = {
        'id': 'p3',
        'user_id': 'u3',
        'sport_id': 's3',
        'position_id': 'pos3',
        'price_per_match': 50000,
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
      };
      final p = Player.fromJson(json);
      expect(p.pricePerMatch, 50000.0);
    });
  });

  group('Player.toJson', () {
    test('serializes editable fields only', () {
      final player = Player(
        id: 'id',
        userId: 'uid',
        sportId: 'sid',
        positionId: 'pid',
        bio: 'test',
        experienceYears: 3,
        pricePerMatch: 150000,
        rating: 4.5,
        completedMatches: 10,
        latitude: 4.711,
        longitude: -74.072,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      final json = player.toJson();
      expect(json['user_id'], 'uid');
      expect(json['sport_id'], 'sid');
      expect(json['position_id'], 'pid');
      expect(json['bio'], 'test');
      expect(json['experience_years'], 3);
      expect(json['price_per_match'], 150000);
      expect(json['availability_status'], true);
      expect(json['latitude'], 4.711);
      expect(json['longitude'], -74.072);
      // Non-editable fields
      expect(json.containsKey('id'), false);
      expect(json.containsKey('rating'), false);
      expect(json.containsKey('completed_matches'), false);
    });
  });
}
