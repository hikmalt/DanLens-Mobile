// FILE: lib/widgets/heatmap_layer.dart
// File ini berisi widget untuk menampilkan heatmap (peta panas) dan polygon batas kecamatan pada peta.
// Fungsi: HeatmapLayer menampilkan lingkaran-lingkaran semi-transparan di lokasi tempat,
//         dengan warna dan ukuran berdasarkan rating (semakin tinggi rating, semakin merah dan besar).
//         KecamatanPolygonLayer menampilkan batas wilayah kecamatan (hardcoded untuk Medan).
//         MapOverlayToggle menyediakan tombol untuk menyalakan/mematikan layer-layer tersebut.
// Informasi penting: Tidak menggunakan package tambahan, hanya lingkaran bawaan flutter_map.
//         Polygon kecamatan di sini adalah data statis (approximate), bukan dari Supabase.
//         Untuk data polygon dinamis dari database, lihat di map_screen.dart.

// Mengimpor widget dasar Flutter.
import 'package:flutter/material.dart';
// Mengimpor flutter_map untuk menampilkan peta dan layer.
import 'package:flutter_map/flutter_map.dart';
// Mengimpor latlong2 untuk koordinat (LatLng).
import 'package:latlong2/latlong.dart';
// Mengimpor model tempat (TempatModel).
import '../models/models.dart';
// Mengimpor tema aplikasi untuk warna-warna.
import '../config/app_theme.dart';

// Kelas HeatmapLayer untuk menampilkan heatmap (peta panas) berdasarkan rating tempat.
class HeatmapLayer extends StatelessWidget {
  // Daftar tempat yang akan ditampilkan.
  final List<TempatModel> places;
  // Apakah heatmap terlihat (toggle).
  final bool visible;

  const HeatmapLayer({
    super.key,
    required this.places,
    this.visible = true,
  });

  // Menentukan warna lingkaran berdasarkan rating.
  Color _heatColor(double rating) {
    // Rating >= 4.5 -> merah panas.
    if (rating >= 4.5) return const Color(0xFFFF1744);
    // Rating >= 4.0 -> oranye.
    if (rating >= 4.0) return const Color(0xFFFF6D00);
    // Rating >= 3.5 -> kuning.
    if (rating >= 3.5) return const Color(0xFFFFD600);
    // Rating di bawah 3.5 -> biru dingin.
    return const Color(0xFF00E5FF);
  }

  @override
  Widget build(BuildContext context) {
    // Jika tidak terlihat, kembalikan widget kosong.
    if (!visible) return const SizedBox.shrink();

    // Membuat daftar lingkaran (CircleMarker) dari setiap tempat yang memiliki koordinat.
    final circles = places
        .where((t) => t.latitude != null && t.longitude != null) // Hanya tempat dengan koordinat.
        .map((t) {
      // Rating default 3.0 jika null.
      final rating = t.reviewRating ?? 3.0;
      // Radius lingkaran: 150 meter + (rating * 60 meter). Rating tinggi -> lingkaran lebih besar.
      final radius = 150 + (rating * 60);
      return CircleMarker(
        point: LatLng(t.latitude!, t.longitude!), // Posisi lingkaran.
        radius: radius,
        useRadiusInMeter: true, // Radius dalam satuan meter (bukan piksel).
        // Warna lingkaran dengan transparansi 0.18.
        color: _heatColor(rating).withValues(alpha: 0.18),
        // Warna border lingkaran dengan transparansi 0.08.
        borderColor: _heatColor(rating).withValues(alpha: 0.08),
        borderStrokeWidth: 1,
      );
    }).toList();

    // Mengembalikan CircleLayer yang berisi semua lingkaran.
    return CircleLayer(circles: circles);
  }
}

// Kelas untuk menampilkan batas-batas kecamatan (polygon) secara statis (approximate).
// Catatan: Data ini hardcoded untuk kecamatan di Medan, bukan dari database.
class KecamatanPolygonLayer extends StatelessWidget {
  final bool visible;

  const KecamatanPolygonLayer({super.key, this.visible = true});

  @override
  Widget build(BuildContext context) {
    // Jika tidak terlihat, kembalikan widget kosong.
    if (!visible) return const SizedBox.shrink();

    // Menampilkan layer polygon dengan data dari daftar statis.
    return PolygonLayer(
      polygons: _kecamatanPolygons,
    );
  }

  // Daftar polygon kecamatan (data perkiraan, bukan data sebenarnya dari GIS).
  static final List<Polygon> _kecamatanPolygons = [
    // Medan Kota (perkiraan batas).
    Polygon(
      points: [
        const LatLng(3.577, 98.672),
        const LatLng(3.592, 98.672),
        const LatLng(3.592, 98.690),
        const LatLng(3.577, 98.690),
      ],
      // Warna isi hijau transparan.
      color: AppColors.primary.withValues(alpha: 0.06),
      // Warna border hijau lebih gelap.
      borderColor: AppColors.primary.withValues(alpha: 0.25),
      borderStrokeWidth: 1.5,
      label: 'Medan Kota',
      labelStyle: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 9,
        color: AppColors.primaryDark,
        fontWeight: FontWeight.w600,
      ),
    ),
    // Medan Baru (perkiraan batas).
    Polygon(
      points: [
        const LatLng(3.557, 98.655),
        const LatLng(3.572, 98.655),
        const LatLng(3.572, 98.672),
        const LatLng(3.557, 98.672),
      ],
      color: AppColors.primaryDark.withValues(alpha: 0.05),
      borderColor: AppColors.primaryDark.withValues(alpha: 0.2),
      borderStrokeWidth: 1.5,
      label: 'Medan Baru',
      labelStyle: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 9,
        color: AppColors.primaryDark,
        fontWeight: FontWeight.w600,
      ),
    ),
    // Medan Petisah (perkiraan batas).
    Polygon(
      points: [
        const LatLng(3.590, 98.645),
        const LatLng(3.605, 98.645),
        const LatLng(3.605, 98.660),
        const LatLng(3.590, 98.660),
      ],
      color: const Color(0xFF5352ED).withValues(alpha: 0.05),
      borderColor: const Color(0xFF5352ED).withValues(alpha: 0.2),
      borderStrokeWidth: 1.5,
      label: 'Medan Petisah',
      labelStyle: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 9,
        color: Color(0xFF5352ED),
        fontWeight: FontWeight.w600,
      ),
    ),
    // Medan Maimun (perkiraan batas).
    Polygon(
      points: [
        const LatLng(3.570, 98.675),
        const LatLng(3.582, 98.675),
        const LatLng(3.582, 98.692),
        const LatLng(3.570, 98.692),
      ],
      color: const Color(0xFFFF6B35).withValues(alpha: 0.05),
      borderColor: const Color(0xFFFF6B35).withValues(alpha: 0.2),
      borderStrokeWidth: 1.5,
      label: 'Medan Maimun',
      labelStyle: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 9,
        color: Color(0xFFFF6B35),
        fontWeight: FontWeight.w600,
      ),
    ),
  ];
}

// Kelas untuk tombol toggle overlay peta (heatmap dan polygon).
class MapOverlayToggle extends StatelessWidget {
  final bool heatmapVisible;
  final bool polygonVisible;
  final VoidCallback onToggleHeatmap;
  final VoidCallback onTogglePolygon;

  const MapOverlayToggle({
    super.key,
    required this.heatmapVisible,
    required this.polygonVisible,
    required this.onToggleHeatmap,
    required this.onTogglePolygon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Padding di dalam container.
      padding: const EdgeInsets.all(8),
      // Dekorasi: latar putih, sudut melengkung, bayangan.
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tombol untuk heatmap.
          _ToggleBtn(
            label: '🔥',
            tooltip: 'Heatmap',
            active: heatmapVisible,
            onTap: onToggleHeatmap,
          ),
          const SizedBox(height: 4),
          // Tombol untuk polygon wilayah.
          _ToggleBtn(
            label: '🗾',
            tooltip: 'Wilayah',
            active: polygonVisible,
            onTap: onTogglePolygon,
          ),
        ],
      ),
    );
  }
}

// Tombol toggle individual dengan animasi.
class _ToggleBtn extends StatelessWidget {
  final String label;
  final String tooltip;
  final bool active;
  final VoidCallback onTap;

  const _ToggleBtn({
    required this.label,
    required this.tooltip,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          // Durasi animasi perubahan warna/border.
          duration: const Duration(milliseconds: 200),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            // Warna latar: hijau transparan jika aktif, transparan jika tidak.
            color: active
                ? AppColors.primary.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: active
                  ? AppColors.primary.withValues(alpha: 0.4) // Border hijau jika aktif.
                  : Colors.transparent, // Tanpa border jika tidak aktif.
            ),
          ),
          child: Center(
            child: Text(label, style: const TextStyle(fontSize: 16)),
          ),
        ),
      ),
    );
  }
}