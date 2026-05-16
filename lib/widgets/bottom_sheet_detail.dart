// FILE: lib/widgets/bottom_sheet_detail.dart
// File ini berisi widget bottom sheet (lembaran dari bawah) untuk menampilkan detail ringkas tempat ketika pengguna memilih marker di peta.
// Fungsi: Menampilkan thumbnail, nama, kategori, kecamatan, rating, jarak dari pengguna (jika ada), deskripsi singkat,
//         serta tombol untuk membuka halaman detail lengkap atau rute ke tempat tersebut.
// Informasi penting: Bottom sheet ini dapat diseret (draggable) ke atas/bawah untuk mengubah ukuran.
//         Menggunakan DraggableScrollableSheet dengan snap points (0.2, 0.45, 0.85 dari tinggi layar).
//         Juga menampilkan tombol favorit (heart) yang terhubung dengan FavoriteProvider.
//         Tombol rute membuka Google Maps dengan titik tujuan tempat tersebut.

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../models/models.dart';
import '../providers/favorite_provider.dart';
import '../screens/detail/detail_screen.dart';
import '../utils/haversine.dart';

// Kelas PlaceBottomSheet adalah StatefulWidget karena ukuran sheet bisa berubah (draggable).
class PlaceBottomSheet extends StatefulWidget {
  final TempatModel tempat; // Data tempat yang akan ditampilkan.
  final double? distanceKm; // Jarak dari pengguna ke tempat (opsional).

  const PlaceBottomSheet({
    super.key,
    required this.tempat,
    this.distanceKm,
  });

  @override
  State<PlaceBottomSheet> createState() => _PlaceBottomSheetState();
}

class _PlaceBottomSheetState extends State<PlaceBottomSheet> {
  // Tinggi awal sheet sebagai proporsi dari tinggi layar (0.6 = 60%).
  final double _sheetHeight = 0.6;

  @override
  Widget build(BuildContext context) {
    final t = widget.tempat;

    return DraggableScrollableSheet(
      // Ukuran awal sheet.
      initialChildSize: _sheetHeight,
      // Ukuran minimal (sheet dapat ditarik ke bawah hingga 20% layar).
      minChildSize: 0.2,
      // Ukuran maksimal (sheet dapat ditarik ke atas hingga 85% layar).
      maxChildSize: 0.85,
      // Snap = sheet akan "mengunci" ke posisi snapSizes jika dilepas.
      snap: true,
      snapSizes: const [0.2, 0.45, 0.85], // Posisi snap (mini, sedang, penuh).
      builder: (_, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: ListView(
            controller: scrollCtrl, // Agar scroll terintegrasi dengan draggable.
            padding: const EdgeInsets.all(0),
            children: [
              // Handle (garis kecil di atas untuk indikasi dapat ditarik).
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),

              // Header: thumbnail, info teks, tombol favorit.
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thumbnail gambar.
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 68,
                        height: 68,
                        child: t.imageUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: t.imageUrl,
                                fit: BoxFit.cover,
                                placeholder: (_, __) =>
                                    Container(color: AppColors.surface),
                                errorWidget: (_, __, ___) =>
                                    _placeholder(t.categoryIcon),
                              )
                            : _placeholder(t.categoryIcon),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Informasi teks (nama, kategori, kecamatan, rating, jarak).
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.namaTempat,
                              style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: AppColors.textDark)),
                          const SizedBox(height: 3),
                          Text(
                            '${t.namaKategori ?? ''} · ${t.namaKecamatan ?? ''}',
                            style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: AppColors.textGray),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded,
                                  color: Colors.amber, size: 14),
                              const SizedBox(width: 2),
                              Text(
                                t.reviewRating?.toStringAsFixed(1) ?? '-',
                                style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12),
                              ),
                              // Tampilkan jarak jika tersedia.
                              if (widget.distanceKm != null) ...[
                                const SizedBox(width: 10),
                                const Icon(Icons.near_me_rounded,
                                    color: AppColors.primary, size: 13),
                                const SizedBox(width: 2),
                                Text(
                                  Haversine.formatDistance(widget.distanceKm!),
                                  style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      color: AppColors.primary),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ).animate().fade(duration: 300.ms).slideY(begin: 0.1, end: 0),
                    ),

                    // Tombol favorit (heart) dengan Consumer agar mendeteksi perubahan state.
                    Consumer<FavoriteProvider>(
                      builder: (_, fav, __) => GestureDetector(
                        onTap: () => fav.toggle(t),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: fav.isFavorite(t.id)
                                ? Colors.red.withValues(alpha: 0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            fav.isFavorite(t.id)
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: fav.isFavorite(t.id)
                                ? Colors.redAccent
                                : AppColors.textGray,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Deskripsi singkat (maksimal 3 baris).
              if (t.detailTempat != null && t.detailTempat!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Text(
                    t.detailTempat!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: AppColors.textDark,
                      height: 1.5,
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Tombol aksi: Detail (buka halaman detail) dan Rute (buka Google Maps).
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    // Tombol Detail.
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetailScreen(tempat: t),
                          ),
                        ),
                        icon: const Icon(Icons.info_outline_rounded, size: 16),
                        label: const Text('Detail'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          textStyle: const TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
                              fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Tombol Rute.
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _openGoogleMaps(t),
                        icon: const Icon(Icons.directions_rounded, size: 16),
                        label: const Text('Rute'),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          textStyle: const TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
                              fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // Placeholder gambar jika URL kosong atau gagal dimuat.
  Widget _placeholder(String emoji) {
    return Container(
      color: AppColors.surface,
      child: Center(
        child: Text(emoji, style: const TextStyle(fontSize: 28)),
      ),
    );
  }

  // Membuka Google Maps dengan arah ke tempat yang dipilih.
  void _openGoogleMaps(TempatModel t) async {
    if (t.latitude == null || t.longitude == null) return;
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${t.latitude},${t.longitude}'
      '&travelmode=driving',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}