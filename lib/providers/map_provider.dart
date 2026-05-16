// FILE: lib/providers/map_provider.dart
// File ini adalah penyedia data (provider) untuk mengelola state yang berkaitan dengan peta.
// Fungsi utama: menyimpan posisi pengguna, tempat yang dipilih, informasi rute, gaya peta, dan filter kategori.
// Informasi penting: Provider ini menggunakan ChangeNotifier agar halaman peta dapat merespon perubahan data secara otomatis.
// Perhitungan rute di sini menggunakan garis lurus (Haversine) untuk estimasi cepat, bukan OSRM (layanan routing eksternal).

import 'package:flutter/foundation.dart';
// Paket inti Flutter untuk ChangeNotifier.

import 'package:latlong2/latlong.dart' hide Haversine;
// Paket koordinat geografis, tetapi menyembunyikan kelas Haversine miliknya agar tidak bentrok dengan versi custom.

import '../models/models.dart';
// Mengimpor model data (TempatModel, dll).

import '../utils/haversine.dart';
// Mengimpor utilitas Haversine buatan sendiri untuk perhitungan jarak dan saran transportasi.

import '../utils/error_logger.dart';
// Pencatat error untuk debugging.

// Kelas untuk menyimpan informasi rute sederhana (garis lurus).
class RouteInfo {
  final double distanceKm;
  // Jarak dalam kilometer.

  final int estimatedMinutes;
  // Estimasi waktu tempuh dalam menit.

  final String suggestedTransport;
  // Saran moda transportasi (jalan kaki, ojek, motor, mobil).

  final String tip;
  // Tips perjalanan berdasarkan jarak.

  final List<LatLng> polylinePoints;
  // Titik-titik koordinat untuk digambar sebagai garis rute (hanya titik awal dan akhir untuk garis lurus).

  RouteInfo({
    required this.distanceKm,
    required this.estimatedMinutes,
    required this.suggestedTransport,
    required this.tip,
    required this.polylinePoints,
  });
}

// Kelas provider untuk peta.
class MapProvider extends ChangeNotifier {
  LatLng? _userLocation;
  // Lokasi pengguna saat ini (dari GPS).

  TempatModel? _selectedTempat;
  // Tempat yang sedang dipilih pengguna (misal dari marker atau daftar).

  RouteInfo? _routeInfo;
  // Informasi rute dari lokasi pengguna ke tempat yang dipilih.

  final bool _loadingRoute = false;
  // Menandakan apakah sedang menghitung rute.

  int? _selectedKategoriId;
  // ID kategori yang dipilih untuk filter tampilan peta (misal hanya tampilkan tempat kuliner).

  String _mapStyle = 'standard';
  // Gaya peta: standard, dark, atau satellite.

  // Getter (properti read-only) untuk mengakses data dari luar.
  LatLng? get userLocation => _userLocation;
  TempatModel? get selectedTempat => _selectedTempat;
  RouteInfo? get routeInfo => _routeInfo;
  bool get loadingRoute => _loadingRoute;
  int? get selectedKategoriId => _selectedKategoriId;
  String get mapStyle => _mapStyle;

  // Mengembalikan URL tile peta sesuai gaya yang dipilih.
  String get tileUrl {
    switch (_mapStyle) {
      case 'dark':
        // Gaya gelap dari CartoDB.
        return 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';
      case 'satellite':
        // Citra satelit dari ArcGIS.
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      default:
        // Gaya standar OpenStreetMap.
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
  }

  // Menyetel lokasi pengguna (dipanggil saat GPS berhasil mendapatkan posisi).
  void setUserLocation(LatLng location) {
    _userLocation = location;
    notifyListeners();
    // Memberitahu UI bahwa lokasi berubah.
  }

  // Memilih tempat (dari marker, daftar, atau dari pencarian).
  void selectTempat(TempatModel? tempat) {
    _selectedTempat = tempat;
    if (tempat == null) {
      _routeInfo = null;
      // Jika tidak ada tempat yang dipilih, hapus rute.
    } else if (_userLocation != null) {
      _calculateRoute(tempat);
      // Jika lokasi pengguna sudah ada, hitung rute ke tempat tersebut.
    }
    notifyListeners();
  }

  // Menyetel filter kategori (untuk membatasi tempat yang ditampilkan di peta).
  void setKategoriFilter(int? id) {
    _selectedKategoriId = id;
    notifyListeners();
  }

  // Mengganti gaya peta secara siklis: standard -> dark -> satellite -> standard.
  void toggleMapStyle() {
    const styles = ['standard', 'dark', 'satellite'];
    final idx = styles.indexOf(_mapStyle);
    _mapStyle = styles[(idx + 1) % styles.length];
    notifyListeners();
  }

  // Menghitung rute sederhana (garis lurus) dari lokasi pengguna ke tempat.
  void _calculateRoute(TempatModel tempat) {
    if (_userLocation == null || tempat.latitude == null) return;

    // Hitung jarak menggunakan rumus Haversine (dalam km).
    final dist = Haversine.distance(
      _userLocation!.latitude,
      _userLocation!.longitude,
      tempat.latitude!,
      tempat.longitude!,
    );

    // Dapatkan saran transportasi berdasarkan jarak.
    final transport = Haversine.suggestTransport(dist);
    // Perkirakan waktu tempuh dalam menit.
    final time = Haversine.estimatedTime(dist);

    // Titik-titik garis lurus: dari lokasi pengguna ke tempat.
    final points = [
      _userLocation!,
      LatLng(tempat.latitude!, tempat.longitude!),
    ];

    _routeInfo = RouteInfo(
      distanceKm: dist,
      estimatedMinutes: time,
      suggestedTransport: transport,
      tip: _buildTip(dist, transport),
      polylinePoints: points,
    );

    ErrorLogger.i('Route calculated: ${dist.toStringAsFixed(2)} km → $transport');
    notifyListeners();
  }

  // Membuat teks tips berdasarkan jarak dan transportasi.
  String _buildTip(double km, String transport) {
    if (km < 0.5) return 'Sangat dekat — cukup jalan kaki.';
    if (km < 3) return 'Ojek online direkomendasikan. Estimasi biaya Rp 5.000–15.000.';
    if (km < 10) return 'Naik motor lebih efisien. Hindari jam sibuk 07.00–09.00.';
    return 'Gunakan mobil atau angkutan umum. Pertimbangkan Trans Metro Deli.';
  }

  // Menyegarkan rute (misal setelah lokasi pengguna berubah).
  Future<void> refreshRoute() async {
    if (_selectedTempat != null && _userLocation != null) {
      _calculateRoute(_selectedTempat!);
    }
  }
}