// C:\Users\hikma\Desktop\DanLens\danlens\lib\widgets\error_log_widget.dart
import 'package:flutter/material.dart';
import '../utils/error_logger.dart';
import '../config/app_theme.dart';

class ErrorLogWidget extends StatefulWidget {
  const ErrorLogWidget({super.key});

  @override
  State<ErrorLogWidget> createState() => _ErrorLogWidgetState();
}

class _ErrorLogWidgetState extends State<ErrorLogWidget> {
  List<LogEntry> get logs => ErrorLogger.logs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error Log'),
        actions: [
          if (logs.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              tooltip: 'Clear logs',
              onPressed: () {
                ErrorLogger.clear();
                setState(() {});
              },
            ),
        ],
      ),
      body: logs.isEmpty
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
          : ListView.builder(
              itemCount: logs.length,
              itemBuilder: (_, i) {
                final log = logs[i];
                return _LogTile(log: log);
              },
            ),
    );
  }
}

class _LogTile extends StatelessWidget {
  final LogEntry log;
  const _LogTile({required this.log});

  Color get _bgColor {
    switch (log.level) {
      case LogLevel.error:
        return AppColors.error.withValues(alpha:0.08);
      case LogLevel.warning:
        return AppColors.warning.withValues(alpha: 0.08);
      case LogLevel.debug:
        return AppColors.surface;
      case LogLevel.info:
      //default:
        return AppColors.background;
    }
  }

  IconData get _icon {
    switch (log.level) {
      case LogLevel.error:
        return Icons.error_rounded;
      case LogLevel.warning:
        return Icons.warning_rounded;
      case LogLevel.debug:
        return Icons.bug_report_rounded;
      case LogLevel.info:
      //default:
        return Icons.info_rounded;
    }
  }

  Color get _iconColor {
    switch (log.level) {
      case LogLevel.error:
        return AppColors.error;
      case LogLevel.warning:
        return AppColors.warning;
      case LogLevel.debug:
        return AppColors.primary;
      case LogLevel.info:
      //default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_icon, size: 16, color: _iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                Text(
                  log.message,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
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