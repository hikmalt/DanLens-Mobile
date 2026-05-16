// FILE: lib/screens/admin/kecamatan_management_screen.dart
// Halaman untuk mengelola data kecamatan (CRUD) oleh admin.
// Fungsi: Menampilkan daftar kecamatan, mencari, menambah, mengedit, menghapus,
//         serta mengekspor dan mengimpor data kecamatan dalam format JSON, Excel, SQL.
// Informasi penting: Data kecamatan diambil dari Supabase melalui KecamatanService.
//         Setiap kecamatan menampilkan status polygon dan luas wilayah dalam km persegi.
//         Ekspor dan impor menggunakan layanan ExportService dan ImportService.

import 'dart:io'; // Untuk mengakses file yang diimpor.
import 'package:flutter/material.dart'; // Widget dasar Flutter.
import 'package:file_picker/file_picker.dart'; // Memilih file dari penyimpanan.
import '../../config/app_theme.dart'; // Tema dan warna.
import '../../models/kecamatan_model.dart'; // Model kecamatan.
import '../../services/kecamatan_service.dart'; // Layanan CRUD kecamatan.
import '../../services/export_service.dart'; // Layanan ekspor data.
import '../../services/import_service.dart'; // Layanan impor data.
import '../../utils/error_logger.dart'; // Pencatatan error.
import 'polygon_editor_screen.dart'; // Halaman editor polygon.

// Halaman utama manajemen kecamatan.
class KecamatanManagementScreen extends StatefulWidget {
  const KecamatanManagementScreen({super.key});

  @override
  State<KecamatanManagementScreen> createState() => _KecamatanManagementScreenState();
}

class _KecamatanManagementScreenState extends State<KecamatanManagementScreen> {
  List<KecamatanModel> _kecamatan = []; // Menyimpan semua data kecamatan.
  bool _loading = true; // Status loading saat memuat data.
  String _search = ''; // Teks pencarian.
  bool _exporting = false; // Status ekspor (menampilkan indikator loading).

  @override
  void initState() {
    super.initState();
    _load(); // Muat data saat halaman pertama kali dibuka.
  }

  // Memuat data kecamatan dari Supabase.
  Future<void> _load() async {
    setState(() => _loading = true);
    _kecamatan = await KecamatanService.getAll();
    if (mounted) setState(() => _loading = false);
  }

  // Daftar kecamatan setelah difilter berdasarkan pencarian.
  List<KecamatanModel> get _filtered {
    if (_search.isEmpty) return _kecamatan;
    return _kecamatan.where((k) => k.namaKecamatan.toLowerCase().contains(_search.toLowerCase())).toList();
  }

  // Menghapus kecamatan setelah konfirmasi.
  Future<void> _delete(KecamatanModel k) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Kecamatan'),
        content: Text('Hapus "${k.namaKecamatan}"? Data tidak dapat dikembalikan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final ok = await KecamatanService.delete(k.id);
    if (!mounted) return;
    if (ok) {
      _load(); // Muat ulang data setelah penghapusan.
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kecamatan dihapus'), backgroundColor: AppColors.success));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menghapus'), backgroundColor: AppColors.error));
    }
  }

  // Mengekspor data kecamatan ke format yang dipilih (JSON, Excel, SQL).
  Future<void> _export(String format) async {
    if (_kecamatan.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak ada data untuk diekspor')));
      return;
    }
    setState(() => _exporting = true);
    try {
      if (format == 'JSON') {
        await ExportService.exportKecamatanToJson(_kecamatan);
      } else if (format == 'Excel') {
        await ExportService.exportKecamatanToExcel(_kecamatan);
      } else if (format == 'SQL') {
        await ExportService.exportKecamatanToSql(_kecamatan);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ekspor $format berhasil'), backgroundColor: AppColors.success));
    } catch (e, stack) {
      ErrorLogger.e('Export $format gagal', e, stack);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ekspor gagal: $e'), backgroundColor: AppColors.error));
    }
    if (mounted) setState(() => _exporting = false);
  }

  // Mengimpor data kecamatan dari file (Excel, SQL, JSON).
  Future<void> _import(String type) async {
    FilePickerResult? result;
    try {
      // Pilih file sesuai tipe.
      if (type == 'Excel') {
        result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['xlsx', 'xls']);
      } else if (type == 'SQL') {
        result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['sql']);
      } else {
        result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
      }
    } catch (e, stack) {
      ErrorLogger.e('Import gagal memilih file', e, stack);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memilih file: $e'), backgroundColor: AppColors.error));
      return;
    }
    if (result == null || result.files.isEmpty) return;
    final file = File(result.files.first.path!);

    setState(() => _loading = true);
    ImportResult importResult;
    try {
      if (type == 'Excel') {
        importResult = await ImportService.importKecamatanFromExcel(file, _kecamatan);
      } else if (type == 'SQL') {
        importResult = await ImportService.importKecamatanFromSql(file, _kecamatan);
      } else {
        importResult = await ImportService.importKecamatanFromJson(file, _kecamatan);
      }
      await _load(); // Muat ulang data setelah impor.
      if (mounted) _showImportResult(importResult);
    } catch (e, stack) {
      ErrorLogger.e('Import $type gagal', e, stack);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import gagal: $e'), backgroundColor: AppColors.error));
      if (mounted) setState(() => _loading = false);
    }
  }

  // Menampilkan dialog hasil impor (jumlah berhasil, duplikat, gagal).
  void _showImportResult(ImportResult r) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Hasil Import ${r.inserted} berhasil, ${r.duplicates} duplikat, ${r.failed} gagal'),
        content: r.errors.isNotEmpty ? Column(mainAxisSize: MainAxisSize.min, children: r.errors.map((e) => Text(e, style: const TextStyle(fontSize: 12))).toList()) : null,
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Kecamatan'),
        actions: [
          // Tombol ekspor (popup menu).
          PopupMenuButton<String>(
            onSelected: _export,
            tooltip: 'Export',
            icon: _exporting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.download_rounded),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'JSON', child: Text('JSON (GeoJSON)')),
              PopupMenuItem(value: 'Excel', child: Text('Excel')),
              PopupMenuItem(value: 'SQL', child: Text('SQL Dump')),
            ],
          ),
          // Tombol impor (popup menu).
          PopupMenuButton<String>(
            onSelected: _import,
            tooltip: 'Import',
            icon: const Icon(Icons.upload_file_rounded),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'Excel', child: Text('Import Excel (.xlsx)')),
              PopupMenuItem(value: 'SQL', child: Text('Import SQL (.sql)')),
              PopupMenuItem(value: 'JSON', child: Text('Import JSON (GeoJSON)')),
            ],
          ),
          // Tombol tambah kecamatan (buka editor polygon).
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Tambah Kecamatan',
            onPressed: () async {
              final ok = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const PolygonEditorScreen()));
              if (ok == true) _load();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Pencarian kecamatan.
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: const InputDecoration(hintText: 'Cari kecamatan...', prefixIcon: Icon(Icons.search_rounded), isDense: true),
            ),
          ),
          // Daftar kecamatan (ListView).
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? const Center(child: Text('Belum ada data kecamatan'))
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final k = filtered[i];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            child: ListTile(
                              leading: const Icon(Icons.hexagon_rounded, color: AppColors.primary),
                              title: Text(k.namaKecamatan),
                              // Subtitle menampilkan status polygon dan luas (jika ada).
                              subtitle: k.hasPolygon
                                ? Text('✅ Polygon tersedia • Luas: ${k.getAreaInKm2().toStringAsFixed(2)} km²',
                                    style: const TextStyle(fontSize: 12))
                                : const Text('❌ Belum ada polygon', style: TextStyle(fontSize: 12)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Tombol edit (buka editor polygon dengan data kecamatan yang ada).
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.orange),
                                    onPressed: () async {
                                      final ok = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => PolygonEditorScreen(existingKecamatan: k)));
                                      if (ok == true) _load();
                                    },
                                  ),
                                  // Tombol hapus.
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: AppColors.error),
                                    onPressed: () => _delete(k),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}