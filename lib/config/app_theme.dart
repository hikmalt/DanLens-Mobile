// FILE: lib/config/app_theme.dart
// File ini berisi konfigurasi tema visual aplikasi DanLens.
// Fungsi utama: mendefinisikan warna-warna utama, tema Material 3, dan gaya teks (font Poppins) yang digunakan secara konsisten di seluruh aplikasi.
// Informasi penting: Tema ini diterapkan di MaterialApp (main.dart) sehingga semua halaman mengikuti warna dan gaya yang sama. Warna primary adalah hijau (#4a7c59) sebagai warna merek DanLens.

import 'package:flutter/material.dart';
// Mengimpor paket Material Design Flutter untuk mendefinisikan tema.

// Kelas yang berisi konstanta warna yang digunakan di aplikasi.
class AppColors {
  static const primary = Color(0xFF4a7c59);
  // Warna utama merek (hijau tua).

  static const primaryDark = Color(0xFF365e47);
  // Warna hijau lebih gelap untuk aksen atau gradient.

  static const primaryDeep = Color(0xFF2e5240);
  // Warna hijau paling gelap untuk efek bayangan atau gradasi.

  static const surface = Color(0xFFd6e8db);
  // Warna latar permukaan (surface) seperti card, input, dll (hijau sangat muda).

  static const background = Color(0xFFf0f7f2);
  // Warna latar belakang utama halaman (putih kehijauan).

  static const white = Color(0xFFFFFFFF);
  // Warna putih murni.

  static const textDark = Color(0xFF1a2e24);
  // Warna teks gelap (hijau kehitaman).

  static const textGray = Color(0xFF6b8c7a);
  // Warna teks abu-abu kehijauan untuk teks sekunder.

  static const error = Color(0xFFe74c3c);
  // Warna merah untuk pesan error.

  static const warning = Color(0xFFf39c12);
  // Warna kuning/oranye untuk peringatan.

  static const success = Color(0xFF27ae60);
  // Warna hijau terang untuk indikasi sukses.

  static const cardShadow = Color(0x1A4a7c59);
  // Warna bayangan untuk card, dengan opacity rendah (sekitar 10%).
}

// Kelas yang menyediakan tema Material 3 untuk aplikasi.
class AppTheme {
  // Getter statis untuk tema terang (light theme).
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        // Mengaktifkan Material Design 3.
        fontFamily: 'Poppins',
        // Mengatur font default menjadi Poppins.
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          // Membangun skema warna dari warna utama.
          primary: AppColors.primary,
          secondary: AppColors.primaryDark,
          surface: AppColors.surface,
            // background: AppColors.background, // Dikomentari, menggunakan scaffoldBackgroundColor.
        ),
        scaffoldBackgroundColor: AppColors.background,
        // Warna latar belakang scaffold (halaman).
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          // Warna latar AppBar.
          foregroundColor: AppColors.white,
          // Warna ikon dan teks di AppBar.
          elevation: 0,
          // Tanpa bayangan.
          centerTitle: true,
          // Judul di tengah.
          titleTextStyle: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: AppColors.white,
          ),
          // Gaya teks judul AppBar.
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            textStyle: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
        // Tema tombol ElevatedButton.
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          // Mengisi latar belakang input.
          fillColor: AppColors.white,
          // Warna isian putih.
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.surface),
          ),
          // Gaya border default.
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.surface),
          ),
          // Gaya border saat input tidak fokus.
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          // Gaya border saat input fokus (warna hijau).
          labelStyle: const TextStyle(color: AppColors.textGray, fontFamily: 'Poppins'),
          // Gaya label.
        ),
        cardTheme: CardThemeData(
          color: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          shadowColor: AppColors.cardShadow,
        ),
        // Tema untuk Card.
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textGray,
          type: BottomNavigationBarType.fixed,
          elevation: 16,
        ),
        // Tema untuk BottomNavigationBar.
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.surface,
          selectedColor: AppColors.primary,
          labelStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        // Tema untuk Chip.
      );
}

// Kelas yang berisi gaya teks statis untuk digunakan di berbagai tempat.
class AppTextStyles {
  static const h1 = TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textDark, fontFamily: 'Poppins');
  static const h2 = TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textDark, fontFamily: 'Poppins');
  static const h3 = TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textDark, fontFamily: 'Poppins');
  static const body = TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textDark, fontFamily: 'Poppins');
  static const bodyMedium = TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textDark, fontFamily: 'Poppins');
  static const small = TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textGray, fontFamily: 'Poppins');
  static const caption = TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.textGray, fontFamily: 'Poppins');
  // Mendefinisikan berbagai ukuran dan ketebalan teks dengan font Poppins.
}