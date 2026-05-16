// FILE: lib/services/location_service.dart
// File ini menyediakan layanan untuk mengakses lokasi GPS perangkat.
// Fungsi: Mendapatkan posisi pengguna saat ini (koordinat lintang dan bujur) serta menyediakan stream posisi berkelanjutan.
// Informasi penting: Menggunakan package geolocator. Memeriksa apakah layanan lokasi aktif dan izin telah diberikan.
// Menyimpan posisi terakhir dalam variabel statis _lastPosition agar dapat diakses kembali tanpa harus meminta ulang ke GPS.

import 'package:geolocator/geolocator.dart';
import '../utils/error_logger.dart';

class LocationService {
  // Menyimpan posisi terakhir yang berhasil didapatkan.
  static Position? _lastPosition;
  // Getter untuk mengakses posisi terakhir dari luar kelas.
  static Position? get lastPosition => _lastPosition;

  // Method statis untuk mendapatkan posisi pengguna saat ini (satu kali).
  static Future<Position?> getCurrentPosition() async {
    try {
      // Periksa apakah layanan lokasi perangkat (GPS) aktif.
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Catat peringatan jika layanan lokasi tidak aktif.
        ErrorLogger.w('Location services disabled');
        return null;
      }

      // Periksa izin lokasi yang sudah diberikan pengguna.
      LocationPermission permission = await Geolocator.checkPermission();
      // Jika izin belum diberikan, minta izin.
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // Izin ditolak, catat dan hentikan.
          ErrorLogger.w('Location permission denied');
          return null;
        }
      }
      // Jika izin ditolak secara permanen (pengguna memilih "Jangan tanyakan lagi").
      if (permission == LocationPermission.deniedForever) {
        ErrorLogger.w('Location permission permanently denied');
        return null;
      }

      // Ambil posisi saat ini dengan akurasi tinggi, batas waktu 10 detik.
      _lastPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      // Catat log koordinat yang berhasil.
      ErrorLogger.i('Got location: ${_lastPosition!.latitude}, ${_lastPosition!.longitude}');
      return _lastPosition;
    } catch (e, stack) {
      // Tangkap error (misalnya GPS mati, timeout, dll) dan catat.
      ErrorLogger.e('getCurrentPosition failed', e, stack);
      return null;
    }
  }

  // Stream (aliran data) posisi yang berkelanjutan. Akan mengirim posisi setiap kali GPS berubah.
  static Stream<Position> get positionStream => Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high, // Akurasi tinggi.
          distanceFilter: 10,               // Kirim update jika pergerakan >= 10 meter.
        ),
      );
}