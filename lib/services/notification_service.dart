// lib/services/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../utils/error_logger.dart';
//import 'package:flutter/material.dart';
import 'dart:ui' show Color;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const settings = InitializationSettings(android: android, iOS: ios);

      await _plugin.initialize(
        settings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );

      // Request permission (Android 13+)
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

  static void _onNotificationTap(NotificationResponse response) {
    ErrorLogger.i('Notification tapped: ${response.payload}');
    // Handle navigation based on payload here
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'danlens_channel',
        'DanLens Notifikasi',
        channelDescription: 'Notifikasi dari aplikasi DanLens',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF4a7c59),
        enableVibration: true,
        playSound: true,
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      const details = NotificationDetails(
          android: androidDetails, iOS: iosDetails);

      await _plugin.show(id, title, body, details, payload: payload);
      ErrorLogger.i('Notification shown: $title');
    } catch (e, stack) {
      ErrorLogger.e('showNotification failed', e, stack);
    }
  }

  static Future<void> showNewTempatNotification(String namaTemp) async {
    await showNotification(
      id: 1001,
      title: '📍 Tempat Baru Ditambahkan!',
      body: '$namaTemp kini tersedia di DanLens.',
      payload: 'new_tempat',
    );
  }

  static Future<void> showWelcomeNotification(String name) async {
    await showNotification(
      id: 1000,
      title: 'Selamat Datang di DanLens! 👋',
      body: 'Halo $name! Jelajahi tempat menarik di Medan sekarang.',
      payload: 'welcome',
    );
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}

// Workaround for Color import in non-UI file
//class Color {
  //final int value;
  //const Color(this.value);
//}