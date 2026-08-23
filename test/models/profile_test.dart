import 'package:flutter_test/flutter_test.dart';
import 'package:playergo/shared/models/profile.dart';
import 'package:playergo/shared/models/enums/enums.dart';

void main() {
  group('Profile.fromJson', () {
    test('parses valid profile', () {
      final json = {
        'id': 'test-id',
        'email': 'test@test.com',
        'full_name': 'Test User',
        'phone': '3001234567',
        'role': 'PLAYER',
        'photo_url': null,
        'verification_status': 'UNVERIFIED',
        'country_id': null,
        'region_id': null,
        'city_id': null,
        'is_active': true,
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
      };

      final profile = Profile.fromJson(json);

      expect(profile.id, 'test-id');
      expect(profile.email, 'test@test.com');
      expect(profile.fullName, 'Test User');
      expect(profile.phone, '3001234567');
      expect(profile.role, UserRole.player);
      expect(profile.isActive, true);
    });

    test('parses TEAM role', () {
      final json = {
        'id': 'id',
        'role': 'TEAM',
        'is_active': true,
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
      };
      final p = Profile.fromJson(json);
      expect(p.role, UserRole.team);
    });

    test('parses ADMIN role', () {
      final json = {
        'id': 'id',
        'role': 'ADMIN',
        'is_active': true,
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
      };
      final p = Profile.fromJson(json);
      expect(p.role, UserRole.admin);
    });

    test('defaults unknown role to player', () {
      final json = {
        'id': 'id',
        'role': 'UNKNOWN',
        'is_active': true,
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
      };
      final p = Profile.fromJson(json);
      expect(p.role, UserRole.player);
    });

    test('parses verification statuses', () {
      for (final status in ['UNVERIFIED', 'PENDING', 'VERIFIED', 'REJECTED', 'SUSPENDED']) {
        final json = {
          'id': 'id',
          'role': 'PLAYER',
          'verification_status': status,
          'is_active': true,
          'created_at': '2026-01-01T00:00:00Z',
          'updated_at': '2026-01-01T00:00:00Z',
        };
        final p = Profile.fromJson(json);
        expect(p.verificationStatus, isNotNull);
      }
    });

    test('defaults is_active to true when null', () {
      final json = {
        'id': 'id',
        'role': 'PLAYER',
        'is_active': null,
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
      };
      final p = Profile.fromJson(json);
      expect(p.isActive, true);
    });
  });

  group('Profile.toJson', () {
    test('serializes correctly', () {
      final profile = Profile(
        id: 'test-id',
        email: 'test@test.com',
        fullName: 'Test',
        role: UserRole.admin,
        isActive: true,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );

      final json = profile.toJson();
      expect(json['id'], 'test-id');
      expect(json['role'], 'admin');
      expect(json['full_name'], 'Test');
    });
  });

  group('Profile.copyWith', () {
    test('copies with changes', () {
      final profile = Profile(
        id: 'id',
        fullName: 'Original',
        role: UserRole.player,
        isActive: true,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );

      final updated = profile.copyWith(fullName: 'Updated');
      expect(updated.fullName, 'Updated');
      expect(updated.role, UserRole.player);
      expect(updated.id, 'id');
    });
  });
}
