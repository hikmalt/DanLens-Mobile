// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/tempat_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../widgets/carousel_widget.dart';
import '../../widgets/place_card.dart';
import '../../widgets/skeleton_loader.dart';
import '../map/map_screen.dart';
import '../../models/models.dart';
import '../../models/kategori_model.dart';
import '../recommendation/recommendation_screen.dart';
import '../../widgets/error_log_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tp = context.read<TempatProvider>();
      final fav = context.read<FavoriteProvider>();
      if (tp.allTempat.isEmpty) tp.loadAll();
      if (tp.carouselTempat.isEmpty) tp.loadCarousel();
      fav.syncItems(tp.allTempat);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final tempat = context.watch<TempatProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          await tempat.refresh();
          await tempat.loadCarousel();
        },
        child: CustomScrollView(
          controller: _scrollCtrl,
          slivers: [
            // ── APP BAR ──────────────────────────────────
            SliverAppBar(
              expandedHeight: 0,
              floating: true,
              snap: true,
              backgroundColor: AppColors.white,
              elevation: 0,
              automaticallyImplyLeading: false,
              title: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.location_on_rounded,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 8),
                  const Text('DanLens',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: AppColors.textDark,
                      )),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined,
                      color: AppColors.textDark),
                  //onPressed: () {},
                   //onPressed: () => _showNotifications(context), // ← ganti dari () {}
                   onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ErrorLogWidget()),
                  ),
                ),
              ],
            ),

            // ── CONTENT ──────────────────────────────────
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Halo, ${auth.user?.name.split(' ').first ?? 'Penjelajah'}! 👋',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ).animate().fade(duration: 400.ms).slideY(begin: -0.2, end: 0),
                        const SizedBox(height: 2),
                        const Text(
                          'Temukan tempat menarik di Medan',
                          style: AppTextStyles.small,
                        ).animate().fade(delay: 100.ms),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Search bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GestureDetector(
                      onTap: () => _showSearchSheet(context, tempat),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 13),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.surface),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha:0.06),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search_rounded,
                                color: AppColors.textGray, size: 22),
                            const SizedBox(width: 10),
                            const Text('Cari tempat di Medan...',
                                style: TextStyle(
                                    fontFamily: 'Poppins',
                                    color: AppColors.textGray,
                                    fontSize: 14)),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.tune_rounded,
                                  color: AppColors.primary, size: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ).animate().fade(delay: 150.ms).slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 20),

                  // Carousel
                  HomeCarousel(
                    items: tempat.carouselTempat,
                    isLoading: tempat.isLoadingCarousel,
                  ).animate().fade(delay: 200.ms),

                  const SizedBox(height: 20),

                  // Category chips
                  const _SectionHeader(title: 'Kategori', onSeeAll: null),
                  const SizedBox(height: 10),
                  _CategoryChips(tempat: tempat),

                  const SizedBox(height: 20),

                  // Top rated
                  _SectionHeader(
                    title: 'Rating Tertinggi ⭐',
                    onSeeAll: () {
                       Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DefaultTabController(
                            length: 3,
                            initialIndex: 1,  // langsung ke tab "Rating"
                            child: RecommendationScreen(),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 200,
                    child: tempat.isLoading
                        ? ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: 4,
                            itemBuilder: (_, __) => const PlaceCardSkeleton(),
                          )
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: tempat.getTopRated(limit: 6).length,
                            itemBuilder: (_, i) => PlaceCard(
                              tempat: tempat.getTopRated(limit: 6)[i],
                              index: i,
                            ),
                          ),
                  ),

                  const SizedBox(height: 20),

                  // Quick action - View Map
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const MapScreen())),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryDark],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha:0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha:0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.map_rounded,
                                  color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Jelajahi Peta',
                                      style: TextStyle(
                                          fontFamily: 'Poppins',
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16)),
                                  Text('Lihat semua lokasi di Medan',
                                      style: TextStyle(
                                          fontFamily: 'Poppins',
                                          color: Colors.white70,
                                          fontSize: 12)),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_rounded,
                                color: Colors.white, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ).animate().fade(delay: 300.ms).slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 20),

                  // All places
                  _SectionHeader(
                    title: tempat.selectedKategoriId == null
                        ? 'Semua Tempat'
                        : tempat.kategori
                                .firstWhere(
                                    (k) => k.id == tempat.selectedKategoriId,
                                    orElse: () => KategoriModel(id: 0, namaKategori: 'Tempat'))
                                .namaKategori,
                    onSeeAll: null,
                  ),
                  const SizedBox(height: 10),

                  tempat.isLoading
                      ? Column(
                          children: List.generate(5, (_) => const ListTileSkeleton()))
                      : tempat.allTempat.isEmpty
                          ? _EmptyState()
                          : Column(
                              children: List.generate(
                                tempat.allTempat.length,
                                (i) => PlaceListTile(
                                    tempat: tempat.allTempat[i], index: i),
                              ),
                            ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  //void _showNotifications(BuildContext context) {
  // Untuk saat ini tampilkan snackbar bahwa notifikasi akan datang dari server
    //ScaffoldMessenger.of(context).showSnackBar(
      //SnackBar(
        //content: const Text('Notifikasi akan muncul di sini saat ada tempat baru'),
        //behavior: SnackBarBehavior.floating,
        //shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        //duration: const Duration(seconds: 2),
      //),
    //);
    // Nanti bisa diganti dengan halaman daftar notifikasi yang lebih lengkap
  //}

  void _showSearchSheet(BuildContext context, TempatProvider tempat) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SearchSheet(tempat: tempat),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  const _SectionHeader({required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(title, style: AppTextStyles.h3),
          const Spacer(),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              child: const Text('Lihat Semua',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      color: AppColors.primary,
                      fontSize: 12)),
            ),
        ],
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  final TempatProvider tempat;
  const _CategoryChips({required this.tempat});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: tempat.kategori.length + 1,
        itemBuilder: (_, i) {
          if (i == 0) {
            final selected = tempat.selectedKategoriId == null;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => tempat.setKategoriFilter(null),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: selected ? AppColors.primary : AppColors.surface),
                  ),
                  child: Text('Semua',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: selected ? Colors.white : AppColors.textGray)),
                ),
              ),
            );
          }
          final k = tempat.kategori[i - 1];
          final selected = tempat.selectedKategoriId == k.id;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => tempat.setKategoriFilter(selected ? null : k.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: selected ? AppColors.primary : AppColors.surface),
                ),
                child: Text('${k.icon} ${k.namaKategori}',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: selected ? Colors.white : AppColors.textGray)),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.search_off_rounded,
                size: 60, color: AppColors.textGray),
            SizedBox(height: 12),
            Text('Tidak ada tempat ditemukan',
                style: AppTextStyles.body, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _SearchSheet extends StatefulWidget {
  final TempatProvider tempat;
  const _SearchSheet({required this.tempat});

  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ctrl.text = widget.tempat.searchQuery;
    _ctrl.addListener(() => widget.tempat.setSearch(_ctrl.text));
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            // Search input
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _ctrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Cari tempat...',
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                  suffixIcon: _ctrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, color: AppColors.textGray),
                          onPressed: () {
                            _ctrl.clear();
                            widget.tempat.setSearch('');
                          },
                        )
                      : null,
                ),
              ),
            ),

            // Results
            Expanded(
              child: Consumer<TempatProvider>(
                builder: (_, tp, __) => ListView.builder(
                  controller: scrollCtrl,
                  itemCount: tp.allTempat.length,
                  itemBuilder: (_, i) => PlaceListTile(
                    tempat: tp.allTempat[i],
                    index: i,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    widget.tempat.setSearch('');
    _ctrl.dispose();
    super.dispose();
  }
}