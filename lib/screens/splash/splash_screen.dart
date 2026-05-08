// lib/screens/splash/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/tempat_provider.dart';
import '../../providers/favorite_provider.dart';
import '../main_screen.dart';
import '../auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _rippleCtrl;

  @override
  void initState() {
    super.initState();
    _rippleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    // Segera muat data tanpa penundaan
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final auth = context.read<AuthProvider>();
    final tempat = context.read<TempatProvider>();
    final fav = context.read<FavoriteProvider>();

    await auth.restoreSession();
    await Future.wait([
      tempat.loadAll(),
      tempat.loadCarousel(),
      fav.load(),
    ]);

    if (!mounted) return;
    // Hapus penundaan ini
    // await Future.delayed(const Duration(milliseconds: 600));

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) =>
            auth.isLoggedIn ? const MainScreen() : const LoginScreen(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child: child,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _rippleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ripple background
            SizedBox(
              width: 180,
              height: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _rippleCtrl,
                    builder: (_, __) => Container(
                      width: 140 + (_rippleCtrl.value * 40),
                      height: 140 + (_rippleCtrl.value * 40),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.white.withValues(alpha: 0.08 * (1 - _rippleCtrl.value)),
                      ),
                    ),
                  ),
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                           color: AppColors.primaryDeep.withValues(alpha: 0.3),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      size: 52,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .scale(duration: 600.ms, curve: Curves.elasticOut)
                .fade(duration: 400.ms),

            const SizedBox(height: 24),

            const Text(
              'DanLens',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
                letterSpacing: 1.5,
              ),
            )
                .animate()
                .fade(delay: 300.ms, duration: 500.ms)
                .slideY(begin: 0.3, end: 0),

            const SizedBox(height: 8),

            const Text(
              'Sistem Informasi GIS Medan',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: Color(0xCCFFFFFF),
                fontWeight: FontWeight.w400,
              ),
            )
                .animate()
                .fade(delay: 500.ms, duration: 500.ms),

            const SizedBox(height: 60),

            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                 color: AppColors.white.withValues(alpha: 0.7),
              ),
            ).animate().fade(delay: 700.ms),
          ],
        ),
      ),
    );
  }
}