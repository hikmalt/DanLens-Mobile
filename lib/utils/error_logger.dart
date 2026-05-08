// lib/utils/error_logger.dart
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class ErrorLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
    ),
  );

  static final List<LogEntry> _logs = [];

  static List<LogEntry> get logs => List.unmodifiable(_logs);

  static void d(String msg, [dynamic data]) {
    if (kDebugMode) _logger.d(msg, error: data);
    _addLog(LogLevel.debug, msg);
  }

  static void i(String msg, [dynamic data]) {
    _logger.i(msg, error: data);
    _addLog(LogLevel.info, msg);
  }

  static void w(String msg, [dynamic data]) {
    _logger.w(msg, error: data);
    _addLog(LogLevel.warning, msg);
  }

  static void e(String msg, [dynamic error, StackTrace? stack]) {
    _logger.e(msg, error: error, stackTrace: stack);
    _addLog(LogLevel.error, '$msg ${error ?? ''}');
  }

  static void _addLog(LogLevel level, String msg) {
    _logs.add(LogEntry(level: level, message: msg, time: DateTime.now()));
    if (_logs.length > 200) _logs.removeAt(0);
  }

  static void clear() => _logs.clear();
}

enum LogLevel { debug, info, warning, error }

class LogEntry {
  final LogLevel level;
  final String message;
  final DateTime time;

  LogEntry({required this.level, required this.message, required this.time});

  String get levelLabel {
    switch (level) {
      case LogLevel.debug: return 'DEBUG';
      case LogLevel.info: return 'INFO';
      case LogLevel.warning: return 'WARN';
      case LogLevel.error: return 'ERROR';
    }
  }
}