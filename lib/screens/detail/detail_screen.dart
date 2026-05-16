// FILE: lib/screens/detail/detail_screen.dart
// Halaman detail dari suatu tempat (wisata, kuliner, dll).
// Fungsi: Menampilkan informasi lengkap tempat: gambar, nama, kategori, kecamatan, jalan, deskripsi, kontak, rating, jarak dari pengguna, serta saran rute AI.
// Informasi penting: Halaman ini menerima parameter TempatModel. Menghitung jarak dari lokasi pengguna menggunakan Haversine. Terdapat panel saran rute AI yang bisa dibuka/tutup.
// Tombol di bottom bar: "Lihat Peta" (buka MapScreen dengan tempat ini difokuskan) dan "Mulai Rute" (buka Google Maps dengan arah ke tempat ini).

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_theme.dart';
import '../../models/models.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/tempat_provider.dart';
import '../../services/location_service.dart';
import '../../utils/haversine.dart';
import '../map/map_screen.dart';

// Kelas DetailScreen adalah StatefulWidget karena ada state untuk jarak dan status panel AI.
class DetailScreen extends StatefulWidget {
  final TempatModel tempat; // Data tempat yang akan ditampilkan.
  const DetailScreen({super.key, required this.tempat});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  double? _distanceKm; // Jarak dari pengguna ke tempat (kilometer).
  bool _loadingDistance = true; // Status sedang menghitung jarak.
  bool _showAiRoute = false; // Apakah panel saran rute AI ditampilkan.

  @override
  void initState() {
    super.initState();
    // Menambahkan tempat ke daftar riwayat dilihat (recently viewed) setelah frame pertama.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TempatProvider>().addRecentlyViewed(widget.tempat);
    });
    _loadDistance(); // Mulai hitung jarak.
  }

  // Menghitung jarak dari lokasi pengguna saat ini ke tempat.
  Future<void> _loadDistance() async {
    // Ambil lokasi terakhir atau minta posisi baru.
    final pos = LocationService.lastPosition ??
        await LocationService.getCurrentPosition();
    if (pos != null && widget.tempat.latitude != null && mounted) {
      setState(() {
        _distanceKm = Haversine.distance(
          pos.latitude,
          pos.longitude,
          widget.tempat.latitude!,
          widget.tempat.longitude!,
        );
        _loadingDistance = false;
      });
    } else {
      setState(() => _loadingDistance = false);
    }
  }

  // Membuka dialer telepon (jika ada nomor kontak).
  void _openPhoneDialer() async {
    final tel = widget.tempat.kontak;
    if (tel == null || tel.isEmpty) return;
    final uri = Uri.parse('tel:$tel');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tempat;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── SLIVER APP BAR with Hero image ──
          SliverAppBar(
            expandedHeight: 280, // Tinggi app bar saat mengembang.
            pinned: true, // Tetap di atas saat scroll.
            backgroundColor: AppColors.primary,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                onTap: () => Navigator.pop(context), // Tombol back.
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 22),
                ),
              ),
            ),
            actions: [
              // Tombol favorit (menggunakan Consumer agar merespons perubahan state).
              Consumer<FavoriteProvider>(
                builder: (_, fav, __) => Padding(
                  padding: const EdgeInsets.all(8),
                  child: GestureDetector(
                    onTap: () => fav.toggle(t), // Tambah/hapus favorit.
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: fav.isFavorite(t.id)
                            ? Colors.red.withValues(alpha:0.15)
                            : Colors.black26,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        fav.isFavorite(t.id)
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: fav.isFavorite(t.id) ? Colors.redAccent : Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: GestureDetector(
                onTap: () => _showFullImage(context, t.imageUrl), // Klik gambar untuk fullscreen.
                child: Hero(
                  tag: 'tempat_${t.id}', // Tag untuk animasi Hero.
                  child: t.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: t.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              Container(color: AppColors.surface),
                          errorWidget: (_, __, ___) => Container(
                            color: AppColors.surface,
                            child: const Icon(Icons.image_outlined,
                                color: AppColors.textGray, size: 60),
                          ),
                        )
                      : Container(
                          color: AppColors.surface,
                          child: Center(
                            child: Text(t.categoryIcon,
                                style: const TextStyle(fontSize: 60)),
                          ),
                        ),
                ),
              ),
            ),
          ),

          // ── CONTENT ──────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Baris nama + kategori + rating.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.namaTempat, style: AppTextStyles.h2)
                                .animate()
                                .fade(duration: 400.ms)
                                .slideY(begin: 0.2, end: 0),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${t.categoryIcon} ${t.namaKategori ?? ''}',
                                style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Badge rating.
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded,
                                color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              t.reviewRating?.toStringAsFixed(1) ?? '-',
                              style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Info chips (kecamatan, jalan, jarak).
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (t.namaKecamatan != null)
                        _InfoChip(
                            icon: Icons.location_city_rounded,
                            label: t.namaKecamatan!),
                      if (t.jalan != null)
                        _InfoChip(
                            icon: Icons.edit_road_rounded, label: t.jalan!),
                      if (!_loadingDistance && _distanceKm != null)
                        _InfoChip(
                            icon: Icons.near_me_rounded,
                            label: Haversine.formatDistance(_distanceKm!),
                            color: AppColors.primary),
                    ],
                  ).animate().fade(delay: 100.ms),

                  // Deskripsi (jika ada).
                  if (t.detailTempat != null && t.detailTempat!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text('Deskripsi', style: AppTextStyles.h3)
                        .animate()
                        .fade(delay: 150.ms),
                    const SizedBox(height: 8),
                    Text(t.detailTempat!,
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color: AppColors.textDark,
                            height: 1.6))
                        .animate()
                        .fade(delay: 200.ms),
                  ],

                  // Kontak (jika ada) – tappable untuk memanggil.
                  if (t.kontak != null && t.kontak!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: _openPhoneDialer,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.surface),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.phone_rounded,
                                  color: AppColors.primary, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Kontak',
                                    style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 11,
                                        color: AppColors.textGray)),
                                Text(t.kontak!,
                                    style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary)),
                              ],
                            ),
                            const Spacer(),
                            const Icon(Icons.chevron_right_rounded,
                                color: AppColors.textGray),
                          ],
                        ),
                      ),
                    ).animate().fade(delay: 250.ms),
                  ],

                  // Panel Saran Rute AI (toggle).
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => setState(() => _showAiRoute = !_showAiRoute),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDark],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome_rounded,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Saran Rute AI',
                                    style: TextStyle(
                                        fontFamily: 'Poppins',
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14)),
                                Text('Kendaraan & estimasi waktu terbaik',
                                    style: TextStyle(
                                        fontFamily: 'Poppins',
                                        color: Colors.white70,
                                        fontSize: 11)),
                              ],
                            ),
                          ),
                          Icon(
                            _showAiRoute
                                ? Icons.expand_less_rounded
                                : Icons.expand_more_rounded,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ).animate().fade(delay: 300.ms),

                  if (_showAiRoute) _AiRoutePanel(distanceKm: _distanceKm),

                  const SizedBox(height: 100), // Ruang di bawah agar tidak tertutup bottom bar.
                ],
              ),
            ),
          ),
        ],
      ),

      // ── BOTTOM ACTION BUTTONS ──
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))
          ],
        ),
        child: Row(
          children: [
            // Tombol "Lihat Peta" – membuka MapScreen dengan tempat difokuskan.
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MapScreen(focusedTempat: t),
                  ),
                ),
                icon: const Icon(Icons.map_rounded, size: 18),
                label: const Text('Lihat Peta'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(
                      fontFamily: 'Poppins', fontWeight: FontWeight.w500),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Tombol "Mulai Rute" – buka Google Maps langsung navigasi.
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                // Mengganti _openGoogleMaps dengan navigasi ke MapScreen
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MapScreen(
                        focusedTempat: t,
                        autoRoute: true,  // Parameter baru agar langsung tampilkan rute GPS
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.directions_rounded, size: 18),
                label: const Text('Mulai Rute'),
                style: ElevatedButton.styleFrom(
                   shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(
                      fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                )
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Menampilkan gambar dalam mode fullscreen dengan PhotoView.
  void _showFullImage(BuildContext context, String imageUrl) {
    if (imageUrl.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullImageViewer(imageUrl: imageUrl),
      ),
    );
  }
}

// Widget untuk info chip (seperti label kecil dengan ikon).
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _InfoChip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: (color ?? AppColors.textGray).withValues(alpha:0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: (color ?? AppColors.textGray).withValues(alpha:0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color ?? AppColors.textGray),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: color ?? AppColors.textGray)),
        ],
      ),
    );
  }
}

// Panel saran rute AI (menampilkan jarak, estimasi waktu, moda transportasi, tips).
class _AiRoutePanel extends StatelessWidget {
  final double? distanceKm;
  const _AiRoutePanel({this.distanceKm});

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
        border: Border.all(color: AppColors.primary.withValues(alpha:0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🤖 Analisis AI',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark)),
          const SizedBox(height: 12),
          _RouteRow(icon: '📍', label: 'Jarak', value: dist),
          _RouteRow(icon: '⏱️', label: 'Estimasi Waktu', value: '$time menit'),
          _RouteRow(icon: '🚗', label: 'Disarankan', value: transport),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha:0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _getAiTip(distanceKm!, transport),
              style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: AppColors.primaryDark,
                  height: 1.5),
            ),
          ),
        ],
      ),
    ).animate().fade(duration: 300.ms).slideY(begin: -0.1, end: 0);
  }

  String _getAiTip(double km, String transport) {
    if (km < 0.5) return '✅ Lokasi sangat dekat! Lebih baik jalan kaki untuk kesehatan.';
    if (km < 3) return '🛵 Jarak ideal dengan ojek online. Estimasi biaya Rp 5.000–10.000.';
    if (km < 10) return '🏍️ Naik motor lebih efisien. Hindari jam sibuk pukul 07.00–09.00 dan 16.00–18.00.';
    return '🚗 Jarak cukup jauh, gunakan mobil atau angkutan umum. Pertimbangkan TransMétro Deli.';
  }
}

// Baris dalam panel AI (ikon, label, nilai).
class _RouteRow extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  const _RouteRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: AppColors.textGray)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark)),
        ],
      ),
    );
  }
}

// Widget untuk melihat gambar fullscreen (PhotoView).
class _FullImageViewer extends StatelessWidget {
  final String imageUrl;
  const _FullImageViewer({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: PhotoView(
        imageProvider: CachedNetworkImageProvider(imageUrl),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 3,
        backgroundDecoration: const BoxDecoration(color: Colors.black),
      ),
    );
  }
}