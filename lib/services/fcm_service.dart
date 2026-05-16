// FILE: lib/services/fcm_service.dart
// File ini berisi layanan untuk mengintegrasikan Firebase Cloud Messaging (FCM) guna mengirim dan menerima notifikasi push.
// Fungsi: Mengatur izin notifikasi, mendapatkan token perangkat, menangani pesan saat aplikasi di latar depan (foreground),
//         latar belakang (background), atau ketika aplikasi ditutup (terminated). Juga menampilkan notifikasi lokal
//         menggunakan flutter_local_notifications.
// Informasi penting: Memerlukan Firebase yang sudah diinisialisasi di main.dart.
//         Kode penyimpanan token ke Supabase masih dikomentari karena memerlukan kolom fcm_token di tabel users.
//         Background handler harus berupa fungsi top-level dengan anotasi @pragma('vm:entry-point').

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../utils/error_logger.dart';

class FcmService {
  // Plugin untuk menampilkan notifikasi lokal (ketika aplikasi di foreground).
  static final FlutterLocalNotificationsPlugin _localPlugin =
      FlutterLocalNotificationsPlugin();
  // Status apakah layanan sudah diinisialisasi (untuk mencegah inisialisasi ganda).
  static bool _initialized = false;

  // -----------------------------------------------------------------
  //  INISIALISASI FCM
  // -----------------------------------------------------------------

  // Method utama untuk menginisialisasi FCM. Harus dipanggil sekali di awal aplikasi.
  static Future<void> initialize() async {
    if (_initialized) return; // Jika sudah diinisialisasi, langsung keluar.

    try {
      // Pastikan Firebase sudah diinisialisasi (dilakukan di main.dart).
      final messaging = FirebaseMessaging.instance;

      // Minta izin notifikasi (untuk iOS dan Android 13 ke atas).
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      // Catat status izin.
      ErrorLogger.i('FCM permission: ${settings.authorizationStatus}');

      // Dapatkan token FCM unik untuk perangkat ini.
      final token = await messaging.getToken();
      ErrorLogger.i('FCM Token: $token');
      // Simpan token ke Supabase (masih dikomentari karena perlu persiapan tabel).
      await _saveTokenToSupabase(token);

      // Pasang handler untuk pesan saat aplikasi di foreground (aktif).
      FirebaseMessaging.onMessage.listen(_handleForeground);

      // Pasang handler untuk saat notifikasi diklik dan aplikasi terbuka dari latar belakang.
      FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);

      // Pasang handler untuk pesan saat aplikasi di background (tidak aktif) atau terminasi.
      // Fungsi handler harus top-level, didefinisikan di luar class.
      FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

      // Inisialisasi plugin notifikasi lokal.
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings();
      await _localPlugin.initialize(
        const InitializationSettings(android: android, iOS: ios),
        onDidReceiveNotificationResponse: _handleLocalTap, // Saat notifikasi lokal diklik.
      );

      _initialized = true;
      ErrorLogger.i('FcmService ready');
    } catch (e, stack) {
      ErrorLogger.e('FcmService.initialize failed', e, stack);
    }
  }

  // -----------------------------------------------------------------
  //  HANDLER PESAN FOREGROUND
  // -----------------------------------------------------------------

  // Menangani pesan yang diterima saat aplikasi sedang aktif (foreground).
  static Future<void> _handleForeground(RemoteMessage message) async {
    ErrorLogger.i('FCM foreground: ${message.notification?.title}');
    // Tampilkan notifikasi lokal agar user tetap melihat pop-up.
    await _showLocalNotification(
      title: message.notification?.title ?? 'DanLens',
      body: message.notification?.body ?? '',
      payload: message.data['screen'] ?? '', // Data tambahan untuk navigasi.
    );
  }

  // -----------------------------------------------------------------
  //  HANDLER SAAT NOTIFIKASI DIKLIK (background/terminated)
  // -----------------------------------------------------------------

  // Menangani saat pengguna menekan notifikasi dan aplikasi terbuka dari background atau terminasi.
  static void _handleTap(RemoteMessage message) {
    ErrorLogger.i('FCM tap: ${message.data}');
    // Contoh navigasi berdasarkan payload. Di sini masih placeholder.
    final screen = message.data['screen'];
    if (screen == 'tempat') {
      // final id = message.data['id']; // Bisa digunakan untuk navigasi ke halaman detail.
      // Gunakan navigatorKey global untuk navigasi (perlu diimplementasikan).
    }
  }

  // -----------------------------------------------------------------
  //  HANDLER NOTIFIKASI LOKAL (saat app foreground)
  // -----------------------------------------------------------------

  // Menangani saat notifikasi lokal yang ditampilkan oleh _showLocalNotification diklik.
  static void _handleLocalTap(NotificationResponse response) {
    ErrorLogger.i('Local notification tap: ${response.payload}');
  }

  // -----------------------------------------------------------------
  //  MENAMPILKAN NOTIFIKASI LOKAL
  // -----------------------------------------------------------------

  // Menampilkan notifikasi lokal menggunakan flutter_local_notifications.
  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    // Konfigurasi channel untuk Android.
    const android = AndroidNotificationDetails(
      'danlens_fcm',
      'DanLens Push',
      channelDescription: 'Push notifications dari server DanLens',
      importance: Importance.high,
      priority: Priority.high,
    );
    // Tampilkan notifikasi dengan ID unik (timestamp dalam detik).
    await _localPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(android: android),
      payload: payload,
    );
  }

  // -----------------------------------------------------------------
  //  MENYIMPAN FCM TOKEN KE SUPABASE
  // -----------------------------------------------------------------

  // Menyimpan token FCM ke tabel users di Supabase (belum diaktifkan).
  static Future<void> _saveTokenToSupabase(String? token) async {
    if (token == null) return;
    // Kode di bawah dikomentari karena perlu kolom 'fcm_token' di tabel users dan sesi user aktif.
    // await SupabaseService.client
    //     .from('users')
    //     .update({'fcm_token': token})
    //     .eq('id', AuthService.currentUser!.id);
  }
}

// -----------------------------------------------------------------
//  HANDLER BACKGROUND (TOP-LEVEL)
// -----------------------------------------------------------------

// Fungsi top-level yang dipanggil saat pesan diterima ketika aplikasi berada di background atau terminasi.
// Wajib menggunakan anotasi @pragma('vm:entry-point') agar tidak dihilangkan saat tree shaking.
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  // Inisialisasi ulang Firebase karena proses background memiliki instance terpisah.
  await Firebase.initializeApp();
  // Catat log bahwa pesan background diterima.
  ErrorLogger.i('FCM background: ${message.notification?.title}');
}