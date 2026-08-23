import 'package:flutter_test/flutter_test.dart';
import 'package:playergo/core/utils/geo_helper.dart';

void main() {
  group('GeoHelper.haversineKm', () {
    test('same point returns 0', () {
      final distance = GeoHelper.haversineKm(4.711, -74.072, 4.711, -74.072);
      expect(distance, 0.0);
    });

    test('calculates distance between Bogota and Medellin', () {
      final distance = GeoHelper.haversineKm(4.711, -74.072, 6.244, -75.581);
      expect(distance, greaterThan(200));
      expect(distance, lessThan(400));
    });

    test('calculates distance between Bogota and NYC', () {
      final distance = GeoHelper.haversineKm(4.711, -74.072, 40.712, -74.006);
      expect(distance, greaterThan(3000));
      expect(distance, lessThan(5000));
    });
  });

  group('GeoHelper.isWithinRadius', () {
    test('same point is within radius', () {
      expect(
        GeoHelper.isWithinRadius(
          centerLat: 4.711,
          centerLon: -74.072,
          pointLat: 4.711,
          pointLon: -74.072,
          radiusKm: 5,
        ),
        true,
      );
    });

    test('far point is outside radius', () {
      expect(
        GeoHelper.isWithinRadius(
          centerLat: 4.711,
          centerLon: -74.072,
          pointLat: 6.244,
          pointLon: -75.581,
          radiusKm: 5,
        ),
        false,
      );
    });
  });

  group('GeoHelper.formatDistance', () {
    test('formats meters for < 1 km', () {
      expect(GeoHelper.formatDistance(0.5), '500 m');
      expect(GeoHelper.formatDistance(0.1), '100 m');
    });

    test('formats km with decimal for < 10 km', () {
      expect(GeoHelper.formatDistance(5.3), '5.3 km');
    });

    test('formats rounded km for >= 10 km', () {
      expect(GeoHelper.formatDistance(15.7), '16 km');
    });
  });
}
