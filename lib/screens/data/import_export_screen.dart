// lib/screens/data/import_export_screen.dart
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/tempat_provider.dart';
import '../../services/export_service.dart';
import '../../services/import_service.dart';
import '../../utils/error_logger.dart';

class ImportExportScreen extends StatefulWidget {
  const ImportExportScreen({super.key});
  @override
  State<ImportExportScreen> createState() => _ImportExportScreenState();
}

class _ImportExportScreenState extends State<ImportExportScreen> {
  bool _exporting = false;
  bool _importing = false;
  String _status = '';
  // ignore: unused_field
  ImportResult? _lastImportResult;

  // ── EXPORT ──────────────────────────────────────────────────
  Future<void> _export(String type) async {
    setState(() {
      _exporting = true;
      _status = 'Menyiapkan ekspor $type...';
      _lastImportResult = null;
    });

    try {
      if (!mounted) return;
      final data = context.read<TempatProvider>().allTempat;
      if (data.isEmpty) {
        _showSnack('Tidak ada data untuk diekspor', isError: true);
        setState(() => _exporting = false);
        return;
      }

      switch (type) {
        case 'PDF':
          setState(() => _status = 'Membuat PDF (${data.length} data)...');
          await ExportService.exportToPdf(data);
          break;
        case 'Excel':
          setState(() => _status = 'Membuat Excel...');
          await ExportService.exportToExcel(data);
          break;
        case 'SQL':
          setState(() => _status = 'Membuat SQL dump...');
          await ExportService.exportToSql(data);
          break;
      }

      _showSnack('✅ Ekspor $type berhasil!', isError: false);
    } catch (e, stack) {
      ErrorLogger.e('Export $type failed', e, stack);
      _showSnack('❌ Gagal ekspor: ${e.toString()}', isError: true);
    }

    setState(() {
      _exporting = false;
      _status = '';
    });
  }

  // ── IMPORT ──────────────────────────────────────────────────
  Future<void> _import(String type) async {
    final auth = context.read<AuthProvider>();
      final tp = context.read<TempatProvider>(); // ← tambahkan baris ini
    if (!auth.isLoggedIn) {
      _showSnack('Login terlebih dahulu untuk import', isError: true);
      return;
    }

    // Pick file
    FilePickerResult? picked;
    try {
      picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: type == 'Excel' ? ['xlsx', 'xls'] : ['sql'],
        allowMultiple: false,
      );
    } catch (e) {
      _showSnack('Gagal membuka file picker', isError: true);
      return;
    }

    if (picked == null || picked.files.isEmpty) return;
    final filePath = picked.files.first.path;
    if (filePath == null) return;

    final file = File(filePath);

    setState(() {
      _importing = true;
      _status = 'Membaca file $type...';
      _lastImportResult = null;
    });

    try {
      //final existing = context.read<TempatProvider>().allTempat;
      final existing = tp.allTempat;
      ImportResult result;

      if (type == 'Excel') {
        setState(() => _status = 'Memproses data Excel...');
        result = await ImportService.importFromExcel(file, existing);
      } else {
        setState(() => _status = 'Memproses SQL statements...');
        result = await ImportService.importFromSql(file, existing);
      }

      setState(() => _lastImportResult = result);

      if (result.inserted > 0) {
        if (!mounted) return;
        await context.read<TempatProvider>().refresh();
      }

      // Show result dialog
      if (mounted) _showImportResultDialog(result, type);
    } catch (e, stack) {
      ErrorLogger.e('Import $type failed', e, stack);
      _showSnack('❌ Error: ${e.toString()}', isError: true);
    }

    setState(() {
      _importing = false;
      _status = '';
    });
  }

  void _showImportResultDialog(ImportResult result, String type) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: result.inserted > 0
                    ? AppColors.success.withValues(alpha:0.1)
                    : AppColors.error.withValues(alpha:0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                result.inserted > 0
                    ? Icons.check_circle_rounded
                    : Icons.error_outline_rounded,
                color: result.inserted > 0 ? AppColors.success : AppColors.error,
              ),
            ),
            const SizedBox(width: 10),
            Text('Hasil Import $type',
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ResultRow(
              icon: Icons.add_circle_rounded,
              color: AppColors.success,
              label: 'Berhasil ditambahkan',
              value: result.inserted,
            ),
            const SizedBox(height: 8),
            _ResultRow(
              icon: Icons.copy_rounded,
              color: AppColors.warning,
              label: 'Duplikat dilewati',
              value: result.duplicates,
            ),
            const SizedBox(height: 8),
            _ResultRow(
              icon: Icons.cancel_rounded,
              color: AppColors.error,
              label: 'Gagal disimpan',
              value: result.failed,
            ),

            // Duplicate names list
            if (result.duplicateNames.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha:0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.warning.withValues(alpha:0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('⚠️ Nama duplikat:',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.warning)),
                    const SizedBox(height: 4),
                    ...result.duplicateNames
                        .take(5)
                        .map((n) => Text('• $n',
                            style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                color: AppColors.textGray))),
                    if (result.duplicateNames.length > 5)
                      Text(
                          '• ... dan ${result.duplicateNames.length - 5} lainnya',
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: AppColors.textGray)),
                  ],
                ),
              ),
            ],

            // Error list
            if (result.errors.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha:0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.error.withValues(alpha:0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('❌ Error:',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.error)),
                    const SizedBox(height: 4),
                    ...result.errors
                        .take(3)
                        .map((e) => Text(e,
                            style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10,
                                color: AppColors.textGray))),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Selesai', style: TextStyle(fontFamily: 'Poppins')),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'Poppins')),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final tempat = context.watch<TempatProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Import & Export Data')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withValues(alpha:0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${tempat.allTempat.length} tempat tersedia di database.',
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: AppColors.primaryDark),
                    ),
                  ),
                ],
              ),
            ).animate().fade(duration: 400.ms),

            // Status indicator
            if (_status.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha:0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.primary),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(_status,
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: AppColors.primaryDark)),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // ── EXPORT SECTION ────────────────────────────
            const Text('📤 Export Data', style: AppTextStyles.h3)
                .animate().fade(delay: 50.ms),
            const SizedBox(height: 4),
            const Text(
              'Unduh semua data tempat dalam format pilihan Anda.',
              style: AppTextStyles.small,
            ).animate().fade(delay: 80.ms),
            const SizedBox(height: 14),

            Row(
              children: [
                _ExportCard(
                  icon: Icons.picture_as_pdf_rounded,
                  label: 'PDF',
                  color: const Color(0xFFE53935),
                  subtitle: 'Tabel siap cetak',
                  loading: _exporting,
                  onTap: () => _export('PDF'),
                  index: 0,
                ),
                const SizedBox(width: 10),
                _ExportCard(
                  icon: Icons.table_chart_rounded,
                  label: 'Excel',
                  color: const Color(0xFF1B7F36),
                  subtitle: 'Spreadsheet .xlsx',
                  loading: _exporting,
                  onTap: () => _export('Excel'),
                  index: 1,
                ),
                const SizedBox(width: 10),
                _ExportCard(
                  icon: Icons.code_rounded,
                  label: 'SQL',
                  color: const Color(0xFF1565C0),
                  subtitle: 'Database dump',
                  loading: _exporting,
                  onTap: () => _export('SQL'),
                  index: 2,
                ),
              ],
            ),

            const SizedBox(height: 32),

            // ── IMPORT SECTION ────────────────────────────
            Row(
              children: [
                const Text('📥 Import Data', style: AppTextStyles.h3),
                const SizedBox(width: 8),
                if (!auth.isLoggedIn)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Login diperlukan',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            color: AppColors.error)),
                  ),
              ],
            ).animate().fade(delay: 200.ms),
            const SizedBox(height: 4),
            const Text(
              'Import data dari file Excel atau SQL. Duplikat akan otomatis dilewati.',
              style: AppTextStyles.small,
            ).animate().fade(delay: 220.ms),
            const SizedBox(height: 14),

            // Excel import
            _ImportCard(
              icon: Icons.table_chart_rounded,
              label: 'Import dari Excel',
              color: const Color(0xFF1B7F36),
              subtitle: 'Format: .xlsx atau .xls\nKolom: nama_tempat, kategori_id, lat, lng, ...',
              loading: _importing,
              enabled: auth.isLoggedIn,
              onTap: () => _import('Excel'),
            ).animate().fade(delay: 250.ms),

            const SizedBox(height: 12),

            // SQL import
            _ImportCard(
              icon: Icons.code_rounded,
              label: 'Import dari SQL',
              color: const Color(0xFF1565C0),
              subtitle: 'Format: INSERT INTO tempat (...) VALUES (...)',
              loading: _importing,
              enabled: auth.isLoggedIn,
              onTap: () => _import('SQL'),
            ).animate().fade(delay: 300.ms),

            const SizedBox(height: 24),

            // Template download hint
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.surface),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.help_outline_rounded,
                          color: AppColors.primary, size: 16),
                      SizedBox(width: 6),
                      Text('Format Excel yang Diharapkan',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: AppColors.textDark)),
                    ],
                  ),
                  SizedBox(height: 10),
                  _FormatRow('nama_tempat', 'Nama tempat (wajib)'),
                  _FormatRow('kategori_id', '1=Kuliner, 2=Wisata, 3=Kesehatan, ...'),
                  _FormatRow('kecamatan_id', 'ID kecamatan (1–19)'),
                  _FormatRow('latitude', 'Koordinat desimal (3.59...)'),
                  _FormatRow('longitude', 'Koordinat desimal (98.67...)'),
                  _FormatRow('detail_tempat', 'Deskripsi (opsional)'),
                  _FormatRow('jalan', 'Alamat jalan (opsional)'),
                  _FormatRow('review_rating', '0.0 – 5.0 (opsional)'),
                  _FormatRow('kontak', 'Nomor telepon (opsional)'),
                  SizedBox(height: 8),
                  Text(
                    '💡 Tip: Export ke Excel dulu, lalu edit, lalu import kembali.',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: AppColors.primary,
                        fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ).animate().fade(delay: 350.ms),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────

class _ExportCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String subtitle;
  final bool loading;
  final VoidCallback onTap;
  final int index;

  const _ExportCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.subtitle,
    required this.loading,
    required this.onTap,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: loading ? null : onTap,
        child: AnimatedOpacity(
          opacity: loading ? 0.5 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha:0.2)),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha:0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: loading
                      ? Center(
                          child: SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: color),
                          ),
                        )
                      : Icon(icon, color: color, size: 22),
                ),
                const SizedBox(height: 8),
                Text(label,
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: color)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 9,
                        color: AppColors.textGray),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      )
          .animate(delay: Duration(milliseconds: index * 80))
          .fade(duration: 400.ms)
          .slideY(begin: 0.2, end: 0),
    );
  }
}

class _ImportCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String subtitle;
  final bool loading;
  final bool enabled;
  final VoidCallback onTap;

  const _ImportCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.subtitle,
    required this.loading,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (loading || !enabled) ? null : onTap,
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.45,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: enabled ? color.withValues(alpha:0.2) : AppColors.surface),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha:0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: loading
                    ? Center(
                        child: SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: color),
                        ),
                      )
                    : Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppColors.textDark)),
                    const SizedBox(height: 3),
                    Text(subtitle,
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: AppColors.textGray,
                            height: 1.4)),
                  ],
                ),
              ),
              Icon(Icons.upload_file_rounded, color: color, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final int value;

  const _ResultRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label,
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 13)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha:0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$value',
            style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: color),
          ),
        ),
      ],
    );
  }
}

class _FormatRow extends StatelessWidget {
  final String col;
  final String desc;
  const _FormatRow(this.col, this.desc);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(col,
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(desc,
                style: const TextStyle(
                    fontFamily: 'Poppins', fontSize: 11, color: AppColors.textGray)),
          ),
        ],
      ),
    );
  }
}