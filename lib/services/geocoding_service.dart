// FILE: lib/services/geocoding_service.dart
// File ini berisi layanan untuk mengubah alamat menjadi koordinat (geocoding) dan sebaliknya (reverse geocoding).
// Fungsi: Menggunakan API Nominatim dari OpenStreetMap yang gratis tanpa kunci API.
//         Geocoding: mengubah teks alamat (misalnya "Medan Johor") menjadi lintang dan bujur.
//         Reverse geocoding: mengubah koordinat menjadi nama alamat.
// Informasi penting: API ini gratis, tetapi memiliki batasan penggunaan (tidak untuk komersial berat).
//         Di sini ditambahkan filter wilayah "Medan, Sumatera Utara, Indonesia" untuk hasil yang lebih relevan.
//         Timeout 10 detik untuk setiap request.

import 'package:dio/dio.dart';
import '../utils/error_logger.dart';

// Kelas untuk menyimpan hasil geocoding.
class GeocodingResult {
  final String displayName; // Nama alamat lengkap (jalan, kecamatan, kota, dll).
  final double lat; // Lintang (latitude).
  final double lng; // Bujur (longitude).

  const GeocodingResult({
    required this.displayName,
    required this.lat,
    required this.lng,
  });
}

class GeocodingService {
  // Instance Dio untuk HTTP request.
  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'User-Agent': 'DanLens/1.0'}, // Wajib untuk Nominatim (identifikasi aplikasi).
  ));

  // Base URL API Nominatim search (geocoding).
  static const _base = 'https://nominatim.openstreetmap.org/search';

  // Fungsi untuk mencari alamat (geocoding).
  // Parameter: query (teks alamat), limit (jumlah hasil maksimal, default 5).
  static Future<List<GeocodingResult>> search(String query,
      {int limit = 5}) async {
    if (query.trim().isEmpty) return []; // Jika query kosong, kembalikan daftar kosong.
    try {
      // Kirim request GET dengan parameter.
      final response = await _dio.get(_base, queryParameters: {
        'q': '$query, Medan, Sumatera Utara, Indonesia', // Filter wilayah Medan.
        'format': 'json', // Format respons JSON.
        'limit': limit,
        'addressdetails': 1, // Sertakan detail alamat (tapi tidak dipakai).
      });

      if (response.statusCode != 200) return []; // Jika gagal, kembalikan kosong.
      final data = response.data as List; // Data berupa list of maps.
      return data.map((item) {
        return GeocodingResult(
          displayName: item['display_name'] as String,
          lat: double.parse(item['lat'] as String),
          lng: double.parse(item['lon'] as String),
        );
      }).toList();
    } catch (e, s) {
      ErrorLogger.e('GeocodingService.search failed', e, s);
      return [];
    }
  }

  // Reverse geocoding: dari koordinat ke alamat.
  static Future<String?> reverse(double lat, double lng) async {
    try {
      final response = await _dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'lat': lat,
          'lon': lng,
          'format': 'json',
        },
      );
      if (response.statusCode != 200) return null;
      return response.data['display_name'] as String?; // Ambil nama alamat.
    } catch (e, s) {
      ErrorLogger.e('GeocodingService.reverse failed', e, s);
      return null;
    }
  }
}