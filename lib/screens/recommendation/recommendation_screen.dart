// lib/screens/recommendation/recommendation_screen.dart
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

class RecommendationScreen extends StatefulWidget {
  const RecommendationScreen({super.key});
  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<_PlaceWithDist> _nearby = [];
  bool _loadingNearby = true;
  bool _noGps = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _loadNearby();
  }

  Future<void> _loadNearby() async {
    setState(() => _loadingNearby = true);
    final tp = context.read<TempatProvider>();  // tambahkan sebelum baris 38
    final pos = LocationService.lastPosition ??
        await LocationService.getCurrentPosition();

    if (!mounted) return;   // tambahkan baris ini
    if (pos == null) {
      setState(() {
        _loadingNearby = false;
        _noGps = true;
      });
      return;
    }

    //final all = context.read<TempatProvider>().allTempat;
    final all = tp.allTempat;
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
      ..sort((a, b) => a.distKm.compareTo(b.distKm));

    setState(() {
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
          labelColor: Colors.white,                // ← tambahkan
          unselectedLabelColor: Colors.white70,    // ← tambahkan
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
          // Tab 1: Nearby
          _NearbyTab(
            items: _nearby,
            loading: _loadingNearby,
            noGps: _noGps,
            onRefresh: _loadNearby,
          ),

          // Tab 2: Top Rated
          _TopRatedTab(tempat: tempat),

          // Tab 3: Popular (most viewed simulation = top rated by rating desc limit 10)
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

class _PlaceWithDist {
  final TempatModel tempat;
  final double distKm;
  const _PlaceWithDist({required this.tempat, required this.distKm});
}

// ── Tab 1: Nearby ──────────────────────────────────────────────────
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
    if (loading) {
      return ListView.builder(
        itemCount: 5,
        itemBuilder: (_, __) => const ListTileSkeleton(),
      );
    }

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

    if (items.isEmpty) {
      return const Center(
        child: Text('Tidak ada tempat ditemukan', style: AppTextStyles.small),
      );
    }

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

// ── Tab 2: Top Rated ───────────────────────────────────────────────
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
            // Rank badge for top 3
            if (i < 3)
              Positioned(
                top: 14,
                right: 28,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: [
                      const Color(0xFFFFD700),
                      const Color(0xFFC0C0C0),
                      const Color(0xFFCD7F32),
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

// ── Tab 3: Popular ─────────────────────────────────────────────────
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

    // Group by category + sort by rating
    final byCategory = <String, List<TempatModel>>{};
    for (final t in tempat.allTempat) {
      final cat = t.namaKategori ?? 'Lainnya';
      byCategory.putIfAbsent(cat, () => []).add(t);
    }

    final categories = byCategory.keys.toList();

    return CustomScrollView(
      slivers: [
        for (var i = 0; i < categories.length; i++) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
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
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
}