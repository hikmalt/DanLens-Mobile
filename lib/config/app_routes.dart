// FILE: lib/config/app_routes.dart
// File ini bertanggung jawab untuk mengelola navigasi (perpindahan halaman) antar layar di aplikasi DanLens.
// Fungsi utama: mendefinisikan semua rute (path) yang tersedia dan bagaimana membuat halaman (route) saat navigasi dipanggil.
// Informasi penting: Menggunakan pendekatan named routes dengan generator (generateRoute) sehingga navigasi bisa dilakukan dengan memanggil
// Navigator.pushNamed(context, AppRoutes.detail, arguments: tempat). Jika rute tidak dikenali, akan menampilkan halaman 404 kustom.

import 'package:flutter/material.dart';
// Mengimpor library Material Design Flutter untuk widget dasar dan navigasi.

import '../screens/splash/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/main_screen.dart';
import '../screens/detail/detail_screen.dart';
import '../screens/map/map_screen.dart';
import '../screens/profile/team_profile_screen.dart';
import '../models/models.dart';
// Mengimpor semua halaman (screens) dan model yang diperlukan untuk navigasi dan passing data.

// Kelas yang berisi konstanta nama rute dan method generator.
class AppRoutes {
  // Konstanta untuk setiap nama rute (path). Digunakan saat memanggil navigator.
  static const String splash = '/';
  // Rute untuk halaman splash screen (tampilan awal).

  static const String login = '/login';
  // Rute untuk halaman login.

  static const String register = '/register';
  // Rute untuk halaman registrasi.

  static const String main = '/main';
  // Rute untuk halaman utama (berisi bottom navigation bar dengan home, map, tambah, favorit, profil).

  static const String detail = '/detail';
  // Rute untuk halaman detail tempat (menerima argumen TempatModel).

  static const String map = '/map';
  // Rute untuk halaman peta (bisa menerima argumen TempatModel untuk fokus ke tempat tertentu).

  static const String team = '/team';
  // Rute untuk halaman profil tim pengembang.

  // Method untuk menghasilkan Route berdasarkan nama rute yang diberikan.
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Switch case mencocokkan settings.name (nama rute) dengan konstanta di atas.
    switch (settings.name) {
      case splash:
        // Jika rute splash, buat MaterialPageRoute yang menampilkan SplashScreen.
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case login:
        // Rute login, tampilkan LoginScreen.
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case register:
        // Rute register, tampilkan RegisterScreen.
        return MaterialPageRoute(builder: (_) => const RegisterScreen());

      case main:
        // Rute utama, tampilkan MainScreen.
        return MaterialPageRoute(builder: (_) => const MainScreen());

      case detail:
        // Rute detail tempat, ambil argumen yang dikirim (berupa TempatModel).
        final tempat = settings.arguments as TempatModel;
        // Pastikan argumen bertipe TempatModel (bisa juga null, tetapi di sini tidak).
        return MaterialPageRoute(
          builder: (_) => DetailScreen(tempat: tempat),
        );

      case map:
        // Rute peta, argumen bersifat opsional (bisa null) untuk fokus tempat.
        final tempat = settings.arguments as TempatModel?;
        return MaterialPageRoute(
          builder: (_) => MapScreen(focusedTempat: tempat),
        );

      case team:
        // Rute profil tim.
        return MaterialPageRoute(
          builder: (_) => const TeamProfileScreen(),
        );

      default:
        // Jika tidak ada rute yang cocok, tampilkan halaman 404 kustom.
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('404 - Halaman tidak ditemukan: ${settings.name}',
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 16)),
            ),
          ),
        );
    }
  }
}