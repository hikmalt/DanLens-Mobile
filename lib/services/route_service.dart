// FILE: lib/services/route_service.dart
// File ini berisi layanan untuk menghitung rute (jalur perjalanan) antara dua titik koordinat.
// Fungsi: Menghubungi API OSRM (router.project-osrm.org) untuk mendapatkan rute jalan darat (driving)
//         beserta jarak dan estimasi waktu tempuh. Jika gagal, menyediakan rute garis lurus sebagai cadangan.
// Informasi penting: OSRM adalah layanan routing open source gratis tanpa kunci API.
//         Format koordinat yang digunakan adalah longitude, latitude (sesuai standar GeoJSON).
//         Hasil rute mencakup polyline (titik-titik) untuk digambar di peta, jarak dalam meter, dan durasi dalam detik.

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import '../utils/error_logger.dart';

// Kelas untuk menyimpan hasil rute.
class RouteResult {
  // Titik-titik polyline yang membentuk rute.
  final List<LatLng> points;
  // Jarak dalam meter.
  final double distanceMeters;
  // Durasi dalam detik.
  final double durationSeconds;
  // Teks jarak yang sudah diformat (misal "1.2 km" atau "500 m").
  final String distanceText;
  // Teks durasi yang sudah diformat (misal "15 menit" atau "45 detik").
  final String durationText;

  RouteResult({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.distanceText,
    required this.durationText,
  });

  // Getter jarak dalam kilometer (mudah dibaca).
  double get distanceKm => distanceMeters / 1000;
  // Getter durasi dalam menit (dibulatkan ke atas).
  int get durationMinutes => (durationSeconds / 60).ceil();
}

class RouteService {
  // Instance Dio untuk melakukan HTTP request.
  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
  ));

  // Base URL API OSRM untuk mode driving (mobil).
  static const String _osrmBase = 'https://router.project-osrm.org/route/v1/driving';

  // Mendapatkan rute antara origin (titik asal) dan destination (tujuan).
  static Future<RouteResult?> getRoute(LatLng origin, LatLng dest) async {
    try {
      // Format URL OSRM: koordinat ditulis longitude,latitude.
      final url =
          '$_osrmBase/${origin.longitude},${origin.latitude};'
          '${dest.longitude},${dest.latitude}'
          '?overview=full&geometries=geojson&steps=false';

      // Catat log permintaan.
      ErrorLogger.i('OSRM request: $url');

      // Kirim request GET.
      final response = await _dio.get(url);
      if (response.statusCode != 200) {
        ErrorLogger.w('OSRM non-200: ${response.statusCode}');
        return null;
      }

      // Parsing response (bisa String atau Map).
      final data = response.data is String
          ? jsonDecode(response.data)
          : response.data;

      // Ambil array routes.
      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) {
        ErrorLogger.w('OSRM: no routes found');
        return null;
      }

      // Ambil rute pertama (biasanya yang terbaik).
      final route = routes[0];
      final distM = (route['distance'] as num).toDouble(); // meter
      final durS = (route['duration'] as num).toDouble(); // detik

      // Decode GeoJSON LineString menjadi daftar LatLng.
      final coords = route['geometry']['coordinates'] as List;
      final points = coords
          .map((c) => LatLng(
                (c[1] as num).toDouble(), // latitude
                (c[0] as num).toDouble(), // longitude
              ))
          .toList();

      ErrorLogger.i(
          'OSRM route: ${points.length} pts, ${(distM / 1000).toStringAsFixed(2)} km');

      // Kembalikan hasil.
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
      // Tangkap error dari Dio (timeout, koneksi, dll).
      ErrorLogger.e('RouteService DioException', e);
      return null;
    } catch (e, stack) {
      // Tangkap error lain.
      ErrorLogger.e('RouteService.getRoute failed', e, stack);
      return null;
    }
  }

  // Rute cadangan: garis lurus antara dua titik (tanpa mengikuti jalan).
  // Digunakan jika OSRM gagal atau offline.
  static RouteResult straightLine(LatLng origin, LatLng dest) {
    // Hitung jarak garis lurus menggunakan Distance dari latlong2.
    const d = Distance();
    final distM = d.as(LengthUnit.Meter, origin, dest);
    // Estimasi kecepatan rata-rata 36 km/jam (10 m/detik).
    final durationS = (distM / 10).ceil().toDouble();

    return RouteResult(
      points: [origin, dest], // Polyline hanya dua titik.
      distanceMeters: distM,
      durationSeconds: durationS,
      distanceText: distM < 1000
          ? '${distM.toInt()} m'
          : '${(distM / 1000).toStringAsFixed(1)} km',
      durationText: '${(durationS / 60).ceil()} menit',
    );
  }
}