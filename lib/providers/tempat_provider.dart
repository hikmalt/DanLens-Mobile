// lib/providers/tempat_provider.dart  (FINAL — v3 with Realtime)
// Replace the previous tempat_provider.dart with this file.
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';
import '../services/realtime_service.dart';
import '../services/notification_service.dart';
import '../utils/cache_manager.dart';
import '../utils/error_logger.dart';

class TempatProvider extends ChangeNotifier {
  List<TempatModel> _allTempat = [];
  List<TempatModel> _filtered = [];
  List<TempatModel> _carouselTempat = [];
  List<KategoriModel> _kategori = [];
  List<KecamatanModel> _kecamatan = [];
  List<TempatModel> _recentlyViewed = [];

  bool _isLoading = false;
  bool _isLoadingCarousel = false;
  bool _isOffline = false;
  bool _realtimeConnected = false;
  String? _error;
  int? _selectedKategoriId;
  String _searchQuery = '';

  List<TempatModel> get allTempat => _filtered;
  List<TempatModel> get carouselTempat => _carouselTempat;
  List<KategoriModel> get kategori => _kategori;
  List<KecamatanModel> get kecamatan => _kecamatan;
  List<TempatModel> get recentlyViewed => _recentlyViewed;
  bool get isLoading => _isLoading;
  bool get isLoadingCarousel => _isLoadingCarousel;
  bool get isOffline => _isOffline;
  bool get realtimeConnected => _realtimeConnected;
  String? get error => _error;
  int? get selectedKategoriId => _selectedKategoriId;
  String get searchQuery => _searchQuery;

  // ── Connectivity check ──────────────────────────────────────
  Future<bool> _hasConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  // ── Load all data with offline fallback ─────────────────────
  Future<void> loadAll() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final online = await _hasConnectivity();

    if (!online) {
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

    _isOffline = false;

    try {
      _allTempat = await SupabaseService.getAllTempat(limit: 50);
      await _loadKategoriAndKecamatan();
      _applyFilter();

      // Persist to cache
      await CacheManager.saveTempat(_allTempat);
      await CacheManager.saveKategori(_kategori);
      await CacheManager.saveKecamatan(_kecamatan);

      // Start realtime listener
      _startRealtime();
    } catch (e, stack) {
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

  Future<void> _loadKategoriAndKecamatan() async {
    _kategori = await SupabaseService.getKategori();
    _kecamatan = await SupabaseService.getKecamatan();
  }

  Future<void> loadKategori() async {
    _kategori = await SupabaseService.getKategori();
    notifyListeners();
  }

  Future<void> loadKecamatan() async {
    _kecamatan = await SupabaseService.getKecamatan();
    notifyListeners();
  }

  // ── Realtime integration ─────────────────────────────────────
  void _startRealtime() {
    RealtimeService.startListening(
      onInsert: (tempat) {
        ErrorLogger.i('Realtime: new tempat "${tempat.namaTempat}"');
        // Avoid duplicate
        if (_allTempat.any((t) => t.id == tempat.id)) return;
        _allTempat.insert(0, tempat);
        _applyFilter();
        _realtimeConnected = true;
        notifyListeners();
        // Push local notification
        NotificationService.showNewTempatNotification(tempat.namaTempat);
      },
      onUpdate: (tempat) {
        ErrorLogger.i('Realtime: updated tempat "${tempat.namaTempat}"');
        final idx = _allTempat.indexWhere((t) => t.id == tempat.id);
        if (idx >= 0) {
          _allTempat[idx] = tempat;
          _applyFilter();
          notifyListeners();
        }
      },
      onDelete: (id) {
        ErrorLogger.i('Realtime: deleted tempat id=$id');
        _allTempat.removeWhere((t) => t.id == id);
        _applyFilter();
        notifyListeners();
      },
    );
    _realtimeConnected = true;
    notifyListeners();
  }

  void stopRealtime() {
    RealtimeService.stopListening();
    _realtimeConnected = false;
    notifyListeners();
  }

  // ── Carousel ─────────────────────────────────────────────────
  Future<void> loadCarousel() async {
    _isLoadingCarousel = true;
    notifyListeners();

    final online = await _hasConnectivity();
    if (online) {
      _carouselTempat = await SupabaseService.getRandomTempat(limit: 8);
    } else {
      final withMedia = _allTempat
          .where((t) => t.media != null && t.media!.isNotEmpty)
          .toList()
        ..shuffle();
      _carouselTempat = withMedia.take(8).toList();
    }

    _isLoadingCarousel = false;
    notifyListeners();
  }

  // ── Filter & search ──────────────────────────────────────────
  void setKategoriFilter(int? id) {
    _selectedKategoriId = id;
    _applyFilter();
    notifyListeners();
  }

  void setSearch(String q) {
    _searchQuery = q;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    _filtered = _allTempat.where((t) {
      final matchKat =
          _selectedKategoriId == null || t.kategoriId == _selectedKategoriId;
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

  // ── Helpers ──────────────────────────────────────────────────
  void addRecentlyViewed(TempatModel t) {
    _recentlyViewed.removeWhere((r) => r.id == t.id);
    _recentlyViewed.insert(0, t);
    if (_recentlyViewed.length > 20) {
      _recentlyViewed = _recentlyViewed.take(20).toList();
    }
    notifyListeners();
  }

  List<TempatModel> getTopRated({int limit = 5}) {
    return [..._allTempat]
      ..sort((a, b) => (b.reviewRating ?? 0).compareTo(a.reviewRating ?? 0))
      ..take(limit);
  }

  List<TempatModel> getByKategori(int kategoriId) =>
      _allTempat.where((t) => t.kategoriId == kategoriId).toList();

  Future<void> refresh() async {
    stopRealtime();
    await loadAll();
  }

  @override
  void dispose() {
    stopRealtime();
    super.dispose();
  }
}