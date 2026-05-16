// FILE: lib/widgets/carousel_widget.dart
// File ini berisi widget carousel (slide gambar) untuk halaman beranda (HomeScreen).
// Fungsi: Menampilkan gambar tempat dalam bentuk slide yang dapat digeser atau berjalan otomatis.
// Setiap slide menampilkan gambar tempat, nama tempat, kategori, dan rating.
// Jika belum ada gambar, menampilkan placeholder. Mendukung skeleton loading saat data sedang dimuat.
// Informasi penting: Menggunakan package carousel_slider untuk carousel dan smooth_page_indicator untuk indikator titik.
// Menggunakan CachedNetworkImage untuk memuat gambar dari internet dengan cache.

import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_theme.dart';
import '../models/models.dart';
import '../screens/detail/detail_screen.dart';
import 'skeleton_loader.dart';

// Kelas HomeCarousel adalah StatefulWidget karena perlu menyimpan indeks slide aktif.
class HomeCarousel extends StatefulWidget {
  // Daftar tempat yang akan ditampilkan di carousel.
  final List<TempatModel> items;
  // Status loading untuk menampilkan skeleton.
  final bool isLoading;

  const HomeCarousel({super.key, required this.items, this.isLoading = false});

  @override
  State<HomeCarousel> createState() => _HomeCarouselState();
}

class _HomeCarouselState extends State<HomeCarousel> {
  // Indeks slide yang sedang aktif (untuk indikator titik).
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    // Jika sedang loading, tampilkan skeleton carousel.
    if (widget.isLoading) return const CarouselSkeleton();

    // Jika data tempat kosong, tampilkan pesan "Belum ada gambar".
    if (widget.items.isEmpty) {
      return Container(
        height: 200,
        color: AppColors.surface,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.image_not_supported_outlined,
                  color: AppColors.textGray, size: 40),
              SizedBox(height: 8),
              Text('Belum ada gambar',
                  style: TextStyle(fontFamily: 'Poppins', color: AppColors.textGray)),
            ],
          ),
        ),
      );
    }

    // Tampilkan carousel.
    return Column(
      children: [
        // Widget CarouselSlider dari package.
        CarouselSlider.builder(
          itemCount: widget.items.length,
          options: CarouselOptions(
            height: 210, // Tinggi carousel 210 piksel.
            viewportFraction: 1.0, // Setiap slide memenuhi lebar penuh.
            autoPlay: true, // Putar otomatis.
            autoPlayInterval: const Duration(seconds: 4), // Ganti slide setiap 4 detik.
            autoPlayAnimationDuration: const Duration(milliseconds: 800), // Durasi animasi perpindahan.
            autoPlayCurve: Curves.easeInOutCubic, // Kurva animasi halus.
            onPageChanged: (index, _) => setState(() => _current = index), // Update indeks aktif.
          ),
          itemBuilder: (context, index, realIndex) {
            final item = widget.items[index];
            return GestureDetector(
              // Saat slide diketuk, buka halaman detail tempat.
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => DetailScreen(tempat: item))),
              child: Stack(
                fit: StackFit.expand, // Stack memenuhi seluruh area.
                children: [
                  // Gambar latar belakang.
                  item.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: item.imageUrl,
                          fit: BoxFit.cover, // Gambar memenuhi area.
                          placeholder: (_, __) =>
                              Container(color: AppColors.surface), // Placeholder saat loading.
                          errorWidget: (_, __, ___) =>
                              Container(color: AppColors.surface,
                                  child: const Icon(Icons.image_outlined,
                                      color: AppColors.textGray, size: 48)), // Jika gagal muat.
                        )
                      : Container(color: AppColors.surface), // Jika tidak ada URL gambar.

                  // Lapisan gradien gelap di bagian bawah agar teks lebih terbaca.
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent, // Atas transparan.
                          Color(0x44000000), // Agak gelap di tengah.
                          Color(0xCC000000), // Sangat gelap di bawah.
                        ],
                        stops: [0.4, 0.6, 1.0],
                      ),
                    ),
                  ),

                  // Informasi teks (kategori, nama, alamat, rating) di pojok kiri bawah.
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Chip kategori (ikon + nama kategori).
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${item.categoryIcon} ${item.namaKategori ?? ''}',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Nama tempat (maksimal 2 baris).
                        Text(
                          item.namaTempat,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            shadows: [
                              Shadow(color: Colors.black45, blurRadius: 8) // Bayangan teks.
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // Jika ada alamat (jalan), tampilkan alamat, ikon lokasi, dan rating.
                        if (item.jalan != null) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  color: Colors.white70, size: 12),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  item.jalan!,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 11,
                                    color: Colors.white70,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.star_rounded,
                                  color: Colors.amber, size: 13),
                              Text(
                                item.reviewRating?.toStringAsFixed(1) ?? '-',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        // Indikator titik (dot) di bawah carousel.
        const SizedBox(height: 10),
        AnimatedSmoothIndicator(
          activeIndex: _current, // Indeks aktif.
          count: widget.items.length, // Jumlah titik sesuai jumlah slide.
          effect: const ExpandingDotsEffect(
            activeDotColor: AppColors.primary, // Warna titik aktif (hijau).
            dotColor: AppColors.surface, // Warna titik tidak aktif (abu-abu).
            dotHeight: 6,
            dotWidth: 6,
            expansionFactor: 3, // Titik aktif melebar 3x lipat.
          ),
        ),
      ],
    ).animate().fade(duration: 500.ms); // Animasi fade-in seluruh carousel.
  }
}