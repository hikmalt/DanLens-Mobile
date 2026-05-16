// FILE: lib/firebase_options.dart
// File ini berisi konfigurasi Firebase untuk berbagai platform (web, Android, iOS, macOS, Windows).
// File ini dihasilkan secara otomatis oleh FlutterFire CLI berdasarkan project Firebase yang terdaftar.
// Fungsinya: menyediakan kunci API dan pengaturan lain yang diperlukan untuk menginisialisasi Firebase di aplikasi.
// Informasi penting: Jangan diedit secara manual karena akan ditimpa saat menjalankan perintah 'flutterfire configure' lagi.
// Setiap platform memiliki konfigurasi sendiri karena kebutuhan keamanan dan teknis yang berbeda.

// Perintah untuk mengabaikan pemeriksaan tipe (lint) agar file generated tidak memicu peringatan.
// ignore_for_file: type=lint

// Mengimpor kelas FirebaseOptions dari firebase_core untuk mendefinisikan konfigurasi.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
// Mengimpor utilitas untuk mendeteksi platform (web, android, ios, dll) saat runtime.
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Kelas yang menyediakan konfigurasi Firebase yang sesuai dengan platform saat aplikasi berjalan.
/// Contoh penggunaan: Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
class DefaultFirebaseOptions {
  // Metode statis untuk mendapatkan konfigurasi yang sesuai dengan platform saat ini.
  static FirebaseOptions get currentPlatform {
    // Jika aplikasi berjalan di web, gunakan konfigurasi web.
    if (kIsWeb) {
      return web;
    }
    // Berdasarkan target platform, pilih konfigurasi yang sesuai.
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        // Firebase belum mendukung Linux secara resmi.
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        // Platform tidak dikenal.
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Konfigurasi untuk aplikasi web.
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA810SVS3xrQzIbfMEkYC-hwgVRXiH2Pho',
    appId: '1:933811200183:web:19e12ef6f828c6bbd62d32',
    messagingSenderId: '933811200183',
    projectId: 'danlens',
    authDomain: 'danlens.firebaseapp.com',
    storageBucket: 'danlens.firebasestorage.app',
    measurementId: 'G-GTQP41GJK1',
  );

  // Konfigurasi untuk Android.
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBBlwGa60cXzHuxX_YvZfiH4EPj7cVio2c',
    appId: '1:933811200183:android:0744e407beced2b4d62d32',
    messagingSenderId: '933811200183',
    projectId: 'danlens',
    storageBucket: 'danlens.firebasestorage.app',
  );

  // Konfigurasi untuk iOS.
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAOFdOVLeMiRR7tY4DjT9KPABWvMpIlBZM',
    appId: '1:933811200183:ios:115cd9ceca22f6aad62d32',
    messagingSenderId: '933811200183',
    projectId: 'danlens',
    storageBucket: 'danlens.firebasestorage.app',
    iosBundleId: 'com.example.danlens',
  );

  // Konfigurasi untuk macOS.
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAOFdOVLeMiRR7tY4DjT9KPABWvMpIlBZM',
    appId: '1:933811200183:ios:115cd9ceca22f6aad62d32',
    messagingSenderId: '933811200183',
    projectId: 'danlens',
    storageBucket: 'danlens.firebasestorage.app',
    iosBundleId: 'com.example.danlens',
  );

  // Konfigurasi untuk Windows.
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyA810SVS3xrQzIbfMEkYC-hwgVRXiH2Pho',
    appId: '1:933811200183:web:9d991186d5aefe20d62d32',
    messagingSenderId: '933811200183',
    projectId: 'danlens',
    authDomain: 'danlens.firebaseapp.com',
    storageBucket: 'danlens.firebasestorage.app',
    measurementId: 'G-QBPSFNETBV',
  );
}