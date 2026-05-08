// lib/services/export_service.dart
// ignore_for_file: unnecessary_brace_in_string_interps

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import '../models/models.dart';
import '../utils/error_logger.dart';

class ExportService {
  // ── Export to PDF ──────────────────────────────────────────
  static Future<void> exportToPdf(List<TempatModel> data) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(36),
          header: (ctx) => pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('DanLens - Data Tempat Medan',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Text('${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
            ],
          ),
          footer: (ctx) => pw.Center(
            child: pw.Text('Halaman ${ctx.pageNumber} dari ${ctx.pagesCount}',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
          ),
          build: (ctx) => [
            pw.SizedBox(height: 16),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {
                0: const pw.FlexColumnWidth(0.5),
                1: const pw.FlexColumnWidth(2.0),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(1.5),
                4: const pw.FlexColumnWidth(1.0),
                5: const pw.FlexColumnWidth(1.0),
              },
              children: [
                // Header
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
                // Data
                ...data.asMap().entries.map((e) => pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: e.key.isEven ? PdfColors.grey50 : PdfColors.white,
                  ),
                  children: [
                    _pdfCell('${e.key + 1}'),
                    _pdfCell(e.value.namaTempat),
                    _pdfCell(e.value.namaKategori ?? '-'),
                    _pdfCell(e.value.namaKecamatan ?? '-'),
                    _pdfCell(e.value.latitude?.toStringAsFixed(4) ?? '-'),
                    _pdfCell(e.value.reviewRating?.toStringAsFixed(1) ?? '-'),
                  ],
                )),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Text('Total: ${data.length} tempat',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          ],
        ),
      );

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/danlens_export_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());

      await SharePlus.instance.share(ShareParams(text: 'DanLens - Data Tempat Medan', files: [XFile(file.path)]));
      ErrorLogger.i('PDF exported: ${file.path}');
    } catch (e, stack) {
      ErrorLogger.e('exportToPdf failed', e, stack);
      rethrow;
    }
  }

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
        maxLines: 2,
      ),
    );
  }

  // ── Export to Excel ────────────────────────────────────────
  static Future<void> exportToExcel(List<TempatModel> data) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Data Tempat'];

      // Header
      final headers = [
        'ID', 'Nama Tempat', 'Detail', 'Jalan', 'Kecamatan',
        'Kategori', 'Latitude', 'Longitude', 'Rating', 'Kontak', 'Media'
      ];
      for (var i = 0; i < headers.length; i++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#4a7c59'),
          fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        );
      }

      // Data rows
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

      // Auto width
      for (var i = 0; i < headers.length; i++) {
        sheet.setColumnWidth(i, 18);
      }

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

  // ── Export to SQL ──────────────────────────────────────────
  static Future<void> exportToSql(List<TempatModel> data) async {
    try {
      final buf = StringBuffer();
      buf.writeln('-- DanLens Data Export');
      buf.writeln('-- Generated: ${DateTime.now()}');
      buf.writeln('-- Total: ${data.length} records\n');
      buf.writeln('INSERT INTO tempat (id, nama_tempat, detail_tempat, jalan, kecamatan_id, latitude, longitude, kategori_id, review_rating, kontak, media) VALUES');

      for (var i = 0; i < data.length; i++) {
        final t = data[i];
        final nama = t.namaTempat.replaceAll("'", "''");
        final detail = (t.detailTempat ?? '').replaceAll("'", "''");
        final jalan = (t.jalan ?? '').replaceAll("'", "''");
        final kontak = t.kontak ?? '';
        final media = t.media ?? '';
        final isLast = i == data.length - 1;

        buf.write(
          "(${t.id}, '${nama}', '${detail}', '${jalan}', "
          "${t.kecamatanId ?? 'NULL'}, "
          "${t.latitude ?? 'NULL'}, ${t.longitude ?? 'NULL'}, "
          "${t.kategoriId ?? 'NULL'}, ${t.reviewRating ?? 'NULL'}, "
          "'${kontak}', '${media}')"
        );
        buf.writeln(isLast ? ';' : ',');
      }

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
}