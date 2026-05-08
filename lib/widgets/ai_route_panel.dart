// C:\Users\hikma\Desktop\DanLens\danlens\lib\widgets\ai_route_panel.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_theme.dart';
import '../utils/haversine.dart';

class AiRoutePanel extends StatelessWidget {
  final double? distanceKm;

  const AiRoutePanel({super.key, this.distanceKm});

  @override
  Widget build(BuildContext context) {
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

    final transport = Haversine.suggestTransport(distanceKm!);
    final time = Haversine.estimatedTime(distanceKm!);
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
          const Text(
            '🤖 Analisis AI',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 12),
          _RouteRow(icon: '📍', label: 'Jarak', value: dist),
          _RouteRow(icon: '⏱️', label: 'Estimasi Waktu', value: '$time menit'),
          _RouteRow(icon: '🚗', label: 'Disarankan', value: transport),
          const SizedBox(height: 8),
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
    ).animate().fade(duration: 300.ms).slideY(begin: -0.1, end: 0);
  }

  String _getAiTip(double km, String transport) {
    if (km < 0.5) {
      return '✅ Lokasi sangat dekat! Lebih baik jalan kaki untuk kesehatan.';
    }
    if (km < 3) {
      return '🛵 Jarak ideal dengan ojek online. Estimasi biaya Rp 5.000–10.000.';
    }
    if (km < 10) {
      return '🏍️ Naik motor lebih efisien. Hindari jam sibuk pukul 07.00–09.00 dan 16.00–18.00.';
    }
    return '🚗 Jarak cukup jauh, gunakan mobil atau angkutan umum. Pertimbangkan TransMétro Deli.';
  }
}

class _RouteRow extends StatelessWidget {
  final String icon;
  final String label;
  final String value;

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
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: AppColors.textGray,
            ),
          ),
          const Spacer(),
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