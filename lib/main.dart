// FILE: lib/main.dart
// File ini adalah pintu masuk utama (entry point) aplikasi DanLens.
// Fungsi: Menginisialisasi semua layanan penting seperti Firebase, Supabase,
// notifikasi, dan provider state management sebelum aplikasi ditampilkan.
// Informasi penting: Urutan inisialisasi sangat menentukan stabilitas aplikasi.
// Kode di sini dijalankan pertama kali saat pengguna membuka aplikasi.

import 'package:danlens/screens/splash/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'config/supabase_config.dart';
import 'config/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/tempat_provider.dart';
import 'providers/favorite_provider.dart';
import 'providers/map_provider.dart';
import 'services/notification_service.dart';
import 'services/fcm_service.dart';
import 'package:firebase_core/firebase_core.dart';

// Fungsi utama yang dijalankan pertama kali.
void main() async {
  // Memastikan binding widget Flutter sudah siap sebelum menjalankan kode asinkron.
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inisialisasi Firebase. Wajib sebelum layanan Firebase lainnya digunakan.
  await Firebase.initializeApp();
  
  // Inisialisasi Supabase (backend database dan autentikasi).
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
    realtimeClientOptions: const RealtimeClientOptions(
      logLevel: RealtimeLogLevel.info,
    ),
  );

  // Inisialisasi layanan notifikasi push (FCM) tanpa menunggu (biar tidak menghalangi UI).
  FcmService.initialize();
  
  // Inisialisasi notifikasi lokal, ditunggu karena butuh izin dari pengguna.
  await NotificationService.initialize();

  // Mengatur tampilan status bar (bagian atas layar) menjadi transparan dengan ikon gelap.
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  
  // Memaksa orientasi layar hanya potrait (tidak bisa landscape).
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Menjalankan aplikasi dengan menyediakan semua provider (manajemen state) ke seluruh widget.
  runApp(
    MultiProvider(
      providers: [
        // Provider untuk data autentikasi (login, register, logout).
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // Provider untuk data tempat (lokasi, daftar tempat, filter).
        ChangeNotifierProvider(create: (_) => TempatProvider()),
        // Provider untuk data favorit pengguna.
        ChangeNotifierProvider(create: (_) => FavoriteProvider()),
        // Provider untuk data peta (posisi pengguna, rute, dll).
        ChangeNotifierProvider(create: (_) => MapProvider()),
      ],
      child: const DanLensApp(),
    ),
  );
}

// Kelas utama aplikasi (StatelessWidget karena tidak perlu state sendiri).
class DanLensApp extends StatelessWidget {
  const DanLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Judul aplikasi (muncul di task manager).
      title: 'DanLens',
      // Menghilangkan banner debug "DEBUG" di pojok kanan atas.
      debugShowCheckedModeBanner: false,
      // Tema aplikasi (warna, font, dll) diambil dari file konfigurasi.
      theme: AppTheme.light,
      // Halaman pertama yang ditampilkan adalah SplashScreen.
      home: const SplashScreen(),
      // Builder untuk menangani error global (jika terjadi crash di widget).
      builder: (context, child) {
        // Mengganti tampilan error bawaan Flutter dengan tampilan kustom.
        ErrorWidget.builder = (FlutterErrorDetails details) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Ikon bug merah sebagai indikator error.
                    const Icon(Icons.bug_report_rounded,
                        size: 60, color: AppColors.error),
                    const SizedBox(height: 16),
                    // Teks "Terjadi kesalahan".
                    const Text('Terjadi kesalahan',
                        style: AppTextStyles.h2),
                    const SizedBox(height: 8),
                    // Menampilkan pesan error yang sesungguhnya.
                    Text(
                      details.exceptionAsString(),
                      style: AppTextStyles.small,
                      textAlign: TextAlign.center,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 20),
                    // Tombol untuk melaporkan (belum diimplementasikan).
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text('Laporkan'),
                    ),
                  ],
                ),
              ),
            ),
          );
        };
        // Mengembalikan child (aplikasi utama).
        return child!;
      },
    );
  }
}