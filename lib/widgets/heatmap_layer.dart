// lib/widgets/heatmap_layer.dart
// Heatmap visual effect using circle overlays (no extra package needed)
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/models.dart';
import '../config/app_theme.dart';

/// Simple heatmap using translucent circles at each place location.
/// Higher rated / more popular = larger + more opaque circle.
class HeatmapLayer extends StatelessWidget {
  final List<TempatModel> places;
  final bool visible;

  const HeatmapLayer({
    super.key,
    required this.places,
    this.visible = true,
  });

  Color _heatColor(double rating) {
    if (rating >= 4.5) return const Color(0xFFFF1744); // hot red
    if (rating >= 4.0) return const Color(0xFFFF6D00); // orange
    if (rating >= 3.5) return const Color(0xFFFFD600); // yellow
    return const Color(0xFF00E5FF);                     // cool blue
  }

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    final circles = places
        .where((t) => t.latitude != null && t.longitude != null)
        .map((t) {
      final rating = t.reviewRating ?? 3.0;
      final radius = 150 + (rating * 60); // 330m–450m based on rating
      return CircleMarker(
        point: LatLng(t.latitude!, t.longitude!),
        radius: radius,
        useRadiusInMeter: true,
        color: _heatColor(rating).withValues(alpha:0.18),
        borderColor: _heatColor(rating).withValues(alpha:0.08),
        borderStrokeWidth: 1,
      );
    }).toList();

    return CircleLayer(circles: circles);
  }
}

/// Kecamatan polygon boundaries (simplified convex hulls)
/// Points approximate untuk kecamatan Medan utama
class KecamatanPolygonLayer extends StatelessWidget {
  final bool visible;

  const KecamatanPolygonLayer({super.key, this.visible = true});

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    return PolygonLayer(
      polygons: _kecamatanPolygons,
    );
  }

  static final List<Polygon> _kecamatanPolygons = [
    // Medan Kota (approximate)
    Polygon(
      points: [
        const LatLng(3.577, 98.672),
        const LatLng(3.592, 98.672),
        const LatLng(3.592, 98.690),
        const LatLng(3.577, 98.690),
      ],
      color: AppColors.primary.withValues(alpha:0.06),
      borderColor: AppColors.primary.withValues(alpha:0.25),
      borderStrokeWidth: 1.5,
      label: 'Medan Kota',
      labelStyle: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 9,
        color: AppColors.primaryDark,
        fontWeight: FontWeight.w600,
      ),
    ),
    // Medan Baru (approximate)
    Polygon(
      points: [
        const LatLng(3.557, 98.655),
        const LatLng(3.572, 98.655),
        const LatLng(3.572, 98.672),
        const LatLng(3.557, 98.672),
      ],
      color: AppColors.primaryDark.withValues(alpha:0.05),
      borderColor: AppColors.primaryDark.withValues(alpha:0.2),
      borderStrokeWidth: 1.5,
      label: 'Medan Baru',
      labelStyle: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 9,
        color: AppColors.primaryDark,
        fontWeight: FontWeight.w600,
      ),
    ),
    // Medan Petisah (approximate)
    Polygon(
      points: [
        const LatLng(3.590, 98.645),
        const LatLng(3.605, 98.645),
        const LatLng(3.605, 98.660),
        const LatLng(3.590, 98.660),
      ],
      color: const Color(0xFF5352ED).withValues(alpha:0.05),
      borderColor: const Color(0xFF5352ED).withValues(alpha:0.2),
      borderStrokeWidth: 1.5,
      label: 'Medan Petisah',
      labelStyle: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 9,
        color: Color(0xFF5352ED),
        fontWeight: FontWeight.w600,
      ),
    ),
    // Medan Maimun (approximate)
    Polygon(
      points: [
        const LatLng(3.570, 98.675),
        const LatLng(3.582, 98.675),
        const LatLng(3.582, 98.692),
        const LatLng(3.570, 98.692),
      ],
      color: const Color(0xFFFF6B35).withValues(alpha:0.05),
      borderColor: const Color(0xFFFF6B35).withValues(alpha:0.2),
      borderStrokeWidth: 1.5,
      label: 'Medan Maimun',
      labelStyle: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 9,
        color: Color(0xFFFF6B35),
        fontWeight: FontWeight.w600,
      ),
    ),
  ];
}

/// Toggle button for map overlays (heatmap / polygon)
class MapOverlayToggle extends StatelessWidget {
  final bool heatmapVisible;
  final bool polygonVisible;
  final VoidCallback onToggleHeatmap;
  final VoidCallback onTogglePolygon;

  const MapOverlayToggle({
    super.key,
    required this.heatmapVisible,
    required this.polygonVisible,
    required this.onToggleHeatmap,
    required this.onTogglePolygon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha:0.1),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleBtn(
            label: '🔥',
            tooltip: 'Heatmap',
            active: heatmapVisible,
            onTap: onToggleHeatmap,
          ),
          const SizedBox(height: 4),
          _ToggleBtn(
            label: '🗾',
            tooltip: 'Wilayah',
            active: polygonVisible,
            onTap: onTogglePolygon,
          ),
        ],
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final String tooltip;
  final bool active;
  final VoidCallback onTap;

  const _ToggleBtn({
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
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: active
                ? AppColors.primary.withValues(alpha:0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: active
                  ? AppColors.primary.withValues(alpha:0.4)
                  : Colors.transparent,
            ),
          ),
          child: Center(
            child: Text(label, style: const TextStyle(fontSize: 16)),
          ),
        ),
      ),
    );
  }
}