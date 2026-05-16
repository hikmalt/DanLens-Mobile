// FILE: lib/services/import_service.dart
// File ini menyediakan layanan untuk mengimpor data tempat dan kecamatan dari file eksternal (Excel, SQL, JSON).
// Fungsi: Membaca file, mem-parsing data, dan menyisipkannya ke database Supabase dengan penanganan duplikat.
// Informasi penting: Untuk tempat, duplikat dicek berdasarkan nama_tempat. Untuk kecamatan, duplikat dicek berdasarkan nama_kecamatan.
//         Menggunakan package excel untuk membaca file .xlsx, dan regex untuk parsing SQL.
//         Hasil import dikembalikan dalam bentuk ImportResult (jumlah berhasil, duplikat, gagal, dan daftar error).

import 'dart:io';
import 'package:excel/excel.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';
import '../utils/error_logger.dart';
import 'dart:convert'; // Untuk JSON decode.

// Kelas untuk menyimpan hasil operasi import.
class ImportResult {
  final int inserted;           // Jumlah data yang berhasil disisipkan.
  final int duplicates;         // Jumlah data yang dilewati karena duplikat.
  final int failed;             // Jumlah data yang gagal disimpan.
  final List<String> duplicateNames; // Daftar nama yang duplikat.
  final List<String> errors;    // Daftar pesan error.

  ImportResult({
    required this.inserted,
    required this.duplicates,
    required this.failed,
    required this.duplicateNames,
    required this.errors,
  });

  // Ringkasan singkat hasil import.
  String get summary =>
      '✅ $inserted berhasil · ⚠️ $duplicates duplikat · ❌ $failed gagal';
}

class ImportService {
  // ------------------------------------------------------------------
  // IMPORT TEMPAT DARI EXCEL
  // ------------------------------------------------------------------

  // Mengimpor data tempat dari file Excel (.xlsx).
  // Parameter: file (File Excel), existing (daftar tempat yang sudah ada di database untuk cek duplikat).
  static Future<ImportResult> importFromExcel(
    File file,
    List<TempatModel> existing,
  ) async {
    int inserted = 0, duplicates = 0, failed = 0;
    final dupNames = <String>[];
    final errors = <String>[];

    try {
      // Baca file sebagai bytes dan decode Excel.
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);

      // Ambil sheet pertama.
      final sheetName = excel.tables.keys.first;
      final sheet = excel.tables[sheetName]!;

      if (sheet.rows.isEmpty) {
        return ImportResult(
          inserted: 0, duplicates: 0, failed: 0,
          duplicateNames: [], errors: ['File Excel kosong'],
        );
      }

      // Baca baris header (baris 0) untuk menentukan posisi kolom.
      final headers = sheet.rows[0]
          .map((c) => c?.value?.toString().toLowerCase().trim() ?? '')
          .toList();

      ErrorLogger.i('Excel headers: $headers');

      // Fungsi helper untuk mencari indeks kolom berdasarkan kata kunci.
      int colIdx(String name) => headers.indexWhere((h) => h.contains(name));

      // Cari indeks kolom yang dibutuhkan.
      final colNama = colIdx('nama');
      final colDetail = colIdx('detail');
      final colJalan = colIdx('jalan');
      final colKecId = colIdx('kecamatan_id');
      final colKatId = colIdx('kategori_id');
      final colLat = colIdx('lat');
      final colLng = colIdx('lon');
      final colRating = colIdx('rating');
      final colKontak = colIdx('kontak');
      final colMedia = colIdx('media');

      // Pastikan kolom nama_tempat ada.
      if (colNama < 0) {
        return ImportResult(
          inserted: 0, duplicates: 0, failed: 0,
          duplicateNames: [],
          errors: ['Kolom "nama_tempat" tidak ditemukan di Excel'],
        );
      }

      // Kumpulkan nama tempat yang sudah ada (untuk deteksi duplikat).
      final existingNames =
          existing.map((t) => t.namaTempat.toLowerCase().trim()).toSet();

      // Proses setiap baris setelah header (mulai baris 1).
      for (var i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        final nama = _cellStr(row, colNama);
        if (nama.isEmpty) continue;

        // Jika nama sudah ada, lewati (duplikat).
        if (existingNames.contains(nama.toLowerCase().trim())) {
          duplicates++;
          dupNames.add(nama);
          ErrorLogger.w('Duplicate skipped: $nama');
          continue;
        }

        try {
          // Bangun map data untuk disisipkan.
          final data = {
            'nama_tempat': nama,
            'detail_tempat': _cellStr(row, colDetail).isEmpty
                ? null : _cellStr(row, colDetail),
            'jalan': _cellStr(row, colJalan).isEmpty
                ? null : _cellStr(row, colJalan),
            'kecamatan_id': _cellInt(row, colKecId),
            'kategori_id': _cellInt(row, colKatId),
            'latitude': _cellDouble(row, colLat),
            'longitude': _cellDouble(row, colLng),
            'review_rating': _cellDouble(row, colRating),
            'kontak': _cellStr(row, colKontak).isEmpty
                ? null : _cellStr(row, colKontak),
            'media': _cellStr(row, colMedia).isEmpty
                ? null : _cellStr(row, colMedia),
          };

          // Sisipkan ke Supabase.
          final result = await SupabaseService.insertTempat(data);
          if (result != null) {
            inserted++;
            existingNames.add(nama.toLowerCase().trim()); // Tambahkan ke set untuk baris berikutnya.
          } else {
            failed++;
            errors.add('Baris ${i + 1}: $nama — gagal disimpan');
          }
        } catch (e) {
          failed++;
          errors.add('Baris ${i + 1}: $nama — ${e.toString()}');
          ErrorLogger.e('Import row $i failed', e);
        }
      }
    } catch (e, stack) {
      ErrorLogger.e('importFromExcel failed', e, stack);
      errors.add('Error membaca file: ${e.toString()}');
    }

    return ImportResult(
      inserted: inserted,
      duplicates: duplicates,
      failed: failed,
      duplicateNames: dupNames,
      errors: errors,
    );
  }

  // ------------------------------------------------------------------
  // IMPORT TEMPAT DARI SQL (.sql)
  // ------------------------------------------------------------------

  // Mengimpor data tempat dari file SQL yang berisi pernyataan INSERT.
  static Future<ImportResult> importFromSql(
    File file,
    List<TempatModel> existing,
  ) async {
    int inserted = 0, duplicates = 0, failed = 0;
    final dupNames = <String>[];
    final errors = <String>[];

    try {
      final content = await file.readAsString();
      final existingNames =
          existing.map((t) => t.namaTempat.toLowerCase().trim()).toSet();

      // Regex untuk menangkap seluruh pernyataan INSERT INTO ... VALUES (...);
      final insertRegex = RegExp(
        r"INSERT INTO\s+\w+\s*\([^)]+\)\s*VALUES\s*(.+?);",
        caseSensitive: false,
        dotAll: true,
      );

      // Regex untuk menangkap nilai dalam kurung (value row).
      final valueRowRegex = RegExp(r'\(([^)]+)\)');

      // Iterasi setiap pernyataan INSERT.
      for (final match in insertRegex.allMatches(content)) {
        final valuesBlock = match.group(1) ?? '';

        // Iterasi setiap baris nilai (mungkin multiple values dalam satu INSERT).
        for (final rowMatch in valueRowRegex.allMatches(valuesBlock)) {
          final raw = rowMatch.group(1) ?? '';
          final cols = _parseSqlRow(raw); // Pisahkan kolom.

          if (cols.length < 2) continue;

          // Asumsikan urutan kolom: id, nama_tempat, detail, jalan, kecamatan_id, lat, lng, kategori_id, rating, kontak, media.
          String nama = '';
          if (cols.length > 1) {
            nama = _stripQuotes(cols[1]); // Hapus tanda kutip.
          }
          if (nama.isEmpty || nama == 'NULL') continue;

          // Cek duplikat.
          if (existingNames.contains(nama.toLowerCase().trim())) {
            duplicates++;
            dupNames.add(nama);
            continue;
          }

          try {
            // Bangun data sesuai kolom yang tersedia.
            final data = <String, dynamic>{
              'nama_tempat': nama,
              if (cols.length > 2) 'detail_tempat': _sqlVal(cols, 2),
              if (cols.length > 3) 'jalan': _sqlVal(cols, 3),
              if (cols.length > 4) 'kecamatan_id': _sqlInt(cols, 4),
              if (cols.length > 5) 'latitude': _sqlDouble(cols, 5),
              if (cols.length > 6) 'longitude': _sqlDouble(cols, 6),
              if (cols.length > 7) 'kategori_id': _sqlInt(cols, 7),
              if (cols.length > 8) 'review_rating': _sqlDouble(cols, 8),
              if (cols.length > 9) 'kontak': _sqlVal(cols, 9),
              if (cols.length > 10) 'media': _sqlVal(cols, 10),
            };

            final result = await SupabaseService.insertTempat(data);
            if (result != null) {
              inserted++;
              existingNames.add(nama.toLowerCase().trim());
            } else {
              failed++;
              errors.add('$nama — gagal disimpan');
            }
          } catch (e) {
            failed++;
            errors.add('$nama — ${e.toString()}');
            ErrorLogger.e('Import SQL row failed: $nama', e);
          }
        }
      }
    } catch (e, stack) {
      ErrorLogger.e('importFromSql failed', e, stack);
      errors.add('Error membaca file SQL: ${e.toString()}');
    }

    return ImportResult(
      inserted: inserted,
      duplicates: duplicates,
      failed: failed,
      duplicateNames: dupNames,
      errors: errors,
    );
  }

  // ------------------------------------------------------------------
  // FUNGSI BANTUAN UNTUK PARSING
  // ------------------------------------------------------------------

  // Mengambil nilai string dari sel Excel (cell).
  static String _cellStr(List<Data?> row, int idx) {
    if (idx < 0 || idx >= row.length) return '';
    return row[idx]?.value?.toString().trim() ?? '';
  }

  // Mengambil nilai integer dari sel Excel.
  static int? _cellInt(List<Data?> row, int idx) {
    final s = _cellStr(row, idx);
    return s.isEmpty ? null : int.tryParse(s);
  }

  // Mengambil nilai double dari sel Excel.
  static double? _cellDouble(List<Data?> row, int idx) {
    final s = _cellStr(row, idx);
    return s.isEmpty ? null : double.tryParse(s);
  }

  // Mem-parsing baris nilai SQL menjadi daftar string (memperhatikan kutip).
  static List<String> _parseSqlRow(String raw) {
    final result = <String>[];
    final buf = StringBuffer();
    bool inQuote = false;

    for (var i = 0; i < raw.length; i++) {
      final c = raw[i];
      // Deteksi awal/akhir kutip tunggal, hindari karakter escape.
      if (c == "'" && (i == 0 || raw[i - 1] != '\\')) {
        inQuote = !inQuote;
        buf.write(c);
      } else if (c == ',' && !inQuote) {
        result.add(buf.toString().trim());
        buf.clear();
      } else {
        buf.write(c);
      }
    }
    if (buf.isNotEmpty) result.add(buf.toString().trim());
    return result;
  }

  // Menghapus tanda kutip tunggal di awal dan akhir string.
  static String _stripQuotes(String s) {
    s = s.trim();
    if (s.startsWith("'") && s.endsWith("'")) {
      return s.substring(1, s.length - 1).replaceAll("''", "'");
    }
    return s;
  }

  // Mengambil nilai string dari hasil parsing SQL, mengubah NULL menjadi null.
  static String? _sqlVal(List<String> cols, int idx) {
    if (idx >= cols.length) return null;
    final v = _stripQuotes(cols[idx]);
    if (v.toUpperCase() == 'NULL' || v.isEmpty) return null;
    return v;
  }

  // Mengambil nilai integer dari hasil parsing SQL.
  static int? _sqlInt(List<String> cols, int idx) {
    final v = _sqlVal(cols, idx);
    return v == null ? null : int.tryParse(v);
  }

  // Mengambil nilai double dari hasil parsing SQL.
  static double? _sqlDouble(List<String> cols, int idx) {
    final v = _sqlVal(cols, idx);
    return v == null ? null : double.tryParse(v);
  }

  // ------------------------------------------------------------------
  // IMPORT KECAMATAN DARI EXCEL
  // ------------------------------------------------------------------

  // Mengimpor data kecamatan dari file Excel.
  static Future<ImportResult> importKecamatanFromExcel(File file, List<KecamatanModel> existing) async {
    int inserted = 0, duplicates = 0, failed = 0;
    final dupNames = <String>[];
    final errors = <String>[];

    try {
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      final sheet = excel.tables.values.first; // Ambil sheet pertama.
      if (sheet.rows.isEmpty) {
        return ImportResult(inserted: 0, duplicates: 0, failed: 0, duplicateNames: [], errors: ['File Excel kosong']);
      }

      // Cari kolom berdasarkan header.
      final headers = sheet.rows[0].map((c) => c?.value?.toString().toLowerCase().trim() ?? '').toList();
      int colNama = headers.indexWhere((h) => h.contains('nama'));
      int colGeojson = headers.indexWhere((h) => h.contains('geojson'));
      if (colNama < 0) {
        return ImportResult(inserted: 0, duplicates: 0, failed: 0, duplicateNames: [], errors: ['Kolom "nama_kecamatan" tidak ditemukan']);
      }

      // Nama kecamatan yang sudah ada untuk pengecekan duplikat.
      final existingNames = existing.map((k) => k.namaKecamatan.toLowerCase().trim()).toSet();

      // Proses setiap baris data (mulai baris 1).
      for (var i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        final nama = _cellStr(row, colNama);
        if (nama.isEmpty) continue;
        if (existingNames.contains(nama.toLowerCase().trim())) {
          duplicates++;
          dupNames.add(nama);
          continue;
        }
        String geojson = '';
        if (colGeojson >= 0) geojson = _cellStr(row, colGeojson);
        if (geojson.isEmpty) {
          failed++;
          errors.add('Baris ${i+1}: $nama — GeoJSON kosong');
          continue;
        }
        try {
          await SupabaseService.insertKecamatan({'nama_kecamatan': nama, 'geojson': geojson});
          inserted++;
          existingNames.add(nama.toLowerCase().trim());
        } catch (e) {
          failed++;
          errors.add('Baris ${i+1}: $nama — ${e.toString()}');
        }
      }
    } catch (e, s) {
      ErrorLogger.e('importKecamatanFromExcel failed', e, s);
      errors.add('Error membaca file: ${e.toString()}');
    }
    return ImportResult(inserted: inserted, duplicates: duplicates, failed: failed, duplicateNames: dupNames, errors: errors);
  }

  // ------------------------------------------------------------------
  // IMPORT KECAMATAN DARI SQL
  // ------------------------------------------------------------------

  static Future<ImportResult> importKecamatanFromSql(File file, List<KecamatanModel> existing) async {
    int inserted = 0, duplicates = 0, failed = 0;
    final dupNames = <String>[];
    final errors = <String>[];

    try {
      final content = await file.readAsString();
      final existingNames = existing.map((k) => k.namaKecamatan.toLowerCase().trim()).toSet();

      // Regex untuk INSERT INTO kecamatan.
      final insertRegex = RegExp(r"INSERT INTO\s+kecamatan\s*\([^)]+\)\s*VALUES\s*(.+?);", caseSensitive: false, dotAll: true);
      final valueRowRegex = RegExp(r'\(([^)]+)\)');

      for (final match in insertRegex.allMatches(content)) {
        final valuesBlock = match.group(1) ?? '';
        for (final rowMatch in valueRowRegex.allMatches(valuesBlock)) {
          final raw = rowMatch.group(1) ?? '';
          final cols = _parseSqlRow(raw);
          if (cols.length < 2) continue;
          final nama = _stripQuotes(cols[1]);
          if (nama.isEmpty || nama == 'NULL') continue;
          if (existingNames.contains(nama.toLowerCase().trim())) {
            duplicates++;
            dupNames.add(nama);
            continue;
          }
          final geojson = cols.length > 2 ? _stripQuotes(cols[2]) : '';
          if (geojson.isEmpty) {
            failed++;
            errors.add('$nama — GeoJSON kosong');
            continue;
          }
          try {
            await SupabaseService.insertKecamatan({'nama_kecamatan': nama, 'geojson': geojson});
            inserted++;
            existingNames.add(nama.toLowerCase().trim());
          } catch (e) {
            failed++;
            errors.add('$nama — ${e.toString()}');
          }
        }
      }
    } catch (e, s) {
      ErrorLogger.e('importKecamatanFromSql failed', e, s);
      errors.add('Error parsing SQL: ${e.toString()}');
    }
    return ImportResult(inserted: inserted, duplicates: duplicates, failed: failed, duplicateNames: dupNames, errors: errors);
  }

  // ------------------------------------------------------------------
  // IMPORT KECAMATAN DARI JSON
  // ------------------------------------------------------------------

  static Future<ImportResult> importKecamatanFromJson(File file, List<KecamatanModel> existing) async {
    int inserted = 0, duplicates = 0, failed = 0;
    final dupNames = <String>[];
    final errors = <String>[];

    try {
      final jsonString = await file.readAsString();
      final List<dynamic> list = jsonDecode(jsonString); // Decode JSON menjadi List.
      final existingNames = existing.map((k) => k.namaKecamatan.toLowerCase().trim()).toSet();

      for (var i = 0; i < list.length; i++) {
        final obj = list[i] as Map<String, dynamic>;
        final nama = (obj['nama_kecamatan'] ?? '').toString().trim();
        if (nama.isEmpty) {
          failed++;
          errors.add('Baris ${i+1}: nama_kecamatan kosong');
          continue;
        }
        if (existingNames.contains(nama.toLowerCase())) {
          duplicates++;
          dupNames.add(nama);
          continue;
        }
        final geojson = obj['geojson']?.toString() ?? '';
        if (geojson.isEmpty) {
          failed++;
          errors.add('$nama — GeoJSON kosong');
          continue;
        }
        try {
          await SupabaseService.insertKecamatan({'nama_kecamatan': nama, 'geojson': geojson});
          inserted++;
          existingNames.add(nama.toLowerCase());
        } catch (e) {
          failed++;
          errors.add('$nama — ${e.toString()}');
        }
      }
    } catch (e, s) {
      ErrorLogger.e('importKecamatanFromJson failed', e, s);
      errors.add('Error parsing JSON: ${e.toString()}');
    }
    return ImportResult(inserted: inserted, duplicates: duplicates, failed: failed, duplicateNames: dupNames, errors: errors);
  }
}