// lib/widgets/image_viewer.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import '../config/app_theme.dart';

/// Full-screen image viewer with swipe support (for gallery)
class ImageGalleryViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  final String heroTag;

  const ImageGalleryViewer({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
    this.heroTag = '',
  });

  @override
  State<ImageGalleryViewer> createState() => _ImageGalleryViewerState();
}

class _ImageGalleryViewerState extends State<ImageGalleryViewer> {
  late PageController _pageCtrl;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _pageCtrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Gallery
          PhotoViewGallery.builder(
            pageController: _pageCtrl,
            itemCount: widget.imageUrls.length,
            onPageChanged: (i) => setState(() => _current = i),
            builder: (ctx, i) => PhotoViewGalleryPageOptions(
              imageProvider:
                  CachedNetworkImageProvider(widget.imageUrls[i]),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 3,
              heroAttributes: i == widget.initialIndex && widget.heroTag.isNotEmpty
                  ? PhotoViewHeroAttributes(tag: widget.heroTag)
                  : null,
            ),
            backgroundDecoration:
                const BoxDecoration(color: Colors.black),
            loadingBuilder: (_, __) => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),

          // Top bar
          SafeArea(
            child: Row(
              children: [
                // Close button
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha:0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ),
                const Spacer(),
                // Counter
                if (widget.imageUrls.length > 1)
                  Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha:0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_current + 1} / ${widget.imageUrls.length}',
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
              ],
            ),
          ).animate().fade(duration: 300.ms),

          // Dot indicator
          if (widget.imageUrls.length > 1)
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.imageUrls.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _current == i ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _current == i
                          ? AppColors.primary
                          : Colors.white.withValues(alpha:0.4),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }
}

/// Open single image fullscreen
void openImageViewer(
  BuildContext context,
  String imageUrl, {
  String heroTag = '',
}) {
  Navigator.push(
    context,
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black87,
      pageBuilder: (_, __, ___) => ImageGalleryViewer(
        imageUrls: [imageUrl],
        heroTag: heroTag,
      ),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
    ),
  );
}

/// Tappable image with Hero + tap-to-zoom
class TappableImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final String heroTag;

  const TappableImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.heroTag = '',
  });

  @override
  Widget build(BuildContext context) {
    final tag = heroTag.isNotEmpty ? heroTag : 'img_$imageUrl';

    return GestureDetector(
      onTap: () => openImageViewer(context, imageUrl, heroTag: tag),
      child: Hero(
        tag: tag,
        child: ClipRRect(
          borderRadius: borderRadius ?? BorderRadius.zero,
          child: imageUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: width,
                  height: height,
                  fit: fit,
                  placeholder: (_, __) => _PlaceholderBox(
                      width: width, height: height),
                  errorWidget: (_, __, ___) =>
                      _ErrorBox(width: width, height: height),
                )
              : _ErrorBox(width: width, height: height),
        ),
      ),
    );
  }
}

class _PlaceholderBox extends StatelessWidget {
  final double? width;
  final double? height;
  const _PlaceholderBox({this.width, this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: AppColors.surface,
      child: const Center(
        child: CircularProgressIndicator(
            strokeWidth: 2, color: AppColors.primary),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final double? width;
  final double? height;
  const _ErrorBox({this.width, this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: AppColors.surface,
      child: const Center(
        child: Icon(Icons.broken_image_outlined,
            color: AppColors.textGray, size: 32),
      ),
    );
  }
}