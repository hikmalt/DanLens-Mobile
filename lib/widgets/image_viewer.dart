// FILE: lib/widgets/image_viewer.dart
// File ini berisi widget untuk melihat gambar dalam mode layar penuh (fullscreen).
// Fungsi: Menampilkan gambar dari URL dengan dukungan zoom (pinch-to-zoom), swipe untuk galeri,
// serta animasi Hero saat transisi.
// Informasi penting: Menggunakan package photo_view untuk zoom dan galeri.
// Terdapat tiga komponen utama: ImageGalleryViewer (galeri gambar), openImageViewer (fungsi helper),
// dan TappableImage (gambar yang bisa diketuk untuk zoom).
// Cocok untuk menampilkan foto tempat, profil, atau gambar lainnya.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import '../config/app_theme.dart';

// Kelas untuk melihat galeri gambar (beberapa gambar) dalam mode fullscreen dengan swipe.
class ImageGalleryViewer extends StatefulWidget {
  final List<String> imageUrls; // Daftar URL gambar.
  final int initialIndex; // Indeks gambar pertama yang ditampilkan.
  final String heroTag; // Tag untuk animasi Hero (opsional).

  const ImageGalleryViewer({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
    this.heroTag = '',
  });

  @override
  State<ImageGalleryViewer> createState() => _ImageGalleryViewerState();
}

class _ImageGalleryViewerState extends State<ImageGalleryViewer> {
  late PageController _pageCtrl; // Controller untuk halaman galeri.
  late int _current; // Indeks gambar yang sedang aktif.

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _pageCtrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Latar belakang hitam.
      body: Stack(
        children: [
          // Galeri gambar dengan PhotoViewGallery.
          PhotoViewGallery.builder(
            pageController: _pageCtrl,
            itemCount: widget.imageUrls.length,
            onPageChanged: (i) => setState(() => _current = i), // Update indeks saat swipe.
            builder: (ctx, i) => PhotoViewGalleryPageOptions(
              imageProvider:
                  CachedNetworkImageProvider(widget.imageUrls[i]), // Muat gambar dari cache.
              minScale: PhotoViewComputedScale.contained, // Skala minimal (gambar muat dalam layar).
              maxScale: PhotoViewComputedScale.covered * 3, // Skala maksimal (3x ukuran layar).
              heroAttributes: i == widget.initialIndex && widget.heroTag.isNotEmpty
                  ? PhotoViewHeroAttributes(tag: widget.heroTag) // Animasi Hero untuk gambar pertama.
                  : null,
            ),
            backgroundDecoration:
                const BoxDecoration(color: Colors.black),
            loadingBuilder: (_, __) => const Center(
              child: CircularProgressIndicator(color: AppColors.primary), // Indikator loading.
            ),
          ),

          // Bar atas (tombol tutup dan counter gambar).
          SafeArea(
            child: Row(
              children: [
                // Tombol tutup (lingkaran hitam transparan).
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ),
                const Spacer(),
                // Counter (nomor gambar aktif / total) jika lebih dari 1 gambar.
                if (widget.imageUrls.length > 1)
                  Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_current + 1} / ${widget.imageUrls.length}',
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
              ],
            ),
          ).animate().fade(duration: 300.ms), // Animasi fade-in untuk bar atas.

          // Indikator titik (dot) di bagian bawah untuk galeri.
          if (widget.imageUrls.length > 1)
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.imageUrls.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _current == i ? 18 : 6, // Lebar berbeda untuk titik aktif.
                    height: 6,
                    decoration: BoxDecoration(
                      color: _current == i
                          ? AppColors.primary // Warna hijau untuk titik aktif.
                          : Colors.white.withValues(alpha: 0.4), // Putih transparan untuk titik tidak aktif.
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }
}

// Fungsi helper untuk membuka satu gambar dalam mode fullscreen (tanpa galeri).
void openImageViewer(
  BuildContext context,
  String imageUrl, {
  String heroTag = '',
}) {
  Navigator.push(
    context,
    PageRouteBuilder(
      opaque: false, // Membiarkan latar belakang tembus pandang.
      barrierColor: Colors.black87, // Warna gelap di belakang.
      pageBuilder: (_, __, ___) => ImageGalleryViewer(
        imageUrls: [imageUrl], // Galeri dengan satu gambar.
        heroTag: heroTag,
      ),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child), // Animasi fade.
    ),
  );
}

// Widget gambar yang dapat diketuk untuk zoom (dengan Hero dan tap-to-zoom).
class TappableImage extends StatelessWidget {
  final String imageUrl; // URL gambar.
  final double? width; // Lebar opsional.
  final double? height; // Tinggi opsional.
  final BoxFit fit; // Mode fit (cover, contain, dll).
  final BorderRadius? borderRadius; // Sudut melengkung opsional.
  final String heroTag; // Tag Hero.

  const TappableImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.heroTag = '',
  });

  @override
  Widget build(BuildContext context) {
    // Jika heroTag tidak disediakan, buat default berdasarkan URL.
    final tag = heroTag.isNotEmpty ? heroTag : 'img_$imageUrl';

    return GestureDetector(
      onTap: () => openImageViewer(context, imageUrl, heroTag: tag), // Buka viewer saat diketuk.
      child: Hero(
        tag: tag, // Untuk animasi transisi.
        child: ClipRRect(
          borderRadius: borderRadius ?? BorderRadius.zero,
          child: imageUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: width,
                  height: height,
                  fit: fit,
                  placeholder: (_, __) => _PlaceholderBox(
                      width: width, height: height), // Placeholder saat loading.
                  errorWidget: (_, __, ___) =>
                      _ErrorBox(width: width, height: height), // Jika gagal muat.
                )
              : _ErrorBox(width: width, height: height), // Jika URL kosong.
        ),
      ),
    );
  }
}

// Placeholder kotak dengan indikator loading (CircularProgressIndicator).
class _PlaceholderBox extends StatelessWidget {
  final double? width;
  final double? height;
  const _PlaceholderBox({this.width, this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: AppColors.surface, // Warna latar permukaan.
      child: const Center(
        child: CircularProgressIndicator(
            strokeWidth: 2, color: AppColors.primary),
      ),
    );
  }
}

// Kotak error (gambar gagal dimuat) dengan ikon gambar pecah.
class _ErrorBox extends StatelessWidget {
  final double? width;
  final double? height;
  const _ErrorBox({this.width, this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: AppColors.surface,
      child: const Center(
        child: Icon(Icons.broken_image_outlined,
            color: AppColors.textGray, size: 32),
      ),
    );
  }
}