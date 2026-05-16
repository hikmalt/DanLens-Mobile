// FILE: lib/screens/splash/splash_screen.dart
// Halaman splash screen (layar pembuka) yang ditampilkan saat aplikasi pertama kali diluncurkan.
// Fungsi: Menampilkan animasi logo (lingkaran berdenyut, teks, dan indikator loading)
//         sambil melakukan inisialisasi data di latar belakang (restore session, load tempat, kategori, favorit).
// Informasi penting: Setelah proses selesai, pengguna akan diarahkan ke MainScreen jika sudah login,
//         atau ke LoginScreen jika belum login. Tidak ada penundaan buatan (delay) setelah data siap.
//         Menggunakan AnimationController untuk efek ripple (lingkaran membesar).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/tempat_provider.dart';
import '../../providers/favorite_provider.dart';
import '../main_screen.dart';
import '../auth/login_screen.dart';

// Kelas SplashScreen adalah StatefulWidget karena memerlukan AnimationController.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // Controller untuk animasi ripple (lingkaran membesar).
  late AnimationController _rippleCtrl;

  @override
  void initState() {
    super.initState();
    // Inisialisasi controller animasi dengan durasi 2 detik, diulang terus (repeat).
    _rippleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    // Panggil _init() setelah build selesai (post frame callback).
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  // Memuat data dan menentukan navigasi setelah splash.
  Future<void> _init() async {
    // Ambil instance provider yang dibutuhkan.
    final auth = context.read<AuthProvider>();
    final tempat = context.read<TempatProvider>();
    final fav = context.read<FavoriteProvider>();

    // Restore session (login dari SharedPreferences).
    await auth.restoreSession();
    // Load data tempat, carousel, dan favorit secara paralel.
    await Future.wait([
      tempat.loadAll(),
      tempat.loadCarousel(),
      fav.load(),
    ]);

    // Pastikan widget masih aktif (belum dibuang) sebelum navigasi.
    if (!mounted) return;

    // Ganti halaman dengan animasi fade.
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        // Durasi animasi 600 milidetik.
        transitionDuration: const Duration(milliseconds: 600),
        // Tentukan halaman tujuan: MainScreen jika sudah login, LoginScreen jika belum.
        pageBuilder: (_, __, ___) =>
            auth.isLoggedIn ? const MainScreen() : const LoginScreen(),
        // Efek transisi fade.
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child: child,
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Bersihkan controller animasi saat widget dihancurkan.
    _rippleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Latar belakang hijau (warna primary).
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Area logo dengan efek ripple.
            SizedBox(
              width: 180,
              height: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Lingkaran ripple (berdenyut membesar dan memudar).
                  AnimatedBuilder(
                    animation: _rippleCtrl,
                    builder: (_, __) => Container(
                      // Lebar dan tinggi bertambah dari 140 ke 180 (140 + 40*value).
                      width: 140 + (_rippleCtrl.value * 40),
                      height: 140 + (_rippleCtrl.value * 40),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        // Opasitas menurun dari 8% ke 0%.
                        color: AppColors.white.withValues(alpha: 0.08 * (1 - _rippleCtrl.value)),
                      ),
                    ),
                  ),
                  // Lingkaran putih dengan ikon lokasi di tengah.
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
                // Animasi scale (membesar) dan fade-in.
                .animate()
                .scale(duration: 600.ms, curve: Curves.elasticOut)
                .fade(duration: 400.ms),

            const SizedBox(height: 24),

            // Teks "DanLens".
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
                // Animasi fade dan slide dari bawah.
                .animate()
                .fade(delay: 300.ms, duration: 500.ms)
                .slideY(begin: 0.3, end: 0),

            const SizedBox(height: 8),

            // Subtitle "Sistem Informasi GIS Medan".
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

            // Indikator loading (CircularProgressIndicator) di bagian bawah.
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