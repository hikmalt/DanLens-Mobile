// lib/services/import_service.dart
import 'dart:io';
import 'package:excel/excel.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';
import '../utils/error_logger.dart';

class ImportResult {
  final int inserted;
  final int duplicates;
  final int failed;
  final List<String> duplicateNames;
  final List<String> errors;

  ImportResult({
    required this.inserted,
    required this.duplicates,
    required this.failed,
    required this.duplicateNames,
    required this.errors,
  });

  String get summary =>
      '✅ $inserted berhasil · ⚠️ $duplicates duplikat · ❌ $failed gagal';
}

class ImportService {
  // ── Import dari Excel (.xlsx) ──────────────────────────────
  static Future<ImportResult> importFromExcel(
    File file,
    List<TempatModel> existing,
  ) async {
    int inserted = 0, duplicates = 0, failed = 0;
    final dupNames = <String>[];
    final errors = <String>[];

    try {
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);

      // Ambil sheet pertama
      final sheetName = excel.tables.keys.first;
      final sheet = excel.tables[sheetName]!;

      if (sheet.rows.isEmpty) {
        return ImportResult(
          inserted: 0, duplicates: 0, failed: 0,
          duplicateNames: [], errors: ['File Excel kosong'],
        );
      }

      // Baca header row (row 0)
      final headers = sheet.rows[0]
          .map((c) => c?.value?.toString().toLowerCase().trim() ?? '')
          .toList();

      ErrorLogger.i('Excel headers: $headers');

      // Cari index kolom
       int colIdx(String name) => headers.indexWhere((h) => h.contains(name));

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

      if (colNama < 0) {
        return ImportResult(
          inserted: 0, duplicates: 0, failed: 0,
          duplicateNames: [],
          errors: ['Kolom "nama_tempat" tidak ditemukan di Excel'],
        );
      }

      final existingNames =
          existing.map((t) => t.namaTempat.toLowerCase().trim()).toSet();

      // Proses setiap baris (skip header)
      for (var i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        final nama = _cellStr(row, colNama);
        if (nama.isEmpty) continue;

        // Cek duplikat
        if (existingNames.contains(nama.toLowerCase().trim())) {
          duplicates++;
          dupNames.add(nama);
          ErrorLogger.w('Duplicate skipped: $nama');
          continue;
        }

        try {
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

          final result = await SupabaseService.insertTempat(data);
          if (result != null) {
            inserted++;
            existingNames.add(nama.toLowerCase().trim());
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

  // ── Import dari SQL (.sql) ─────────────────────────────────
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

      // Parse INSERT INTO ... VALUES (...) statements
      final insertRegex = RegExp(
        r"INSERT INTO\s+\w+\s*\([^)]+\)\s*VALUES\s*(.+?);",
        caseSensitive: false,
        dotAll: true,
      );

      final valueRowRegex = RegExp(r'\(([^)]+)\)');

      for (final match in insertRegex.allMatches(content)) {
        final valuesBlock = match.group(1) ?? '';

        for (final rowMatch in valueRowRegex.allMatches(valuesBlock)) {
          final raw = rowMatch.group(1) ?? '';
          final cols = _parseSqlRow(raw);

          if (cols.length < 2) continue;

          // Expect order: id, nama_tempat, detail, jalan, kecamatan_id, lat, lng, kategori_id, rating, kontak, media
          // Try to find nama (index 1 if id is first)
          String nama = '';
          if (cols.length > 1) {
            nama = _stripQuotes(cols[1]);
          }
          if (nama.isEmpty || nama == 'NULL') continue;

          if (existingNames.contains(nama.toLowerCase().trim())) {
            duplicates++;
            dupNames.add(nama);
            continue;
          }

          try {
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

  // ── Helpers ────────────────────────────────────────────────
  static String _cellStr(List<Data?> row, int idx) {
    if (idx < 0 || idx >= row.length) return '';
    return row[idx]?.value?.toString().trim() ?? '';
  }

  static int? _cellInt(List<Data?> row, int idx) {
    final s = _cellStr(row, idx);
    return s.isEmpty ? null : int.tryParse(s);
  }

  static double? _cellDouble(List<Data?> row, int idx) {
    final s = _cellStr(row, idx);
    return s.isEmpty ? null : double.tryParse(s);
  }

  static List<String> _parseSqlRow(String raw) {
    final result = <String>[];
    final buf = StringBuffer();
    bool inQuote = false;

    for (var i = 0; i < raw.length; i++) {
      final c = raw[i];
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

  static String _stripQuotes(String s) {
    s = s.trim();
    if (s.startsWith("'") && s.endsWith("'")) {
      return s.substring(1, s.length - 1).replaceAll("''", "'");
    }
    return s;
  }

  static String? _sqlVal(List<String> cols, int idx) {
    if (idx >= cols.length) return null;
    final v = _stripQuotes(cols[idx]);
    if (v.toUpperCase() == 'NULL' || v.isEmpty) return null;
    return v;
  }

  static int? _sqlInt(List<String> cols, int idx) {
    final v = _sqlVal(cols, idx);
    return v == null ? null : int.tryParse(v);
  }

  static double? _sqlDouble(List<String> cols, int idx) {
    final v = _sqlVal(cols, idx);
    return v == null ? null : double.tryParse(v);
  }
}