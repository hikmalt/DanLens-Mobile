// FILE: lib/widgets/place_card.dart
// File ini berisi widget untuk menampilkan informasi tempat dalam bentuk kartu (card).
// Fungsi: Menampilkan preview tempat (gambar, nama, kategori, rating) dan tombol favorit.
// Digunakan di halaman beranda (HomeScreen) dan halaman rekomendasi (RecommendationScreen).
// Informasi penting: Terdapat dua widget utama: PlaceCard (untuk horizontal card) dan PlaceListTile (untuk list vertikal).
// Menggunakan CachedNetworkImage untuk memuat gambar dari internet, dan Provider untuk state favorit.

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../models/models.dart';
import '../providers/favorite_provider.dart';
import '../screens/detail/detail_screen.dart';

// Kelas PlaceCard: kartu tempat dengan ukuran tetap 180 piksel lebar, biasanya digunakan di horizontal list.
class PlaceCard extends StatelessWidget {
  final TempatModel tempat; // Data tempat yang akan ditampilkan.
  final int index; // Indeks untuk animasi bertahap (staggered animation).

  const PlaceCard({super.key, required this.tempat, this.index = 0});

  // Membangun tampilan kartu.
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Saat diklik, buka halaman detail tempat.
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetailScreen(tempat: tempat)),
      ),
      child: Container(
        // Lebar kartu 180 piksel.
        width: 180,
        // Margin kanan 14 piksel agar antar kartu berjarak.
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: AppColors.white, // Latar belakang putih.
          borderRadius: BorderRadius.circular(16), // Sudut melengkung.
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.10), // Bayangan hijau transparan.
              blurRadius: 16,
              offset: const Offset(0, 4), // Bayangan ke bawah.
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Rata kiri.
          mainAxisSize: MainAxisSize.min, // Tinggi minimal.
          children: [
            // Bagian gambar.
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                height: 108, // Tinggi gambar.
                width: double.infinity,
                child: tempat.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: tempat.imageUrl,
                        fit: BoxFit.cover, // Gambar memenuhi area.
                        placeholder: (_, __) => Container(color: AppColors.surface), // Placeholder saat loading.
                        errorWidget: (_, __, ___) => _placeholderImage(), // Jika gagal muat.
                      )
                    : _placeholderImage(), // Jika tidak ada URL gambar.
              ),
            ),
            // Bagian informasi.
            Padding(
              // Padding kiri, kanan, atas, bawah. (lebih ringkas)
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Baris kategori (ikon + nama kategori).
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          tempat.categoryIcon, // Emoji kategori.
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          tempat.namaKategori ?? '', // Nama kategori.
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis, // Jika panjang, potong dengan titik tiga.
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Nama tempat.
                  Text(
                    tempat.namaTempat,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                    maxLines: 2, // Maksimal 2 baris.
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Baris rating dan tombol favorit.
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                      const SizedBox(width: 2),
                      Text(
                        tempat.reviewRating?.toStringAsFixed(1) ?? '-', // Rating, format 1 desimal.
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      const Spacer(), // Dorong tombol favorit ke kanan.
                      // Tombol favorit dengan Consumer agar mendeteksi perubahan state.
                      Consumer<FavoriteProvider>(
                        builder: (_, fav, __) => GestureDetector(
                          onTap: () => fav.toggle(tempat), // Tambah/hapus favorit.
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Icon(
                              fav.isFavorite(tempat.id)
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              key: ValueKey(fav.isFavorite(tempat.id)), // Agar animasi berganti.
                              color: fav.isFavorite(tempat.id)
                                  ? Colors.redAccent
                                  : AppColors.textGray,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      )
          // Animasi masuk: fade + slide dari bawah, dengan jeda berdasarkan index.
          .animate(delay: Duration(milliseconds: index * 80))
          .fade(duration: 400.ms)
          .slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic),
    );
  }
}

// Fungsi untuk menampilkan placeholder gambar default (ikon gambar pecah).
Widget _placeholderImage() {
  return Container(
    color: AppColors.surface,
    child: const Center(
      child: Icon(Icons.image_outlined, color: AppColors.textGray, size: 36),
    ),
  );
}

// Kelas PlaceListTile: kartu tempat dengan gaya list (gambar kiri, teks kanan, seperti ListTile).
// Biasanya digunakan di halaman beranda (daftar vertikal) dan halaman favorit.
class PlaceListTile extends StatelessWidget {
  final TempatModel tempat; // Data tempat.
  final int index; // Indeks untuk animasi bertahap.
  final double? distanceKm; // Jarak dari pengguna (opsional, untuk menampilkan jarak).

  const PlaceListTile({
    super.key,
    required this.tempat,
    this.index = 0,
    this.distanceKm,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Saat diklik, buka halaman detail.
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetailScreen(tempat: tempat)),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5), // Margin luar.
        padding: const EdgeInsets.all(12), // Padding dalam.
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.07),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Gambar thumbnail (64x64 piksel, sudut melengkung).
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 64,
                height: 64,
                child: tempat.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: tempat.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: AppColors.surface),
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.surface,
                          child: const Icon(Icons.image_outlined,
                              color: AppColors.textGray),
                        ),
                      )
                    : Container(
                        color: AppColors.surface,
                        child: Center(
                          child: Text(tempat.categoryIcon,
                              style: const TextStyle(fontSize: 24)),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            // Area teks (nama, kecamatan, kategori, rating, jarak).
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nama tempat.
                  Text(tempat.namaTempat,
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.textDark),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  // Kecamatan dan kategori.
                  Text(
                    '${tempat.namaKecamatan ?? ''} · ${tempat.namaKategori ?? ''}',
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: AppColors.textGray),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  // Baris rating dan jarak (jika ada).
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 13),
                      const SizedBox(width: 2),
                      Text(tempat.reviewRating?.toStringAsFixed(1) ?? '-',
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                      if (distanceKm != null) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.near_me_rounded,
                            color: AppColors.primary, size: 12),
                        const SizedBox(width: 2),
                        Text(
                          distanceKm! < 1
                              ? '${(distanceKm! * 1000).toInt()} m' // Tampilkan meter jika kurang dari 1 km.
                              : '${distanceKm!.toStringAsFixed(1)} km', // Tampilkan km dengan 1 desimal.
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: AppColors.primary),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Ikon chevron kanan sebagai petunjuk bisa diklik.
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textGray, size: 20),
          ],
        ),
      )
          // Animasi masuk: fade + slide dari kanan, dengan jeda berdasarkan index.
          .animate(delay: Duration(milliseconds: index * 60))
          .fade(duration: 350.ms)
          .slideX(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
    );
  }
}