// FILE: lib/widgets/animated_route.dart
// File ini berisi widget untuk animasi rute (polyline bergerak), marker kendaraan yang bergerak,
// serta marker titik tujuan yang berdenyut (pulsing).
// Fungsi: Memberikan efek visual yang menarik pada rute yang ditampilkan di peta.
// Informasi penting: Digunakan bersama flutter_map. AnimatedRouteLayer menggambar polyline secara bertahap.
// MovingMarkerLayer menampilkan emoji kendaraan yang bergerak di sepanjang rute.
// PulsingDestinationMarker menampilkan lingkaran berdenyut di titik tujuan.

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../config/app_theme.dart';

// Kelas untuk menampilkan polyline (garis rute) dengan animasi menggambar dari awal hingga akhir.
class AnimatedRouteLayer extends StatefulWidget {
  // Titik-titik koordinat yang membentuk rute.
  final List<LatLng> points;
  // Warna polyline.
  final Color color;
  // Ketebalan garis.
  final double strokeWidth;

  const AnimatedRouteLayer({
    super.key,
    required this.points,
    this.color = const Color(0xFF2196F3), // Warna biru default.
    this.strokeWidth = 5.0,
  });

  @override
  State<AnimatedRouteLayer> createState() => _AnimatedRouteLayerState();
}

// State untuk AnimatedRouteLayer.
class _AnimatedRouteLayerState extends State<AnimatedRouteLayer>
    with SingleTickerProviderStateMixin {
  // Controller animasi.
  late AnimationController _ctrl;
  // Progress animasi (nilai 0.0 hingga 1.0).
  late Animation<double> _progress;
  // Bagian polyline yang sudah terlihat (berdasarkan progress).
  List<LatLng> _visible = [];

  @override
  void initState() {
    super.initState();
    // Inisialisasi controller dengan durasi 1500 milidetik.
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    // Gunakan kurva easing in-out.
    _progress = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    // Setiap nilai progress berubah, update polyline yang terlihat.
    _progress.addListener(_updateVisible);
    // Mulai animasi.
    _ctrl.forward();
  }

  // Dipanggil jika widget diupdate dengan data baru (misal rute berubah).
  @override
  void didUpdateWidget(AnimatedRouteLayer old) {
    super.didUpdateWidget(old);
    // Jika titik-titik rute berbeda, reset animasi dan mainkan ulang.
    if (old.points != widget.points) {
      _ctrl.reset();
      _ctrl.forward();
    }
  }

  // Menentukan bagian polyline yang harus ditampilkan berdasarkan progress animasi.
  void _updateVisible() {
    // Jika widget tidak aktif atau tidak ada titik, berhenti.
    if (!mounted || widget.points.isEmpty) return;
    final total = widget.points.length;
    // Jumlah titik yang harus ditampilkan = total titik * progress, minimal 1.
    final count = (total * _progress.value).ceil().clamp(1, total);
    setState(() => _visible = widget.points.sublist(0, count));
  }

  @override
  Widget build(BuildContext context) {
    // Jika belum ada titik yang terlihat, kembalikan widget kosong.
    if (_visible.isEmpty) return const SizedBox.shrink();
    return PolylineLayer(
      polylines: [
        // Garis bayangan (shadow) di bawah garis utama, lebih tebal dan transparan.
        Polyline(
          points: _visible,
          strokeWidth: widget.strokeWidth + 3,
          color: Colors.black.withValues(alpha: 0.15),
        ),
        // Garis utama polyline.
        Polyline(
          points: _visible,
          strokeWidth: widget.strokeWidth,
          color: widget.color,
          strokeCap: StrokeCap.round, // Ujung garis membulat.
          strokeJoin: StrokeJoin.round, // Sambungan garis membulat.
        ),
        // Sorotan (highlight) di ujung garis yang sedang digambar (hanya jika animasi belum selesai).
        if (_progress.value < 1.0)
          Polyline(
            points: _visible.length > 1
                ? [
                    _visible[_visible.length - 2], // Titik sebelum terakhir.
                    _visible.last, // Titik terakhir.
                  ]
                : _visible,
            strokeWidth: widget.strokeWidth + 2,
            color: Colors.white.withValues(alpha: 0.6),
            strokeCap: StrokeCap.round,
          ),
      ],
    );
  }

  @override
  void dispose() {
    // Bersihkan controller saat widget dihancurkan.
    _ctrl.dispose();
    super.dispose();
  }
}

// Kelas untuk menampilkan marker kendaraan yang bergerak di sepanjang rute.
class MovingMarkerLayer extends StatefulWidget {
  final List<LatLng> points; // Titik-titik rute.
  final String emoji; // Emoji kendaraan (default 🏍️).

  const MovingMarkerLayer({
    super.key,
    required this.points,
    this.emoji = '🏍️',
  });

  @override
  State<MovingMarkerLayer> createState() => _MovingMarkerLayerState();
}

class _MovingMarkerLayerState extends State<MovingMarkerLayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  LatLng? _current; // Posisi kendaraan saat ini.

  @override
  void initState() {
    super.initState();
    // Controller dengan durasi 2200 milidetik (satu putaran penuh).
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    // Setiap nilai animasi berubah, update posisi.
    _ctrl.addListener(_update);
    // Mulai animasi.
    _ctrl.forward();
  }

  // Jika widget diupdate dengan rute baru, reset animasi.
  @override
  void didUpdateWidget(MovingMarkerLayer old) {
    super.didUpdateWidget(old);
    if (old.points != widget.points) {
      _ctrl.reset();
      _ctrl.forward();
    }
  }

  // Menghitung posisi kendaraan berdasarkan progress animasi.
  void _update() {
    if (!mounted || widget.points.length < 2) return;
    final t = _ctrl.value; // Nilai progress (0..1).
    final total = widget.points.length - 1; // Jumlah segmen.
    // Indeks segmen saat ini.
    final idx = (t * total).floor().clamp(0, total - 1);
    // Posisi lokal di dalam segmen (0..1).
    final localT = (t * total) - idx;
    final a = widget.points[idx]; // Titik awal segmen.
    final b = widget.points[idx + 1]; // Titik akhir segmen.
    // Interpolasi linear antara a dan b.
    setState(() => _current = LatLng(
          a.latitude + (b.latitude - a.latitude) * localT,
          a.longitude + (b.longitude - a.longitude) * localT,
        ));
  }

  @override
  Widget build(BuildContext context) {
    if (_current == null) return const SizedBox.shrink();
    return MarkerLayer(
      markers: [
        Marker(
          point: _current!,
          width: 36,
          height: 36,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Center(
              child: Text(widget.emoji,
                  style: const TextStyle(fontSize: 18)),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
}

// Kelas untuk menampilkan marker titik tujuan dengan efek berdenyut (pulsing).
class PulsingDestinationMarker extends StatefulWidget {
  final LatLng point; // Koordinat tujuan.
  final Color color; // Warna marker (default hijau primary).

  const PulsingDestinationMarker({
    super.key,
    required this.point,
    this.color = AppColors.primary,
  });

  @override
  State<PulsingDestinationMarker> createState() =>
      _PulsingDestinationMarkerState();
}

class _PulsingDestinationMarkerState extends State<PulsingDestinationMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale; // Skala lingkaran luar.
  late Animation<double> _opacity; // Opasitas lingkaran luar.

  @override
  void initState() {
    super.initState();
    // Controller berulang (repeat) dengan durasi 1200 milidetik.
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: false); // Ulang terus.
    // Skala dari 0.8 ke 2.0 dengan kurva ease-out.
    _scale = Tween<double>(begin: 0.8, end: 2.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    // Opasitas dari 0.6 ke 0.0.
    _opacity = Tween<double>(begin: 0.6, end: 0.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  Widget build(BuildContext context) {
    return CircleLayer(
      circles: [
        // Lingkaran dalam (statis) berwarna solid.
        CircleMarker(
          point: widget.point,
          radius: 12,
          color: widget.color.withValues(alpha: 0.9),
          borderColor: Colors.white,
          borderStrokeWidth: 2.5,
          useRadiusInMeter: false,
        ),
        // Lingkaran luar yang berdenyut (skala dan opasitas berubah).
        CircleMarker(
          point: widget.point,
          radius: 12 * _scale.value,
          color: widget.color.withValues(alpha: _opacity.value),
          borderColor: Colors.transparent,
          useRadiusInMeter: false,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
}