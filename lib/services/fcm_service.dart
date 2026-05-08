// lib/services/fcm_service.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../utils/error_logger.dart';

class FcmService {
  static final FlutterLocalNotificationsPlugin _localPlugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // ── Initialize FCM ──────────────────────────────────────────
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Pastikan Firebase sudah diinisialisasi (panggil di main.dart sebelum ini)
      final messaging = FirebaseMessaging.instance;

      // Request permission (iOS/Android 13+)
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      ErrorLogger.i('FCM permission: ${settings.authorizationStatus}');

      // Get FCM token (kirim ke server/Supabase untuk targeting)
      final token = await messaging.getToken();
      ErrorLogger.i('FCM Token: $token');
      await _saveTokenToSupabase(token);

      // Foreground messages
      FirebaseMessaging.onMessage.listen(_handleForeground);

      // Background tap
      FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);

      // Background handler (top-level function required)
      FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

      // Init local notification plugin
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings();
      await _localPlugin.initialize(
        const InitializationSettings(android: android, iOS: ios),
        onDidReceiveNotificationResponse: _handleLocalTap,
      );

      _initialized = true;
      ErrorLogger.i('FcmService ready');
    } catch (e, stack) {
      ErrorLogger.e('FcmService.initialize failed', e, stack);
    }
  }

  // ── Foreground message handler ───────────────────────────────
  static Future<void> _handleForeground(RemoteMessage message) async {
    ErrorLogger.i('FCM foreground: ${message.notification?.title}');
    await _showLocalNotification(
      title: message.notification?.title ?? 'DanLens',
      body: message.notification?.body ?? '',
      payload: message.data['screen'] ?? '',
    );
  }

  // ── Notification tap handler (background/terminated) ─────────
  static void _handleTap(RemoteMessage message) {
    ErrorLogger.i('FCM tap: ${message.data}');
    // Navigate based on payload
    final screen = message.data['screen'];
    if (screen == 'tempat') {
      // ignore: unused_local_variable
      final id = message.data['id'];
      // Gunakan navigatorKey global untuk navigasi (opsional)
    }
  }

  // ── Local notification tap (saat app di foreground) ──────────
  static void _handleLocalTap(NotificationResponse response) {
    ErrorLogger.i('Local notification tap: ${response.payload}');
  }

  // ── Show local notification ─────────────────────────────────
  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const android = AndroidNotificationDetails(
      'danlens_fcm',
      'DanLens Push',
      channelDescription: 'Push notifications dari server DanLens',
      importance: Importance.high,
      priority: Priority.high,
    );
    await _localPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(android: android),
      payload: payload,
    );
  }

  // ── Save FCM token to Supabase ──────────────────────────────
  static Future<void> _saveTokenToSupabase(String? token) async {
    if (token == null) return;
    // Simpan token ke tabel users (perlu kolom 'fcm_token')
    // await SupabaseService.client
    //     .from('users')
    //     .update({'fcm_token': token})
    //     .eq('id', AuthService.currentUser!.id);
  }
}

// ── Background message handler (top-level function) ────────────
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  ErrorLogger.i('FCM background: ${message.notification?.title}');
}
