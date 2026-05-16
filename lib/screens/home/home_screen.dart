// FILE: lib/screens/home/home_screen.dart
// Halaman beranda (home) aplikasi DanLens.
// Fungsi: Menampilkan sambutan, carousel gambar tempat, daftar kategori, tempat dengan rating tertinggi,
// tombol cepat menuju peta, serta daftar semua tempat dengan fitur pencarian dan filter kategori.
// Informasi penting: Menggunakan provider untuk state management (AuthProvider, TempatProvider, FavoriteProvider).
// Mendukung pull-to-refresh untuk memuat ulang data. Halaman ini adalah halaman utama setelah login.

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

// Kelas HomeScreen adalah StatefulWidget karena memiliki scroll controller dan state untuk pencarian.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Controller untuk text field pencarian (tidak digunakan langsung, tetapi disediakan untuk keperluan jika ada).
  final _searchCtrl = TextEditingController();
  // Controller untuk scroll view, dapat digunakan untuk mengontrol posisi scroll.
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    // Setelah widget pertama kali dibangun, muat data awal.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tp = context.read<TempatProvider>();
      final fav = context.read<FavoriteProvider>();
      // Jika data tempat masih kosong, muat dari server/cache.
      if (tp.allTempat.isEmpty) tp.loadAll();
      // Jika carousel masih kosong, muat data carousel.
      if (tp.carouselTempat.isEmpty) tp.loadCarousel();
      // Sinkronkan daftar favorit dengan data tempat yang tersedia.
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
        // Widget untuk pull-to-refresh.
        color: AppColors.primary,
        onRefresh: () async {
          // Saat di-refresh, muat ulang semua data dan carousel.
          await tempat.refresh();
          await tempat.loadCarousel();
        },
        child: CustomScrollView(
          controller: _scrollCtrl,
          slivers: [
            // ── APP BAR ──────────────────────────────────
            SliverAppBar(
              expandedHeight: 0, // Tidak ada area yang diperluas.
              floating: true, // AppBar muncul saat scroll ke atas.
              snap: true, // AppBar langsung muncul seluruhnya saat scroll.
              backgroundColor: AppColors.white,
              elevation: 0,
              automaticallyImplyLeading: false, // Tidak menampilkan tombol back.
              title: Row(
                children: [
                  // Lingkaran hijau dengan ikon lokasi.
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
                  // Teks judul aplikasi.
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
                // Tombol notifikasi (saat ini mengarah ke halaman ErrorLogWidget).
                IconButton(
                  icon: const Icon(Icons.notifications_outlined,
                      color: AppColors.textDark),
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
                  // Sambutan (greeting) dengan nama pengguna.
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Teks sambutan, mengambil nama depan dari user.
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

                  // Bar pencarian (sebenarnya hanya tiruan, menampilkan bottom sheet saat diketuk).
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
                            // Ikon filter (tune) sebagai petunjuk bahwa ada filter.
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

                  // Carousel gambar tempat.
                  HomeCarousel(
                    items: tempat.carouselTempat,
                    isLoading: tempat.isLoadingCarousel,
                  ).animate().fade(delay: 200.ms),

                  const SizedBox(height: 20),

                  // Header Rating Tertinggi dengan tombol lihat semua.
                  _SectionHeader(
                    title: 'Rating Tertinggi ⭐',
                    onSeeAll: () {
                       Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DefaultTabController(
                            length: 3,
                            initialIndex: 1,  // Tab rating (1 = rating).
                            child: RecommendationScreen(),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  // List horizontal tempat dengan rating tertinggi.
                  SizedBox(
                    height: 200,
                    child: tempat.isLoading
                        ? // Tampilkan skeleton jika loading.
                        ListView.builder(
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

                  // Tombol aksi cepat: Jelajahi Peta.
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

                  // Header Kategori (tanpa tombol lihat semua).
                  const _SectionHeader(title: 'Kategori', onSeeAll: null),
                  const SizedBox(height: 10),
                  // Baris chip kategori (dapat dipilih).
                  _CategoryChips(tempat: tempat),

                  const SizedBox(height: 20),

                  // Header daftar semua tempat (judul berubah sesuai filter kategori).
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

                  // Daftar vertikal semua tempat (dengan PlaceListTile).
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

                  const SizedBox(height: 100), // Ruang kosong di bagian bawah.
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Menampilkan bottom sheet pencarian dan filter.
  void _showSearchSheet(BuildContext context, TempatProvider tempat) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Memungkinkan sheet setinggi layar.
      backgroundColor: Colors.transparent,
      builder: (_) => _SearchSheet(tempat: tempat),
    );
  }

  @override
  void dispose() {
    // Bersihkan controller saat widget dihancurkan.
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }
}

// Widget header bagian (judul dengan tombol "Lihat Semua" opsional).
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

// Baris chip kategori (dapat dipilih untuk filter).
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
        itemCount: tempat.kategori.length + 1, // +1 untuk chip "Semua".
        itemBuilder: (_, i) {
          // Chip "Semua" (indeks 0).
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
          // Chip kategori lainnya.
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

// Widget untuk menampilkan pesan ketika tidak ada tempat.
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

// Bottom sheet untuk pencarian (dapat digeser).
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
    // Set teks awal dari query pencarian yang tersimpan di provider.
    _ctrl.text = widget.tempat.searchQuery;
    // Saat teks berubah, perbarui filter pencarian di provider.
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
            // Gagang (handle) untuk menarik sheet.
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            // Input teks pencarian.
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

            // Daftar hasil pencarian.
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
    // Reset filter pencarian saat sheet ditutup.
    widget.tempat.setSearch('');
    _ctrl.dispose();
    super.dispose();
  }
}