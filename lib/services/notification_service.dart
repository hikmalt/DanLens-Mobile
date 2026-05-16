// FILE: lib/services/notification_service.dart
// File ini mengelola notifikasi lokal pada perangkat (Android/iOS).
// Fungsi: Menampilkan notifikasi pop-up untuk berbagai kejadian, seperti tempat baru ditambahkan atau ucapan selamat datang.
// Informasi penting: Menggunakan package flutter_local_notifications.
//         ID notifikasi 1000 untuk welcome, 1001 untuk tempat baru.
//         Notifikasi memerlukan izin (dengan requestNotificationsPermission).
//         Warna notifikasi menggunakan hijau primary (#4a7c59).

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../utils/error_logger.dart';
// import 'package:flutter/material.dart'; // tidak digunakan, diabaikan
import 'dart:ui' show Color; // Mengimpor Color dari dart:ui untuk parameter warna.

class NotificationService {
  // Plugin untuk notifikasi lokal (singleton).
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  // Menandai apakah layanan sudah diinisialisasi.
  static bool _initialized = false;

  // Inisialisasi notifikasi: membuat channel, meminta izin, dan mendaftarkan handler tap.
  static Future<void> initialize() async {
    // Jika sudah diinisialisasi, lewati.
    if (_initialized) return;
    try {
      // Konfigurasi untuk Android: ikon aplikasi, channel id, dll.
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      // Konfigurasi untuk iOS: meminta izin notifikasi.
      const ios = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      // Gabungan pengaturan untuk semua platform.
      const settings = InitializationSettings(android: android, iOS: ios);

      // Inisialisasi plugin.
      await _plugin.initialize(
        settings,
        onDidReceiveNotificationResponse: _onNotificationTap, // Fungsi saat notifikasi diklik.
      );

      // Minta izin notifikasi untuk Android 13+.
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      _initialized = true;
      ErrorLogger.i('NotificationService initialized');
    } catch (e, stack) {
      ErrorLogger.e('NotificationService.initialize failed', e, stack);
    }
  }

  // Dipanggil saat pengguna mengetuk notifikasi.
  static void _onNotificationTap(NotificationResponse response) {
    ErrorLogger.i('Notification tapped: ${response.payload}');
    // Di sini nantinya bisa diarahkan ke halaman tertentu berdasarkan payload.
  }

  // Menampilkan notifikasi dengan parameter id, judul, isi, dan payload opsional.
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      // Detail notifikasi untuk Android.
      const androidDetails = AndroidNotificationDetails(
        'danlens_channel',               // ID channel
        'DanLens Notifikasi',            // Nama channel
        channelDescription: 'Notifikasi dari aplikasi DanLens',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',     // Ikon notifikasi
        color: Color(0xFF4a7c59),        // Warna hijau (dari dart:ui)
        enableVibration: true,
        playSound: true,
      );
      // Detail untuk iOS.
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      // Gabungan detail.
      const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

      // Tampilkan notifikasi.
      await _plugin.show(id, title, body, details, payload: payload);
      ErrorLogger.i('Notification shown: $title');
    } catch (e, stack) {
      ErrorLogger.e('showNotification failed', e, stack);
    }
  }

  // Notifikasi khusus untuk tempat baru (id 1001).
  static Future<void> showNewTempatNotification(String namaTemp) async {
    await showNotification(
      id: 1001,
      title: '📍 Tempat Baru Ditambahkan!',
      body: '$namaTemp kini tersedia di DanLens.',
      payload: 'new_tempat',
    );
  }

  // Notifikasi selamat datang (id 1000).
  static Future<void> showWelcomeNotification(String name) async {
    await showNotification(
      id: 1000,
      title: 'Selamat Datang di DanLens! 👋',
      body: 'Halo $name! Jelajahi tempat menarik di Medan sekarang.',
      payload: 'welcome',
    );
  }

  // Membatalkan semua notifikasi yang sedang tertunda.
  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}

// (Komentar berikut adalah kode lama yang tidak digunakan)
// Workaround for Color import in non-UI file
//class Color {
  //final int value;
  //const Color(this.value);
//}