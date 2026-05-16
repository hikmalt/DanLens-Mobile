// FILE: lib/utils/haversine.dart
// File ini berisi utilitas perhitungan jarak antara dua titik koordinat geografis menggunakan rumus Haversine.
// Fungsi: Menghitung jarak (dalam kilometer), memberikan saran moda transportasi berdasarkan jarak,
//         mengestimasi waktu tempuh, dan memformat jarak agar mudah dibaca.
// Informasi penting: Digunakan di berbagai bagian aplikasi, seperti filter jarak, tampilan jarak dari GPS,
//         panel saran rute AI, dan perhitungan jarak antar tempat. Tidak bergantung pada package luar selain dart:math.

import 'dart:math'; // Mengimpor pustaka matematika untuk fungsi trigonometri (sin, cos, atan2, sqrt, pi).

// Kelas Haversine berisi method statis untuk perhitungan jarak dan utilitas terkait.
class Haversine {
  // Jari-jari bumi dalam kilometer (konstanta).
  static const double _earthRadius = 6371.0; // km

  // Method statis untuk menghitung jarak antara dua titik koordinat dalam kilometer.
  // Parameter: lat1, lon1 (koordinat titik pertama), lat2, lon2 (koordinat titik kedua).
  static double distance(double lat1, double lon1, double lat2, double lon2) {
    // Selisih lintang dalam radian.
    final dLat = _toRad(lat2 - lat1);
    // Selisih bujur dalam radian.
    final dLon = _toRad(lon2 - lon1);
    // Rumus Haversine: a = sin²(Δlat/2) + cos(lat1) * cos(lat2) * sin²(Δlon/2)
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    // c = 2 * atan2(√a, √(1-a))
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    // Jarak = jari-jari bumi * c
    return _earthRadius * c;
  }

  // Method helper untuk mengonversi derajat ke radian.
  static double _toRad(double deg) => deg * (pi / 180);

  // Memberikan saran moda transportasi berdasarkan jarak (dalam kilometer).
  // Output: "Jalan Kaki", "Sepeda / Ojek", "Motor", atau "Mobil / Angkutan Umum".
  static String suggestTransport(double distanceKm) {
    // Jarak kurang dari 0.5 km -> jalan kaki.
    if (distanceKm < 0.5) return 'Jalan Kaki';
    // Jarak antara 0.5 - 3 km -> sepeda atau ojek.
    if (distanceKm < 3.0) return 'Sepeda / Ojek';
    // Jarak antara 3 - 10 km -> motor.
    if (distanceKm < 10.0) return 'Motor';
    // Jarak lebih dari 10 km -> mobil atau angkutan umum.
    return 'Mobil / Angkutan Umum';
  }

  // Mengestimasi waktu tempuh dalam menit berdasarkan jarak.
  // Kecepatan diasumsikan berdasarkan moda transportasi yang disarankan.
  static int estimatedTime(double distanceKm) {
    // Dapatkan moda transportasi yang disarankan.
    final transport = suggestTransport(distanceKm);
    double speedKmh; // Kecepatan dalam km/jam.
    // Tentukan kecepatan berdasarkan moda.
    switch (transport) {
      case 'Jalan Kaki': speedKmh = 5; break;      // Jalan kaki: 5 km/jam.
      case 'Sepeda / Ojek': speedKmh = 15; break; // Sepeda/ojek: 15 km/jam.
      case 'Motor': speedKmh = 25; break;         // Motor: 25 km/jam.
      default: speedKmh = 35;                     // Mobil: 35 km/jam (kecepatan dalam kota).
    }
    // Waktu (jam) = jarak / kecepatan. Konversi ke menit (*60), lalu dibulatkan ke atas (ceil).
    return ((distanceKm / speedKmh) * 60).ceil();
  }

  // Memformat jarak (kilometer) menjadi string yang mudah dibaca.
  // Jika kurang dari 1 km, tampilkan dalam meter (tanpa desimal).
  // Jika lebih atau sama dengan 1 km, tampilkan dalam km dengan 1 angka di belakang koma.
  static String formatDistance(double km) {
    if (km < 1) return '${(km * 1000).toStringAsFixed(0)} m';
    return '${km.toStringAsFixed(1)} km';
  }
}