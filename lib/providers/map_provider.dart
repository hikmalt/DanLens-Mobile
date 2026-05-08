// lib/providers/map_provider.dart
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart' hide Haversine;
import '../models/models.dart';
import '../utils/haversine.dart';
import '../utils/error_logger.dart';

class RouteInfo {
  final double distanceKm;
  final int estimatedMinutes;
  final String suggestedTransport;
  final String tip;
  final List<LatLng> polylinePoints;

  RouteInfo({
    required this.distanceKm,
    required this.estimatedMinutes,
    required this.suggestedTransport,
    required this.tip,
    required this.polylinePoints,
  });
}

class MapProvider extends ChangeNotifier {
  LatLng? _userLocation;
  TempatModel? _selectedTempat;
  RouteInfo? _routeInfo;
  // ignore: prefer_final_fields
  bool _loadingRoute = false;
  int? _selectedKategoriId;
  String _mapStyle = 'standard'; // standard | dark | satellite

  LatLng? get userLocation => _userLocation;
  TempatModel? get selectedTempat => _selectedTempat;
  RouteInfo? get routeInfo => _routeInfo;
  bool get loadingRoute => _loadingRoute;
  int? get selectedKategoriId => _selectedKategoriId;
  String get mapStyle => _mapStyle;

  String get tileUrl {
    switch (_mapStyle) {
      case 'dark':
        return 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';
      case 'satellite':
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      default:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
  }

  void setUserLocation(LatLng location) {
    _userLocation = location;
    notifyListeners();
  }

  void selectTempat(TempatModel? tempat) {
    _selectedTempat = tempat;
    if (tempat == null) {
      _routeInfo = null;
    } else if (_userLocation != null) {
      _calculateRoute(tempat);
    }
    notifyListeners();
  }

  void setKategoriFilter(int? id) {
    _selectedKategoriId = id;
    notifyListeners();
  }

  void toggleMapStyle() {
    const styles = ['standard', 'dark', 'satellite'];
    final idx = styles.indexOf(_mapStyle);
    _mapStyle = styles[(idx + 1) % styles.length];
    notifyListeners();
  }

  void _calculateRoute(TempatModel tempat) {
    if (_userLocation == null || tempat.latitude == null) return;

    final dist = Haversine.distance(
      _userLocation!.latitude,
      _userLocation!.longitude,
      tempat.latitude!,
      tempat.longitude!,
    );

    final transport = Haversine.suggestTransport(dist);
    final time = Haversine.estimatedTime(dist);

    // Straight-line polyline (simple — no OSRM)
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

  String _buildTip(double km, String transport) {
    if (km < 0.5) return '✅ Sangat dekat — cukup jalan kaki!';
    if (km < 3) return '🛵 Ojek online direkomendasikan. Estimasi biaya Rp 5.000–15.000.';
    if (km < 10) return '🏍️ Naik motor lebih efisien. Hindari jam sibuk 07.00–09.00.';
    return '🚗 Gunakan mobil atau angkutan umum. Pertimbangkan Trans Metro Deli.';
  }

  Future<void> refreshRoute() async {
    if (_selectedTempat != null && _userLocation != null) {
      _calculateRoute(_selectedTempat!);
    }
  }
}