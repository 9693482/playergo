import 'package:flutter_test/flutter_test.dart';
import 'package:playergo/shared/models/team.dart';

void main() {
  group('Team.fromJson', () {
    test('parses valid team with all fields', () {
      final json = {
        'id': 'team-1',
        'user_id': 'user-1',
        'team_name': 'Los Tigres',
        'logo_url': 'https://example.com/logo.png',
        'sport_id': 'sport-1',
        'description': 'Equipo top',
        'captain_name': 'Juan',
        'captain_phone': '3001234567',
        'rating': 4.5,
        'completed_matches': 12,
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-06-01T00:00:00Z',
      };
      final t = Team.fromJson(json);
      expect(t.id, 'team-1');
      expect(t.userId, 'user-1');
      expect(t.teamName, 'Los Tigres');
      expect(t.logoUrl, 'https://example.com/logo.png');
      expect(t.sportId, 'sport-1');
      expect(t.description, 'Equipo top');
      expect(t.captainName, 'Juan');
      expect(t.captainPhone, '3001234567');
      expect(t.rating, 4.5);
      expect(t.completedMatches, 12);
    });

    test('defaults for nullable/optional fields', () {
      final json = {
        'id': 't2',
        'user_id': 'u2',
        'team_name': 'Minimal',
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
      };
      final t = Team.fromJson(json);
      expect(t.logoUrl, isNull);
      expect(t.sportId, isNull);
      expect(t.description, isNull);
      expect(t.captainName, isNull);
      expect(t.captainPhone, isNull);
      expect(t.rating, 0);
      expect(t.completedMatches, 0);
    });

    test('handles null rating gracefully', () {
      final json = {
        'id': 't3',
        'user_id': 'u3',
        'team_name': 'NoRating',
        'rating': null,
        'completed_matches': null,
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
      };
      final t = Team.fromJson(json);
      expect(t.rating, 0);
      expect(t.completedMatches, 0);
    });
  });

  group('Team.toJson', () {
    test('serializes editable fields only', () {
      final team = Team(
        id: 'id',
        userId: 'uid',
        teamName: 'Tigers',
        rating: 4.8,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      final json = team.toJson();
      expect(json['team_name'], 'Tigers');
      expect(json.containsKey('id'), false);
      expect(json.containsKey('user_id'), false);
      expect(json.containsKey('rating'), false);
    });
  });
}
