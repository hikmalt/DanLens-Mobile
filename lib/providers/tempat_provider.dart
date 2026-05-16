// FILE: lib/providers/tempat_provider.dart
// File ini adalah penyedia data (provider) yang mengelola semua data tempat, kategori, kecamatan, dan carousel.
// Fungsi utama: menyediakan data tempat ke seluruh halaman, menangani filter, pencarian, offline cache, realtime update, dan notifikasi.
// Informasi penting: Provider ini menggunakan pola ChangeNotifier agar UI dapat mendengar perubahan data.
// Versi ini (v3) sudah mendukung realtime dari Supabase, cache offline, serta auto-notifikasi saat ada tempat baru.

import 'package:connectivity_plus/connectivity_plus.dart';
// Paket untuk mengecek koneksi internet.

import 'package:flutter/foundation.dart';
// Paket inti Flutter untuk ChangeNotifier.

import '../models/models.dart';
// Mengimpor semua model data (TempatModel, KategoriModel, KecamatanModel).

import '../services/supabase_service.dart';
// Layanan untuk berinteraksi dengan Supabase (database).

import '../services/realtime_service.dart';
// Layanan untuk mendengarkan perubahan data secara realtime.

import '../services/notification_service.dart';
// Layanan untuk menampilkan notifikasi lokal.

import '../utils/cache_manager.dart';
// Manajer untuk menyimpan data ke cache lokal (SharedPreferences).

import '../utils/error_logger.dart';
// Pencatat error untuk debugging.

// Kelas provider untuk data tempat.
class TempatProvider extends ChangeNotifier {
  // --- Daftar data yang disimpan ---
  List<TempatModel> _allTempat = [];
  // Menyimpan semua tempat yang diambil dari server (belum difilter).

  List<TempatModel> _filtered = [];
  // Menyimpan tempat yang sudah difilter (berdasarkan kategori atau pencarian).

  List<TempatModel> _carouselTempat = [];
  // Menyimpan tempat untuk ditampilkan di carousel (slide gambar) pada beranda.

  List<KategoriModel> _kategori = [];
  // Menyimpan daftar semua kategori (kuliner, wisata, dll).

  List<KecamatanModel> _kecamatan = [];
  // Menyimpan daftar semua kecamatan dengan polygon geografis.

  List<TempatModel> _recentlyViewed = [];
  // Menyimpan riwayat tempat yang baru dilihat pengguna.

  // --- Status loading dan koneksi ---
  bool _isLoading = false;
  // Menandakan apakah sedang memuat data dari server.

  bool _isLoadingCarousel = false;
  // Menandakan apakah carousel sedang dimuat.

  bool _isOffline = false;
  // Menandakan apakah aplikasi sedang offline (tidak ada koneksi internet).

  bool _realtimeConnected = false;
  // Menandakan apakah koneksi realtime ke Supabase sedang aktif.

  String? _error;
  // Menyimpan pesan error terakhir.

  int? _selectedKategoriId;
  // ID kategori yang sedang dipilih untuk filter.

  String _searchQuery = '';
  // Teks pencarian yang sedang digunakan.

  // --- Getter (properti read-only) untuk mengakses data dari luar ---
  List<TempatModel> get allTempat => _filtered;
  // Mengembalikan tempat yang sudah difilter (bukan semua tempat mentah).

  List<TempatModel> get carouselTempat => _carouselTempat;
  // Mengembalikan daftar tempat untuk carousel.

  List<KategoriModel> get kategori => _kategori;
  // Mengembalikan daftar kategori.

  List<KecamatanModel> get kecamatan => _kecamatan;
  // Mengembalikan daftar kecamatan.

  List<TempatModel> get recentlyViewed => _recentlyViewed;
  // Mengembalikan riwayat dilihat.

  bool get isLoading => _isLoading;
  // Apakah sedang loading.

  bool get isLoadingCarousel => _isLoadingCarousel;
  // Apakah carousel sedang loading.

  bool get isOffline => _isOffline;
  // Apakah offline.

  bool get realtimeConnected => _realtimeConnected;
  // Apakah realtime terhubung.

  String? get error => _error;
  // Pesan error.

  int? get selectedKategoriId => _selectedKategoriId;
  // ID kategori filter.

  String get searchQuery => _searchQuery;
  // Teks pencarian.

  // Mengecek apakah ada koneksi internet.
  Future<bool> _hasConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    // Mengembalikan true jika setidaknya ada satu koneksi (WiFi, seluler, dll).
    return !result.contains(ConnectivityResult.none);
  }

  // Memuat semua data (dipanggil saat aplikasi dimulai atau refresh).
  Future<void> loadAll() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    // Memberitahu UI bahwa loading mulai.

    final online = await _hasConnectivity();
    // Cek koneksi.

    if (!online) {
      // Jika offline, coba gunakan cache lokal.
      _isOffline = true;
      final cached = await CacheManager.loadTempat();
      final cachedKat = await CacheManager.loadKategori();
      final cachedKec = await CacheManager.loadKecamatan();
      if (cached != null) {
        _allTempat = cached;
        _kategori = cachedKat ?? [];
        _kecamatan = cachedKec ?? [];
        _applyFilter();
        ErrorLogger.w('Offline: loaded ${cached.length} from cache');
      } else {
        _error = 'Tidak ada koneksi & cache kosong';
      }
      _isLoading = false;
      notifyListeners();
      return;
    }

    // Jika online, ambil data dari Supabase.
    _isOffline = false;

    try {
      _allTempat = await SupabaseService.getAllTempat(limit: 50);
      // Ambil 50 tempat terbaru.

      await _loadKategoriAndKecamatan();
      // Ambil kategori dan kecamatan.

      _applyFilter();
      // Terapkan filter (kategori & pencarian) pada data tempat.

      // Simpan data ke cache untuk digunakan offline nanti.
      await CacheManager.saveTempat(_allTempat);
      await CacheManager.saveKategori(_kategori);
      await CacheManager.saveKecamatan(_kecamatan);

      // Mulai mendengarkan perubahan realtime dari Supabase.
      _startRealtime();
    } catch (e, stack) {
      // Jika gagal, coba gunakan cache.
      final cached = await CacheManager.loadTempat();
      if (cached != null) {
        _allTempat = cached;
        _applyFilter();
        _error = 'Menggunakan data cache';
        _isOffline = true;
      } else {
        _error = 'Gagal memuat data';
      }
      ErrorLogger.e('TempatProvider.loadAll', e, stack);
    }

    _isLoading = false;
    notifyListeners();
  }

  // Memuat kategori dan kecamatan dari Supabase.
  Future<void> _loadKategoriAndKecamatan() async {
    _kategori = await SupabaseService.getKategori();
    _kecamatan = await SupabaseService.getKecamatan();
  }

  // Memuat ulang kategori (dapat dipanggil dari luar).
  Future<void> loadKategori() async {
    _kategori = await SupabaseService.getKategori();
    notifyListeners();
  }

  // Memuat ulang kecamatan.
  Future<void> loadKecamatan() async {
    _kecamatan = await SupabaseService.getKecamatan();
    notifyListeners();
  }

  // Menjalankan listener realtime untuk tabel tempat.
  void _startRealtime() {
    RealtimeService.startListening(
      onInsert: (tempat) {
        // Ketika ada tempat baru ditambahkan oleh pengguna lain.
        ErrorLogger.i('Realtime: new tempat "${tempat.namaTempat}"');
        if (_allTempat.any((t) => t.id == tempat.id)) return;
        _allTempat.insert(0, tempat);
        _applyFilter();
        _realtimeConnected = true;
        notifyListeners();
        // Tampilkan notifikasi lokal.
        NotificationService.showNewTempatNotification(tempat.namaTempat);
      },
      onUpdate: (tempat) {
        // Ketika ada tempat diubah.
        ErrorLogger.i('Realtime: updated tempat "${tempat.namaTempat}"');
        final idx = _allTempat.indexWhere((t) => t.id == tempat.id);
        if (idx >= 0) {
          _allTempat[idx] = tempat;
          _applyFilter();
          notifyListeners();
        }
      },
      onDelete: (id) {
        // Ketika ada tempat dihapus.
        ErrorLogger.i('Realtime: deleted tempat id=$id');
        _allTempat.removeWhere((t) => t.id == id);
        _applyFilter();
        notifyListeners();
      },
    );
    _realtimeConnected = true;
    notifyListeners();
  }

  // Menghentikan listener realtime.
  void stopRealtime() {
    RealtimeService.stopListening();
    _realtimeConnected = false;
    notifyListeners();
  }

  // Memuat data carousel (gambar slide di beranda).
  Future<void> loadCarousel() async {
    _isLoadingCarousel = true;
    notifyListeners();

    final online = await _hasConnectivity();
    if (online) {
      // Jika online, ambil tempat dengan gambar secara acak.
      _carouselTempat = await SupabaseService.getRandomTempat(limit: 8);
    } else {
      // Jika offline, ambil dari data yang sudah ada.
      final withMedia = _allTempat
          .where((t) => t.media != null && t.media!.isNotEmpty)
          .toList()
        ..shuffle();
      _carouselTempat = withMedia.take(8).toList();
    }

    _isLoadingCarousel = false;
    notifyListeners();
  }

  // Menyetel filter berdasarkan kategori.
  void setKategoriFilter(int? id) {
    _selectedKategoriId = id;
    _applyFilter();
    notifyListeners();
  }

  // Menyetel teks pencarian.
  void setSearch(String q) {
    _searchQuery = q;
    _applyFilter();
    notifyListeners();
  }

  // Menerapkan filter kategori dan pencarian ke daftar tempat.
  void _applyFilter() {
    _filtered = _allTempat.where((t) {
      final matchKat = _selectedKategoriId == null || t.kategoriId == _selectedKategoriId;
      final q = _searchQuery.toLowerCase();
      final matchSearch = q.isEmpty ||
          t.namaTempat.toLowerCase().contains(q) ||
          (t.jalan?.toLowerCase().contains(q) ?? false) ||
          (t.namaKategori?.toLowerCase().contains(q) ?? false) ||
          (t.namaKecamatan?.toLowerCase().contains(q) ?? false) ||
          (t.detailTempat?.toLowerCase().contains(q) ?? false);
      return matchKat && matchSearch;
    }).toList();
  }

  // Menambahkan tempat ke riwayat dilihat (paling atas).
  void addRecentlyViewed(TempatModel t) {
    _recentlyViewed.removeWhere((r) => r.id == t.id);
    _recentlyViewed.insert(0, t);
    if (_recentlyViewed.length > 20) {
      _recentlyViewed = _recentlyViewed.take(20).toList();
    }
    notifyListeners();
  }

  // Mengembalikan daftar tempat dengan rating tertinggi (limit 5 default).
  List<TempatModel> getTopRated({int limit = 5}) {
    return [..._allTempat]
      ..sort((a, b) => (b.reviewRating ?? 0).compareTo(a.reviewRating ?? 0))
      ..take(limit);
  }

  // Mengembalikan tempat berdasarkan ID kategori.
  List<TempatModel> getByKategori(int kategoriId) =>
      _allTempat.where((t) => t.kategoriId == kategoriId).toList();

  // Menyegarkan data (menghentikan realtime lalu memuat ulang).
  Future<void> refresh() async {
    stopRealtime();
    await loadAll();
  }

  // Dibersihkan saat provider tidak digunakan lagi (misal aplikasi ditutup).
  @override
  void dispose() {
    stopRealtime();
    super.dispose();
  }
}