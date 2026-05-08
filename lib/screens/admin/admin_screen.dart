// lib/screens/admin/admin_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/app_theme.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/tempat_provider.dart';
import '../../services/supabase_service.dart';
import '../../utils/error_logger.dart';
import '../../widgets/skeleton_loader.dart';
import '../detail/detail_screen.dart';
import '../data/import_export_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  String _search = '';
  int? _filterKat;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    ErrorLogger.i('Admin panel opened'); // ← tambahkan
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final tp = context.watch<TempatProvider>();

    if (!auth.isLoggedIn || !auth.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin Panel')),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.admin_panel_settings_rounded,
                  size: 64, color: AppColors.textGray),
              SizedBox(height: 16),
              Text('Akses Ditolak', style: AppTextStyles.h2),
              SizedBox(height: 8),
              Text('Halaman ini hanya untuk Admin.',
                  style: AppTextStyles.small),
            ],
          ),
        ),
      );
    }

    final filtered = tp.allTempat.where((t) {
      final matchSearch = _search.isEmpty ||
          t.namaTempat.toLowerCase().contains(_search.toLowerCase());
      final matchKat =
          _filterKat == null || t.kategoriId == _filterKat;
      return matchSearch && matchKat;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.import_export_rounded),
            tooltip: 'Import / Export Data',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ImportExportScreen()),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          labelColor: Colors.white,               // ← tambahkan
          unselectedLabelColor: Colors.white60,   // ← tambahkan
          indicatorColor: Colors.white,
          labelStyle: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 12),
          tabs: [
            Tab(text: '📋 Semua Tempat (${tp.allTempat.length})'),
            const Tab(text: '📊 Statistik'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          // ── Tab 1: Data Management ────────────────────────
          Column(
            children: [
              // Search + filter bar
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (v) => setState(() => _search = v),
                        decoration: const InputDecoration(
                          hintText: 'Cari tempat...',
                          prefixIcon: Icon(Icons.search_rounded,
                              color: AppColors.primary, size: 18),
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Category filter dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.surface),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int?>(
                          value: _filterKat,
                          isDense: true,
                          hint: const Text('Kat',
                              style: TextStyle(
                                  fontFamily: 'Poppins', fontSize: 12)),
                          items: [
                            const DropdownMenuItem<int?>(
                                value: null,
                                child: Text('Semua',
                                    style: TextStyle(
                                        fontFamily: 'Poppins', fontSize: 12))),
                            ...tp.kategori.map((k) => DropdownMenuItem<int>(
                                  value: k.id,
                                  child: Text('${k.icon} ${k.namaKategori}',
                                      style: const TextStyle(
                                          fontFamily: 'Poppins', fontSize: 12)),
                                )),
                          ],
                          onChanged: (v) => setState(() => _filterKat = v),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Count bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Text('${filtered.length} tempat',
                        style: AppTextStyles.small),
                    const Spacer(),
                    if (_deleting)
                      const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.error)),
                  ],
                ),
              ),

              // List
              Expanded(
                child: tp.isLoading
                    ? ListView.builder(
                        itemCount: 6,
                        itemBuilder: (_, __) => const ListTileSkeleton(),
                      )
                    : filtered.isEmpty
                        ? const Center(
                            child: Text('Tidak ada data',
                                style: AppTextStyles.small))
                        : ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (_, i) => _AdminPlaceTile(
                              tempat: filtered[i],
                              index: i,
                              onEdit: () =>
                                  _showEditDialog(context, filtered[i], tp),
                              onDelete: () =>
                                  _confirmDelete(context, filtered[i], tp),
                              onView: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        DetailScreen(tempat: filtered[i])),
                              ),
                            ),
                          ),
              ),
            ],
          ),

          // ── Tab 2: Statistics ────────────────────────────────
          _StatsTab(tp: tp),
        ],
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, TempatModel t, TempatProvider tp) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Tempat',
            style: TextStyle(
                fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        content: Text(
          'Hapus "${t.namaTempat}"?\nData tidak dapat dikembalikan.',
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal',
                  style: TextStyle(
                      fontFamily: 'Poppins', color: AppColors.textGray))),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _deleting = true);
              ErrorLogger.i('Admin: deleting tempat id=${t.id}'); // ← tambahkan
              final ok = await SupabaseService.deleteTempat(t.id);
              if (!mounted) return;
              setState(() => _deleting = false);
              if (ok) {
                await tp.refresh();
                _showSnack('✅ "${t.namaTempat}" berhasil dihapus',
                    isError: false);
              } else {
                _showSnack('❌ Gagal menghapus', isError: true);
                ErrorLogger.e('Admin: failed to delete tempat id=${t.id}'); // ← tambahkan
              }
            },
            child: const Text('Hapus',
                style: TextStyle(fontFamily: 'Poppins')),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(
      BuildContext context, TempatModel t, TempatProvider tp) {
    final namaCtrl = TextEditingController(text: t.namaTempat);
    final detailCtrl = TextEditingController(text: t.detailTempat ?? '');
    final jalanCtrl = TextEditingController(text: t.jalan ?? '');
    final kontakCtrl = TextEditingController(text: t.kontak ?? '');
    double? rating = t.reviewRating;
    KategoriModel? selKat = tp.kategori
        .where((k) => k.id == t.kategoriId)
        .firstOrNull;
    KecamatanModel? selKec = tp.kecamatan
        .where((k) => k.id == t.kecamatanId)
        .firstOrNull;
    bool saving = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: const Text('Edit Tempat',
              style: TextStyle(
                  fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogField(namaCtrl, 'Nama Tempat', Icons.location_on_rounded),
                const SizedBox(height: 10),
                _dialogField(detailCtrl, 'Deskripsi', Icons.description_rounded,
                    maxLines: 3),
                const SizedBox(height: 10),
                _dialogField(jalanCtrl, 'Jalan', Icons.edit_road_rounded),
                const SizedBox(height: 10),
                _dialogField(kontakCtrl, 'Kontak', Icons.phone_rounded,
                    keyboard: TextInputType.phone),
                const SizedBox(height: 10),
                // Kategori
                DropdownButtonFormField<KategoriModel>(
                  initialValue: selKat,
                  decoration: const InputDecoration(
                    labelText: 'Kategori',
                    prefixIcon: Icon(Icons.category_rounded,
                        color: AppColors.primary),
                    isDense: true,
                  ),
                  items: tp.kategori
                      .map((k) => DropdownMenuItem(
                            value: k,
                            child: Text('${k.icon} ${k.namaKategori}',
                                style: const TextStyle(
                                    fontFamily: 'Poppins', fontSize: 13)),
                          ))
                      .toList(),
                  onChanged: (v) => setS(() => selKat = v),
                ),
                const SizedBox(height: 10),
                // Kecamatan
                DropdownButtonFormField<KecamatanModel>(
                   initialValue:  selKec,
                  decoration: const InputDecoration(
                    labelText: 'Kecamatan',
                    prefixIcon: Icon(Icons.location_city_rounded,
                        color: AppColors.primary),
                    isDense: true,
                  ),
                  items: tp.kecamatan
                      .map((k) => DropdownMenuItem(
                            value: k,
                            child: Text(k.namaKecamatan,
                                style: const TextStyle(
                                    fontFamily: 'Poppins', fontSize: 13)),
                          ))
                      .toList(),
                  onChanged: (v) => setS(() => selKec = v),
                ),
                const SizedBox(height: 10),
                // Rating
                Row(
                  children: [
                    const Text('Rating: ',
                        style: TextStyle(
                            fontFamily: 'Poppins', fontSize: 13)),
                    ...List.generate(
                      5,
                      (i) => GestureDetector(
                        onTap: () =>
                            setS(() => rating = (i + 1).toDouble()),
                        child: Icon(
                          (i + 1) <= (rating ?? 0)
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: Colors.amber,
                          size: 26,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(rating?.toStringAsFixed(1) ?? '-',
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: saving ? null : () => Navigator.pop(ctx),
                child: const Text('Batal',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        color: AppColors.textGray))),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (namaCtrl.text.trim().isEmpty) return;
                      setS(() => saving = true);
                      final data = {
                        'nama_tempat': namaCtrl.text.trim(),
                        'detail_tempat': detailCtrl.text.trim().isEmpty
                            ? null
                            : detailCtrl.text.trim(),
                        'jalan': jalanCtrl.text.trim().isEmpty
                            ? null
                            : jalanCtrl.text.trim(),
                        'kontak': kontakCtrl.text.trim().isEmpty
                            ? null
                            : kontakCtrl.text.trim(),
                        'kategori_id': selKat?.id,
                        'kecamatan_id': selKec?.id,
                        'review_rating': rating,
                      };
                      final ok =
                          await SupabaseService.updateTempat(t.id, data);
                      setS(() => saving = false);
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      if (ok) {
                        await tp.refresh();
                        _showSnack('✅ Data berhasil diperbarui',
                            isError: false);
                      } else {
                        _showSnack('❌ Gagal memperbarui', isError: true);
                        ErrorLogger.e('Admin: failed to update tempat id=${t.id}'); // ← tambahkan
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Simpan',
                      style: TextStyle(fontFamily: 'Poppins')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    int maxLines = 1,
    TextInputType? keyboard,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary, size: 18),
        isDense: true,
      ),
      style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:
          Text(msg, style: const TextStyle(fontFamily: 'Poppins')),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }
}

// ── Admin Place Tile ───────────────────────────────────────────────
class _AdminPlaceTile extends StatelessWidget {
  final TempatModel tempat;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onView;

  const _AdminPlaceTile({
    required this.tempat,
    required this.index,
    required this.onEdit,
    required this.onDelete,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha:0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(14)),
            child: SizedBox(
              width: 72,
              height: 72,
              child: tempat.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: tempat.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: AppColors.surface),
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.surface,
                        child: Center(
                          child: Text(tempat.categoryIcon,
                              style: const TextStyle(fontSize: 24)),
                        ),
                      ),
                    )
                  : Container(
                      color: AppColors.surface,
                      child: Center(
                        child: Text(tempat.categoryIcon,
                            style: const TextStyle(fontSize: 28)),
                      ),
                    ),
            ),
          ),
          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tempat.namaTempat,
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.textDark),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${tempat.namaKategori ?? ''} · ${tempat.namaKecamatan ?? ''}',
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: AppColors.textGray),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: Colors.amber, size: 12),
                      Text(
                        ' ${tempat.reviewRating?.toStringAsFixed(1) ?? '-'}',
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ID: ${tempat.id}',
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            color: AppColors.textGray),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Actions
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ActionBtn(
                  icon: Icons.visibility_rounded,
                  color: AppColors.primary,
                  onTap: onView),
              _ActionBtn(
                  icon: Icons.edit_rounded,
                  color: Colors.orange,
                  onTap: onEdit),
              _ActionBtn(
                  icon: Icons.delete_rounded,
                  color: AppColors.error,
                  onTap: onDelete),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: index * 40))
        .fade(duration: 300.ms)
        .slideX(begin: 0.05, end: 0);
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

// ── Statistics Tab ─────────────────────────────────────────────────
class _StatsTab extends StatelessWidget {
  final TempatProvider tp;
  const _StatsTab({required this.tp});

  @override
  Widget build(BuildContext context) {
    // Build stats per category
    final catStats = <String, int>{};
    final catRating = <String, List<double>>{};
    for (final t in tp.allTempat) {
      final cat = t.namaKategori ?? 'Lainnya';
      catStats[cat] = (catStats[cat] ?? 0) + 1;
      if (t.reviewRating != null) {
        catRating.putIfAbsent(cat, () => []).add(t.reviewRating!);
      }
    }

    final totalTempat = tp.allTempat.length;
    final avgRating = tp.allTempat
            .where((t) => t.reviewRating != null)
            .map((t) => t.reviewRating!)
            .fold<double>(0, (a, b) => a + b) /
        (tp.allTempat.where((t) => t.reviewRating != null).length.clamp(1, 999));

    final topPlace = tp.getTopRated(limit: 1).firstOrNull;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overview cards
          Row(
            children: [
              _StatBig(
                  label: 'Total Tempat',
                  value: '$totalTempat',
                  icon: Icons.location_on_rounded,
                  color: AppColors.primary),
              const SizedBox(width: 12),
              _StatBig(
                  label: 'Rata-rata Rating',
                  value: avgRating.toStringAsFixed(2),
                  icon: Icons.star_rounded,
                  color: Colors.amber),
            ],
          ).animate().fade(duration: 400.ms),

          const SizedBox(height: 12),

          if (topPlace != null)
            _TopPlaceCard(tempat: topPlace)
                .animate()
                .fade(delay: 100.ms),

          const SizedBox(height: 20),

          const Text('Distribusi per Kategori', style: AppTextStyles.h3)
              .animate()
              .fade(delay: 150.ms),
          const SizedBox(height: 12),

          ...catStats.entries.toList().asMap().entries.map((e) {
            final i = e.key;
            final entry = e.value;
            final pct = totalTempat > 0
                ? (entry.value / totalTempat)
                : 0.0;
            final avgCat = catRating[entry.key]?.isEmpty == true
                ? 0.0
                : (catRating[entry.key]?.fold<double>(0, (a, b) => a + b) ??
                        0) /
                    (catRating[entry.key]?.length ?? 1);
            final catModel = tp.kategori.firstWhere(
                (k) => k.namaKategori == entry.key,
                orElse: () =>
                    KategoriModel(id: 0, namaKategori: entry.key));

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha:0.06),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(catModel.icon,
                          style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text(entry.key,
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: 14)),
                      const Spacer(),
                      Text('${entry.value} tempat',
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: AppColors.textGray)),
                      const SizedBox(width: 8),
                      const Icon(Icons.star_rounded,
                          color: Colors.amber, size: 13),
                      Text(avgCat.toStringAsFixed(1),
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct.toDouble(),
                      backgroundColor: AppColors.surface,
                      color: AppColors.primary,
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(pct * 100).toStringAsFixed(1)}% dari total',
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        color: AppColors.textGray),
                  ),
                ],
              ),
            )
                .animate(delay: Duration(milliseconds: 200 + i * 60))
                .fade(duration: 400.ms)
                .slideX(begin: 0.1, end: 0);
          }),

          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _StatBig extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatBig({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha:0.1),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                        color: color)),
                Text(label,
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        color: AppColors.textGray)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TopPlaceCard extends StatelessWidget {
  final TempatModel tempat;
  const _TopPlaceCard({required this.tempat});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Text('🏆', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Rating Tertinggi',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white70,
                        fontSize: 11)),
                Text(tempat.namaTempat,
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha:0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.star_rounded,
                    color: Colors.amber, size: 16),
                const SizedBox(width: 3),
                Text(
                  tempat.reviewRating?.toStringAsFixed(1) ?? '-',
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
    );
  }
}