import 'dart:math';

class GeoHelper {
  static const double _earthRadiusKm = 6371;

  static double haversineKm(double lat1, double lon1, double lat2, double lon2) {
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return _earthRadiusKm * c;
  }

  static double haversineMeters(double lat1, double lon1, double lat2, double lon2) {
    return haversineKm(lat1, lon1, lat2, lon2) * 1000;
  }

  static double _toRad(double degree) {
    return degree * pi / 180;
  }

  static String formatDistance(double km) {
    if (km < 1) {
      return '${(km * 1000).round()} m';
    }
    if (km < 10) {
      return '${km.toStringAsFixed(1)} km';
    }
    return '${km.round()} km';
  }

  static bool isWithinRadius({
    required double centerLat,
    required double centerLon,
    required double pointLat,
    required double pointLon,
    required double radiusKm,
  }) {
    final distance = haversineKm(centerLat, centerLon, pointLat, pointLon);
    return distance <= radiusKm;
  }
}
