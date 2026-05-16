// FILE: lib/services/export_service.dart
// File ini berisi layanan untuk mengekspor data tempat dan data kecamatan ke berbagai format file.
// Fungsi: Mengekspor data ke PDF, Excel (XLSX), dan SQL (INSERT statements).
//         Juga mendukung ekspor data kecamatan (polygon) ke JSON (GeoJSON), Excel, dan SQL.
// Informasi penting: Menggunakan package pdf untuk PDF, excel untuk Excel, dan share_plus untuk berbagi file.
//         Semua file disimpan sementara di temporary directory lalu dibagikan ke aplikasi lain.
//         Ekspor tidak menyertakan gambar; hanya data teks.
//         Untuk SQL, nilai null ditulis sebagai NULL (tanpa tanda kutip).

// ignore_for_file: unnecessary_brace_in_string_interps

// Mengimpor pustaka untuk encoding JSON.
import 'dart:convert';
// Mengimpor pustaka untuk operasi file (File, Directory).
import 'dart:io';
// Mengimpor path_provider untuk mendapatkan direktori temporary.
import 'package:path_provider/path_provider.dart';
// Mengimpor share_plus untuk berbagi file ke aplikasi lain (Email, Drive, dll).
import 'package:share_plus/share_plus.dart';
// Mengimpor package pdf untuk membuat file PDF.
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
// Mengimpor package excel untuk membuat file Excel.
import 'package:excel/excel.dart';
// Mengimpor model-model data.
import '../models/models.dart';
// Mengimpor error logger untuk mencatat keberhasilan/kegagalan.
import '../utils/error_logger.dart';

class ExportService {
  // ------------------------------------------------------------------
  //  EKSPOR KE PDF (UNTUK DATA TEMPAT)
  // ------------------------------------------------------------------
  // Mengekspor daftar tempat ke file PDF dengan format tabel.
  static Future<void> exportToPdf(List<TempatModel> data) async {
    try {
      // Buat dokumen PDF baru.
      final pdf = pw.Document();

      // Tambahkan halaman dengan MultiPage (mendukung header, footer, dan paginasi).
      pdf.addPage(
        pw.MultiPage(
          // Format halaman A4.
          pageFormat: PdfPageFormat.a4,
          // Margin halaman 36 poin di semua sisi.
          margin: const pw.EdgeInsets.all(36),
          // Header: judul dan tanggal.
          header: (ctx) => pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('DanLens - Data Tempat Medan',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Text('${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
            ],
          ),
          // Footer: nomor halaman.
          footer: (ctx) => pw.Center(
            child: pw.Text('Halaman ${ctx.pageNumber} dari ${ctx.pagesCount}',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
          ),
          // Konten utama: tabel.
          build: (ctx) => [
            pw.SizedBox(height: 16),
            pw.Table(
              // Border abu-abu di semua sel.
              border: pw.TableBorder.all(color: PdfColors.grey300),
              // Lebar kolom (proporsional).
              columnWidths: {
                0: const pw.FlexColumnWidth(0.5), // No
                1: const pw.FlexColumnWidth(2.0), // Nama Tempat
                2: const pw.FlexColumnWidth(1.5), // Kategori
                3: const pw.FlexColumnWidth(1.5), // Kecamatan
                4: const pw.FlexColumnWidth(1.0), // Lat
                5: const pw.FlexColumnWidth(1.0), // Rating
              },
              children: [
                // Baris header (warna hijau).
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.green800),
                  children: [
                    _pdfCell('No', isHeader: true),
                    _pdfCell('Nama Tempat', isHeader: true),
                    _pdfCell('Kategori', isHeader: true),
                    _pdfCell('Kecamatan', isHeader: true),
                    _pdfCell('Lat', isHeader: true),
                    _pdfCell('Rating', isHeader: true),
                  ],
                ),
                // Baris data (setiap tempat).
                ...data.asMap().entries.map((e) => pw.TableRow(
                  // Warna latar berselang (ganti-ganti) untuk keterbacaan.
                  decoration: pw.BoxDecoration(
                    color: e.key.isEven ? PdfColors.grey50 : PdfColors.white,
                  ),
                  children: [
                    _pdfCell('${e.key + 1}'), // Nomor urut.
                    _pdfCell(e.value.namaTempat),
                    _pdfCell(e.value.namaKategori ?? '-'),
                    _pdfCell(e.value.namaKecamatan ?? '-'),
                    _pdfCell(e.value.latitude?.toStringAsFixed(4) ?? '-'),
                    _pdfCell(e.value.reviewRating?.toStringAsFixed(1) ?? '-'),
                  ],
                )),
              ],
            ),
            // Footer teks jumlah total tempat.
            pw.SizedBox(height: 16),
            pw.Text('Total: ${data.length} tempat',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          ],
        ),
      );

      // Simpan PDF ke file sementara.
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/danlens_export_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());

      // Bagikan file.
      await SharePlus.instance.share(ShareParams(text: 'DanLens - Data Tempat Medan', files: [XFile(file.path)]));
      ErrorLogger.i('PDF exported: ${file.path}');
    } catch (e, stack) {
      ErrorLogger.e('exportToPdf failed', e, stack);
      rethrow; // Lempar ulang agar pemanggil tahu terjadi error.
    }
  }

  // Helper untuk membuat sel tabel PDF dengan teks.
  static pw.Widget _pdfCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: isHeader ? pw.FontWeight.bold : null,
          color: isHeader ? PdfColors.white : PdfColors.black,
        ),
        maxLines: 2, // Maksimal 2 baris untuk menjaga kerapian.
      ),
    );
  }

  // ------------------------------------------------------------------
  //  EKSPOR KE EXCEL (UNTUK DATA TEMPAT)
  // ------------------------------------------------------------------
  // Mengekspor daftar tempat ke file Excel (.xlsx).
  static Future<void> exportToExcel(List<TempatModel> data) async {
    try {
      // Buat workbook baru.
      final excel = Excel.createExcel();
      // Buat sheet bernama 'Data Tempat'.
      final sheet = excel['Data Tempat'];

      // Header kolom.
      final headers = [
        'ID', 'Nama Tempat', 'Detail', 'Jalan', 'Kecamatan',
        'Kategori', 'Latitude', 'Longitude', 'Rating', 'Kontak', 'Media'
      ];
      // Tulis header di baris 0.
      for (var i = 0; i < headers.length; i++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#4a7c59'), // Warna hijau.
          fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        );
      }

      // Tulis data per baris.
      for (var i = 0; i < data.length; i++) {
        final t = data[i];
        final rowData = [
          t.id.toString(),
          t.namaTempat,
          t.detailTempat ?? '',
          t.jalan ?? '',
          t.namaKecamatan ?? '',
          t.namaKategori ?? '',
          t.latitude?.toString() ?? '',
          t.longitude?.toString() ?? '',
          t.reviewRating?.toString() ?? '',
          t.kontak ?? '',
          t.media ?? '',
        ];
        for (var j = 0; j < rowData.length; j++) {
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: j, rowIndex: i + 1))
              .value = TextCellValue(rowData[j]);
        }
      }

      // Atur lebar kolom agar lebih rapi.
      for (var i = 0; i < headers.length; i++) {
        sheet.setColumnWidth(i, 18);
      }

      // Simpan ke file sementara.
      final dir = await getTemporaryDirectory();
      final fileName = 'danlens_export_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final file = File('${dir.path}/$fileName');
      final bytes = excel.save();
      if (bytes != null) {
        await file.writeAsBytes(bytes);
        await SharePlus.instance.share(ShareParams(text: 'DanLens - Data Excel', files: [XFile(file.path)]));
        ErrorLogger.i('Excel exported: ${file.path}');
      }
    } catch (e, stack) {
      ErrorLogger.e('exportToExcel failed', e, stack);
      rethrow;
    }
  }

  // ------------------------------------------------------------------
  //  EKSPOR KE SQL (UNTUK DATA TEMPAT)
  // ------------------------------------------------------------------
  // Mengekspor daftar tempat ke file SQL (INSERT statements).
  static Future<void> exportToSql(List<TempatModel> data) async {
    try {
      final buf = StringBuffer();
      buf.writeln('-- DanLens Data Export');
      buf.writeln('-- Generated: ${DateTime.now()}');
      buf.writeln('-- Total: ${data.length} records\n');
      buf.writeln('INSERT INTO tempat (id, nama_tempat, detail_tempat, jalan, kecamatan_id, latitude, longitude, kategori_id, review_rating, kontak, media) VALUES');

      // Loop untuk setiap tempat.
      for (var i = 0; i < data.length; i++) {
        final t = data[i];
        // Escape tanda petik tunggal (') dengan ''.
        final nama = t.namaTempat.replaceAll("'", "''");
        final detail = (t.detailTempat ?? '').replaceAll("'", "''");
        final jalan = (t.jalan ?? '').replaceAll("'", "''");
        final kontak = t.kontak ?? '';
        final media = t.media ?? '';
        final isLast = i == data.length - 1;

        // Tulis satu baris INSERT VALUES.
        buf.write(
          "(${t.id}, '${nama}', '${detail}', '${jalan}', "
          "${t.kecamatanId ?? 'NULL'}, "
          "${t.latitude ?? 'NULL'}, ${t.longitude ?? 'NULL'}, "
          "${t.kategoriId ?? 'NULL'}, ${t.reviewRating ?? 'NULL'}, "
          "'${kontak}', '${media}')"
        );
        buf.writeln(isLast ? ';' : ','); // Akhiri dengan titik koma jika baris terakhir.
      }

      // Simpan ke file sementara.
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/danlens_export_${DateTime.now().millisecondsSinceEpoch}.sql');
      await file.writeAsString(buf.toString());
      await SharePlus.instance.share(ShareParams(text: 'DanLens - SQL Export', files: [XFile(file.path)]));
      ErrorLogger.i('SQL exported: ${file.path}');
    } catch (e, stack) {
      ErrorLogger.e('exportToSql failed', e, stack);
      rethrow;
    }
  }

  // ------------------------------------------------------------------
  //  EKSPOR KECAMATAN (POLYGON) KE JSON (GeoJSON)
  // ------------------------------------------------------------------
  // Mengekspor daftar kecamatan ke file JSON (format GeoJSON FeatureCollection? tidak, hanya array of objects dengan field geojson).
  static Future<void> exportKecamatanToJson(List<KecamatanModel> data) async {
    try {
      // Konversi setiap kecamatan ke Map menggunakan toJson(), lalu ke JSON string.
      final jsonList = data.map((k) => k.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/kecamatan_export_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(jsonString);
      await SharePlus.instance.share(ShareParams(
        text: 'DanLens - Data Kecamatan (GeoJSON)',
        files: [XFile(file.path)],
      ));
      ErrorLogger.i('Kecamatan JSON exported: ${file.path}');
    } catch (e, stack) {
      ErrorLogger.e('exportKecamatanToJson failed', e, stack);
      rethrow;
    }
  }

  // ------------------------------------------------------------------
  //  EKSPOR KECAMATAN KE EXCEL
  // ------------------------------------------------------------------
  static Future<void> exportKecamatanToExcel(List<KecamatanModel> data) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Kecamatan'];
      // Header: ID, Nama Kecamatan, GeoJSON.
      final headers = ['ID', 'Nama Kecamatan', 'GeoJSON'];
      for (var i = 0; i < headers.length; i++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = CellStyle(bold: true);
      }
      // Data rows.
      for (var i = 0; i < data.length; i++) {
        final k = data[i];
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i + 1)).value = TextCellValue(k.id.toString());
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i + 1)).value = TextCellValue(k.namaKecamatan);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: i + 1)).value = TextCellValue(k.geojson ?? '');
      }
      // Atur lebar kolom.
      for (var i = 0; i < headers.length; i++) {
        sheet.setColumnWidth(i, 20);
      }

      final dir = await getTemporaryDirectory();
      final fileName = 'kecamatan_export_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final file = File('${dir.path}/$fileName');
      final bytes = excel.save();
      if (bytes != null) {
        await file.writeAsBytes(bytes);
        await SharePlus.instance.share(ShareParams(
          text: 'DanLens - Data Kecamatan Excel',
          files: [XFile(file.path)],
        ));
        ErrorLogger.i('Kecamatan Excel exported: ${file.path}');
      }
    } catch (e, stack) {
      ErrorLogger.e('exportKecamatanToExcel failed', e, stack);
      rethrow;
    }
  }

  // ------------------------------------------------------------------
  //  EKSPOR KECAMATAN KE SQL (INSERT statements)
  // ------------------------------------------------------------------
  static Future<void> exportKecamatanToSql(List<KecamatanModel> data) async {
    try {
      final buf = StringBuffer();
      buf.writeln('-- DanLens Kecamatan Export');
      buf.writeln('-- Generated: ${DateTime.now()}');
      buf.writeln('-- Total: ${data.length} records\n');
      buf.writeln('INSERT INTO kecamatan (id, nama_kecamatan, geojson) VALUES');

      for (var i = 0; i < data.length; i++) {
        final k = data[i];
        final nama = k.namaKecamatan.replaceAll("'", "''");
        final geojson = (k.geojson ?? '').replaceAll("'", "''");
        final isLast = i == data.length - 1;
        buf.write("(${k.id}, '$nama', '$geojson')");
        buf.writeln(isLast ? ';' : ',');
      }

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/kecamatan_export_${DateTime.now().millisecondsSinceEpoch}.sql');
      await file.writeAsString(buf.toString());
      await SharePlus.instance.share(ShareParams(
        text: 'DanLens - Kecamatan SQL Dump',
        files: [XFile(file.path)],
      ));
      ErrorLogger.i('Kecamatan SQL exported: ${file.path}');
    } catch (e, stack) {
      ErrorLogger.e('exportKecamatanToSql failed', e, stack);
      rethrow;
    }
  }
}