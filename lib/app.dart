// FILE: lib/app.dart
// File ini mendefinisikan widget utama aplikasi DanLens.
// Fungsi: mengkonfigurasi MaterialApp yang menjadi wadah seluruh halaman aplikasi.
// Informasi penting: File ini dipanggil dari main.dart setelah semua provider dan inisialisasi selesai.
// Di sini diatur tema, judul, dan halaman awal (SplashScreen).

import 'package:flutter/material.dart';
import 'config/app_theme.dart';
import 'screens/splash/splash_screen.dart';

// Kelas DanLensApp adalah stateless widget yang tidak memiliki state sendiri.
class DanLensApp extends StatelessWidget {
  // Konstruktor dengan key opsional.
  const DanLensApp({super.key});
 
  // Method build untuk membangun tampilan widget.
  @override
  Widget build(BuildContext context) {
    // Mengembalikan MaterialApp sebagai root widget.
    return MaterialApp(
      // Judul aplikasi yang muncul di task manager / recent apps.
      title: 'DanLens',
      // Menghilangkan banner "DEBUG" di pojok kanan atas.
      debugShowCheckedModeBanner: false,
      // Menggunakan tema yang sudah didefinisikan di config/app_theme.dart.
      theme: AppTheme.light,
      // Halaman pertama yang ditampilkan adalah SplashScreen.
      home: const SplashScreen(),
    );
  }
}