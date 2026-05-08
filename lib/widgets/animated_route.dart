// lib/widgets/animated_route.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../config/app_theme.dart';

/// Animated polyline that "draws" itself from start to end
class AnimatedRouteLayer extends StatefulWidget {
  final List<LatLng> points;
  final Color color;
  final double strokeWidth;

  const AnimatedRouteLayer({
    super.key,
    required this.points,
    this.color = const Color(0xFF2196F3),
    this.strokeWidth = 5.0,
  });

  @override
  State<AnimatedRouteLayer> createState() => _AnimatedRouteLayerState();
}

class _AnimatedRouteLayerState extends State<AnimatedRouteLayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _progress;
  List<LatLng> _visible = [];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _progress = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    _progress.addListener(_updateVisible);
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(AnimatedRouteLayer old) {
    super.didUpdateWidget(old);
    if (old.points != widget.points) {
      _ctrl.reset();
      _ctrl.forward();
    }
  }

  void _updateVisible() {
    if (!mounted || widget.points.isEmpty) return;
    final total = widget.points.length;
    final count = (total * _progress.value).ceil().clamp(1, total);
    setState(() => _visible = widget.points.sublist(0, count));
  }

  @override
  Widget build(BuildContext context) {
    if (_visible.isEmpty) return const SizedBox.shrink();
    return PolylineLayer(
      polylines: [
        // Shadow line
        Polyline(
          points: _visible,
          strokeWidth: widget.strokeWidth + 3,
          color: Colors.black.withValues(alpha:0.15),
        ),
        // Main line
        Polyline(
          points: _visible,
          strokeWidth: widget.strokeWidth,
          color: widget.color,
          strokeCap: StrokeCap.round,
          strokeJoin: StrokeJoin.round,
        ),
        // Animated dash overlay (highlight)
        if (_progress.value < 1.0)
          Polyline(
            points: _visible.length > 1
                ? [
                    _visible[_visible.length - 2],
                    _visible.last,
                  ]
                : _visible,
            strokeWidth: widget.strokeWidth + 2,
            color: Colors.white.withValues(alpha:0.6),
            strokeCap: StrokeCap.round,
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

/// Moving vehicle icon along the route
class MovingMarkerLayer extends StatefulWidget {
  final List<LatLng> points;
  final String emoji;

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
  LatLng? _current;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _ctrl.addListener(_update);
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(MovingMarkerLayer old) {
    super.didUpdateWidget(old);
    if (old.points != widget.points) {
      _ctrl.reset();
      _ctrl.forward();
    }
  }

  void _update() {
    if (!mounted || widget.points.length < 2) return;
    final t = _ctrl.value;
    final total = widget.points.length - 1;
    final idx = (t * total).floor().clamp(0, total - 1);
    final localT = (t * total) - idx;
    final a = widget.points[idx];
    final b = widget.points[idx + 1];
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
                  color: Colors.black.withValues(alpha:0.2),
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

/// Pulsing destination marker
class PulsingDestinationMarker extends StatefulWidget {
  final LatLng point;
  final Color color;

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
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: false);
    _scale = Tween<double>(begin: 0.8, end: 2.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _opacity = Tween<double>(begin: 0.6, end: 0.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  //@override
  //Widget build(BuildContext context) {
    //return CircleLayer(
      //circles: [
        // Static inner
        //CircleMarker(
          //point: widget.point,
          //radius: 12,
          //color: widget.color.withValues(alpha:0.9),
          //borderColor: Colors.white,
          //borderStrokeWidth: 2.5,
          //useRadiusInMeter: false,
        //),
      //],
    //);
  //}

@override
Widget build(BuildContext context) {
  return CircleLayer(
    circles: [
      // Static inner
      CircleMarker(
        point: widget.point,
        radius: 12,
        color: widget.color.withValues(alpha: 0.9),
        borderColor: Colors.white,
        borderStrokeWidth: 2.5,
        useRadiusInMeter: false,
      ),
      // Pulsing outer (menggunakan _scale dan _opacity agar tidak unused)
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