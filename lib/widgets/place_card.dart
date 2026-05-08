// lib/widgets/place_card.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../models/models.dart';
import '../providers/favorite_provider.dart';
import '../screens/detail/detail_screen.dart';

class PlaceCard extends StatelessWidget {
  final TempatModel tempat;
  final int index;

  const PlaceCard({super.key, required this.tempat, this.index = 0});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetailScreen(tempat: tempat)),
      ),
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha:0.10),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                height: 108,// sedikit dikurangi agar tidak overflow
                width: double.infinity,
                child: tempat.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: tempat.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: AppColors.surface),
                        errorWidget: (_, __, ___) => _placeholderImage(),
                      )
                    : _placeholderImage(),
              ),
            ),
            // Info
            Padding(
              //padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 8), // <-- padding lebih ringkas
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          tempat.categoryIcon,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          tempat.namaKategori ?? '',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tempat.namaTempat,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                      const SizedBox(width: 2),
                      Text(
                        tempat.reviewRating?.toStringAsFixed(1) ?? '-',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      const Spacer(),
                      // Favorite button
                      Consumer<FavoriteProvider>(
                        builder: (_, fav, __) => GestureDetector(
                          onTap: () => fav.toggle(tempat),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Icon(
                              fav.isFavorite(tempat.id)
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              key: ValueKey(fav.isFavorite(tempat.id)),
                              color: fav.isFavorite(tempat.id)
                                  ? Colors.redAccent
                                  : AppColors.textGray,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      )
          .animate(delay: Duration(milliseconds: index * 80))
          .fade(duration: 400.ms)
          .slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic),
    );
  }

  // ... (placeholder method tetap sama)
}

  Widget _placeholderImage() {
    return Container(
      color: AppColors.surface,
      child: const Center(
        child: Icon(Icons.image_outlined, color: AppColors.textGray, size: 36),
      ),
    );
  }

class PlaceListTile extends StatelessWidget {
  final TempatModel tempat;
  final int index;
  final double? distanceKm;

  const PlaceListTile({
    super.key,
    required this.tempat,
    this.index = 0,
    this.distanceKm,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetailScreen(tempat: tempat)),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha:0.07),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 64,
                height: 64,
                child: tempat.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: tempat.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: AppColors.surface),
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.surface,
                          child: const Icon(Icons.image_outlined,
                              color: AppColors.textGray),
                        ),
                      )
                    : Container(
                        color: AppColors.surface,
                        child: Center(
                          child: Text(tempat.categoryIcon,
                              style: const TextStyle(fontSize: 24)),
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
                          fontSize: 14,
                          color: AppColors.textDark),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(
                    '${tempat.namaKecamatan ?? ''} · ${tempat.namaKategori ?? ''}',
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: AppColors.textGray),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 13),
                      const SizedBox(width: 2),
                      Text(tempat.reviewRating?.toStringAsFixed(1) ?? '-',
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                      if (distanceKm != null) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.near_me_rounded,
                            color: AppColors.primary, size: 12),
                        const SizedBox(width: 2),
                        Text(
                          distanceKm! < 1
                              ? '${(distanceKm! * 1000).toInt()} m'
                              : '${distanceKm!.toStringAsFixed(1)} km',
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
                color: AppColors.textGray, size: 20),
          ],
        ),
      )
          .animate(delay: Duration(milliseconds: index * 60))
          .fade(duration: 350.ms)
          .slideX(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
    );
  }
}