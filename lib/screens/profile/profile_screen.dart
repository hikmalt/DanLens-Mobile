// lib/screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_theme.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/tempat_provider.dart';
import '../../services/supabase_service.dart';
import '../../utils/error_logger.dart';
import '../auth/login_screen.dart';
import '../detail/detail_screen.dart';
import 'team_profile_screen.dart';
import '../admin/admin_screen.dart';
import '../data/import_export_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<TempatModel> _myPlaces = [];
  bool _loadingMyPlaces = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadMyPlaces();
  }

  Future<void> _loadMyPlaces() async {
    final auth = context.read<AuthProvider>();
    if (auth.user != null) {
      final places = await SupabaseService.getTempatByUserId(auth.user!.id);
      if (mounted) {
        setState(() {
          _myPlaces = places;
          _loadingMyPlaces = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final tempat = context.watch<TempatProvider>();

    if (!auth.isLoggedIn) {
      return _GuestProfile();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: Colors.white,               // ← tambahkan
          unselectedLabelColor: Colors.white60,   // ← tambahkan
          indicatorColor: Colors.white,
          labelStyle: const TextStyle(
              fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle:
              const TextStyle(fontFamily: 'Poppins', fontSize: 12),
          tabs: [
            const Tab(text: 'Profil'),
            Tab(text: 'Tempat Saya (${_myPlaces.length})'),
          ],
        ),
        actions: [
          if (auth.isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings_rounded),
              tooltip: 'Panel Admin',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminScreen()),
              ),
            ),
        ],
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          // Tab 1: Profil (dari kode lama)
          _ProfileTab(auth: auth, tempat: tempat),
          // Tab 2: Tempat Saya
          _MyPlacesTab(
            places: _myPlaces,
            loading: _loadingMyPlaces,
            onRefresh: _loadMyPlaces,
          ),
        ],
      ),
    );
  }
}

// ── Profil Tab (kode lama disatukan ke sini) ──────────────────────
class _ProfileTab extends StatelessWidget {
  final AuthProvider auth;
  final TempatProvider tempat;
  const _ProfileTab({required this.auth, required this.tempat});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Header
        SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          automaticallyImplyLeading: false,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDeep],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.white,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha:0.2),
                              blurRadius: 12)
                        ],
                      ),
                      child: auth.user?.photoUrl.isNotEmpty == true
                          ? ClipOval(
                              child: Image.network(
                                auth.user!.photoUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.person_rounded,
                                  size: 40, color: AppColors.primary),
                              ))
                          : const Icon(Icons.person_rounded,
                              size: 40, color: AppColors.primary),
                    ),
                    const SizedBox(height: 12),
                    Text(auth.user?.name ?? '',
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                    Text(auth.user?.email ?? '',
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: Colors.white70)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha:0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        auth.isAdmin ? '👑 Admin' : '📤 Uploader',
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Stats
                Row(
                  children: [
                    _StatCard(label: 'Total Tempat',
                        value: '${tempat.allTempat.length}',
                        icon: Icons.location_on_rounded),
                    const SizedBox(width: 10),
                    _StatCard(label: 'Kategori',
                        value: '${tempat.kategori.length}',
                        icon: Icons.category_rounded),
                    const SizedBox(width: 10),
                    _StatCard(label: 'Kecamatan',
                        value: '${tempat.kecamatan.length}',
                        icon: Icons.map_rounded),
                  ],
                ),
                const SizedBox(height: 20),

                // Menu items
                _MenuSection(title: 'Akun', items: [
                  _MenuItem(
                    icon: Icons.people_rounded,
                    label: 'Profil Tim',
                    subtitle: 'Kenali tim pengembang DanLens',
                    color: AppColors.primary,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const TeamProfileScreen())),
                  ),
                  _MenuItem(
                    icon: Icons.history_rounded,
                    label: 'Riwayat Dilihat',
                    subtitle: '${tempat.recentlyViewed.length} tempat',
                    color: Colors.orange,
                    onTap: () => _showRecentlyViewed(context, tempat),
                  ),
                  // ⬇️ Item baru untuk admin
                  if (auth.isAdmin)
                    _MenuItem(
                      icon: Icons.import_export_rounded,
                      label: 'Import / Export Data',
                      subtitle: 'Kelola data tempat (admin)',
                      color: AppColors.primary,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ImportExportScreen()),
                      ),
                    ),
                ]).animate().fade(delay: 200.ms),  // ← animasi fade menggunakan flutter_animate
                const SizedBox(height: 12),

                _MenuSection(title: 'Informasi', items: [
                  _MenuItem(
                    icon: Icons.info_outline_rounded,
                    label: 'Tentang DanLens',
                    subtitle: 'Sistem Informasi GIS Medan',
                    color: Colors.blue,
                    onTap: () => _showAbout(context),
                  ),
                  _MenuItem(
                    icon: Icons.bug_report_rounded,
                    label: 'Log Error',
                    subtitle: '${ErrorLogger.logs.length} log tersimpan',
                    color: Colors.red,
                    onTap: () => _showErrorLog(context),
                  ),
                  _MenuItem(
                    icon: Icons.code_rounded,
                    label: 'GitHub Proyek',
                    subtitle: 'Lihat source code',
                    color: Colors.grey[800]!,
                    onTap: () => launchUrl(
                      Uri.parse('https://github.com/hikmalt/DanLens-Sistem-Informasi-GIS-Medan-Projek-Kelompok-TRPL-6D-Praktik-SIstem-Informasi-Geografis.git'),
                      mode: LaunchMode.externalApplication,
                    ),
                  ),
                ]),
                const SizedBox(height: 12),

                // Logout
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmLogout(context, auth),
                    icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                    label: const Text('Keluar',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            color: AppColors.error,
                            fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _confirmLogout(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Keluar', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
        content: const Text('Yakin ingin keluar dari akun?', style: TextStyle(fontFamily: 'Poppins')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(fontFamily: 'Poppins', color: AppColors.textGray)),
          ),
          ElevatedButton(
            onPressed: () async {
              await auth.logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Keluar', style: TextStyle(fontFamily: 'Poppins')),
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.location_on_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('DanLens', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
          ],
        ),
        content: const Text(
          'DanLens adalah aplikasi Sistem Informasi Geografis (SIG) yang memetakan ratusan titik lokasi penting di Medan.\n\nFitur: Kuliner, Wisata, Kesehatan, dan Layanan Publik.\n\nVersi: 1.0.0',
          style: TextStyle(fontFamily: 'Poppins', fontSize: 13, height: 1.6),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup', style: TextStyle(fontFamily: 'Poppins')),
          ),
        ],
      ),
    );
  }

  void _showRecentlyViewed(BuildContext context, TempatProvider tp) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                width: 36, height: 4,
                decoration: BoxDecoration(
                    color: AppColors.surface, borderRadius: BorderRadius.circular(4)),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.history_rounded, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Riwayat Dilihat',
                        style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 16)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: tp.recentlyViewed.isEmpty
                    ? const Center(
                        child: Text('Belum ada riwayat',
                            style: TextStyle(fontFamily: 'Poppins', color: AppColors.textGray)))
                    : ListView.builder(
                        controller: ctrl,
                        itemCount: tp.recentlyViewed.length,
                        itemBuilder: (_, i) => ListTile(
                          leading: Text(tp.recentlyViewed[i].categoryIcon,
                              style: const TextStyle(fontSize: 24)),
                          title: Text(tp.recentlyViewed[i].namaTempat,
                              style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500)),
                          subtitle: Text(tp.recentlyViewed[i].namaKategori ?? '',
                              style: const TextStyle(fontFamily: 'Poppins', fontSize: 11)),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorLog(BuildContext context) {
    final logs = ErrorLogger.logs;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1a1a2e),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                width: 36, height: 4,
                decoration: BoxDecoration(
                    color: Colors.white24, borderRadius: BorderRadius.circular(4)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.bug_report_rounded, color: Colors.redAccent),
                    const SizedBox(width: 8),
                    const Text('Error Log',
                        style: TextStyle(fontFamily: 'Poppins', color: Colors.white,
                            fontWeight: FontWeight.w600, fontSize: 16)),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        ErrorLogger.clear();
                        Navigator.pop(context);
                      },
                      child: const Text('Clear', style: TextStyle(color: Colors.redAccent, fontFamily: 'Poppins')),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: logs.isEmpty
                    ? const Center(
                        child: Text('Tidak ada log error 🎉',
                            style: TextStyle(fontFamily: 'Poppins', color: Colors.white54)))
                    : ListView.builder(
                        controller: ctrl,
                        padding: const EdgeInsets.all(8),
                        itemCount: logs.length,
                        itemBuilder: (_, i) {
                          final log = logs[logs.length - 1 - i];
                          final color = log.level == LogLevel.error
                              ? Colors.redAccent
                              : log.level == LogLevel.warning
                                  ? Colors.orange
                                  : log.level == LogLevel.info
                                      ? Colors.greenAccent
                                      : Colors.white54;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha:0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 48,
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha:0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(log.levelLabel,
                                      style: TextStyle(fontFamily: 'Poppins', fontSize: 9, color: color),
                                      textAlign: TextAlign.center),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(log.message,
                                      style: const TextStyle(
                                          fontFamily: 'Poppins', fontSize: 11, color: Colors.white70)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tab Tempat Saya ─────────────────────────────────────────────
class _MyPlacesTab extends StatelessWidget {
  final List<TempatModel> places;
  final bool loading;
  final VoidCallback onRefresh;

  const _MyPlacesTab({
    required this.places,
    required this.loading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (places.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_city_rounded, size: 64, color: AppColors.surface),
            SizedBox(height: 12),
            Text('Belum ada tempat yang diunggah', style: AppTextStyles.h3),
            SizedBox(height: 8),
            Text('Tempat yang Anda tambahkan akan muncul di sini',
                style: AppTextStyles.small),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: places.length,
        itemBuilder: (_, i) {
          final t = places[i];
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
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 48, height: 48,
                  child: t.imageUrl.isNotEmpty
                      ? Image.network(t.imageUrl, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                              color: AppColors.surface,
                              child: Center(child: Text(t.categoryIcon,
                                  style: const TextStyle(fontSize: 20)))))
                      : Container(
                          color: AppColors.surface,
                          child: Center(child: Text(t.categoryIcon,
                              style: const TextStyle(fontSize: 20)))),
                ),
              ),
              title: Text(t.namaTempat,
                  style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
              subtitle: Text('${t.namaKategori ?? ''} · ${t.namaKecamatan ?? ''}',
                  style: const TextStyle(
                      fontFamily: 'Poppins', fontSize: 11, color: AppColors.textGray)),
              trailing: PopupMenuButton<String>(
                onSelected: (action) {
                  if (action == 'edit') {
                    _showEditDialog(context, t);
                  } else if (action == 'hapus') {
                    _confirmDelete(context, t);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_rounded, color: Colors.orange, size: 18),
                        SizedBox(width: 8),
                        Text('Edit', style: TextStyle(fontFamily: 'Poppins')),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'hapus',
                    child: Row(
                      children: [
                        Icon(Icons.delete_rounded, color: AppColors.error, size: 18),
                        SizedBox(width: 8),
                        Text('Hapus', style: TextStyle(fontFamily: 'Poppins')),
                      ],
                    ),
                  ),
                ],
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => DetailScreen(tempat: t)),
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, TempatModel t) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Tempat',
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        content: Text('Hapus "${t.namaTempat}"?\nData tidak dapat dikembalikan.',
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal',
                style: TextStyle(fontFamily: 'Poppins', color: AppColors.textGray)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(context);
              final ok = await SupabaseService.deleteTempat(t.id);
              if (context.mounted) {
                if (ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('"${t.namaTempat}" berhasil dihapus',
                        style: const TextStyle(fontFamily: 'Poppins'))),
                  );
                  onRefresh();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gagal menghapus',
                        style: TextStyle(fontFamily: 'Poppins'))),
                  );
                }
              }
            },
            child: const Text('Hapus', style: TextStyle(fontFamily: 'Poppins')),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, TempatModel t) {
    final namaCtrl = TextEditingController(text: t.namaTempat);
    final detailCtrl = TextEditingController(text: t.detailTempat ?? '');
    final jalanCtrl = TextEditingController(text: t.jalan ?? '');
    final kontakCtrl = TextEditingController(text: t.kontak ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Tempat',
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: namaCtrl,
                decoration: const InputDecoration(labelText: 'Nama Tempat'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: detailCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Deskripsi'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: jalanCtrl,
                decoration: const InputDecoration(labelText: 'Jalan'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: kontakCtrl,
                decoration: const InputDecoration(labelText: 'Kontak'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal',
                style: TextStyle(fontFamily: 'Poppins', color: AppColors.textGray)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (namaCtrl.text.trim().isEmpty) return;
              final data = {
                'nama_tempat': namaCtrl.text.trim(),
                'detail_tempat': detailCtrl.text.trim().isEmpty ? null : detailCtrl.text.trim(),
                'jalan': jalanCtrl.text.trim().isEmpty ? null : jalanCtrl.text.trim(),
                'kontak': kontakCtrl.text.trim().isEmpty ? null : kontakCtrl.text.trim(),
              };
              final ok = await SupabaseService.updateTempat(t.id, data);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                if (ok) {
                  onRefresh();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Data berhasil diperbarui',
                        style: TextStyle(fontFamily: 'Poppins'))),
                  );
                }
              }
            },
            child: const Text('Simpan', style: TextStyle(fontFamily: 'Poppins')),
          ),
        ],
      ),
    );
  }
}

// ── Sub‑widget classes tetap sama ────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha:0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: AppColors.textDark)),
            Text(label,
                style: const TextStyle(
                    fontFamily: 'Poppins', fontSize: 10, color: AppColors.textGray),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  final String title;
  final List<_MenuItem> items;

  const _MenuSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(title, style: AppTextStyles.small),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha:0.06),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            children: items.asMap().entries.map((e) {
              final isLast = e.key == items.length - 1;
              return Column(
                children: [
                  e.value,
                  if (!isLast)
                    const Divider(height: 1, indent: 56, color: AppColors.surface),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: color.withValues(alpha:0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(label,
          style: const TextStyle(
              fontFamily: 'Poppins', fontWeight: FontWeight.w500, fontSize: 14)),
      subtitle: Text(subtitle,
          style: const TextStyle(
              fontFamily: 'Poppins', fontSize: 11, color: AppColors.textGray)),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textGray, size: 18),
    );
  }
}

class _GuestProfile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil'), automaticallyImplyLeading: false),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_outline_rounded, size: 80, color: AppColors.surface),
            const SizedBox(height: 16),
            const Text('Belum Login', style: AppTextStyles.h2),
            const SizedBox(height: 8),
            const Text('Login untuk akses fitur lengkap', style: AppTextStyles.small),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const LoginScreen())),
              icon: const Icon(Icons.login_rounded),
              label: const Text('Login Sekarang'),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const TeamProfileScreen())),
              icon: const Icon(Icons.people_rounded, color: AppColors.primary),
              label: const Text('Lihat Tim', style: TextStyle(color: AppColors.primary, fontFamily: 'Poppins')),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}