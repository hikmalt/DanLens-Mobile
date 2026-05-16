// FILE: lib/widgets/skeleton_loader.dart
// File ini berisi widget skeleton loader untuk menampilkan placeholder animasi saat data sedang dimuat.
// Fungsi: Memberikan efek shimmer (kilau) pada area konten yang belum siap, memberi tahu pengguna bahwa aplikasi sedang memuat data.
// Informasi penting: Menggunakan package 'shimmer' untuk efek animasi. Skeleton loader membantu mengurangi persepsi waktu loading dan mencegah layout shift.

// Mengimpor pustaka Flutter untuk widget dasar.
import 'package:flutter/material.dart';
// Mengimpor package Shimmer untuk efek animasi berkilau pada placeholder.
import 'package:shimmer/shimmer.dart';
// Mengimpor tema aplikasi untuk mendapatkan warna yang konsisten.
import '../config/app_theme.dart';

// Kelas untuk membuat kotak skeleton dengan ukuran tertentu.
class SkeletonBox extends StatelessWidget {
  // Lebar kotak skeleton.
  final double width;
  // Tinggi kotak skeleton.
  final double height;
  // Radius sudut kotak skeleton.
  final double radius;

  // Konstruktor dengan parameter wajib width dan height, radius opsional default 8.
  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.radius = 8,
  });

  // Membangun tampilan skeleton box.
  @override
  Widget build(BuildContext context) {
    // Menggunakan efek shimmer dari package.
    return Shimmer.fromColors(
      // Warna dasar placeholder (warna permukaan/surface).
      baseColor: AppColors.surface,
      // Warna sorotan (lebih terang) untuk efek kilau.
      highlightColor: AppColors.white,
      // Container kotak dengan ukuran dan warna permukaan.
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

// Kelas skeleton khusus untuk placeholder kartu tempat (PlaceCard).
class PlaceCardSkeleton extends StatelessWidget {
  const PlaceCardSkeleton({super.key});

  // Membangun tampilan placeholder untuk kartu tempat (horizontal).
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.white,
      child: Container(
        // Lebar kartu placeholder 180 piksel.
        width: 180,
        // Margin kanan agar antar kartu terpisah.
        margin: const EdgeInsets.only(right: 12),
        // Dekorasi background putih dengan sudut melengkung.
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Area gambar placeholder (120 piksel tinggi).
            Container(
              height: 120,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
            ),
            // Area teks (nama tempat dan info kecil) dengan padding.
            const Padding(
              padding: EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 120, height: 12),
                  SizedBox(height: 6),
                  SkeletonBox(width: 80, height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Kelas skeleton khusus untuk placeholder carousel (slide gambar).
class CarouselSkeleton extends StatelessWidget {
  const CarouselSkeleton({super.key});

  // Membangun placeholder carousel (kotak tinggi 200 piksel).
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.white,
      child: Container(
        height: 200,
        color: AppColors.surface,
      ),
    );
  }
}

// Kelas skeleton untuk placeholder list tile (item daftar).
class ListTileSkeleton extends StatelessWidget {
  const ListTileSkeleton({super.key});

  // Membangun placeholder baris daftar (gambar thumbnail + teks).
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.white,
      child: Padding(
        // Margin horizontal 16, vertical 8.
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // Placeholder gambar thumbnail kotak 60x60.
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 12),
            // Placeholder teks (judul dan subtitle) di sebelah kanan.
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 160, height: 13),
                  SizedBox(height: 6),
                  SkeletonBox(width: 100, height: 10),
                  SizedBox(height: 4),
                  SkeletonBox(width: 80, height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}