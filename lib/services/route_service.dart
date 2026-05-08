// lib/services/route_service.dart
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import '../utils/error_logger.dart';

class RouteResult {
  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;
  final String distanceText;
  final String durationText;

  RouteResult({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.distanceText,
    required this.durationText,
  });

  double get distanceKm => distanceMeters / 1000;
  int get durationMinutes => (durationSeconds / 60).ceil();
}

class RouteService {
  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
  ));

  // OSRM public API (free, no key needed)
  static const String _osrmBase = 'https://router.project-osrm.org/route/v1/driving';

  /// Get driving route from [origin] to [destination]
  static Future<RouteResult?> getRoute(LatLng origin, LatLng dest) async {
    try {
      final url =
          '$_osrmBase/${origin.longitude},${origin.latitude};'
          '${dest.longitude},${dest.latitude}'
          '?overview=full&geometries=geojson&steps=false';

      ErrorLogger.i('OSRM request: $url');

      final response = await _dio.get(url);
      if (response.statusCode != 200) {
        ErrorLogger.w('OSRM non-200: ${response.statusCode}');
        return null;
      }

      final data = response.data is String
          ? jsonDecode(response.data)
          : response.data;

      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) {
        ErrorLogger.w('OSRM: no routes found');
        return null;
      }

      final route = routes[0];
      final distM = (route['distance'] as num).toDouble();
      final durS = (route['duration'] as num).toDouble();

      // Decode GeoJSON LineString coordinates → LatLng list
      final coords = route['geometry']['coordinates'] as List;
      final points = coords
          .map((c) => LatLng(
                (c[1] as num).toDouble(),
                (c[0] as num).toDouble(),
              ))
          .toList();

      ErrorLogger.i(
          'OSRM route: ${points.length} pts, ${(distM / 1000).toStringAsFixed(2)} km');

      return RouteResult(
        points: points,
        distanceMeters: distM,
        durationSeconds: durS,
        distanceText: distM < 1000
            ? '${distM.toInt()} m'
            : '${(distM / 1000).toStringAsFixed(1)} km',
        durationText: durS < 60
            ? '${durS.toInt()} detik'
            : '${(durS / 60).ceil()} menit',
      );
    } on DioException catch (e) {
      ErrorLogger.e('RouteService DioException', e);
      return null;
    } catch (e, stack) {
      ErrorLogger.e('RouteService.getRoute failed', e, stack);
      return null;
    }
  }

  /// Fallback: straight line between two points
  static RouteResult straightLine(LatLng origin, LatLng dest) {
    const d = Distance();
    final distM = d.as(LengthUnit.Meter, origin, dest);
    final durationS = (distM / 10).ceil().toDouble(); // ~36 km/h estimate

    return RouteResult(
      points: [origin, dest],
      distanceMeters: distM,
      durationSeconds: durationS,
      distanceText: distM < 1000
          ? '${distM.toInt()} m'
          : '${(distM / 1000).toStringAsFixed(1)} km',
      durationText: '${(durationS / 60).ceil()} menit',
    );
  }
}