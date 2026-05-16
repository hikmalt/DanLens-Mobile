// FILE: lib/widgets/ai_route_panel.dart
// File ini berisi widget panel yang menampilkan saran rute berdasarkan analisis sederhana dari jarak.
// Fungsi: Menampilkan informasi jarak, estimasi waktu, moda transportasi yang disarankan, dan tips perjalanan.
// Informasi penting: Menggunakan utilitas Haversine untuk menghitung jarak, estimasi waktu, dan format jarak.
// Panel ini muncul di halaman detail tempat (DetailScreen) ketika pengguna menekan tombol "Saran Rute AI".
// Tidak melakukan pemanggilan API eksternal, hanya logika sederhana berdasarkan jarak.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_theme.dart';
import '../utils/haversine.dart';

// Kelas AiRoutePanel adalah StatelessWidget karena tidak memiliki state internal.
class AiRoutePanel extends StatelessWidget {
  // Jarak dari pengguna ke tempat dalam kilometer (bisa null jika GPS tidak aktif).
  final double? distanceKm;

  const AiRoutePanel({super.key, this.distanceKm});

  @override
  Widget build(BuildContext context) {
    // Jika jarak tidak diketahui (GPS mati), tampilkan pesan peringatan.
    if (distanceKm == null) {
      return Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          '⚠️ Aktifkan GPS untuk mendapatkan saran rute',
          style: TextStyle(fontFamily: 'Poppins', fontSize: 13),
        ),
      );
    }

    // Mendapatkan moda transportasi yang disarankan berdasarkan jarak.
    final transport = Haversine.suggestTransport(distanceKm!);
    // Estimasi waktu tempuh dalam menit.
    final time = Haversine.estimatedTime(distanceKm!);
    // Format jarak (misal "1.2 km" atau "500 m").
    final dist = Haversine.formatDistance(distanceKm!);

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header panel dengan ikon robot (analisis AI).
          const Text(
            '🤖 Analisis AI',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 12),
          // Baris jarak.
          _RouteRow(icon: '📍', label: 'Jarak', value: dist),
          // Baris estimasi waktu.
          _RouteRow(icon: '⏱️', label: 'Estimasi Waktu', value: '$time menit'),
          // Baris moda transportasi yang disarankan.
          _RouteRow(icon: '🚗', label: 'Disarankan', value: transport),
          const SizedBox(height: 8),
          // Kotak tips perjalanan (saran spesifik berdasarkan jarak).
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _getAiTip(distanceKm!, transport),
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: AppColors.primaryDark,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    ).animate().fade(duration: 300.ms).slideY(begin: -0.1, end: 0); // Animasi fade-in dan slide dari atas.
  }

  // Menghasilkan teks tips berdasarkan jarak dan moda transportasi.
  String _getAiTip(double km, String transport) {
    // Tips untuk jarak sangat dekat (kurang dari 0.5 km).
    if (km < 0.5) {
      return '✅ Lokasi sangat dekat! Lebih baik jalan kaki untuk kesehatan.';
    }
    // Tips untuk jarak dekat (0.5 - 3 km).
    if (km < 3) {
      return '🛵 Jarak ideal dengan ojek online. Estimasi biaya Rp 5.000–10.000.';
    }
    // Tips untuk jarak sedang (3 - 10 km).
    if (km < 10) {
      return '🏍️ Naik motor lebih efisien. Hindari jam sibuk pukul 07.00–09.00 dan 16.00–18.00.';
    }
    // Tips untuk jarak jauh (lebih dari 10 km).
    return '🚗 Jarak cukup jauh, gunakan mobil atau angkutan umum. Pertimbangkan TransMétro Deli.';
  }
}

// Kelas helper untuk menampilkan satu baris informasi (ikon, label, nilai).
class _RouteRow extends StatelessWidget {
  final String icon;   // Emoji atau ikon teks.
  final String label;  // Label (Jarak, Estimasi Waktu, Disarankan).
  final String value;  // Nilai yang ditampilkan.

  const _RouteRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          // Ikon (emoji).
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          // Label teks.
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: AppColors.textGray,
            ),
          ),
          const Spacer(), // Dorong nilai ke kanan.
          // Nilai (jarak, waktu, transportasi).
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}