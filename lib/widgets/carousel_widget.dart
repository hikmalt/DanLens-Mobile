// lib/widgets/carousel_widget.dart
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_theme.dart';
import '../models/models.dart';
import '../screens/detail/detail_screen.dart';
import 'skeleton_loader.dart';

class HomeCarousel extends StatefulWidget {
  final List<TempatModel> items;
  final bool isLoading;

  const HomeCarousel({super.key, required this.items, this.isLoading = false});

  @override
  State<HomeCarousel> createState() => _HomeCarouselState();
}

class _HomeCarouselState extends State<HomeCarousel> {
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) return const CarouselSkeleton();

    if (widget.items.isEmpty) {
      return Container(
        height: 200,
        color: AppColors.surface,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.image_not_supported_outlined,
                  color: AppColors.textGray, size: 40),
              SizedBox(height: 8),
              Text('Belum ada gambar',
                  style: TextStyle(fontFamily: 'Poppins', color: AppColors.textGray)),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: widget.items.length,
          options: CarouselOptions(
            height: 210,
            viewportFraction: 1.0,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 4),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            autoPlayCurve: Curves.easeInOutCubic,
            onPageChanged: (index, _) => setState(() => _current = index),
          ),
          itemBuilder: (context, index, realIndex) {
            final item = widget.items[index];
            return GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => DetailScreen(tempat: item))),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background image
                  item.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: item.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              Container(color: AppColors.surface),
                          errorWidget: (_, __, ___) =>
                              Container(color: AppColors.surface,
                                  child: const Icon(Icons.image_outlined,
                                      color: AppColors.textGray, size: 48)),
                        )
                      : Container(color: AppColors.surface),

                  // Gradient overlay
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Color(0x44000000),
                          Color(0xCC000000),
                        ],
                        stops: [0.4, 0.6, 1.0],
                      ),
                    ),
                  ),

                  // Text info
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha:0.85),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${item.categoryIcon} ${item.namaKategori ?? ''}',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.namaTempat,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            shadows: [
                              Shadow(color: Colors.black45, blurRadius: 8)
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (item.jalan != null) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  color: Colors.white70, size: 12),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  item.jalan!,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 11,
                                    color: Colors.white70,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.star_rounded,
                                  color: Colors.amber, size: 13),
                              Text(
                                item.reviewRating?.toStringAsFixed(1) ?? '-',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        // Dot indicator
        const SizedBox(height: 10),
        AnimatedSmoothIndicator(
          activeIndex: _current,
          count: widget.items.length,
          effect: const ExpandingDotsEffect(
            activeDotColor: AppColors.primary,
            dotColor: AppColors.surface,
            dotHeight: 6,
            dotWidth: 6,
            expansionFactor: 3,
          ),
        ),
      ],
    ).animate().fade(duration: 500.ms);
  }
}