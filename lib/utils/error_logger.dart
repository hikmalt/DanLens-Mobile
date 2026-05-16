// FILE: lib/utils/error_logger.dart
// File ini berisi utilitas untuk mencatat (logging) pesan error, warning, info, dan debug selama aplikasi berjalan.
// Fungsi: Menyediakan method statis untuk mencatat log ke konsol (menggunakan package logger) dan menyimpannya dalam memori.
// Log yang tersimpan dapat dilihat di halaman ErrorLogWidget (untuk pengembang atau admin).
// Informasi penting: Log disimpan dalam daftar (list) dengan batas maksimal 200 entri (FIFO).
// Level log: debug (hanya tampil di mode debug), info, warning, error.
// Package logger digunakan untuk format output yang rapi di konsol.

// Mengimpor foundation untuk deteksi mode debug (kDebugMode).
import 'package:flutter/foundation.dart';
// Mengimpor package logger untuk mencatat log dengan format menarik.
import 'package:logger/logger.dart';

// Kelas utama untuk pencatatan error.
class ErrorLogger {
  // Instance logger dengan printer PrettyPrinter untuk tampilan rapi.
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,          // Jumlah baris method dalam stack trace.
      errorMethodCount: 8,     // Jumlah baris method saat error.
      lineLength: 120,         // Panjang maksimal baris log.
      colors: true,            // Mengaktifkan warna di konsol.
      printEmojis: true,       // Mengaktifkan emoji di konsol (opsional).
    ),
  );

  // Daftar untuk menyimpan entri log dalam memori.
  static final List<LogEntry> _logs = [];

  // Getter untuk mengakses daftar log (tidak dapat dimodifikasi dari luar).
  static List<LogEntry> get logs => List.unmodifiable(_logs);

  // Method untuk mencatat log level DEBUG.
  // Hanya akan dicetak ke konsol jika aplikasi berjalan dalam mode debug (kDebugMode).
  static void d(String msg, [dynamic data]) {
    if (kDebugMode) _logger.d(msg, error: data);
    _addLog(LogLevel.debug, msg);
  }

  // Method untuk mencatat log level INFO (informasi umum).
  static void i(String msg, [dynamic data]) {
    _logger.i(msg, error: data);
    _addLog(LogLevel.info, msg);
  }

  // Method untuk mencatat log level WARNING (peringatan).
  static void w(String msg, [dynamic data]) {
    _logger.w(msg, error: data);
    _addLog(LogLevel.warning, msg);
  }

  // Method untuk mencatat log level ERROR (kesalahan).
  // Parameter error dan stackTrace opsional untuk detail error.
  static void e(String msg, [dynamic error, StackTrace? stack]) {
    _logger.e(msg, error: error, stackTrace: stack);
    // Menambahkan pesan error ke daftar log, menyertakan teks error jika ada.
    _addLog(LogLevel.error, '$msg ${error ?? ''}');
  }

  // Method internal untuk menambahkan entri log ke daftar _logs.
  static void _addLog(LogLevel level, String msg) {
    // Buat entri baru dengan waktu sekarang.
    _logs.add(LogEntry(level: level, message: msg, time: DateTime.now()));
    // Jika jumlah log melebihi 200, hapus entri tertua (index 0).
    if (_logs.length > 200) _logs.removeAt(0);
  }

  // Method untuk menghapus semua log yang tersimpan.
  static void clear() => _logs.clear();
}

// Enum untuk level log (debug, info, warning, error).
enum LogLevel { debug, info, warning, error }

// Kelas untuk merepresentasikan satu entri log.
class LogEntry {
  final LogLevel level;      // Level log.
  final String message;      // Pesan log.
  final DateTime time;       // Waktu kejadian.

  LogEntry({required this.level, required this.message, required this.time});

  // Getter untuk label level log dalam bentuk string huruf besar.
  String get levelLabel {
    switch (level) {
      case LogLevel.debug:   return 'DEBUG';
      case LogLevel.info:    return 'INFO';
      case LogLevel.warning: return 'WARN';
      case LogLevel.error:   return 'ERROR';
    }
  }
}