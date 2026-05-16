// FILE: lib/screens/map/map_screen.dart
// Halaman peta utama aplikasi DanLens.
// Fungsi: menampilkan peta interaktif dengan marker lokasi tempat, polygon kecamatan,
// fitur rute (GPS ke tempat atau antar dua titik), filter tempat, heatmap, rekam jalur,
// dan berbagai kontrol tampilan peta.
// Informasi penting: File ini sangat besar dan menggabungkan semua fitur peta dalam satu tempat.
// Menggunakan flutter_map untuk rendering peta, supabase untuk data polygon, OSRM untuk routing,
// dan geolocator untuk lokasi pengguna. Fitur realtime dari Supabase juga dipantau di sini.

// Perintah untuk mengabaikan peringatan parameter yang tidak digunakan (karena beberapa widget mungkin tidak butuh semua parameter).
// ignore_for_file: unnecessary_null_comparison, unused_element_parameter

// Mengimpor pustaka untuk operasi asinkron (Future, Timer, dll).
import 'dart:async';
// Mengimpor pustaka untuk encoding/decoding JSON (tidak digunakan, diabaikan).
// ignore: unused_import
import 'dart:convert';
// Mengimpor widget untuk menampilkan gambar dari internet dengan cache.
import 'package:cached_network_image/cached_network_image.dart';
// Mengimpor Dio untuk melakukan HTTP request (geocoding dan routing).
import 'package:dio/dio.dart';
// Mengimpor widget dasar Flutter.
import 'package:flutter/material.dart';
// Mengimpor paket animasi Flutter untuk efek fade, slide, dll.
import 'package:flutter_animate/flutter_animate.dart';
// Mengimpor FlutterMap untuk menampilkan peta.
import 'package:flutter_map/flutter_map.dart';
// Mengimpor marker cluster untuk mengelompokkan marker pada zoom rendah.
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
// Mengimpor kelas LatLng dan utilitas bounds, tetapi menyembunyikan Haversine milik latlong2 (gunakan milik sendiri).
import 'package:latlong2/latlong.dart' hide Haversine;
// Mengimpor PhotoView untuk melihat gambar fullscreen dengan zoom.
import 'package:photo_view/photo_view.dart';
// Mengimpor provider untuk state management.
import 'package:provider/provider.dart';
// Mengimpor url_launcher untuk membuka Google Maps atau WhatsApp.
import 'package:url_launcher/url_launcher.dart';
// Mengimpor tema dan warna dari konfigurasi aplikasi.
import '../../config/app_theme.dart';
// Mengimpor semua model (TempatModel, KecamatanModel, dll).
import '../../models/models.dart';
// Mengimpor provider untuk data tempat (daftar lokasi, filter, dll).
import '../../providers/tempat_provider.dart';
// Mengimpor service untuk mengelola data kecamatan (polygon).
import '../../services/kecamatan_service.dart';
// Mengimpor service untuk mengakses lokasi GPS.
import '../../services/location_service.dart';
// Mengimpor service untuk menghitung rute dengan OSRM.
import '../../services/route_service.dart';
// Mengimpor utilitas Haversine (untuk hitung jarak sederhana).
import '../../utils/haversine.dart';
// Mengimpor utilitas pencatat error.
import '../../utils/error_logger.dart';
// Mengimpor widget polyline animasi (rute bergerak).
import '../../widgets/animated_route.dart';
// Mengimpor widget heatmap (lingkaran berdasarkan rating).
import '../../widgets/heatmap_layer.dart';
// Mengimpor halaman detail tempat (jika tombol detail ditekan).
import '../detail/detail_screen.dart';
// Mengimpor dart:ui untuk menggambar path custom (arrow marker).
import 'dart:ui' as ui;
// Mengimpor dart:math untuk fungsi trigonometri (tidak dipakai, diabaikan).
// ignore: unused_import
import 'dart:math';
// Mengimpor geolocator untuk tipe Position pada stream rekaman jalur.
import 'package:geolocator/geolocator.dart';


// ---------------------------------------------------------------------
//  FILTER MODEL
// ---------------------------------------------------------------------
// Model untuk menyimpan kriteria filter tempat yang dipilih pengguna.
class PlaceFilter {
  // Daftar id kategori yang dipilih.
  final List<int> selectedKategoriIds;
  // 'highest' atau 'lowest' untuk urutan rating, null jika tidak diurut.
  final String? sortByRating;
  // Apakah hanya menampilkan tempat yang buka (belum diimplementasikan sepenuhnya).
  final bool openNow;
  // Jarak maksimal dari pengguna dalam kilometer, null jika tidak dibatasi.
  final double? maxDistanceKm;
  // Apakah hanya menampilkan tempat yang memiliki nomor kontak.
  final bool hasContact;
  // Apakah hanya menampilkan tempat dengan rating minimal 3.5.
  final bool minRating35;
  // Apakah mengurutkan berdasarkan jarak terdekat.
  final bool sortNearest;

  // Konstruktor dengan nilai default.
  const PlaceFilter({
    this.selectedKategoriIds = const [],
    this.sortByRating,
    this.openNow = false,
    this.maxDistanceKm,
    this.hasContact = false,
    this.minRating35 = false,
    this.sortNearest = false,
  });

  // Apakah ada filter aktif (bukan default).
  bool get isActive =>
      selectedKategoriIds.isNotEmpty ||
      sortByRating != null ||
      openNow ||
      maxDistanceKm != null ||
      hasContact ||
      minRating35 ||
      sortNearest;

  // Jumlah filter yang aktif (untuk ditampilkan di badge).
  int get activeCount {
    int c = 0;
    if (selectedKategoriIds.isNotEmpty) c++;
    if (sortByRating != null) c++;
    if (openNow) c++;
    if (maxDistanceKm != null) c++;
    if (hasContact) c++;
    if (minRating35) c++;
    if (sortNearest) c++;
    return c;
  }

  // Filter kosong (tidak ada filter aktif).
  static const PlaceFilter empty = PlaceFilter();
}

// ---------------------------------------------------------------------
//  ROUTE POINT
// ---------------------------------------------------------------------
// Kelas untuk menyimpan informasi titik awal atau tujuan pada mode rute A-B.
class _RoutePoint {
  final LatLng latlng;                // Koordinat titik.
  final String label;                 // Nama tempat atau "Lokasi Saya (GPS)".
  final String? sublabel;             // Informasi tambahan (jalan, kategori, rating).
  final TempatModel? tempat;          // Jika berasal dari database, referensi model.
  final bool isGps;                  // Apakah titik berasal dari GPS.

  const _RoutePoint({
    required this.latlng,
    required this.label,
    this.sublabel,
    this.tempat,
    this.isGps = false,
  });
}

// ---------------------------------------------------------------------
//  GEOCODE RESULT
// ---------------------------------------------------------------------
// Hasil pencarian alamat dari Nominatim (geocoding).
class _GeoResult {
  final String name;   // Nama alamat lengkap.
  final double lat;    // Lintang.
  final double lng;    // Bujur.

  const _GeoResult({required this.name, required this.lat, required this.lng});
}

// ---------------------------------------------------------------------
//  MAP SCREEN
// ---------------------------------------------------------------------
// Halaman peta utama.
class MapScreen extends StatefulWidget {
  final TempatModel? focusedTempat; // tempat yang di fokuskan
  final bool autoRoute;  // Jika true, langsung hitung rute dari GPS ke focusedTempat
  const MapScreen({
    super.key, 
    this.focusedTempat,
    this.autoRoute = false,  // Default false agar kompatibel dengan navigasi lama
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

// State untuk MapScreen.
class _MapScreenState extends State<MapScreen>
    with SingleTickerProviderStateMixin {
  // Controller untuk FlutterMap.
  final _mapController = MapController();
  // Controller untuk text field pencarian.
  final _searchCtrl = TextEditingController();
  // Instance Dio untuk request HTTP (geocoding).
  final _dio = Dio();
  // Timer untuk debounce pencarian.
  Timer? _debounce;
  bool _autoRouteTriggered = false;  // Mencegah pemanggilan rute otomatis berulang

  // Data lokasi pengguna.
  LatLng? _userLocation;           // Koordinat GPS terakhir.
  bool _loadingLocation = false;    // Sedang mengambil lokasi.

  // Pencarian dan autocomplete.
  String _searchQuery = '';                     // Teks pencarian.
  List<TempatModel> _autocompleteItems = [];    // Hasil autocomplete tempat.
  bool _showAutocomplete = false;               // Tampilkan dropdown autocomplete.

  // Filter tempat.
  PlaceFilter _filter = PlaceFilter.empty;      // Filter aktif.
  bool _hideAllMarkers = false;                 // Sembunyikan semua marker (mode none).

  // Tempat yang dipilih dan rute sederhana (dari GPS ke tempat).
  TempatModel? _selectedTempat;                 // Tempat yang sedang dipilih.
  RouteResult? _routeResult;                    // Hasil rute GPS->tempat.
  bool _loadingRoute = false;                   // Sedang memuat rute.
  bool _showRoute = false;                      // Apakah rute sedang ditampilkan.

  // Mode rute penuh A ke B.
  bool _routeMode = false;                      // Apakah dalam mode rute A-B.
  _RoutePoint? _routeStart;                     // Titik awal.
  _RoutePoint? _routeEnd;                       // Titik tujuan.
  bool _loadingRouteAB = false;                 // Sedang memuat rute A-B.
  bool _showRouteAB = false;                    // Tampilkan rute A-B.
  RouteResult? _routeABResult;                  // Hasil rute A-B.
  bool _pickingOnMap = false;                   // Mode memilih titik dengan tap pada peta.

  // Pencarian geocoding untuk titik tujuan.
  List<_GeoResult> _geoResults = [];             // Hasil geocoding.
  bool _searchingGeo = false;                   // Sedang mencari geocoding.
  final _endSearchCtrl = TextEditingController(); // Text field untuk mencari alamat tujuan.

  // Pengaturan visual peta.
  String _mapStyle = 'standard';                // 'standard', 'dark', 'satellite'.
  bool _showHeatmap = false;                    // Tampilkan heatmap.
  bool _showKecLabels = false;                  // Tampilkan label teks kecamatan.
  bool _showPolygon = false;                    // Tampilkan polygon kecamatan.

  // Data polygon kecamatan.
  List<KecamatanModel> _kecamatanPolygons = []; // Daftar semua kecamatan.
  bool _loadingPolygon = false;                 // Sedang memuat polygon.
  Set<int> _selectedKecamatanIds = {};          // ID kecamatan yang dipilih untuk filter (kosong = semua).

  // Fitur rekam jalur (record track).
  bool _isRecording = false;                    // Sedang merekam.
  final List<LatLng> _trackPoints = [];         // Titik-titik jalur.
  StreamSubscription<Position>? _trackSub;      // Subscription ke stream GPS.

  // Koordinat default Medan.
  static const LatLng _medanCenter = LatLng(3.5896654, 98.6738261);

  // Koordinat label teks kecamatan (hardcoded untuk tampilan cepat).
  static const List<_KecLabel> _kecLabels = [
    _KecLabel('Medan Belawan', 3.786, 98.696),
    _KecLabel('Percut Sei Tuan', 3.638, 98.701),
    _KecLabel('Medan Johor', 3.561, 98.666),
    _KecLabel('Medan Helvetia', 3.569, 98.704),
    _KecLabel('Medan Sunggal', 3.581, 98.673),
    _KecLabel('Medan Kota', 3.583, 98.682),
    _KecLabel('Medan Baru', 3.565, 98.658),
    _KecLabel('Sibolangit', 3.280, 98.556),
    _KecLabel('Beringin', 3.635, 98.879),
    _KecLabel('Medan Tuntungan', 3.508, 98.612),
    _KecLabel('Medan Barat', 3.594, 98.674),
    _KecLabel('Medan Petisah', 3.598, 98.654),
    _KecLabel('Medan Amplas', 3.539, 98.718),
    _KecLabel('Medan Selayang', 3.555, 98.638),
    _KecLabel('Ajibata/Balige', 2.844, 98.529),
    _KecLabel('Medan Polonia', 3.551, 98.680),
    _KecLabel('Medan Area', 3.578, 98.699),
    _KecLabel('Medan Maimun', 3.575, 98.687),
    _KecLabel('Medan Timur', 3.591, 98.688),
  ];

  // Warna untuk polygon (tidak dipakai lagi karena menggunakan choropleth).
  static const List<Color> _polyColors = [
    Color(0xFF4a7c59), Color(0xFF4ECDC4), Color(0xFF45B7D1),
    Color(0xFFFF6B35), Color(0xFF5352ED), Color(0xFFFF4757),
    Color(0xFF2ED573), Color(0xFFFFD700), Color(0xFF9B59B6),
    Color(0xFF1ABC9C),
  ];
  // Perintah untuk mengabaikan peringatan bahwa _polyColor tidak dipakai.
  // ignore: unused_element
  Color _polyColor(int i) => _polyColors[i % _polyColors.length];

  // URL tile peta berdasarkan gaya yang dipilih.
  String get _tileUrl {
    switch (_mapStyle) {
      case 'dark':
        return 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';
      case 'satellite':
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      default:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
  }

  // Daftar tempat setelah diterapkan filter dan pencarian.
  List<TempatModel> get _filteredPlaces {
    if (_hideAllMarkers) return [];
    final tp = context.read<TempatProvider>();
    List<TempatModel> list = tp.allTempat
        .where((t) => t.latitude != null && t.longitude != null)
        .toList();

    final q = _searchQuery.toLowerCase().trim();
    if (q.isNotEmpty) {
      list = list.where((t) =>
          t.namaTempat.toLowerCase().contains(q) ||
          (t.jalan?.toLowerCase().contains(q) ?? false) ||
          (t.namaKategori?.toLowerCase().contains(q) ?? false) ||
          (t.namaKecamatan?.toLowerCase().contains(q) ?? false) ||
          (t.detailTempat?.toLowerCase().contains(q) ?? false)).toList();
    }
    if (_filter.selectedKategoriIds.isNotEmpty) {
      list = list.where((t) => _filter.selectedKategoriIds.contains(t.kategoriId)).toList();
    }
    if (_filter.minRating35) {
      list = list.where((t) => (t.reviewRating ?? 0) >= 3.5).toList();
    }
    if (_filter.hasContact) {
      list = list.where((t) => t.kontak != null && t.kontak!.isNotEmpty).toList();
    }
    if (_filter.maxDistanceKm != null && _userLocation != null) {
      list = list.where((t) {
        final d = Haversine.distance(_userLocation!.latitude, _userLocation!.longitude, t.latitude!, t.longitude!);
        return d <= _filter.maxDistanceKm!;
      }).toList();
    }
    if (_filter.sortNearest && _userLocation != null) {
      list.sort((a, b) {
        final da = Haversine.distance(_userLocation!.latitude, _userLocation!.longitude, a.latitude!, a.longitude!);
        final db = Haversine.distance(_userLocation!.latitude, _userLocation!.longitude, b.latitude!, b.longitude!);
        return da.compareTo(db);
      });
    } else if (_filter.sortByRating == 'highest') {
      list.sort((a, b) => (b.reviewRating ?? 0).compareTo(a.reviewRating ?? 0));
    } else if (_filter.sortByRating == 'lowest') {
      list.sort((a, b) => (a.reviewRating ?? 0).compareTo(b.reviewRating ?? 0));
    }
    return list;
  }

  // -----------------------------------------------------------------
  //  INITIALISASI
  // -----------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    // Catat bahwa peta diinisialisasi.
    ErrorLogger.i('MapScreen initialized');
    // Jika ada tempat yang harus difokuskan, set sebagai selected.
    if (widget.focusedTempat != null) _selectedTempat = widget.focusedTempat;
    // Mulai mengambil lokasi pengguna.
    _getUserLocation();
    // Pasang listener untuk perubahan teks pada search bar.
    _searchCtrl.addListener(_onSearchChanged);
    // Fokuskan peta ke tempat yang ditentukan setelah tampilan selesai dibangun.
    _focusAfterBuild();
    // Jika autoRoute true dan ada tempat difokuskan, kita akan cek setelah lokasi didapat.
    if (widget.autoRoute && widget.focusedTempat != null) {
      // Tidak perlu langsung panggil, tunggu _getUserLocation selesai (lihat di _getUserLocation)
    }
  }

  // Memfokuskan peta ke tempat yang ditentukan (jika ada).
  void _focusAfterBuild() {
    if (widget.focusedTempat?.latitude == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          _mapController.move(
            LatLng(widget.focusedTempat!.latitude!, widget.focusedTempat!.longitude!), 15);
        }
      });
    });
  }

  // -----------------------------------------------------------------
  //  REKAM JALUR (RECORD TRACK)
  // -----------------------------------------------------------------
  // Mulai merekam jalur GPS.
  void _startRecording() {
    _trackPoints.clear();
    _isRecording = true;
    // Subscribe ke stream posisi GPS.
    _trackSub = LocationService.positionStream.listen((pos) {
      setState(() {
        _trackPoints.add(LatLng(pos.latitude, pos.longitude));
      });
    });
    _snack('Mulai merekam jalur...');
  }

  // Hentikan rekaman jalur.
  void _stopRecording() async {
    _trackSub?.cancel();
    _isRecording = false;
    if (_trackPoints.length < 2) {
      _snack('Jalur terlalu pendek (minimal 2 titik)');
      _trackPoints.clear();
    } else {
      _snack('Rekaman selesai (${_trackPoints.length} titik)');
    }
  }

  // Hapus jalur yang sudah direkam.
  void _clearTrack() {
    setState(() => _trackPoints.clear());
    _snack('Jalur dihapus');
  }

  // -----------------------------------------------------------------
  //  PENCARIAN & AUTOCOMPLETE
  // -----------------------------------------------------------------
  // Menangani perubahan teks pada search bar.
  void _onSearchChanged() {
    _debounce?.cancel();
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) {
      setState(() {
        _searchQuery = '';
        _autocompleteItems = [];
        _showAutocomplete = false;
      });
      return;
    }
    // Debounce 280ms agar tidak terlalu sering memproses.
    _debounce = Timer(const Duration(milliseconds: 280), () {
      if (!mounted) return;
      setState(() {
        _searchQuery = q;
        _hideAllMarkers = false;
        final tp = context.read<TempatProvider>();
        // Cari tempat yang cocok dengan nama, jalan, kategori, kecamatan, dll.
        _autocompleteItems = tp.allTempat
            .where((t) =>
                t.latitude != null &&
                (t.namaTempat.toLowerCase().contains(q.toLowerCase()) ||
                 (t.jalan?.toLowerCase().contains(q.toLowerCase()) ?? false) ||
                 (t.namaKategori?.toLowerCase().contains(q.toLowerCase()) ?? false) ||
                 (t.namaKecamatan?.toLowerCase().contains(q.toLowerCase()) ?? false)))
            .take(10)
            .toList();
        _showAutocomplete = _autocompleteItems.isNotEmpty;
      });
    });
  }

  // Memilih tempat dari dropdown autocomplete.
  void _selectFromAutocomplete(TempatModel t) {
    _searchCtrl.clear();
    setState(() {
      _searchQuery = '';
      _autocompleteItems = [];
      _showAutocomplete = false;
      _selectedTempat = t;
      _showRoute = false;
      _routeResult = null;
    });
    // Gerakkan peta ke koordinat tempat terpilih, zoom level 16.
    _mapController.move(LatLng(t.latitude!, t.longitude!), 16);
  }

  // -----------------------------------------------------------------
  //  GPS
  // -----------------------------------------------------------------
  // Mendapatkan lokasi pengguna saat ini.
  Future<void> _getUserLocation() async {
    setState(() => _loadingLocation = true);
    final pos = await LocationService.getCurrentPosition();
    if (pos != null && mounted) {
      setState(() => _userLocation = LatLng(pos.latitude, pos.longitude));
      // Jika autoRoute diaktifkan, ada tempat difokuskan, dan rute belum dipanggil, maka hitung rute.
      if (widget.autoRoute && widget.focusedTempat != null && !_autoRouteTriggered && _userLocation != null) {
        _autoRouteTriggered = true;
        // Tunggu sebentar agar UI stabil, lalu panggil fetch simple route.
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && _selectedTempat != null) {
            _fetchSimpleRoute();
          }
        });
      }
    }
    setState(() => _loadingLocation = false);
  }

  // Memusatkan peta ke lokasi pengguna.
  void _centerOnUser() {
    if (_userLocation != null) {
      _mapController.move(_userLocation!, 15);
    } else {
      _getUserLocation();
    }
  }

  // -----------------------------------------------------------------
  //  RUTE SEDERHANA (GPS -> TEMPAT)
  // -----------------------------------------------------------------
  // Mencari rute dari lokasi pengguna ke tempat yang dipilih.
  Future<void> _fetchSimpleRoute() async {
    if (_userLocation == null || _selectedTempat?.latitude == null) {
      _snack('Aktifkan GPS untuk menampilkan rute');
      return;
    }
    setState(() {
      _loadingRoute = true;
      _showRoute = false;
      _routeResult = null;
    });
    final dest = LatLng(_selectedTempat!.latitude!, _selectedTempat!.longitude!);
    RouteResult? r = await RouteService.getRoute(_userLocation!, dest);
    r ??= RouteService.straightLine(_userLocation!, dest);
    if (!mounted) return;
    setState(() {
      _routeResult = r;
      _showRoute = true;
      _loadingRoute = false;
    });
    if (r != null && r.points.length > 1) {
      // Sesuaikan tampilan peta agar seluruh rute terlihat.
      _mapController.fitCamera(
        CameraFit.bounds(bounds: LatLngBounds.fromPoints(r.points), padding: const EdgeInsets.all(72)));
    }
  }

  // -----------------------------------------------------------------
  //  RUTE A - B
  // -----------------------------------------------------------------
  // Mencari rute antara dua titik (_routeStart dan _routeEnd).
  Future<void> _fetchRouteAB() async {
    if (_routeStart == null || _routeEnd == null) {
      _snack('Pilih titik awal dan tujuan');
      return;
    }
    setState(() {
      _loadingRouteAB = true;
      _showRouteAB = false;
      _routeABResult = null;
    });
    RouteResult? r = await RouteService.getRoute(_routeStart!.latlng, _routeEnd!.latlng);
    r ??= RouteService.straightLine(_routeStart!.latlng, _routeEnd!.latlng);
    if (!mounted) return;
    setState(() {
      _routeABResult = r;
      _showRouteAB = true;
      _loadingRouteAB = false;
    });
    if (r != null && r.points.length > 1) {
      _mapController.fitCamera(
        CameraFit.bounds(bounds: LatLngBounds.fromPoints(r.points), padding: const EdgeInsets.all(60)));
    }
  }

  // Menggunakan lokasi GPS sebagai titik awal (mode rute A-B).
  void _useGpsAsStart() async {
    setState(() => _loadingLocation = true);
    final pos = await LocationService.getCurrentPosition();
    if (pos != null && mounted) {
      final latlng = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _userLocation = latlng;
        _routeStart = _RoutePoint(
          latlng: latlng,
          label: 'Lokasi Saya (GPS)',
          sublabel: '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}',
          isGps: true,
        );
      });
    }
    setState(() => _loadingLocation = false);
  }

  // Memilih tempat dari database sebagai titik awal.
  void _selectTempatAsStart(TempatModel t) {
    setState(() {
      _routeStart = _RoutePoint(
        latlng: LatLng(t.latitude!, t.longitude!),
        label: t.namaTempat,
        sublabel: '${t.namaKategori} · ${t.namaKecamatan ?? ''} · ⭐${t.reviewRating?.toStringAsFixed(1) ?? '-'}',
        tempat: t,
      );
    });
  }

  // Menetapkan tempat yang sedang dipilih sebagai titik tujuan (mode rute A-B).
  void _setSelectedAsEnd() {
    if (_selectedTempat == null) return;
    final t = _selectedTempat!;
    setState(() {
      _routeEnd = _RoutePoint(
        latlng: LatLng(t.latitude!, t.longitude!),
        label: t.namaTempat,
        sublabel: '${t.namaKategori} · ${t.namaKecamatan ?? ''} · ⭐${t.reviewRating?.toStringAsFixed(1) ?? '-'}${t.jalan != null ? '\n${t.jalan}' : ''}',
        tempat: t,
      );
    });
  }

  // Menukar titik awal dan tujuan.
  void _swapRoutePoints() {
    setState(() {
      final tmp = _routeStart;
      _routeStart = _routeEnd;
      _routeEnd = tmp;
      _routeABResult = null;
      _showRouteAB = false;
    });
  }

  // Mereset mode rute A-B dan kembali ke mode normal.
  void _resetRoute() {
    setState(() {
      _routeMode = false;
      _routeStart = null;
      _routeEnd = null;
      _routeABResult = null;
      _showRouteAB = false;
      _pickingOnMap = false;
      _geoResults = [];
      _endSearchCtrl.clear();
    });
  }

  // -----------------------------------------------------------------
  //  GEOCODING (Nominatim)
  // -----------------------------------------------------------------
  // Mencari alamat menggunakan Nominatim (OpenStreetMap).
  Future<void> _geocodeEnd(String q) async {
    if (q.length < 4) return;
    setState(() => _searchingGeo = true);
    try {
      final res = await _dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': '$q, Medan',
          'format': 'json',
          'limit': 5,
          'countrycodes': 'id'
        },
        options: Options(headers: {'User-Agent': 'DanLens/1.0'}),
      );
      setState(() {
        _geoResults = (res.data as List).map((e) => _GeoResult(
          name: e['display_name'] ?? '',
          lat: double.parse(e['lat']),
          lng: double.parse(e['lon']),
        )).take(5).toList();
        _searchingGeo = false;
      });
    } catch (e) {
      setState(() => _searchingGeo = false);
    }
  }

  // -----------------------------------------------------------------
  //  POLYGON KECAMATAN
  // -----------------------------------------------------------------
  // Memuat data polygon kecamatan dari Supabase.
  Future<void> _loadPolygons() async {
    setState(() => _loadingPolygon = true);
    _kecamatanPolygons = await KecamatanService.getAll();
    if (!mounted) return;
    setState(() {
      _loadingPolygon = false;
    });
  }

  // Menampilkan atau menyembunyikan layer polygon kecamatan.
  void _togglePolygon() {
    if (!_showPolygon && _kecamatanPolygons.isEmpty) {
      _loadPolygons();
    }
    setState(() => _showPolygon = !_showPolygon);
  }

  // Menampilkan bottom sheet filter kecamatan (long-press pada tombol polygon).
  void _showKecamatanFilterSheet() async {
    if (_kecamatanPolygons.isEmpty) {
      setState(() => _loadingPolygon = true);
      _kecamatanPolygons = await KecamatanService.getAll();
      setState(() => _loadingPolygon = false);
    }
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _KecamatanFilterSheet(
        allKecamatan: _kecamatanPolygons,
        selectedIds: _selectedKecamatanIds,
        onApply: (ids) {
          setState(() {
            _selectedKecamatanIds = ids;
            _showPolygon = true;
          });
        },
      ),
    );
  }

  // -----------------------------------------------------------------
  //  OVERLAY GAMBAR
  // -----------------------------------------------------------------
  // Menampilkan gambar dalam mode fullscreen dengan zoom.
  void _showImageOverlay(String url) {
    if (url.isEmpty) return;
    showDialog(
      context: context,
      barrierColor: Colors.black,
      builder: (_) => _ImageOverlay(imageUrl: url),
    );
  }

  // -----------------------------------------------------------------
  //  FILTER SHEET
  // -----------------------------------------------------------------
  // Menampilkan bottom sheet untuk filter tempat.
  void _openFilterSheet(List<KategoriModel> kategori) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FilterSheet(
        currentFilter: _filter,
        kategori: kategori,
        userLocation: _userLocation,
        onApply: (f) => setState(() {
          _filter = f;
          _selectedTempat = null;
          _showRoute = false;
          _hideAllMarkers = false;
        }),
      ),
    );
  }

  // Menyembunyikan semua marker (mode none).
  void _clearAll() {
    _searchCtrl.clear();
    setState(() {
      _hideAllMarkers = true;
      _searchQuery = '';
      _filter = PlaceFilter.empty;
      _autocompleteItems = [];
      _showAutocomplete = false;
      _selectedTempat = null;
      _showRoute = false;
      _routeResult = null;
    });
  }

  // -----------------------------------------------------------------
  //  UTILITY
  // -----------------------------------------------------------------
  // Membuka Google Maps dengan arah dari start ke end.
  void _openGoogleMaps(LatLng start, LatLng end) async {
    final uri = Uri.parse(
        'https://www.google.com/maps/dir/${start.latitude},${start.longitude}/${end.latitude},${end.longitude}');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  // Mendapatkan emoji kendaraan berdasarkan jarak (untuk marker bergerak).
  String _vehicleEmoji(double? km) {
    final k = km ?? 0;
    if (k < 0.5) return '🚶';
    if (k < 3) return '🛵';
    if (k < 10) return '🏍️';
    return '🚗';
  }

  // Menampilkan snackbar pesan singkat.
  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'Poppins')),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // -----------------------------------------------------------------
  //  BUILD WIDGET
  // -----------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final tp = context.watch<TempatProvider>();
    final places = _filteredPlaces;

    final showSimpleRoute = _showRoute && _routeResult != null && !_routeMode;
    final showABRoute = _showRouteAB && _routeABResult != null && _routeMode;
    final activeRoute = showABRoute ? _routeABResult : (showSimpleRoute ? _routeResult : null);
    final routeEmoji = _vehicleEmoji(activeRoute?.distanceKm);

    return Scaffold(
      body: Stack(
        children: [
          // -----------------------------------------------------------------
          //  PETA FLUTTERMAP
          // -----------------------------------------------------------------
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              // Pusatkan peta ke tempat yang difokuskan atau ke Medan.
              initialCenter: widget.focusedTempat?.latitude != null
                  ? LatLng(widget.focusedTempat!.latitude!, widget.focusedTempat!.longitude!)
                  : _medanCenter,
              initialZoom: 12,
              minZoom: 8,
              maxZoom: 18,
              onTap: (_, latlng) {
                if (_pickingOnMap) {
                  // Jika sedang dalam mode memilih titik, set titik tujuan.
                  setState(() {
                    _routeEnd = _RoutePoint(
                      latlng: latlng,
                      label: '${latlng.latitude.toStringAsFixed(5)}, ${latlng.longitude.toStringAsFixed(5)}',
                      sublabel: 'Titik di peta',
                    );
                    _pickingOnMap = false;
                  });
                  return;
                }
                // Tap biasa: batalkan pilihan tempat dan rute.
                setState(() {
                  _selectedTempat = null;
                  _showRoute = false;
                  _routeResult = null;
                  _showAutocomplete = false;
                });
              },
            ),
            children: [
              // Layer tile peta (OSM atau varian).
              TileLayer(
                urlTemplate: _tileUrl,
                subdomains: _mapStyle == 'dark' ? ['a', 'b', 'c'] : [],
                userAgentPackageName: 'com.danlens.app',
                retinaMode: RetinaMode.isHighDensity(context),
              ),

              // Heatmap (lingkaran berdasarkan rating).
              HeatmapLayer(places: places, visible: _showHeatmap),

              // Polygon kecamatan dengan warna choropleth (berdasarkan jumlah tempat).
              if (_showPolygon && _kecamatanPolygons.isNotEmpty)
                PolygonLayer(
                  polygons: _kecamatanPolygons
                      .where((k) =>
                          k.hasPolygon &&
                          (_selectedKecamatanIds.isEmpty ||
                              _selectedKecamatanIds.contains(k.id)))
                      .map((kec) {
                        // Hitung jumlah tempat di kecamatan ini.
                        final count = tp.allTempat
                            .where((t) => t.kecamatanId == kec.id)
                            .length;
                        // Cari nilai maksimum jumlah tempat di semua kecamatan untuk normalisasi warna.
                        final maxCount = _kecamatanPolygons
                            .map((k) => tp.allTempat
                                .where((t) => t.kecamatanId == k.id)
                                .length)
                            .fold(1, (max, c) => c > max ? c : max);
                        // Intensitas warna (0..1).
                        final intensity = maxCount == 0
                            ? 0.0
                            : (count / maxCount).clamp(0.0, 1.0).toDouble();
                        // Warna isi polygon: hijau muda jika sedikit tempat, hijau tua jika banyak.
                        final fillColor = Color.lerp(
                          const Color(0xFFE8F5E9),
                          AppColors.primary,
                          intensity,
                        )!.withValues(alpha: 0.35);
                        // Warna border juga ikut gelap.
                        final borderColor = AppColors.primary
                            .withValues(alpha: 0.5 + intensity * 0.5);
                        return kec.polygonRings.map((ring) => Polygon(
                              points: ring,
                              color: fillColor,
                              borderColor: borderColor,
                              borderStrokeWidth: 1.8,
                              isFilled: true,
                              label: kec.namaKecamatan,
                              labelStyle: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: intensity > 0.5 ? Colors.white : AppColors.textDark,
                              ),
                            ));
                      })
                      .expand((i) => i)
                      .toList(),
                ),

              // Label teks kecamatan (koordinat statis).
              if (_showKecLabels)
                MarkerLayer(
                  markers: _kecLabels.map((k) => Marker(
                    point: LatLng(k.lat, k.lng),
                    width: 94,
                    height: 26,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryDeep.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        k.name,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 8,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )).toList(),
                ),

              // Polyline rute (dengan animasi).
              if (activeRoute != null) ...[
                AnimatedRouteLayer(
                    points: activeRoute.points,
                    color: const Color(0xFF2196F3),
                    strokeWidth: 5),
                MovingMarkerLayer(points: activeRoute.points, emoji: routeEmoji),
              ],

              // Polyline jalur rekaman GPS (warna ungu).
              if (_trackPoints.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _trackPoints,
                      color: Colors.purple.withValues(alpha: 0.9),
                      strokeWidth: 4,
                      isDotted: false,
                    ),
                  ],
                ),

              // Marker pulsa pada titik tujuan.
              if (showSimpleRoute && _selectedTempat?.latitude != null)
                PulsingDestinationMarker(
                    point: LatLng(_selectedTempat!.latitude!,
                        _selectedTempat!.longitude!)),
              if (showABRoute && _routeEnd != null)
                PulsingDestinationMarker(point: _routeEnd!.latlng),

              // Lingkaran radius lokasi pengguna (jarak 60 meter).
              if (_userLocation != null)
                CircleLayer(circles: [
                  CircleMarker(
                    point: _userLocation!,
                    radius: 60,
                    useRadiusInMeter: true,
                    color: AppColors.primary.withValues(alpha: 0.10),
                    borderColor: AppColors.primary.withValues(alpha: 0.35),
                    borderStrokeWidth: 1.5,
                  ),
                ]),

              // Marker titik awal dan akhir pada mode rute A-B.
              if (_routeMode) ...[
                if (_routeStart != null)
                  MarkerLayer(markers: [
                    Marker(
                      point: _routeStart!.latlng,
                      width: 36,
                      height: 44,
                      child: const _RouteMarker(color: AppColors.success, letter: 'A'),
                    )
                  ]),
                if (_routeEnd != null)
                  MarkerLayer(markers: [
                    Marker(
                      point: _routeEnd!.latlng,
                      width: 36,
                      height: 44,
                      child: const _RouteMarker(color: AppColors.error, letter: 'B'),
                    )
                  ]),
              ],

              // Marker cluster untuk tempat-tempat.
              MarkerClusterLayerWidget(
                options: MarkerClusterLayerOptions(
                  maxClusterRadius: 80,
                  size: const Size(42, 42),
                  markers: [
                    if (_userLocation != null)
                      Marker(
                        point: _userLocation!,
                        width: 26,
                        height: 26,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2)
                            ],
                          ),
                        ),
                      ),
                    ...places.map((t) => Marker(
                      point: LatLng(t.latitude!, t.longitude!),
                      width: 44,
                      height: 52,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedTempat = t;
                            _showRoute = false;
                            _routeResult = null;
                            _showAutocomplete = false;
                            if (_routeMode) {
                              _routeEnd = _RoutePoint(
                                latlng: LatLng(t.latitude!, t.longitude!),
                                label: t.namaTempat,
                                sublabel:
                                    '${t.namaKategori} · ${t.namaKecamatan ?? ''} · ⭐${t.reviewRating?.toStringAsFixed(1) ?? '-'}${t.jalan != null ? '\n${t.jalan}' : ''}',
                                tempat: t,
                              );
                            }
                          });
                          _mapController.move(LatLng(t.latitude!, t.longitude!), 16);
                        },
                        child: _PlaceMarker(
                            tempat: t, isSelected: _selectedTempat?.id == t.id),
                      ),
                    )),
                  ],
                  builder: (ctx, markers) => Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 8)
                      ],
                    ),
                    child: Center(
                      child: Text('${markers.length}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Overlay ketika sedang memilih titik dengan tap pada peta.
          if (_pickingOnMap)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.touch_app_rounded,
                          color: AppColors.primary, size: 36),
                      const SizedBox(height: 8),
                      const Text('Tap peta untuk pilih\ntitik tujuan',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: 14),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      TextButton(
                          onPressed: () => setState(() => _pickingOnMap = false),
                          child: const Text('Batal',
                              style: TextStyle(
                                  fontFamily: 'Poppins', color: AppColors.error))),
                    ],
                  ),
                ),
              ),
            ),

          // Kontrol atas (pencarian, filter, dll) pada mode normal.
          if (!_routeMode)
            SafeArea(child: _buildTopControls(tp))
          else
            SafeArea(child: _buildRoutePanel(tp)),

          // Tombol-tombol sisi kanan (GPS, polygon, heatmap, label, style, zoom).
          Positioned(
            right: 12,
            bottom: (_selectedTempat != null || _showRouteAB) ? 360 : 100,
            child: Column(
              children: [
                _MapBtn(
                    icon: Icons.my_location_rounded,
                    onTap: _centerOnUser,
                    loading: _loadingLocation,
                    color: AppColors.primary),
                const SizedBox(height: 8),
                _PolygonOverlayBtn(
                  active: _showPolygon,
                  loading: _loadingPolygon,
                  selectedCount: _selectedKecamatanIds.length,
                  onTap: _togglePolygon,
                  onLongPress: _showKecamatanFilterSheet,
                ),
                const SizedBox(height: 8),
                _RecordTrackBtn(
                  isRecording: _isRecording,
                  onStart: _startRecording,
                  onStop: _stopRecording,
                  onClear: _clearTrack,
                  hasPoints: _trackPoints.isNotEmpty,
                ),
                const SizedBox(height: 8),
                _OverlayBtn(
                    emoji: '🔥',
                    tooltip: 'Heatmap',
                    active: _showHeatmap,
                    onTap: () => setState(() => _showHeatmap = !_showHeatmap)),
                const SizedBox(height: 8),
                _OverlayBtn(
                    emoji: '🏷️',
                    tooltip: 'Label Kecamatan',
                    active: _showKecLabels,
                    onTap: () => setState(() => _showKecLabels = !_showKecLabels)),
                const SizedBox(height: 8),
                _MapBtn(
                    icon: Icons.layers_rounded,
                    onTap: () => setState(() {
                      const s = ['standard', 'dark', 'satellite'];
                      _mapStyle = s[(s.indexOf(_mapStyle) + 1) % s.length];
                    })),
                const SizedBox(height: 8),
                _MapBtn(
                    icon: Icons.add_rounded,
                    onTap: () => _mapController.move(
                        _mapController.camera.center, _mapController.camera.zoom + 1)),
                const SizedBox(height: 8),
                _MapBtn(
                    icon: Icons.remove_rounded,
                    onTap: () => _mapController.move(
                        _mapController.camera.center, _mapController.camera.zoom - 1)),
              ],
            ),
          ),

          // Info bar rute sederhana (GPS ke tempat).
          if (showSimpleRoute && !_routeMode)
            Positioned(
              top: 190,
              left: 12,
              right: 12,
              child: _RouteInfoBar(
                result: _routeResult!,
                transport: routeEmoji,
                onClose: () =>
                    setState(() {
                      _showRoute = false;
                      _routeResult = null;
                    }),
                onGoogleMaps: () => _openGoogleMaps(
                    _userLocation!,
                    LatLng(_selectedTempat!.latitude!,
                        _selectedTempat!.longitude!)),
              ),
            ),

          // Bottom sheet detail tempat yang dipilih.
          if (_selectedTempat != null && !_routeMode)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _PlaceBottomSheet(
                tempat: _selectedTempat!,
                userLocation: _userLocation,
                loadingRoute: _loadingRoute,
                hasRoute: _showRoute,
                onClose: () => setState(() {
                  _selectedTempat = null;
                  _showRoute = false;
                  _routeResult = null;
                }),
                onRoute: _fetchSimpleRoute,
                onRouteMode: () {
                  setState(() {
                    _routeMode = true;
                    _setSelectedAsEnd();
                    if (_userLocation != null) {
                      _routeStart = _RoutePoint(
                        latlng: _userLocation!,
                        label: 'Lokasi Saya (GPS)',
                        sublabel:
                            '${_userLocation!.latitude.toStringAsFixed(5)}, ${_userLocation!.longitude.toStringAsFixed(5)}',
                        isGps: true,
                      );
                    }
                    _selectedTempat = null;
                  });
                },
                onGoogleMaps: () {
                  if (_userLocation == null) return;
                  _openGoogleMaps(
                      _userLocation!,
                      LatLng(_selectedTempat!.latitude!,
                          _selectedTempat!.longitude!));
                },
                onImageTap: _showImageOverlay,
                onDetail: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => DetailScreen(tempat: _selectedTempat!))),
              ),
            ),

          // Bottom sheet hasil rute A-B.
          if (_showRouteAB && _routeMode && _routeABResult != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _RouteResultSheet(
                result: _routeABResult!,
                start: _routeStart!,
                end: _routeEnd!,
                emoji: routeEmoji,
                onClose: _resetRoute,
                onGoogleMaps: () =>
                    _openGoogleMaps(_routeStart!.latlng, _routeEnd!.latlng),
                onImageTap: _showImageOverlay,
              ),
            ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------
  //  SUB-WIDGET: TOP CONTROLS (mode normal)
  // -----------------------------------------------------------------
  Widget _buildTopControls(TempatProvider tp) {
    final places = _filteredPlaces;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Baris 1: tombol back (jika ada), pencarian, filter.
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Row(
            children: [
              if (Navigator.canPop(context)) ...[
                _MapBtn(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.pop(context)),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 2))
                    ],
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      const Icon(Icons.search_rounded,
                          color: AppColors.textGray, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              color: AppColors.textDark),
                          decoration: const InputDecoration(
                            hintText: 'Cari tempat di peta...',
                            hintStyle: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                color: AppColors.textGray),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchCtrl.clear();
                            setState(() {
                              _searchQuery = '';
                              _autocompleteItems = [];
                              _showAutocomplete = false;
                            });
                          },
                          child: const Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: Icon(Icons.clear_rounded,
                                size: 16, color: AppColors.textGray),
                          ),
                        ),
                      if (tp.realtimeConnected && _searchQuery.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                                color: AppColors.success, shape: BoxShape.circle),
                          ).animate().fade().scale(),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _openFilterSheet(tp.kategori),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _filter.isActive ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2))
                        ],
                      ),
                      child: Icon(Icons.tune_rounded,
                          color: _filter.isActive ? Colors.white : AppColors.textDark,
                          size: 22),
                    ),
                    if (_filter.isActive)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(
                              color: Colors.redAccent, shape: BoxShape.circle),
                          child: Center(
                            child: Text('${_filter.activeCount}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Poppins')),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Dropdown autocomplete.
        if (_showAutocomplete)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            child: _AutocompleteDropdown(
              items: _autocompleteItems,
              userLocation: _userLocation,
              onTap: _selectFromAutocomplete,
              onImageTap: _showImageOverlay,
            ),
          ),

        const SizedBox(height: 6),

        // Baris 2: jumlah lokasi, tombol None, reset filter.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              _InfoChip(label: '${places.length} lokasi'),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _hideAllMarkers
                    ? () => setState(() => _hideAllMarkers = false)
                    : _clearAll,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _hideAllMarkers
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: _hideAllMarkers ? AppColors.primary : AppColors.surface),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 6)
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _hideAllMarkers
                            ? Icons.location_on_rounded
                            : Icons.location_off_rounded,
                        size: 12,
                        color: _hideAllMarkers
                            ? AppColors.primary
                            : AppColors.textGray,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _hideAllMarkers ? 'Tampilkan' : 'None',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: _hideAllMarkers
                                ? AppColors.primary
                                : AppColors.textGray),
                      ),
                    ],
                  ),
                ),
              ),
              if (_filter.isActive) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() => _filter = PlaceFilter.empty),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.filter_list_off_rounded,
                            size: 12, color: AppColors.error),
                        SizedBox(width: 4),
                        Text('Reset Filter',
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                color: AppColors.error,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 6),

        // Strip kategori (chip).
        _CategoryStrip(
          kategori: tp.kategori,
          selectedIds: _filter.selectedKategoriIds,
          onToggle: (id) {
            final ids = List<int>.from(_filter.selectedKategoriIds);
            setState(() {
              if (id == null) {
                _filter = PlaceFilter(
                    sortByRating: _filter.sortByRating,
                    openNow: _filter.openNow,
                    maxDistanceKm: _filter.maxDistanceKm,
                    hasContact: _filter.hasContact,
                    minRating35: _filter.minRating35,
                    sortNearest: _filter.sortNearest);
              } else if (ids.contains(id)) {
                ids.remove(id);
                _filter = PlaceFilter(
                    selectedKategoriIds: ids,
                    sortByRating: _filter.sortByRating,
                    openNow: _filter.openNow,
                    maxDistanceKm: _filter.maxDistanceKm,
                    hasContact: _filter.hasContact,
                    minRating35: _filter.minRating35,
                    sortNearest: _filter.sortNearest);
              } else {
                ids.add(id);
                _filter = PlaceFilter(
                    selectedKategoriIds: ids,
                    sortByRating: _filter.sortByRating,
                    openNow: _filter.openNow,
                    maxDistanceKm: _filter.maxDistanceKm,
                    hasContact: _filter.hasContact,
                    minRating35: _filter.minRating35,
                    sortNearest: _filter.sortNearest);
              }
              _hideAllMarkers = false;
              _selectedTempat = null;
            });
          },
        ),
      ],
    );
  }

  // -----------------------------------------------------------------
  //  SUB-WIDGET: ROUTE PANEL (mode rute A-B)
  // -----------------------------------------------------------------
  Widget _buildRoutePanel(TempatProvider tp) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 14,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header.
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 4),
            child: Row(
              children: [
                const Icon(Icons.directions_rounded,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                const Text('Rute & Jarak',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.textDark)),
                const Spacer(),
                IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.textGray, size: 20),
                    onPressed: _resetRoute),
              ],
            ),
          ),

          // Baris titik awal (A).
          _RouteInputRow(
            letter: 'A',
            color: AppColors.success,
            label: _routeStart?.label ?? 'Titik Awal',
            sublabel: _routeStart?.sublabel,
            onGps: _useGpsAsStart,
            onPick: () => _showStartPicker(tp),
            loadingGps: _loadingLocation,
          ),

          // Baris titik tujuan (B).
          _RouteInputRow(
            letter: 'B',
            color: AppColors.error,
            label: _routeEnd?.label ?? 'Tap tempat di peta atau cari',
            sublabel: _routeEnd?.sublabel,
            onPick: () => _showEndPicker(tp),
            onMapPick: () => setState(() => _pickingOnMap = true),
          ),

          // Pencarian geocoding (untuk titik tujuan).
          _EndSearchBar(
            ctrl: _endSearchCtrl,
            onChanged: (v) {
              if (v.length >= 3) _geocodeEnd(v);
            },
            searching: _searchingGeo,
            geoResults: _geoResults,
            onSelectGeo: (r) {
              setState(() {
                _routeEnd = _RoutePoint(
                  latlng: LatLng(r.lat, r.lng),
                  label: r.name.split(',').first,
                  sublabel: r.name,
                );
                _geoResults = [];
                _endSearchCtrl.clear();
              });
              _mapController.move(LatLng(r.lat, r.lng), 14);
            },
          ),

          // Tombol aksi: tukar titik dan tampilkan rute.
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.swap_vert_rounded,
                      color: AppColors.primary),
                  tooltip: 'Tukar A & B',
                  onPressed: _swapRoutePoints,
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: (_loadingRouteAB ||
                          _routeStart == null ||
                          _routeEnd == null)
                      ? null
                      : _fetchRouteAB,
                  icon: _loadingRouteAB
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.route_rounded, size: 16),
                  label: const Text('Tampilkan Rute'),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    textStyle: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Menampilkan bottom sheet untuk memilih titik awal dari database.
  void _showStartPicker(TempatProvider tp) {
    _showPlacePicker(
      context: context,
      title: 'Pilih Titik Awal',
      places: tp.allTempat,
      onSelect: _selectTempatAsStart,
    );
  }

  // Menampilkan bottom sheet untuk memilih titik tujuan dari database.
  void _showEndPicker(TempatProvider tp) {
    _showPlacePicker(
      context: context,
      title: 'Pilih Titik Tujuan',
      places: tp.allTempat,
      onSelect: (t) => setState(() {
        _routeEnd = _RoutePoint(
          latlng: LatLng(t.latitude!, t.longitude!),
          label: t.namaTempat,
          sublabel:
              '${t.namaKategori} · ${t.namaKecamatan ?? ''} · ⭐${t.reviewRating?.toStringAsFixed(1) ?? '-'}${t.jalan != null ? '\n${t.jalan}' : ''}',
          tempat: t,
        );
      }),
    );
  }

  // Widget bottom sheet untuk memilih tempat dari daftar.
  void _showPlacePicker({
    required BuildContext context,
    required String title,
    required List<TempatModel> places,
    required Function(TempatModel) onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PlacePickerSheet(
          title: title, places: places, onSelect: (t) {
        onSelect(t);
        Navigator.pop(context);
      }),
    );
  }

  // -----------------------------------------------------------------
  //  DISPOSE
  // -----------------------------------------------------------------
  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    _endSearchCtrl.dispose();
    _trackSub?.cancel();
    _mapController.dispose();
    _dio.close();
    super.dispose();
  }
}

// ═══════════════════════════════════════════════════════════════════
//  AUTOCOMPLETE DROPDOWN
// ═══════════════════════════════════════════════════════════════════
// Widget untuk menampilkan dropdown saran tempat saat pengguna mengetik.
class _AutocompleteDropdown extends StatelessWidget {
  final List<TempatModel> items;           // Daftar tempat hasil pencarian.
  final LatLng? userLocation;              // Lokasi pengguna (untuk hitung jarak).
  final Function(TempatModel) onTap;       // Fungsi saat item dipilih.
  final Function(String) onImageTap;       // Fungsi untuk melihat gambar.

  const _AutocompleteDropdown({
    required this.items,
    required this.userLocation,
    required this.onTap,
    required this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 4))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: ListView.separated(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.surface),
          itemBuilder: (_, i) => _AutocompleteTile(
            tempat: items[i],
            userLocation: userLocation,
            onTap: () => onTap(items[i]),
            onImageTap: () => onImageTap(items[i].imageUrl),
          ),
        ),
      ),
    ).animate().fade(duration: 200.ms).slideY(begin: -0.05, end: 0);
  }
}

// Tile untuk setiap item autocomplete.
class _AutocompleteTile extends StatelessWidget {
  final TempatModel tempat;
  final LatLng? userLocation;
  final VoidCallback onTap;
  final VoidCallback onImageTap;

  const _AutocompleteTile({
    required this.tempat,
    required this.userLocation,
    required this.onTap,
    required this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    double? distKm;
    if (userLocation != null && tempat.latitude != null) {
      distKm = Haversine.distance(userLocation!.latitude, userLocation!.longitude,
          tempat.latitude!, tempat.longitude!);
    }
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // Gambar thumbnail (klik untuk zoom).
            GestureDetector(
              onTap: tempat.imageUrl.isNotEmpty ? onImageTap : null,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: tempat.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: tempat.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(color: AppColors.surface),
                          errorWidget: (_, __, ___) => Container(
                            color: AppColors.surface,
                            child: Center(
                              child: Text(tempat.categoryIcon,
                                  style: const TextStyle(fontSize: 20)),
                            ),
                          ),
                        )
                      : Container(
                          color: AppColors.surface,
                          child: Center(
                            child: Text(tempat.categoryIcon,
                                style: const TextStyle(fontSize: 20)),
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Informasi tempat.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tempat.namaTempat,
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppColors.textDark),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(
                      '${tempat.categoryIcon} ${tempat.namaKategori ?? ''} · ${tempat.namaKecamatan ?? ''}',
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: AppColors.textGray),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 12),
                      Text(
                          ' ${tempat.reviewRating?.toStringAsFixed(1) ?? '-'}',
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                      if (distKm != null) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.near_me_rounded,
                            color: AppColors.primary, size: 11),
                        Text(
                          ' ${Haversine.formatDistance(distKm)}',
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: AppColors.primary),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textGray, size: 18),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  IMAGE OVERLAY
// ═══════════════════════════════════════════════════════════════════
// Widget untuk menampilkan gambar dalam mode fullscreen dengan pinch zoom.
class _ImageOverlay extends StatelessWidget {
  final String imageUrl;

  const _ImageOverlay({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Gambar Tempat',
            style: TextStyle(
                fontFamily: 'Poppins',
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600)),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Row(
              children: [
                Icon(Icons.pinch_rounded, color: Colors.white54, size: 16),
                SizedBox(width: 4),
                Text('Pinch zoom',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white54,
                        fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
      body: PhotoView(
        imageProvider: CachedNetworkImageProvider(imageUrl),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 4,
        backgroundDecoration: const BoxDecoration(color: Colors.black),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  PLACE BOTTOM SHEET (from map marker tap)
// ═══════════════════════════════════════════════════════════════════
// Bottom sheet yang muncul saat marker tempat diklik. Menampilkan detail tempat
// dan tombol aksi (detail, rute GPS, buka mode rute A-B).
class _PlaceBottomSheet extends StatelessWidget {
  final TempatModel tempat;
  final LatLng? userLocation;
  final bool loadingRoute;
  final bool hasRoute;
  final VoidCallback onClose;
  final VoidCallback onRoute;       // simple GPS→place route
  final VoidCallback onRouteMode;   // open full A→B route panel
  final VoidCallback onGoogleMaps;
  final Function(String) onImageTap;
  final VoidCallback onDetail;

  const _PlaceBottomSheet({
    required this.tempat,
    required this.userLocation,
    required this.loadingRoute,
    required this.hasRoute,
    required this.onClose,
    required this.onRoute,
    required this.onRouteMode,
    required this.onGoogleMaps,
    required this.onImageTap,
    required this.onDetail,
  });

  @override
  Widget build(BuildContext context) {
    double? distKm;
    if (userLocation != null && tempat.latitude != null) {
      distKm = Haversine.distance(userLocation!.latitude, userLocation!.longitude,
          tempat.latitude!, tempat.longitude!);
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -4))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle (garis tipis di atas).
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 4),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
                color: AppColors.surface, borderRadius: BorderRadius.circular(4)),
          ),

          // Baris informasi: gambar, nama, kategori, rating, jarak.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gambar (tappable untuk zoom).
                GestureDetector(
                  onTap: tempat.imageUrl.isNotEmpty
                      ? () => onImageTap(tempat.imageUrl)
                      : null,
                  child: Hero(
                    tag: 'map_img_${tempat.id}',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 72,
                        height: 72,
                        child: Stack(
                          children: [
                            tempat.imageUrl.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: tempat.imageUrl,
                                    fit: BoxFit.cover,
                                    width: 72,
                                    height: 72,
                                    placeholder: (_, __) =>
                                        Container(color: AppColors.surface),
                                    errorWidget: (_, __, ___) => Container(
                                      color: AppColors.surface,
                                      child: Center(
                                        child: Text(tempat.categoryIcon,
                                            style: const TextStyle(
                                                fontSize: 28)),
                                      ),
                                    ),
                                  )
                                : Container(
                                    color: AppColors.surface,
                                    child: Center(
                                      child: Text(tempat.categoryIcon,
                                          style:
                                              const TextStyle(fontSize: 28)),
                                    ),
                                  ),
                            if (tempat.imageUrl.isNotEmpty)
                              Positioned(
                                bottom: 3,
                                right: 3,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: Colors.black45,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(Icons.zoom_in_rounded,
                                      color: Colors.white, size: 12),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Detail teks.
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tempat.namaTempat,
                          style: AppTextStyles.h3,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 3),
                      Text(
                          '${tempat.namaKategori ?? ''} · ${tempat.namaKecamatan ?? ''}',
                          style: AppTextStyles.small),
                      if (tempat.jalan != null && tempat.jalan!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.edit_road_rounded,
                                size: 11, color: AppColors.textGray),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(tempat.jalan!,
                                  style: AppTextStyles.small,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              color: Colors.amber, size: 13),
                          Text(
                              ' ${tempat.reviewRating?.toStringAsFixed(1) ?? '-'}',
                              style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                          if (distKm != null) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.near_me_rounded,
                                color: AppColors.primary, size: 12),
                            Text(
                              ' ${Haversine.formatDistance(distKm)}',
                              style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  color: AppColors.primary),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.textGray, size: 20),
                  onPressed: onClose,
                ),
              ],
            ),
          ),

          // Tombol aksi.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            child: Row(
              children: [
                // Tombol Detail (buka halaman detail tempat).
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDetail,
                    icon: const Icon(Icons.info_outline_rounded, size: 16),
                    label: const Text('Detail'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      textStyle: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Tombol Rute GPS (rute dari lokasi pengguna ke tempat ini).
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: loadingRoute ? null : onRoute,
                    icon: loadingRoute
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Icon(hasRoute
                            ? Icons.refresh_rounded
                            : Icons.directions_rounded,
                            size: 16),
                    label: Text(loadingRoute
                        ? 'Mencari...'
                        : hasRoute
                            ? 'Refresh'
                            : '🔵 Rute GPS'),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      textStyle: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Tombol Mode Rute Penuh (A-B).
                Tooltip(
                  message: 'Pilih titik awal & tujuan',
                  child: GestureDetector(
                    onTap: onRouteMode,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: const Icon(Icons.alt_route_rounded,
                          color: AppColors.primary, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().slideY(
        begin: 1, end: 0, duration: 300.ms, curve: Curves.easeOutCubic);
  }
}

// ═══════════════════════════════════════════════════════════════════
//  ROUTE RESULT SHEET (A→B)
// ═══════════════════════════════════════════════════════════════════
// Bottom sheet yang menampilkan hasil rute A-B: jarak, waktu, dan detail titik.
class _RouteResultSheet extends StatelessWidget {
  final RouteResult result;
  final _RoutePoint start;
  final _RoutePoint end;
  final String emoji;
  final VoidCallback onClose;
  final VoidCallback onGoogleMaps;
  final Function(String) onImageTap;

  const _RouteResultSheet({
    required this.result,
    required this.start,
    required this.end,
    required this.emoji,
    required this.onClose,
    required this.onGoogleMaps,
    required this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -4))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle.
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 4),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
                color: AppColors.surface, borderRadius: BorderRadius.circular(4)),
          ),

          // Baris statistik jarak dan waktu.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(result.distanceText,
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                              fontSize: 22,
                              color: AppColors.primary)),
                      Text('Estimasi ${result.durationText}',
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              color: AppColors.textGray)),
                    ],
                  ),
                ),
                // Tombol buka di Google Maps.
                GestureDetector(
                  onTap: onGoogleMaps,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                        color: const Color(0xFF4285F4),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Text(
                      'Google\nMaps',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onClose,
                  child: const Icon(Icons.close_rounded,
                      color: AppColors.textGray),
                ),
              ],
            ),
          ),

          // Kartu titik A dan B.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: _PointCard(
                    letter: 'A',
                    color: AppColors.success,
                    point: start,
                    onImageTap: onImageTap,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward_rounded,
                      color: AppColors.textGray, size: 20),
                ),
                Expanded(
                  child: _PointCard(
                    letter: 'B',
                    color: AppColors.error,
                    point: end,
                    onImageTap: onImageTap,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    ).animate().slideY(
        begin: 1, end: 0, duration: 350.ms, curve: Curves.easeOutCubic);
  }
}

// Kartu untuk menampilkan detail satu titik (A atau B) pada sheet hasil rute.
class _PointCard extends StatelessWidget {
  final String letter;
  final Color color;
  final _RoutePoint point;
  final Function(String) onImageTap;

  const _PointCard({
    required this.letter,
    required this.color,
    required this.point,
    required this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = point.tempat;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge huruf A/B + gambar thumbnail.
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Center(
                  child: Text(letter,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ),
              ),
              const Spacer(),
              if (t != null && t.imageUrl.isNotEmpty)
                GestureDetector(
                  onTap: () => onImageTap(t.imageUrl),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: CachedNetworkImage(
                      imageUrl: t.imageUrl,
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(point.label,
              style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          if (point.sublabel != null && point.sublabel!.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(point.sublabel!,
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    color: AppColors.textGray),
                maxLines: 3,
                overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  ROUTE INPUT ROW
// ═══════════════════════════════════════════════════════════════════
// Baris input untuk titik A atau B pada panel rute A-B.
class _RouteInputRow extends StatelessWidget {
  final String letter;                 // Huruf 'A' atau 'B'.
  final Color color;                  // Warna (hijau untuk A, merah untuk B).
  final String label;                 // Label titik (nama tempat atau "Titik Awal").
  final String? sublabel;             // Informasi tambahan (jalan, kategori, rating).
  final VoidCallback? onGps;          // Fungsi saat tombol GPS ditekan (hanya untuk titik A).
  final VoidCallback onPick;          // Fungsi saat area input ditekan (buka daftar tempat).
  final VoidCallback? onMapPick;      // Fungsi saat tombol peta ditekan (hanya untuk titik B).
  final bool loadingGps;              // Status loading GPS.

  const _RouteInputRow({
    required this.letter,
    required this.color,
    required this.label,
    this.sublabel,
    this.onGps,
    required this.onPick,
    this.onMapPick,
    this.loadingGps = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
      child: Row(
        children: [
          // Lingkaran huruf A/B.
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Center(
              child: Text(letter,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 10),

          // Area yang dapat diklik untuk memilih titik (dari daftar tempat).
          Expanded(
            child: GestureDetector(
              onTap: onPick,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.surface),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: sublabel != null ? FontWeight.w600 : FontWeight.w400,
                        color: sublabel != null ? AppColors.textDark : AppColors.textGray,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (sublabel != null)
                      Text(
                        sublabel!,
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            color: AppColors.textGray),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Tombol GPS (hanya untuk titik A).
          if (onGps != null)
            loadingGps
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary))
                : GestureDetector(
                    onTap: onGps,
                    child: const Icon(Icons.my_location_rounded,
                        color: AppColors.primary, size: 20),
                  ),

          // Tombol pilih titik di peta (hanya untuk titik B).
          if (onMapPick != null) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onMapPick,
              child: const Icon(Icons.map_rounded,
                  color: AppColors.primary, size: 20),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  END SEARCH BAR (geocoding)
// ═══════════════════════════════════════════════════════════════════
// Bar pencarian alamat menggunakan Nominatim (geocoding) untuk titik tujuan.
class _EndSearchBar extends StatelessWidget {
  final TextEditingController ctrl;                 // Controller input teks.
  final Function(String) onChanged;                 // Fungsi saat teks berubah.
  final bool searching;                             // Status sedang mencari.
  final List<_GeoResult> geoResults;                // Hasil pencarian alamat.
  final Function(_GeoResult) onSelectGeo;           // Fungsi saat hasil dipilih.

  const _EndSearchBar({
    required this.ctrl,
    required this.onChanged,
    required this.searching,
    required this.geoResults,
    required this.onSelectGeo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Kotak pencarian alamat.
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
          child: Container(
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.surface),
            ),
            child: Row(
              children: [
                const SizedBox(width: 10),
                const Icon(Icons.search_rounded,
                    size: 15, color: AppColors.textGray),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: ctrl,
                    onChanged: onChanged,
                    style: const TextStyle(
                        fontFamily: 'Poppins', fontSize: 12),
                    decoration: const InputDecoration(
                      hintText: 'Cari alamat tujuan via Nominatim...',
                      hintStyle: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: AppColors.textGray),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                if (searching)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.primary)),
                  ),
              ],
            ),
          ),
        ),

        // Dropdown hasil geocoding.
        if (geoResults.isNotEmpty)
          Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 4),
            constraints: const BoxConstraints(maxHeight: 160),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8)
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: geoResults.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppColors.surface),
              itemBuilder: (_, i) => InkWell(
                onTap: () => onSelectGeo(geoResults[i]),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          color: AppColors.primary, size: 14),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          geoResults[i].name,
                          style: const TextStyle(
                              fontFamily: 'Poppins', fontSize: 11),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  PLACE PICKER SHEET
// ═══════════════════════════════════════════════════════════════════
// Bottom sheet untuk memilih tempat dari daftar (digunakan untuk titik awal/tujuan).
class _PlacePickerSheet extends StatefulWidget {
  final String title;                       // Judul sheet.
  final List<TempatModel> places;          // Daftar tempat.
  final Function(TempatModel) onSelect;    // Fungsi saat tempat dipilih.

  const _PlacePickerSheet({
    required this.title,
    required this.places,
    required this.onSelect,
  });

  @override
  State<_PlacePickerSheet> createState() => _PlacePickerSheetState();
}

class _PlacePickerSheetState extends State<_PlacePickerSheet> {
  String _q = ''; // Teks pencarian internal.

  @override
  Widget build(BuildContext context) {
    final filtered = _q.isEmpty
        ? widget.places
        : widget.places.where((t) =>
            t.namaTempat.toLowerCase().contains(_q.toLowerCase()) ||
            (t.namaKecamatan?.toLowerCase().contains(_q.toLowerCase()) ??
                false)).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle.
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(4)),
            ),

            // Header.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Text(widget.title, style: AppTextStyles.h3),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.textGray),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Search bar dalam sheet.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                onChanged: (v) => setState(() => _q = v),
                decoration: const InputDecoration(
                  hintText: 'Cari tempat...',
                  isDense: true,
                  prefixIcon: Icon(Icons.search_rounded,
                      color: AppColors.primary, size: 18),
                ),
              ),
            ),

            // Daftar tempat.
            Expanded(
              child: ListView.separated(
                controller: ctrl,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (_, i) {
                  final t = filtered[i];
                  return InkWell(
                    onTap: () => widget.onSelect(t),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.05),
                              blurRadius: 6)
                        ],
                      ),
                      child: Row(
                        children: [
                          // Thumbnail.
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 44,
                              height: 44,
                              child: t.imageUrl.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: t.imageUrl,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) => Container(
                                        color: AppColors.surface,
                                        child: Center(
                                          child: Text(t.categoryIcon,
                                              style: const TextStyle(
                                                  fontSize: 18)),
                                        ),
                                      ),
                                    )
                                  : Container(
                                      color: AppColors.surface,
                                      child: Center(
                                        child: Text(t.categoryIcon,
                                            style: const TextStyle(
                                                fontSize: 18)),
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Nama dan kategori.
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t.namaTempat,
                                  style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${t.namaKategori ?? ''} · ${t.namaKecamatan ?? ''}',
                                  style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 11,
                                      color: AppColors.textGray),
                                ),
                              ],
                            ),
                          ),

                          // Rating.
                          Row(
                            children: [
                              const Icon(Icons.star_rounded,
                                  color: Colors.amber, size: 12),
                              Text(
                                ' ${t.reviewRating?.toStringAsFixed(1) ?? '-'}',
                                style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  ROUTE INFO BAR (simple GPS→place route)
// ═══════════════════════════════════════════════════════════════════
// Info bar yang muncul saat rute sederhana (GPS ke tempat) ditampilkan.
class _RouteInfoBar extends StatelessWidget {
  final RouteResult result;
  final String transport;
  final VoidCallback onClose;
  final VoidCallback onGoogleMaps;

  const _RouteInfoBar({
    required this.result,
    required this.transport,
    required this.onClose,
    required this.onGoogleMaps,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1565C0),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 3))
        ],
      ),
      child: Row(
        children: [
          Text(transport, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result.distanceText,
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
                Text('± ${result.durationText}',
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white70,
                        fontSize: 11)),
              ],
            ),
          ),
          GestureDetector(
            onTap: onGoogleMaps,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8)),
              child: const Text('GMaps',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onClose,
            child: const Icon(Icons.close_rounded,
                color: Colors.white70, size: 18),
          ),
        ],
      ),
    ).animate().slideY(begin: -0.5, end: 0, duration: 300.ms);
  }
}

// ═══════════════════════════════════════════════════════════════════
//  FILTER SHEET
// ═══════════════════════════════════════════════════════════════════
// Bottom sheet untuk filter tempat: kategori, urutan, jarak, dll.
class FilterSheet extends StatefulWidget {
  final PlaceFilter currentFilter;
  final List<KategoriModel> kategori;
  final LatLng? userLocation;
  final Function(PlaceFilter) onApply;

  const FilterSheet({
    super.key,
    required this.currentFilter,
    required this.kategori,
    required this.userLocation,
    required this.onApply,
  });

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late List<int> _katIds;
  late String? _sortRating;
  late bool _openNow;
  late double? _maxDist;
  late bool _hasContact;
  late bool _minRating35;
  late bool _sortNearest;

  @override
  void initState() {
    super.initState();
    final f = widget.currentFilter;
    _katIds = List<int>.from(f.selectedKategoriIds);
    _sortRating = f.sortByRating;
    _openNow = f.openNow;
    _maxDist = f.maxDistanceKm;
    _hasContact = f.hasContact;
    _minRating35 = f.minRating35;
    _sortNearest = f.sortNearest;
  }

  // Reset semua filter ke default.
  void _reset() => setState(() {
        _katIds = [];
        _sortRating = null;
        _openNow = false;
        _maxDist = null;
        _hasContact = false;
        _minRating35 = false;
        _sortNearest = false;
      });

  // Terapkan filter dan tutup sheet.
  void _apply() {
    widget.onApply(PlaceFilter(
      selectedKategoriIds: _katIds,
      sortByRating: _sortNearest ? null : _sortRating,
      openNow: _openNow,
      maxDistanceKm: _maxDist,
      hasContact: _hasContact,
      minRating35: _minRating35,
      sortNearest: _sortNearest,
    ));
    Navigator.pop(context);
  }

  // Jumlah filter yang aktif.
  int get _count {
    int c = 0;
    if (_katIds.isNotEmpty) c++;
    if (_sortRating != null) c++;
    if (_openNow) c++;
    if (_maxDist != null) c++;
    if (_hasContact) c++;
    if (_minRating35) c++;
    if (_sortNearest) c++;
    return c;
  }

  @override
  Widget build(BuildContext context) {
    final hasGps = widget.userLocation != null;
    return DraggableScrollableSheet(
      initialChildSize: 0.80,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle.
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(4)),
            ),

            // Header.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 12, 0),
              child: Row(
                children: [
                  const Icon(Icons.tune_rounded,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  const Text('Filter Tempat',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                          color: AppColors.textDark)),
                  const Spacer(),
                  if (_count > 0)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10)),
                      child: Text('$_count aktif',
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600)),
                    ),
                  TextButton(
                    onPressed: _reset,
                    child: const Text('Reset',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            color: AppColors.error,
                            fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ),

            const Divider(height: 14, color: AppColors.surface),

            // Daftar opsi filter.
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                children: [
                  const _FLabel('📂 Kategori'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FChip(
                        label: 'Semua',
                        selected: _katIds.isEmpty,
                        onTap: () => setState(() => _katIds = []),
                      ),
                      ...widget.kategori.map((k) => _FChip(
                        label: '${k.icon} ${k.namaKategori}',
                        selected: _katIds.contains(k.id),
                        onTap: () => setState(() {
                          if (_katIds.contains(k.id)) {
                            _katIds.remove(k.id);
                          } else {
                            _katIds.add(k.id);
                          }
                        }),
                      )),
                    ],
                  ),

                  const SizedBox(height: 18),
                  const Divider(color: AppColors.surface),

                  const _FLabel('📊 Urutan'),
                  const SizedBox(height: 10),

                  // Toggle "Terdekat dari Saya".
                  _FToggle(
                    icon: '📍',
                    label: 'Terdekat dari Saya',
                    subtitle: hasGps
                        ? 'Urutkan berdasarkan jarak GPS'
                        : 'GPS belum aktif',
                    value: _sortNearest,
                    enabled: hasGps,
                    onChanged: (v) => setState(() {
                      _sortNearest = v;
                      if (v) _sortRating = null;
                    }),
                  ),

                  const SizedBox(height: 8),

                  // Opsi urutan rating (hanya tampil jika tidak dalam mode terdekat).
                  AnimatedOpacity(
                    opacity: _sortNearest ? 0.4 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Rating',
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: AppColors.textGray)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _FSeg(
                              label: '⭐ Tertinggi',
                              selected: _sortRating == 'highest',
                              onTap: _sortNearest
                                  ? null
                                  : () => setState(() {
                                        _sortRating = _sortRating == 'highest'
                                            ? null
                                            : 'highest';
                                      }),
                            ),
                            const SizedBox(width: 8),
                            _FSeg(
                              label: '📉 Terendah',
                              selected: _sortRating == 'lowest',
                              onTap: _sortNearest
                                  ? null
                                  : () => setState(() {
                                        _sortRating = _sortRating == 'lowest'
                                            ? null
                                            : 'lowest';
                                      }),
                            ),
                            const SizedBox(width: 8),
                            _FSeg(
                              label: 'Default',
                              selected: _sortRating == null && !_sortNearest,
                              onTap: _sortNearest
                                  ? null
                                  : () => setState(() => _sortRating = null),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),
                  const Divider(color: AppColors.surface),

                  const _FLabel('📏 Jarak Maksimal'),
                  const SizedBox(height: 8),

                  // Jika GPS tidak tersedia, tampilkan pesan.
                  if (!hasGps)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.warning.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.location_off_rounded,
                              color: AppColors.warning, size: 16),
                          SizedBox(width: 8),
                          Text('Aktifkan GPS untuk filter jarak',
                              style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  color: AppColors.warning)),
                        ],
                      ),
                    )
                  else ...[
                    // Slider jarak.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _maxDist == null
                              ? 'Tidak dibatasi'
                              : '≤ ${_maxDist!.toStringAsFixed(1)} km',
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary),
                        ),
                        if (_maxDist != null)
                          GestureDetector(
                            onTap: () => setState(() => _maxDist = null),
                            child: const Text('Hapus',
                                style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 11,
                                    color: AppColors.error)),
                          ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppColors.primary,
                        thumbColor: AppColors.primary,
                        inactiveTrackColor: AppColors.surface,
                        overlayColor: AppColors.primary.withValues(alpha: 0.15),
                        trackHeight: 4,
                      ),
                      child: Slider(
                        value: _maxDist ?? 0.5,
                        min: 0.5,
                        max: 20,
                        divisions: 39,
                        label: '${(_maxDist ?? 0.5).toStringAsFixed(1)} km',
                        onChanged: (v) => setState(() => _maxDist = v),
                      ),
                    ),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('0.5 km',
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10,
                                color: AppColors.textGray)),
                        Text('20 km',
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10,
                                color: AppColors.textGray)),
                      ],
                    ),
                  ],

                  const SizedBox(height: 18),
                  const Divider(color: AppColors.surface),

                  const _FLabel('⚙️ Opsi Lain'),
                  const SizedBox(height: 8),

                  _FToggle(
                    icon: '📞',
                    label: 'Memiliki Kontak',
                    subtitle: 'Hanya tempat dengan nomor telepon',
                    value: _hasContact,
                    onChanged: (v) => setState(() => _hasContact = v),
                  ),
                  const SizedBox(height: 6),

                  _FToggle(
                    icon: '⭐',
                    label: 'Rating Minimal 3.5',
                    subtitle: 'Hanya tempat berkualitas',
                    value: _minRating35,
                    onChanged: (v) => setState(() => _minRating35 = v),
                  ),
                  const SizedBox(height: 6),

                  _FToggle(
                    icon: '🕐',
                    label: 'Buka Sekarang',
                    subtitle: 'Segera tersedia',
                    value: _openNow,
                    enabled: false,
                    onChanged: (v) => setState(() => _openNow = v),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // Tombol Terapkan Filter.
            Padding(
              padding: EdgeInsets.fromLTRB(
                  16, 8, 16, MediaQuery.of(context).padding.bottom + 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _apply,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    textStyle: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 15),
                  ),
                  child: Text(_count > 0
                      ? 'Terapkan Filter ($_count aktif)'
                      : 'Terapkan Filter'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
//  FILTER SHEET SUB-WIDGETS
// ---------------------------------------------------------------------

// Label teks dalam filter sheet.
class _FLabel extends StatelessWidget {
  final String text;
  const _FLabel(this.text);
  @override
  Widget build(BuildContext ctx) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          text,
          style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppColors.textDark),
        ),
      );
}

// Chip untuk pilihan kategori (dapat dipilih).
class _FChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext ctx) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: selected ? AppColors.primary : AppColors.surface,
                width: 1.5),
            boxShadow: selected
                ? [
                    BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2))
                  ]
                : [],
          ),
          child: Text(
            label,
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? Colors.white : AppColors.textGray),
          ),
        ),
      );
}

// Segmen untuk pilihan urutan rating (Tertinggi / Terendah / Default).
class _FSeg extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  const _FSeg({
    required this.label,
    required this.selected,
    this.onTap,
  });
  @override
  Widget build(BuildContext ctx) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : AppColors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: selected ? AppColors.primary : AppColors.surface,
                  width: 1.5),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? Colors.white : AppColors.textGray),
            ),
          ),
        ),
      );
}

// Toggle switch dengan ikon dan deskripsi.
class _FToggle extends StatelessWidget {
  final String icon, label, subtitle;
  final bool value;
  final bool enabled;
  final Function(bool) onChanged;
  const _FToggle({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });
  @override
  Widget build(BuildContext ctx) => Opacity(
        opacity: enabled ? 1.0 : 0.45,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surface),
          ),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textDark)),
                    Text(subtitle,
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: AppColors.textGray)),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: enabled ? onChanged : null,
                activeThumbColor: AppColors.primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════
//  CATEGORY STRIP
// ═══════════════════════════════════════════════════════════════════
// Baris chip kategori di bagian atas peta (untuk filter cepat).
class _CategoryStrip extends StatelessWidget {
  final List<KategoriModel> kategori;
  final List<int> selectedIds;
  final Function(int?) onToggle;

  const _CategoryStrip({
    required this.kategori,
    required this.selectedIds,
    required this.onToggle,
  });

  // Widget chip tunggal.
  Widget _chip(String label, bool sel, VoidCallback tap) => GestureDetector(
        onTap: tap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.only(right: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: sel ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06), blurRadius: 6)
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: sel ? Colors.white : AppColors.textGray),
          ),
        ),
      );

  @override
  Widget build(BuildContext ctx) => SizedBox(
        height: 34,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: kategori.length + 1,
          itemBuilder: (_, i) {
            if (i == 0) {
              return _chip('Semua', selectedIds.isEmpty, () => onToggle(null));
            }
            final k = kategori[i - 1];
            return _chip(
              '${k.icon} ${k.namaKategori}',
              selectedIds.contains(k.id),
              () => onToggle(k.id),
            );
          },
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════
//  SUPPORTING WIDGETS
// ═══════════════════════════════════════════════════════════════════

// Data untuk label teks kecamatan (koordinat statis).
class _KecLabel {
  final String name;
  final double lat, lng;
  const _KecLabel(this.name, this.lat, this.lng);
}

// Marker tempat pada peta (ikon lingkaran dengan emoji kategori).
class _PlaceMarker extends StatelessWidget {
  final TempatModel tempat;
  final bool isSelected;
  const _PlaceMarker({required this.tempat, required this.isSelected});

  // Warna marker berdasarkan kategori.
  Color get _color {
    switch (tempat.namaKategori?.toLowerCase()) {
      case 'kuliner':
        return const Color(0xFFFF6B35);
      case 'wisata':
        return const Color(0xFF4ECDC4);
      case 'kesehatan':
        return const Color(0xFFFF4757);
      case 'kemasyarakatan':
        return const Color(0xFF5352ED);
      case 'transportasi':
        return const Color(0xFF2ED573);
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext ctx) => AnimatedScale(
        scale: isSelected ? 1.25 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: isSelected ? 44 : 36,
              height: isSelected ? 44 : 36,
              decoration: BoxDecoration(
                color: _color,
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white, width: isSelected ? 3 : 2),
                boxShadow: [
                  BoxShadow(
                      color: _color.withValues(alpha: 0.5),
                      blurRadius: isSelected ? 14 : 6,
                      spreadRadius: isSelected ? 3 : 0)
                ],
              ),
              child: Center(
                child: Text(tempat.categoryIcon,
                    style: TextStyle(fontSize: isSelected ? 18 : 14)),
              ),
            ),
            CustomPaint(
              size: const Size(10, 6),
              painter: _Arrow(color: _color),
            ),
          ],
        ),
      );
}

// Marker untuk titik A atau B pada mode rute (lingkaran warna dengan huruf).
class _RouteMarker extends StatelessWidget {
  final Color color;
  final String letter;
  const _RouteMarker({required this.color, required this.letter});

  @override
  Widget build(BuildContext ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8)
              ],
            ),
            child: Center(
              child: Text(letter,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
            ),
          ),
          CustomPaint(
            size: const Size(10, 6),
            painter: _Arrow(color: color),
          ),
        ],
      );
}

// Custom painter untuk panah segitiga di bawah marker.
class _Arrow extends CustomPainter {
  final Color color;
  const _Arrow({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Tombol bulat standar untuk kontrol peta.
class _MapBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool loading;
  final Color color;
  const _MapBtn({
    required this.icon,
    required this.onTap,
    this.loading = false,
    this.color = AppColors.textDark,
  });

  @override
  Widget build(BuildContext ctx) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ],
          ),
          child: loading
              ? const Center(
                  child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.primary)))
              : Icon(icon, color: color, size: 20),
        ),
      );
}

// Tombol overlay (heatmap, label kecamatan) dengan emoji.
class _OverlayBtn extends StatelessWidget {
  final String emoji;
  final String tooltip;
  final bool active;
  final bool loading;
  final VoidCallback onTap;
  const _OverlayBtn({
    required this.emoji,
    required this.tooltip,
    required this.active,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext ctx) => Tooltip(
        message: tooltip,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: active ? AppColors.primary.withValues(alpha: 0.15) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: active
                      ? AppColors.primary.withValues(alpha: 0.5)
                      : Colors.transparent),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
            ),
            child: loading
                ? const Center(
                    child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.primary)))
                : Center(child: Text(emoji, style: const TextStyle(fontSize: 18))),
          ),
        ),
      );
}

// Chip informasi jumlah lokasi.
class _InfoChip extends StatelessWidget {
  final String label;
  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06), blurRadius: 6)
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textDark),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════
//  POLYGON OVERLAY BUTTON (tap = toggle, long-press = filter sheet)
// ═══════════════════════════════════════════════════════════════════
// Tombol khusus untuk menampilkan polygon kecamatan. Tap: on/off.
// Long-press: buka sheet filter kecamatan.
class _PolygonOverlayBtn extends StatelessWidget {
  final bool active;
  final bool loading;
  final int selectedCount;   // jumlah kecamatan yang dipilih (0 = semua)
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _PolygonOverlayBtn({
    required this.active,
    required this.loading,
    required this.selectedCount,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Tap: on/off polygon\nTahan: filter kecamatan',
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: active
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: active
                        ? AppColors.primary.withValues(alpha: 0.6)
                        : Colors.transparent),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
              ),
              child: loading
                  ? const Center(
                      child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.primary)))
                  : const Center(child: Text('🗾', style: TextStyle(fontSize: 18))),
            ),
            // Badge jumlah kecamatan terpilih (hanya jika aktif dan ada filter).
            if (active && selectedCount > 0)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                      color: AppColors.primary, shape: BoxShape.circle),
                  child: Center(
                    child: Text(
                      '$selectedCount',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins'),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  RECORD TRACK BUTTON
// ═══════════════════════════════════════════════════════════════════
// Tombol untuk merekam jalur GPS. Tampilan berubah sesuai status:
// - lingkaran merah (sedang merekam)
// - ikon tempat sampah (jika ada jalur)
// - lingkaran biasa (belum merekam)
class _RecordTrackBtn extends StatelessWidget {
  final bool isRecording;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onClear;
  final bool hasPoints;

  const _RecordTrackBtn({
    required this.isRecording,
    required this.onStart,
    required this.onStop,
    required this.onClear,
    required this.hasPoints,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: isRecording
          ? 'Berhenti merekam'
          : (hasPoints ? 'Hapus jalur' : 'Mulai rekam jalur'),
      child: GestureDetector(
        onTap: isRecording ? onStop : (hasPoints ? onClear : onStart),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isRecording
                ? Colors.redAccent.withValues(alpha: 0.2)
                : (hasPoints ? Colors.orange.withValues(alpha: 0.2) : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isRecording
                  ? Colors.redAccent
                  : (hasPoints ? Colors.orange : Colors.transparent),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: isRecording
                ? const Icon(Icons.stop_circle_rounded,
                    color: Colors.redAccent, size: 24)
                : (hasPoints
                    ? const Icon(Icons.delete_sweep_rounded,
                        color: Colors.orange, size: 22)
                    : const Icon(Icons.fiber_manual_record_rounded,
                        color: AppColors.primary, size: 22)),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  KECAMATAN FILTER SHEET  (long-press on 🗾 button)
// ═══════════════════════════════════════════════════════════════════
// Bottom sheet untuk memilih kecamatan yang akan ditampilkan polygonya.
class _KecamatanFilterSheet extends StatefulWidget {
  final List<KecamatanModel> allKecamatan;
  final Set<int> selectedIds;
  final Function(Set<int>) onApply;

  const _KecamatanFilterSheet({
    required this.allKecamatan,
    required this.selectedIds,
    required this.onApply,
  });

  @override
  State<_KecamatanFilterSheet> createState() => _KecamatanFilterSheetState();
}

class _KecamatanFilterSheetState extends State<_KecamatanFilterSheet> {
  late Set<int> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set<int>.from(widget.selectedIds);
  }

  // Pilih / batalkan pilih semua.
  void _toggleAll() {
    setState(() {
      if (_selected.length == widget.allKecamatan.length) {
        _selected = {}; // kosong = tampilkan semua (tanpa filter)
      } else {
        _selected = widget.allKecamatan.map((k) => k.id).toSet();
      }
    });
  }

  void _apply() {
    widget.onApply(_selected);
    Navigator.pop(context);
  }

  String get _title {
    if (_selected.isEmpty) return 'Semua kecamatan';
    if (_selected.length == 1) return '1 kecamatan dipilih';
    return '${_selected.length} kecamatan dipilih';
  }

  @override
  Widget build(BuildContext context) {
    final allKec = widget.allKecamatan;
    final isAllSelected =
        _selected.isEmpty || _selected.length == allKec.length;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle.
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(4)),
            ),

            // Header.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 12, 0),
              child: Row(
                children: [
                  const Text('🗾', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Filter Kecamatan',
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: AppColors.textDark)),
                        Text(_title,
                            style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                color: AppColors.textGray)),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _toggleAll,
                    child: Text(
                      isAllSelected ? 'Hapus Semua' : 'Pilih Semua',
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                          fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 14, color: AppColors.surface),

            // Petunjuk.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: AppColors.primary, size: 14),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pilih satu atau beberapa kecamatan. '
                        'Kosong = tampilkan semua.',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: AppColors.primaryDark),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Daftar kecamatan dengan checkbox.
            Expanded(
              child: allKec.isEmpty
                  ? const Center(
                      child: Text('Tidak ada data kecamatan',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              color: AppColors.textGray)))
                  : ListView.builder(
                      controller: ctrl,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: allKec.length,
                      itemBuilder: (_, i) {
                        final k = allKec[i];
                        final sel = _selected.contains(k.id);
                        final hasGeo = k.hasPolygon;

                        return GestureDetector(
                          onTap: () => setState(() {
                            if (sel) {
                              _selected.remove(k.id);
                            } else {
                              _selected.add(k.id);
                            }
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 11),
                            decoration: BoxDecoration(
                              color: sel
                                  ? AppColors.primary.withValues(alpha: 0.08)
                                  : AppColors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: sel
                                    ? AppColors.primary.withValues(alpha: 0.5)
                                    : AppColors.surface,
                                width: sel ? 1.5 : 1,
                              ),
                              boxShadow: sel
                                  ? [
                                      BoxShadow(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.1),
                                          blurRadius: 6)
                                    ]
                                  : [],
                            ),
                            child: Row(
                              children: [
                                // Indikator lingkaran.
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: sel
                                        ? AppColors.primary
                                        : (hasGeo
                                            ? AppColors.surface
                                            : Colors.grey.shade300),
                                    border: Border.all(
                                        color: sel
                                            ? AppColors.primary
                                            : AppColors.textGray
                                                .withValues(alpha: 0.3)),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Nama kecamatan.
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        k.namaKecamatan,
                                        style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 13,
                                            fontWeight: sel
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                            color: sel
                                                ? AppColors.primaryDark
                                                : AppColors.textDark),
                                      ),
                                      if (!hasGeo)
                                        const Text(
                                          'Belum ada data polygon',
                                          style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 10,
                                              color: AppColors.textGray),
                                        ),
                                    ],
                                  ),
                                ),

                                // Checkmark animasi.
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: sel
                                      ? const Icon(
                                          Icons.check_circle_rounded,
                                          color: AppColors.primary,
                                          size: 20,
                                          key: ValueKey('check'),
                                        )
                                      : const Icon(
                                          Icons.radio_button_unchecked_rounded,
                                          color: AppColors.surface,
                                          size: 20,
                                          key: ValueKey('empty'),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Tombol terapkan.
            Padding(
              padding: EdgeInsets.fromLTRB(
                  16, 8, 16, MediaQuery.of(context).padding.bottom + 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _apply,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    textStyle: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 15),
                  ),
                  child: Text(
                    _selected.isEmpty
                        ? 'Tampilkan Semua Kecamatan'
                        : 'Tampilkan ${_selected.length} Kecamatan',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}