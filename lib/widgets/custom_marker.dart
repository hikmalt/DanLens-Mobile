// FILE: lib/widgets/custom_marker.dart
// File ini berisi widget marker kustom untuk menampilkan titik lokasi (point) pada peta.
// Fungsi: Menampilkan marker berbentuk lingkaran dengan warna berbeda berdasarkan kategori tempat,
//         disertai panah kecil di bawahnya. Marker akan membesar jika sedang dipilih (isSelected = true).
// Informasi penting: Digunakan bersama flutter_map untuk menggantikan marker default.
//         Warna marker ditentukan dari kategori (kuliner, wisata, kesehatan, dll).
//         Ikon di tengah marker adalah emoji kategori (categoryIcon dari model TempatModel).

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_theme.dart';
import '../models/models.dart';

// Kelas CustomMarker untuk marker titik tempat pada peta.
class CustomMarker extends StatelessWidget {
  final TempatModel tempat; // Data tempat yang ditampilkan.
  final bool isSelected; // Apakah marker ini sedang dipilih (aktif).
  final VoidCallback? onTap; // Fungsi saat marker diklik.

  const CustomMarker({
    super.key,
    required this.tempat,
    this.isSelected = false,
    this.onTap,
  });

  // Menentukan warna marker berdasarkan kategori tempat.
  Color get _color {
    switch (tempat.namaKategori?.toLowerCase()) {
      case 'kuliner': // Kategori kuliner -> warna oranye.
        return const Color(0xFFFF6B35);
      case 'wisata': // Kategori wisata -> warna biru toska.
        return const Color(0xFF4ECDC4);
      case 'kesehatan': // Kategori kesehatan -> warna merah.
        return const Color(0xFFFF4757);
      case 'kemasyarakatan': // Kategori kemasyarakatan -> warna ungu.
        return const Color(0xFF5352ED);
      case 'transportasi': // Kategori transportasi -> warna hijau terang.
        return const Color(0xFF2ED573);
      default: // Jika tidak ada kategori atau tidak dikenali, gunakan warna utama (hijau).
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, // Panggil fungsi onTap jika marker diklik.
      child: AnimatedScale(
        scale: isSelected ? 1.2 : 1.0, // Marker membesar 20% jika dipilih.
        duration: const Duration(milliseconds: 200), // Durasi animasi zoom.
        child: Column(
          mainAxisSize: MainAxisSize.min, // Tinggi kolom menyesuaikan konten.
          children: [
            // Bagian badan marker (lingkaran).
            Container(
              width: isSelected ? 44 : 36, // Lebar marker: 44 jika dipilih, 36 jika tidak.
              height: isSelected ? 44 : 36, // Tinggi marker sama dengan lebar.
              decoration: BoxDecoration(
                color: _color, // Warna lingkaran sesuai kategori.
                shape: BoxShape.circle, // Bentuk lingkaran.
                border: Border.all(
                  color: Colors.white, // Border putih.
                  width: isSelected ? 3 : 2, // Border lebih tebal jika dipilih.
                ),
                boxShadow: [
                  BoxShadow(
                    color: _color.withValues(alpha: 0.5), // Bayangan dengan warna marker.
                    blurRadius: isSelected ? 12 : 6, // Bayangan lebih besar jika dipilih.
                    spreadRadius: isSelected ? 2 : 0, // Spread bayangan.
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  tempat.categoryIcon, // Emoji kategori (seperti 🍽️, 🏛️, dll).
                  style: TextStyle(fontSize: isSelected ? 18 : 14), // Ukuran teks lebih besar jika dipilih.
                ),
              ),
            ),
            // Bagian panah segitiga di bawah marker (pointer).
            CustomPaint(
              size: const Size(10, 6), // Lebar 10 piksel, tinggi 6.
              painter: _MarkerPointerPainter(color: _color), // Painter untuk menggambar segitiga.
            ),
          ],
        ).animate().fade(duration: 300.ms).slideY(begin: 0.3, end: 0), // Animasi fade dan slide dari bawah saat muncul.
      ),
    );
  }
}

// Custom painter untuk menggambar panah segitiga di bawah marker.
class _MarkerPointerPainter extends CustomPainter {
  final Color color; // Warna panah sama dengan warna marker.

  const _MarkerPointerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color; // Kuas dengan warna marker.
    // Membuat path segitiga.
    final path = Path()
      ..moveTo(0, 0) // Titik kiri atas.
      ..lineTo(size.width / 2, size.height) // Titik tengah bawah.
      ..lineTo(size.width, 0) // Titik kanan atas.
      ..close(); // Tutup path.
    canvas.drawPath(path, paint); // Gambar segitiga.
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false; // Tidak perlu repaint ulang jika parameter tidak berubah.
}