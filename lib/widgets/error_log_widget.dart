// FILE: lib/widgets/error_log_widget.dart
// File ini berisi halaman untuk menampilkan daftar log error, warning, dan info yang direkam oleh ErrorLogger.
// Fungsi: Menampilkan riwayat pesan error, warning, debug, dan info secara kronologis (terbaru di bawah).
// Informasi penting: Menggunakan data dari ErrorLogger (utils/error_logger.dart). Hanya tersedia untuk pengembang atau admin.
// Dapat menghapus semua log dengan tombol clear di app bar. Warna latar dan ikon berbeda untuk setiap level log.

import 'package:flutter/material.dart';
import '../utils/error_logger.dart';
import '../config/app_theme.dart';

// Halaman utama untuk menampilkan error log.
class ErrorLogWidget extends StatefulWidget {
  const ErrorLogWidget({super.key});

  @override
  State<ErrorLogWidget> createState() => _ErrorLogWidgetState();
}

class _ErrorLogWidgetState extends State<ErrorLogWidget> {
  // Mengambil daftar log dari ErrorLogger (getter static).
  List<LogEntry> get logs => ErrorLogger.logs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error Log'), // Judul halaman.
        actions: [
          // Hanya tampilkan tombol clear jika ada log.
          if (logs.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              tooltip: 'Clear logs', // Tooltip saat tombol ditekan lama.
              onPressed: () {
                ErrorLogger.clear(); // Hapus semua log.
                setState(() {}); // Refresh tampilan.
              },
            ),
        ],
      ),
      body: logs.isEmpty
          // Jika tidak ada log, tampilkan pesan sukses (check icon) dan teks.
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 64, color: AppColors.success),
                  SizedBox(height: 12),
                  Text('Tidak ada error',
                      style: TextStyle(
                          fontFamily: 'Poppins', color: AppColors.textGray)),
                ],
              ),
            )
          // Jika ada log, tampilkan dalam ListView.
          : ListView.builder(
              itemCount: logs.length,
              itemBuilder: (_, i) {
                final log = logs[i];
                return _LogTile(log: log); // Tile untuk setiap entri log.
              },
            ),
    );
  }
}

// Widget tile untuk satu entri log.
class _LogTile extends StatelessWidget {
  final LogEntry log;
  const _LogTile({required this.log});

  // Menentukan warna latar berdasarkan level log.
  Color get _bgColor {
    switch (log.level) {
      case LogLevel.error:
        return AppColors.error.withValues(alpha: 0.08); // Merah transparan untuk error.
      case LogLevel.warning:
        return AppColors.warning.withValues(alpha: 0.08); // Oranye transparan untuk warning.
      case LogLevel.debug:
        return AppColors.surface; // Warna surface untuk debug.
      case LogLevel.info:
      // default:
        return AppColors.background; // Warna background untuk info.
    }
  }

  // Ikon yang sesuai dengan level log.
  IconData get _icon {
    switch (log.level) {
      case LogLevel.error:
        return Icons.error_rounded; // Ikon error (lingkaran merah).
      case LogLevel.warning:
        return Icons.warning_rounded; // Ikon warning (segitiga).
      case LogLevel.debug:
        return Icons.bug_report_rounded; // Ikon bug (debug).
      case LogLevel.info:
      // default:
        return Icons.info_rounded; // Ikon info (i).
    }
  }

  // Warna ikon berdasarkan level log.
  Color get _iconColor {
    switch (log.level) {
      case LogLevel.error:
        return AppColors.error; // Merah.
      case LogLevel.warning:
        return AppColors.warning; // Oranye.
      case LogLevel.debug:
        return AppColors.primary; // Hijau (primary).
      case LogLevel.info:
      // default:
        return AppColors.primary; // Hijau untuk info juga.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3), // Margin luar.
      padding: const EdgeInsets.all(10), // Padding dalam.
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(10), // Sudut melengkung.
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Mulai dari atas.
        children: [
          Icon(_icon, size: 16, color: _iconColor), // Ikon.
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label level log (ERROR, WARN, INFO, DEBUG).
                Text(
                  log.levelLabel,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _iconColor,
                  ),
                ),
                const SizedBox(height: 2),
                // Pesan log.
                Text(
                  log.message,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                // Waktu kejadian dalam format HH:MM:SS.
                Text(
                  '${log.time.hour.toString().padLeft(2, '0')}:${log.time.minute.toString().padLeft(2, '0')}:${log.time.second.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    color: AppColors.textGray,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}