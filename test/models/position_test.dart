import 'package:flutter_test/flutter_test.dart';
import 'package:playergo/shared/models/position.dart';

void main() {
  group('Position.fromJson', () {
    test('parses valid position', () {
      final json = {
        'id': 'pos-1',
        'sport_id': 'sport-1',
        'name': 'Delantero',
        'slug': 'delantero',
        'is_active': true,
      };
      final pos = Position.fromJson(json);
      expect(pos.id, 'pos-1');
      expect(pos.sportId, 'sport-1');
      expect(pos.name, 'Delantero');
      expect(pos.slug, 'delantero');
      expect(pos.isActive, true);
    });

    test('defaults is_active to true when null', () {
      final json = {
        'id': 'pos-2',
        'sport_id': 's1',
        'name': 'Portero',
        'slug': 'portero',
        'is_active': null,
      };
      final pos = Position.fromJson(json);
      expect(pos.isActive, true);
    });
  });

  group('Position.toJson', () {
    test('serializes correctly', () {
      const pos = Position(id: 'p1', sportId: 's1', name: 'CB', slug: 'cb', isActive: false);
      final json = pos.toJson();
      expect(json['id'], 'p1');
      expect(json['sport_id'], 's1');
      expect(json['name'], 'CB');
      expect(json['slug'], 'cb');
      expect(json['is_active'], false);
    });
  });
}
