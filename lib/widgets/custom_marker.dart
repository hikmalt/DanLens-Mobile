// C:\Users\hikma\Desktop\DanLens\danlens\lib\widgets\custom_marker.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_theme.dart';
import '../models/models.dart';

class CustomMarker extends StatelessWidget {
  final TempatModel tempat;
  final bool isSelected;
  final VoidCallback? onTap;

  const CustomMarker({
    super.key,
    required this.tempat,
    this.isSelected = false,
    this.onTap,
  });

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
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: isSelected ? 1.2 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Circle marker body
            Container(
              width: isSelected ? 44 : 36,
              height: isSelected ? 44 : 36,
              decoration: BoxDecoration(
                color: _color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: isSelected ? 3 : 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _color.withValues(alpha: 0.5),
                    blurRadius: isSelected ? 12 : 6,
                    spreadRadius: isSelected ? 2 : 0,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  tempat.categoryIcon,
                  style: TextStyle(fontSize: isSelected ? 18 : 14),
                ),
              ),
            ),
            // Pointer / arrow
            CustomPaint(
              size: const Size(10, 6),
              painter: _MarkerPointerPainter(color: _color),
            ),
          ],
        ).animate().fade(duration: 300.ms).slideY(begin: 0.3, end: 0),
      ),
    );
  }
}

class _MarkerPointerPainter extends CustomPainter {
  final Color color;
  const _MarkerPointerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}