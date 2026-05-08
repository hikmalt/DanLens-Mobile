// lib/utils/haversine.dart
import 'dart:math';

class Haversine {
  static const double _earthRadius = 6371.0; // km

  /// Returns distance in kilometers
  static double distance(double lat1, double lon1, double lat2, double lon2) {
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return _earthRadius * c;
  }

  static double _toRad(double deg) => deg * (pi / 180);

  /// Smart transport suggestion based on distance
  static String suggestTransport(double distanceKm) {
    if (distanceKm < 0.5) return 'Jalan Kaki';
    if (distanceKm < 3.0) return 'Sepeda / Ojek';
    if (distanceKm < 10.0) return 'Motor';
    return 'Mobil / Angkutan Umum';
  }

  /// Estimated travel time in minutes
  static int estimatedTime(double distanceKm) {
    final transport = suggestTransport(distanceKm);
    double speedKmh;
    switch (transport) {
      case 'Jalan Kaki': speedKmh = 5; break;
      case 'Sepeda / Ojek': speedKmh = 15; break;
      case 'Motor': speedKmh = 25; break;
      default: speedKmh = 35;
    }
    return ((distanceKm / speedKmh) * 60).ceil();
  }

  static String formatDistance(double km) {
    if (km < 1) return '${(km * 1000).toStringAsFixed(0)} m';
    return '${km.toStringAsFixed(1)} km';
  }
}