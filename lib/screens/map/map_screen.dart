// lib/screens/map/map_screen.dart
// REVISI LENGKAP:
// ✅ Autocomplete dropdown real-time (gambar, nama, jarak, rating, kategori)
// ✅ Tap dropdown → peta bergeser + info bar + tombol "Tunjukkan Rute"
// ✅ Filter lengkap (kategori multi-select, terdekat, rating, jarak, switch)
// ✅ Tombol "None" untuk sembunyikan semua pin + reset
// ✅ Overlay gambar fullscreen dengan pinch-to-zoom + tombol X
// ✅ Label kecamatan di peta (marker teks)
// ✅ Semua fitur lama tetap: cluster, heatmap, polygon, rute animasi,
//    realtime dot, style toggle, GPS, bottom sheet detail, zoom buttons

import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart' hide Haversine;
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_theme.dart';
import 'dart:ui' as ui;
import '../../models/models.dart';
import '../../providers/tempat_provider.dart';
import '../../services/location_service.dart';
import '../../services/route_service.dart';
import '../../utils/haversine.dart';
import '../../utils/error_logger.dart';
import '../../widgets/animated_route.dart';
import '../../widgets/heatmap_layer.dart';
import '../detail/detail_screen.dart';

// ═══════════════════════════════════════════════════════════════════
//  FILTER MODEL
// ═══════════════════════════════════════════════════════════════════
class PlaceFilter {
  final List<int> selectedKategoriIds;
  final String? sortByRating;
  final bool openNow;
  final double? maxDistanceKm;
  final bool hasContact;
  final bool minRating35;
  final bool sortNearest;

  const PlaceFilter({
    this.selectedKategoriIds = const [],
    this.sortByRating,
    this.openNow = false,
    this.maxDistanceKm,
    this.hasContact = false,
    this.minRating35 = false,
    this.sortNearest = false,
  });

  bool get isActive =>
      selectedKategoriIds.isNotEmpty ||
      sortByRating != null ||
      openNow ||
      maxDistanceKm != null ||
      hasContact ||
      minRating35 ||
      sortNearest;

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

  static const PlaceFilter empty = PlaceFilter();
}

// ═══════════════════════════════════════════════════════════════════
//  MAP SCREEN
// ═══════════════════════════════════════════════════════════════════
class MapScreen extends StatefulWidget {
  final TempatModel? focusedTempat;
  const MapScreen({super.key, this.focusedTempat});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _mapController = MapController();
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  // GPS
  LatLng? _userLocation;
  bool _loadingLocation = false;

  // Route & selection
  TempatModel? _selectedTempat;
  RouteResult? _routeResult;
  bool _loadingRoute = false;
  bool _showRoute = false;

  // Search + autocomplete
  String _searchQuery = '';
  List<TempatModel> _autocompleteItems = [];
  bool _showAutocomplete = false;

  // Filter
  PlaceFilter _filter = PlaceFilter.empty;

  // None mode — hide all markers
  bool _hideAllMarkers = false;

  // Map visual
  String _mapStyle = 'standard';
  bool _showHeatmap = false;
  bool _showKecamatan = false; // text labels for kecamatan

  static const LatLng _medanCenter = LatLng(3.5896654, 98.6738261);

  // ── Tile URL ─────────────────────────────────────────────────────
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

  // ── Filtered places (main list) ───────────────────────────────────
  List<TempatModel> get _filteredPlaces {
    if (_hideAllMarkers) return [];

    final tp = context.read<TempatProvider>();
    List<TempatModel> list = tp.allTempat
        .where((t) => t.latitude != null && t.longitude != null)
        .toList();

    // Text search
    final q = _searchQuery.toLowerCase().trim();
    if (q.isNotEmpty) {
      list = list.where((t) =>
          t.namaTempat.toLowerCase().contains(q) ||
          (t.jalan?.toLowerCase().contains(q) ?? false) ||
          (t.namaKategori?.toLowerCase().contains(q) ?? false) ||
          (t.namaKecamatan?.toLowerCase().contains(q) ?? false) ||
          (t.detailTempat?.toLowerCase().contains(q) ?? false)).toList();
    }

    // Kategori
    if (_filter.selectedKategoriIds.isNotEmpty) {
      list = list
          .where((t) => _filter.selectedKategoriIds.contains(t.kategoriId))
          .toList();
    }

    // Min rating 3.5
    if (_filter.minRating35) {
      list = list.where((t) => (t.reviewRating ?? 0) >= 3.5).toList();
    }

    // Has contact
    if (_filter.hasContact) {
      list = list
          .where((t) => t.kontak != null && t.kontak!.isNotEmpty)
          .toList();
    }

    // Max distance
    if (_filter.maxDistanceKm != null && _userLocation != null) {
      list = list.where((t) {
        final d = Haversine.distance(_userLocation!.latitude,
            _userLocation!.longitude, t.latitude!, t.longitude!);
        return d <= _filter.maxDistanceKm!;
      }).toList();
    }

    // Sort nearest
    if (_filter.sortNearest && _userLocation != null) {
      list.sort((a, b) {
        final da = Haversine.distance(_userLocation!.latitude,
            _userLocation!.longitude, a.latitude!, a.longitude!);
        final db = Haversine.distance(_userLocation!.latitude,
            _userLocation!.longitude, b.latitude!, b.longitude!);
        return da.compareTo(db);
      });
    } else if (_filter.sortByRating == 'highest') {
      list.sort((a, b) =>
          (b.reviewRating ?? 0).compareTo(a.reviewRating ?? 0));
    } else if (_filter.sortByRating == 'lowest') {
      list.sort((a, b) =>
          (a.reviewRating ?? 0).compareTo(b.reviewRating ?? 0));
    }

    return list;
  }

  // ── Kecamatan center labels ────────────────────────────────────────
  static const List<_KecLabel> _kecamatanLabels = [
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

  // ── Init ─────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    if (widget.focusedTempat != null) _selectedTempat = widget.focusedTempat;
    _getUserLocation();
    _focusAfterBuild();
    _searchCtrl.addListener(_onSearchChanged);
  }

  void _focusAfterBuild() {
    if (widget.focusedTempat?.latitude == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          _mapController.move(
            LatLng(widget.focusedTempat!.latitude!,
                widget.focusedTempat!.longitude!),
            15,
          );
        }
      });
    });
  }

  // ── Debounced search → autocomplete ───────────────────────────────
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
    _debounce = Timer(const Duration(milliseconds: 280), () {
      if (!mounted) return;
      setState(() {
        _searchQuery = q;
        _hideAllMarkers = false;
        final tp = context.read<TempatProvider>();
        _autocompleteItems = tp.allTempat
            .where((t) =>
                t.latitude != null &&
                t.longitude != null &&
                (t.namaTempat.toLowerCase().contains(q.toLowerCase()) ||
                    (t.jalan?.toLowerCase().contains(q.toLowerCase()) ??
                        false) ||
                    (t.namaKategori
                            ?.toLowerCase()
                            .contains(q.toLowerCase()) ??
                        false) ||
                    (t.namaKecamatan
                            ?.toLowerCase()
                            .contains(q.toLowerCase()) ??
                        false)))
            .take(10)
            .toList();
        _showAutocomplete = _autocompleteItems.isNotEmpty;
      });
    });
  }

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
    _mapController.move(LatLng(t.latitude!, t.longitude!), 16);
  }

  // ── GPS ──────────────────────────────────────────────────────────
  Future<void> _getUserLocation() async {
    setState(() => _loadingLocation = true);
    final pos = await LocationService.getCurrentPosition();
    if (pos != null && mounted) {
      setState(() => _userLocation = LatLng(pos.latitude, pos.longitude));
    }
    setState(() => _loadingLocation = false);
  }

  // ── Route ─────────────────────────────────────────────────────────
  Future<void> _fetchRoute() async {
    if (_userLocation == null || _selectedTempat?.latitude == null) {
      _snack('Aktifkan GPS untuk menampilkan rute');
      return;
    }
    setState(() {
      _loadingRoute = true;
      _showRoute = false;
      _routeResult = null;
    });

    final dest =
        LatLng(_selectedTempat!.latitude!, _selectedTempat!.longitude!);
    RouteResult? result = await RouteService.getRoute(_userLocation!, dest);
    result ??= RouteService.straightLine(_userLocation!, dest);

    if (!mounted) return;
    setState(() {
      _routeResult = result;
      _showRoute = true;
      _loadingRoute = false;
    });

    if (_routeResult != null && _routeResult!.points.length > 1) {
      final bounds = LatLngBounds.fromPoints(_routeResult!.points);
      _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(72)));
    }
    ErrorLogger.i('Route: ${result.distanceText}');
  }

  void _centerOnUser() {
    if (_userLocation != null) {
      _mapController.move(_userLocation!, 15);
    } else {
      _getUserLocation();
    }
  }

  void _openGoogleMaps() async {
    if (_selectedTempat?.latitude == null) return;
    final t = _selectedTempat!;
    final uri = _userLocation != null
        ? Uri.parse(
            'https://www.google.com/maps/dir/${_userLocation!.latitude},${_userLocation!.longitude}/${t.latitude},${t.longitude}')
        : Uri.parse(
            'https://www.google.com/maps/search/?api=1&query=${t.latitude},${t.longitude}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ── Image overlay ─────────────────────────────────────────────────
  void _showImageOverlay(String imageUrl) {
    if (imageUrl.isEmpty) return;
    showDialog(
      context: context,
      barrierColor: Colors.black,
      builder: (_) => _ImageOverlay(imageUrl: imageUrl),
    );
  }

  // ── Filter sheet ──────────────────────────────────────────────────
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

  // ── Clear all (None) ──────────────────────────────────────────────
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

  void _restoreMarkers() {
    setState(() => _hideAllMarkers = false);
  }

  String _vehicleEmoji() {
    final km = _routeResult?.distanceKm ?? 0;
    if (km < 0.5) return '🚶';
    if (km < 3) return '🛵';
    if (km < 10) return '🏍️';
    return '🚗';
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'Poppins')),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ════════════════════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final tp = context.watch<TempatProvider>();
    final places = _filteredPlaces;

    return Scaffold(
      body: Stack(
        children: [
          // ── FLUTTER MAP ─────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.focusedTempat?.latitude != null
                  ? LatLng(widget.focusedTempat!.latitude!,
                      widget.focusedTempat!.longitude!)
                  : _medanCenter,
               initialZoom: 12,
              minZoom: 8,
              maxZoom: 18,
              onTap: (_, __) => setState(() {
                _selectedTempat = null;
                _showRoute = false;
                _routeResult = null;
                _showAutocomplete = false;
              }),
            ),
            children: [
              // Tile
              TileLayer(
                urlTemplate: _tileUrl,
                subdomains: _mapStyle == 'dark' ? ['a', 'b', 'c'] : [],
                userAgentPackageName: 'com.danlens.app',
              ),

              // Heatmap
              HeatmapLayer(places: places, visible: _showHeatmap),

              // Kecamatan text labels
              if (_showKecamatan)
                MarkerLayer(
                  markers: _kecamatanLabels
                      .map((k) => Marker(
                            point: LatLng(k.lat, k.lng),
                            width: 90,
                            height: 28,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primaryDark.withValues(alpha:0.75),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                k.name,
                                style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 8,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ))
                      .toList(),
                ),

              // Route polyline (animated)
              if (_showRoute && _routeResult != null)
                AnimatedRouteLayer(
                  points: _routeResult!.points,
                  color: const Color(0xFF2196F3),
                  strokeWidth: 5,
                ),

              // Moving vehicle
              if (_showRoute && _routeResult != null)
                MovingMarkerLayer(
                  points: _routeResult!.points,
                  emoji: _vehicleEmoji(),
                ),

              // Destination pulse
              if (_showRoute && _selectedTempat?.latitude != null)
                PulsingDestinationMarker(
                  point: LatLng(_selectedTempat!.latitude!,
                      _selectedTempat!.longitude!),
                ),

              // User location radius
              if (_userLocation != null)
                CircleLayer(circles: [
                  CircleMarker(
                    point: _userLocation!,
                    radius: 60,
                    useRadiusInMeter: true,
                    color: AppColors.primary.withValues(alpha:0.10),
                    borderColor: AppColors.primary.withValues(alpha:0.35),
                    borderStrokeWidth: 1.5,
                  ),
                ]),

              // Cluster markers
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
                            border:
                                Border.all(color: Colors.white, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                  color: AppColors.primary.withValues(alpha:0.5),
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
                              });
                              _mapController.move(
                                  LatLng(t.latitude!, t.longitude!), 16);
                            },
                            child: _PlaceMarker(
                              tempat: t,
                              isSelected: _selectedTempat?.id == t.id,
                            ),
                          ),
                        )),
                  ],
                  builder: (ctx, markers) => Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.primary.withValues(alpha:0.4),
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

          // ── TOP CONTROLS (SafeArea wrapper) ──────────────────
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: back + search + filter button
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Row(
                    children: [
                      if (Navigator.canPop(context)) ...[
                        _MapBtn(
                          icon: Icons.arrow_back_rounded,
                          onTap: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 8),
                      ],

                      // Search field
                      Expanded(
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha:0.08),
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
                              if (tp.realtimeConnected &&
                                  _searchQuery.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                        color: AppColors.success,
                                        shape: BoxShape.circle),
                                  ).animate().fade().scale(),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Filter button + badge
                      GestureDetector(
                        onTap: () => _openFilterSheet(tp.kategori),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: _filter.isActive
                                    ? AppColors.primary
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withValues(alpha:0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2))
                                ],
                              ),
                              child: Icon(Icons.tune_rounded,
                                  color: _filter.isActive
                                      ? Colors.white
                                      : AppColors.textDark,
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
                                      color: Colors.redAccent,
                                      shape: BoxShape.circle),
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

                // ── AUTOCOMPLETE DROPDOWN ──────────────────────
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

                // Row 2: count + None button + reset filter
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      // Count chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha:0.06),
                                blurRadius: 6)
                          ],
                        ),
                        child: Text('${places.length} lokasi',
                            style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textDark)),
                      ),
                      const SizedBox(width: 8),

                      // None / Restore button
                      GestureDetector(
                        onTap: _hideAllMarkers ? _restoreMarkers : _clearAll,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _hideAllMarkers
                                ? AppColors.primary.withValues(alpha:0.1)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _hideAllMarkers
                                  ? AppColors.primary
                                  : AppColors.surface,
                            ),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha:0.06),
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
                          onTap: () =>
                              setState(() => _filter = PlaceFilter.empty),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha:0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: AppColors.error.withValues(alpha:0.3)),
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

                // Row 3: category quick strip
                _CategoryStrip(
                  kategori: tp.kategori,
                  selectedIds: _filter.selectedKategoriIds,
                  onToggle: (id) {
                    final ids =
                        List<int>.from(_filter.selectedKategoriIds);
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
            ),
          ),

          // ── RIGHT SIDE BUTTONS ────────────────────────────────
          Positioned(
            right: 12,
            bottom: _selectedTempat != null ? 340 : 100,
            child: Column(
              children: [
                _MapBtn(
                    icon: Icons.my_location_rounded,
                    onTap: _centerOnUser,
                    loading: _loadingLocation,
                    color: AppColors.primary),
                const SizedBox(height: 8),
                _MapBtn(
                    icon: Icons.layers_rounded,
                    onTap: () => setState(() {
                          const s = ['standard', 'dark', 'satellite'];
                          final i = s.indexOf(_mapStyle);
                          _mapStyle = s[(i + 1) % s.length];
                        })),
                const SizedBox(height: 8),
                _MapBtn(
                    icon: Icons.add_rounded,
                    onTap: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1)),
                const SizedBox(height: 8),
                _MapBtn(
                    icon: Icons.remove_rounded,
                    onTap: () =>  _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1)),
                const SizedBox(height: 8),
                // Heatmap toggle
                _OverlayBtn(
                  label: '🔥',
                  tooltip: 'Heatmap',
                  active: _showHeatmap,
                  onTap: () =>
                      setState(() => _showHeatmap = !_showHeatmap),
                ),
                const SizedBox(height: 6),
                // Kecamatan text labels toggle
                _OverlayBtn(
                  label: '🗾',
                  tooltip: 'Kecamatan',
                  active: _showKecamatan,
                  onTap: () =>
                      setState(() => _showKecamatan = !_showKecamatan),
                ),
              ],
            ),
          ),

          // ── ROUTE INFO BAR ────────────────────────────────────
          if (_showRoute && _routeResult != null)
            Positioned(
              top: 180,
              left: 12,
              right: 12,
              child: _RouteInfoBar(
                result: _routeResult!,
                transport: _vehicleEmoji(),
                onClose: () => setState(() {
                  _showRoute = false;
                  _routeResult = null;
                }),
                onGoogleMaps: _openGoogleMaps,
              ),
            ),

          // ── BOTTOM DETAIL SHEET ───────────────────────────────
          if (_selectedTempat != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _MapBottomSheet(
                tempat: _selectedTempat!,
                userLocation: _userLocation,
                loadingRoute: _loadingRoute,
                hasRoute: _showRoute,
                onClose: () => setState(() {
                  _selectedTempat = null;
                  _showRoute = false;
                  _routeResult = null;
                }),
                onRoute: _fetchRoute,
                onGoogleMaps: _openGoogleMaps,
                onImageTap: _showImageOverlay,
                onDetail: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          DetailScreen(tempat: _selectedTempat!)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    _mapController.dispose();
    super.dispose();
  }
}

// Helper data class for kecamatan labels
class _KecLabel {
  final String name;
  final double lat;
  final double lng;
  const _KecLabel(this.name, this.lat, this.lng);
}

// ═══════════════════════════════════════════════════════════════════
//  AUTOCOMPLETE DROPDOWN
// ═══════════════════════════════════════════════════════════════════
class _AutocompleteDropdown extends StatelessWidget {
  final List<TempatModel> items;
  final LatLng? userLocation;
  final Function(TempatModel) onTap;
  final Function(String) onImageTap;

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
              color: Colors.black.withValues(alpha:0.12),
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
          separatorBuilder: (_, __) =>
              const Divider(height: 1, color: AppColors.surface),
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
      distKm = Haversine.distance(userLocation!.latitude,
          userLocation!.longitude, tempat.latitude!, tempat.longitude!);
    }

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // Thumbnail — tappable for image overlay
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
                          placeholder: (_, __) =>
                              Container(color: AppColors.surface),
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

            // Info
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
                  Row(
                    children: [
                      Text('${tempat.categoryIcon} ',
                          style: const TextStyle(fontSize: 11)),
                      Expanded(
                        child: Text(
                            '${tempat.namaKategori ?? ''} · ${tempat.namaKecamatan ?? ''}',
                            style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                color: AppColors.textGray),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: Colors.amber, size: 12),
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
                                color: AppColors.primary)),
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
//  IMAGE OVERLAY (fullscreen PhotoView)
// ═══════════════════════════════════════════════════════════════════
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
        title: const Text(
          'Gambar Tempat',
          style: TextStyle(
              fontFamily: 'Poppins',
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_in_rounded, color: Colors.white70),
            onPressed: () {},
            tooltip: 'Pinch untuk zoom',
          ),
        ],
      ),
      body: PhotoView(
        imageProvider: CachedNetworkImageProvider(imageUrl),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 4,
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        heroAttributes: PhotoViewHeroAttributes(tag: 'map_img_$imageUrl'),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  FILTER SHEET (full-featured)
// ═══════════════════════════════════════════════════════════════════
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

  void _reset() => setState(() {
        _katIds = [];
        _sortRating = null;
        _openNow = false;
        _maxDist = null;
        _hasContact = false;
        _minRating35 = false;
        _sortNearest = false;
      });

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

  int get _activeCount {
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
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(4)),
            ),
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
                  if (_activeCount > 0)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha:0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('$_activeCount aktif',
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
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                children: [
                  // Kategori
                  const _FLabel('📂 Kategori'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FChip(
                          label: 'Semua',
                          selected: _katIds.isEmpty,
                          onTap: () => setState(() => _katIds = [])),
                      ...widget.kategori.map((k) {
                        final sel = _katIds.contains(k.id);
                        return _FChip(
                          label: '${k.icon} ${k.namaKategori}',
                          selected: sel,
                          onTap: () => setState(() {
                            sel
                                ? _katIds.remove(k.id)
                                : _katIds.add(k.id);
                          }),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Divider(color: AppColors.surface),

                  // Urutan
                  const _FLabel('📊 Urutan'),
                  const SizedBox(height: 10),
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
                                    : () => setState(() => _sortRating =
                                        _sortRating == 'highest'
                                            ? null
                                            : 'highest')),
                            const SizedBox(width: 8),
                            _FSeg(
                                label: '📉 Terendah',
                                selected: _sortRating == 'lowest',
                                onTap: _sortNearest
                                    ? null
                                    : () => setState(() => _sortRating =
                                        _sortRating == 'lowest'
                                            ? null
                                            : 'lowest')),
                            const SizedBox(width: 8),
                            _FSeg(
                                label: 'Default',
                                selected: _sortRating == null && !_sortNearest,
                                onTap: _sortNearest
                                    ? null
                                    : () => setState(() => _sortRating = null)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Divider(color: AppColors.surface),

                  // Jarak Maksimal
                  const _FLabel('📏 Jarak Maksimal dari Saya'),
                  const SizedBox(height: 8),
                  if (!hasGps)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha:0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.warning.withValues(alpha:0.3)),
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
                        overlayColor: AppColors.primary.withValues(alpha:0.15),
                        trackHeight: 4,
                      ),
                      child: Slider(
                        value: _maxDist ?? 0.5,
                        min: 0.5,
                        max: 20,
                        divisions: 39,
                        label:
                            '${(_maxDist ?? 0.5).toStringAsFixed(1)} km',
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

                  // Opsi Lain
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
                    subtitle: 'Hanya tampilkan tempat berkualitas',
                    value: _minRating35,
                    onChanged: (v) => setState(() => _minRating35 = v),
                  ),
                  const SizedBox(height: 6),
                  _FToggle(
                    icon: '🕐',
                    label: 'Buka Sekarang',
                    subtitle: 'Segera tersedia (data jam belum ada)',
                    value: _openNow,
                    enabled: false,
                    onChanged: (v) => setState(() => _openNow = v),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16,
                  MediaQuery.of(context).padding.bottom + 12),
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
                  child: Text(_activeCount > 0
                      ? 'Terapkan Filter ($_activeCount aktif)'
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

// FilterSheet sub-widgets
class _FLabel extends StatelessWidget {
  final String text;
  const _FLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(text,
            style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.textDark)),
      );
}

class _FChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.surface,
              width: 1.5),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: AppColors.primary.withValues(alpha:0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2))
                ]
              : [],
        ),
        child: Text(label,
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? Colors.white : AppColors.textGray)),
      ),
    );
  }
}

class _FSeg extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  const _FSeg(
      {required this.label, required this.selected, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: selected
                    ? AppColors.primary
                    : AppColors.surface,
                width: 1.5),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected
                      ? Colors.white
                      : AppColors.textGray)),
        ),
      ),
    );
  }
}

class _FToggle extends StatelessWidget {
  final String icon;
  final String label;
  final String subtitle;
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
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
}

// ═══════════════════════════════════════════════════════════════════
//  CATEGORY STRIP (multi-select)
// ═══════════════════════════════════════════════════════════════════
class _CategoryStrip extends StatelessWidget {
  final List<KategoriModel> kategori;
  final List<int> selectedIds;
  final Function(int?) onToggle;

  const _CategoryStrip({
    required this.kategori,
    required this.selectedIds,
    required this.onToggle,
  });

  Widget _chip(String label, bool sel, VoidCallback tap) {
    return GestureDetector(
      onTap: tap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 6),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: sel ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha:0.06), blurRadius: 6)
          ],
        ),
        child: Text(label,
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: sel ? Colors.white : AppColors.textGray)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: kategori.length + 1,
        itemBuilder: (_, i) {
          if (i == 0) {
            return _chip(
                'Semua', selectedIds.isEmpty, () => onToggle(null));
          }
          final k = kategori[i - 1];
          return _chip('${k.icon} ${k.namaKategori}',
              selectedIds.contains(k.id), () => onToggle(k.id));
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  OVERLAY TOGGLE BUTTON (Heatmap / Kecamatan)
// ═══════════════════════════════════════════════════════════════════
class _OverlayBtn extends StatelessWidget {
  final String label;
  final String tooltip;
  final bool active;
  final VoidCallback onTap;

  const _OverlayBtn({
    required this.label,
    required this.tooltip,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: active
                ? AppColors.primary.withValues(alpha:0.15)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: active
                    ? AppColors.primary.withValues(alpha:0.5)
                    : Colors.transparent),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha:0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ],
          ),
          child:
              Center(child: Text(label, style: const TextStyle(fontSize: 18))),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  PLACE MARKER
// ═══════════════════════════════════════════════════════════════════
class _PlaceMarker extends StatelessWidget {
  final TempatModel tempat;
  final bool isSelected;
  const _PlaceMarker({required this.tempat, required this.isSelected});

  Color get _color {
    switch (tempat.namaKategori?.toLowerCase()) {
      case 'kuliner': return const Color(0xFFFF6B35);
      case 'wisata': return const Color(0xFF4ECDC4);
      case 'kesehatan': return const Color(0xFFFF4757);
      case 'kemasyarakatan': return const Color(0xFF5352ED);
      case 'transportasi': return const Color(0xFF2ED573);
      default: return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
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
                    color: _color.withValues(alpha:0.5),
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
}

class _Arrow extends CustomPainter {
  final Color color;
  const _Arrow({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
        ui.Path()
        ..moveTo(0, 0)
        ..lineTo(size.width / 2, size.height)
        ..lineTo(size.width, 0)
        ..close(),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

// ═══════════════════════════════════════════════════════════════════
//  MAP BUTTON
// ═══════════════════════════════════════════════════════════════════
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
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha:0.1),
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
}

// ═══════════════════════════════════════════════════════════════════
//  ROUTE INFO BAR
// ═══════════════════════════════════════════════════════════════════
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
              color: Colors.black.withValues(alpha:0.2),
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
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha:0.2),
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
                  color: Colors.white70, size: 18)),
        ],
      ),
    ).animate().slideY(begin: -0.5, end: 0, duration: 300.ms);
  }
}

// ═══════════════════════════════════════════════════════════════════
//  BOTTOM DETAIL SHEET (with onImageTap)
// ═══════════════════════════════════════════════════════════════════
class _MapBottomSheet extends StatelessWidget {
  final TempatModel tempat;
  final LatLng? userLocation;
  final bool loadingRoute;
  final bool hasRoute;
  final VoidCallback onClose;
  final VoidCallback onRoute;
  final VoidCallback onGoogleMaps;
  final VoidCallback onDetail;
  final Function(String) onImageTap;

  const _MapBottomSheet({
    required this.tempat,
    required this.userLocation,
    required this.loadingRoute,
    required this.hasRoute,
    required this.onClose,
    required this.onRoute,
    required this.onGoogleMaps,
    required this.onDetail,
    required this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    double? distKm;
    if (userLocation != null && tempat.latitude != null) {
      distKm = Haversine.distance(userLocation!.latitude,
          userLocation!.longitude, tempat.latitude!, tempat.longitude!);
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
              color: Colors.black12,
              blurRadius: 20,
              offset: Offset(0, -4))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 4),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(4)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail — tappable → image overlay
                GestureDetector(
                  onTap: tempat.imageUrl.isNotEmpty
                      ? () => onImageTap(tempat.imageUrl)
                      : null,
                  child: Hero(
                    tag: 'map_img_${tempat.imageUrl}',
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
                                    placeholder: (_, __) => Container(
                                        color: AppColors.surface),
                                    errorWidget: (_, __, ___) =>
                                        Container(
                                            color: AppColors.surface,
                                            child: Center(
                                                child: Text(
                                                    tempat.categoryIcon,
                                                    style: const TextStyle(
                                                        fontSize: 28)))))
                                : Container(
                                    color: AppColors.surface,
                                    child: Center(
                                        child: Text(tempat.categoryIcon,
                                            style: const TextStyle(
                                                fontSize: 28)))),
                            // Zoom hint overlay
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

                // Info
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
                      const SizedBox(height: 5),
                      Row(children: [
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
                                  color: AppColors.primary)),
                        ],
                      ]),
                    ],
                  ),
                ),
                IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.textGray, size: 20),
                    onPressed: onClose),
              ],
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            child: Row(
              children: [
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
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: loadingRoute ? null : onRoute,
                    icon: loadingRoute
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Icon(
                            hasRoute
                                ? Icons.refresh_rounded
                                : Icons.directions_rounded,
                            size: 16),
                    label: Text(loadingRoute
                        ? 'Mencari...'
                        : hasRoute
                            ? 'Perbarui Rute'
                            : '🔵 Tunjukkan Rute'),
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
              ],
            ),
          ),
        ],
      ),
    ).animate().slideY(
        begin: 1, end: 0, duration: 300.ms, curve: Curves.easeOutCubic);
  }
}