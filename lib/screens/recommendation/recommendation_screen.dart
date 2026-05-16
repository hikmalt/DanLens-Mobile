// FILE: lib/screens/recommendation/recommendation_screen.dart
// Halaman rekomendasi tempat untuk pengguna.
// Fungsi: Menampilkan tiga tab rekomendasi: Terdekat (berdasarkan jarak dari GPS), Rating Tertinggi, dan Populer (berdasarkan kategori dengan rating tertinggi).
// Informasi penting: Tab "Terdekat" memerlukan akses GPS untuk menghitung jarak. Jika GPS tidak tersedia, akan menampilkan pesan error.
// Menggunakan Haversine untuk perhitungan jarak. Data tempat berasal dari TempatProvider.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/models.dart';
import '../../providers/tempat_provider.dart';
import '../../services/location_service.dart';
import '../../utils/haversine.dart';
import '../../widgets/place_card.dart';
import '../../widgets/skeleton_loader.dart';

// StatefulWidget karena memerlukan TabController dan state untuk data tempat terdekat.
class RecommendationScreen extends StatefulWidget {
  const RecommendationScreen({super.key});

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen>
    with SingleTickerProviderStateMixin {
  // Controller untuk tab (3 tab: Terdekat, Rating, Populer).
  late TabController _tabCtrl;
  // Daftar tempat terdekat (berisi objek _PlaceWithDist).
  List<_PlaceWithDist> _nearby = [];
  // Status loading untuk tab terdekat.
  bool _loadingNearby = true;
  // Apakah GPS tidak tersedia.
  bool _noGps = false;

  @override
  void initState() {
    super.initState();
    // Inisialisasi TabController dengan 3 tab.
    _tabCtrl = TabController(length: 3, vsync: this);
    // Muat data tempat terdekat.
    _loadNearby();
  }

  // Memuat data tempat terdekat berdasarkan lokasi GPS saat ini.
  Future<void> _loadNearby() async {
    setState(() => _loadingNearby = true);
    // Ambil provider tempat.
    final tp = context.read<TempatProvider>();
    // Dapatkan posisi terakhir atau cari posisi saat ini.
    final pos = LocationService.lastPosition ??
        await LocationService.getCurrentPosition();

    if (!mounted) return;
    // Jika posisi null, GPS tidak tersedia.
    if (pos == null) {
      setState(() {
        _loadingNearby = false;
        _noGps = true;
      });
      return;
    }

    // Ambil semua tempat dari provider.
    final all = tp.allTempat;
    // Hitung jarak setiap tempat ke posisi GPS, lalu urutkan.
    final withDist = all
        .where((t) => t.latitude != null && t.longitude != null)
        .map((t) => _PlaceWithDist(
              tempat: t,
              distKm: Haversine.distance(
                pos.latitude, pos.longitude,
                t.latitude!, t.longitude!,
              ),
            ))
        .toList()
      ..sort((a, b) => a.distKm.compareTo(b.distKm)); // Urutkan dari terdekat.

    setState(() {
      // Ambil 20 tempat terdekat.
      _nearby = withDist.take(20).toList();
      _loadingNearby = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tempat = context.watch<TempatProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rekomendasi'),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: Colors.white,                // Warna teks tab aktif.
          unselectedLabelColor: Colors.white70,    // Warna teks tab tidak aktif.
          labelStyle: const TextStyle(
              fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle:
              const TextStyle(fontFamily: 'Poppins', fontSize: 12),
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: '📍 Terdekat'),
            Tab(text: '⭐ Rating'),
            Tab(text: '🔥 Populer'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          // Tab 1: Tempat terdekat.
          _NearbyTab(
            items: _nearby,
            loading: _loadingNearby,
            noGps: _noGps,
            onRefresh: _loadNearby,
          ),
          // Tab 2: Rating tertinggi.
          _TopRatedTab(tempat: tempat),
          // Tab 3: Populer (dikelompokkan per kategori, diurutkan rating).
          _PopularTab(tempat: tempat),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }
}

// Kelas helper untuk menyimpan tempat beserta jaraknya.
class _PlaceWithDist {
  final TempatModel tempat;
  final double distKm;
  const _PlaceWithDist({required this.tempat, required this.distKm});
}

// ---------------------------------------------------------------------
//  TAB 1: TERDEKAT (NEARBY)
// ---------------------------------------------------------------------
class _NearbyTab extends StatelessWidget {
  final List<_PlaceWithDist> items;
  final bool loading;
  final bool noGps;
  final VoidCallback onRefresh;

  const _NearbyTab({
    required this.items,
    required this.loading,
    required this.noGps,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    // Jika sedang loading, tampilkan skeleton list.
    if (loading) {
      return ListView.builder(
        itemCount: 5,
        itemBuilder: (_, __) => const ListTileSkeleton(),
      );
    }

    // Jika GPS tidak tersedia, tampilkan pesan dan tombol coba lagi.
    if (noGps) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_off_rounded, size: 60, color: AppColors.textGray),
            const SizedBox(height: 12),
            const Text('GPS tidak tersedia', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            const Text('Aktifkan GPS untuk melihat tempat terdekat',
                style: AppTextStyles.small, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    // Jika daftar kosong (tidak ada tempat dalam radius), tampilkan pesan.
    if (items.isEmpty) {
      return const Center(
        child: Text('Tidak ada tempat ditemukan', style: AppTextStyles.small),
      );
    }

    // Tampilkan daftar tempat dengan PlaceListTile (menampilkan jarak).
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: items.length,
        itemBuilder: (_, i) => PlaceListTile(
          tempat: items[i].tempat,
          index: i,
          distanceKm: items[i].distKm,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
//  TAB 2: RATING TERTINGGI (TOP RATED)
// ---------------------------------------------------------------------
class _TopRatedTab extends StatelessWidget {
  final TempatProvider tempat;
  const _TopRatedTab({required this.tempat});

  @override
  Widget build(BuildContext context) {
    if (tempat.isLoading) {
      return ListView.builder(
        itemCount: 5,
        itemBuilder: (_, __) => const ListTileSkeleton(),
      );
    }

    // Salin daftar tempat dan urutkan berdasarkan rating tertinggi.
    final sorted = [...tempat.allTempat]
      ..sort((a, b) =>
          (b.reviewRating ?? 0).compareTo(a.reviewRating ?? 0));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: sorted.length,
      itemBuilder: (_, i) {
        final t = sorted[i];
        return Stack(
          children: [
            PlaceListTile(tempat: t, index: i),
            // Badge emoji untuk 3 rating tertinggi.
            if (i < 3)
              Positioned(
                top: 14,
                right: 28,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: [
                      const Color(0xFFFFD700), // Emas
                      const Color(0xFFC0C0C0), // Perak
                      const Color(0xFFCD7F32), // Perunggu
                    ][i],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    ['🥇', '🥈', '🥉'][i],
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------
//  TAB 3: POPULER (PER KATEGORI, RATING TERTINGGI)
// ---------------------------------------------------------------------
class _PopularTab extends StatelessWidget {
  final TempatProvider tempat;
  const _PopularTab({required this.tempat});

  @override
  Widget build(BuildContext context) {
    if (tempat.isLoading) {
      return ListView.builder(
        itemCount: 5,
        itemBuilder: (_, __) => const ListTileSkeleton(),
      );
    }

    // Kelompokkan tempat berdasarkan kategori.
    final byCategory = <String, List<TempatModel>>{};
    for (final t in tempat.allTempat) {
      final cat = t.namaKategori ?? 'Lainnya';
      byCategory.putIfAbsent(cat, () => []).add(t);
    }

    final categories = byCategory.keys.toList();

    // Gunakan CustomScrollView dengan sliver untuk setiap kategori.
    return CustomScrollView(
      slivers: [
        for (var i = 0; i < categories.length; i++) ...[
          // Header kategori (dengan ikon, nama, jumlah tempat).
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  // Ikon kategori (dari model kategori, cari berdasarkan nama).
                  Text(
                    tempat.kategori
                        .firstWhere(
                          (k) => k.namaKategori == categories[i],
                          orElse: () => KategoriModel(id: 0, namaKategori: categories[i]),
                        )
                        .icon,
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 8),
                  Text(categories[i], style: AppTextStyles.h3),
                  const Spacer(),
                  Text(
                    '${byCategory[categories[i]]!.length} tempat',
                    style: AppTextStyles.small,
                  ),
                ],
              ),
            ).animate(delay: Duration(milliseconds: i * 60)).fade(),
          ),
          // Daftar tempat dalam kategori (horizontal scroll), diurutkan rating tertinggi.
          SliverToBoxAdapter(
            child: SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: (byCategory[categories[i]]!
                    ..sort((a, b) =>
                        (b.reviewRating ?? 0).compareTo(a.reviewRating ?? 0)))
                    .length,
                itemBuilder: (_, j) => PlaceCard(
                  tempat: byCategory[categories[i]]![j],
                  index: j,
                ),
              ),
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 80)), // Ruang di bawah.
      ],
    );
  }
}