import 'package:flutter_test/flutter_test.dart';
import 'package:playergo/shared/models/sport.dart';

void main() {
  group('Sport.fromJson', () {
    test('parses valid sport', () {
      final json = {
        'id': 'sport-1',
        'name': 'Fútbol',
        'slug': 'futbol',
        'is_active': true,
      };
      final s = Sport.fromJson(json);
      expect(s.id, 'sport-1');
      expect(s.name, 'Fútbol');
      expect(s.slug, 'futbol');
      expect(s.isActive, true);
    });

    test('defaults is_active to true when null', () {
      final json = {
        'id': 'sport-1',
        'name': 'Fútbol',
        'slug': 'futbol',
        'is_active': null,
      };
      final s = Sport.fromJson(json);
      expect(s.isActive, true);
    });
  });

  group('Sport.toJson', () {
    test('serializes correctly', () {
      const sport = Sport(id: 's1', name: 'Basketball', slug: 'basketball', isActive: false);
      final json = sport.toJson();
      expect(json['id'], 's1');
      expect(json['name'], 'Basketball');
      expect(json['slug'], 'basketball');
      expect(json['is_active'], false);
    });
  });
}
