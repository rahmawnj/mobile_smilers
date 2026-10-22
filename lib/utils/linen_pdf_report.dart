import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

Future<Uint8List> createLinenPdfReport({
  required String title,
  required String period,
  required String printedDate,
  required String linenOfficer,
  required String laundryOfficer,
  required List<List<String>> rows,
  String? room,
  String? search,
}) async {
  final reportRows = rows.isEmpty
      ? <List<String>>[
          ['', 'Tidak ada data', '', '', ''],
        ]
      : rows;
  final document = pw.Document();
  document.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(36, 34, 36, 32),
      maxPages: 300,
      build: (context) => [
        pw.Center(
          child: pw.Text(
            title,
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Center(
          child: pw.Text(period, style: const pw.TextStyle(fontSize: 12)),
        ),
        pw.SizedBox(height: 8),
        pw.Divider(color: PdfColors.grey700, thickness: 1),
        pw.SizedBox(height: 8),
        pw.Text(
          'RS Anugerah Global Sehat',
          style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text('Madiun', style: const pw.TextStyle(fontSize: 12)),
        if (room != null || (search != null && search.isNotEmpty)) ...[
          pw.SizedBox(height: 6),
          if (room != null)
            pw.Text('Ruangan: $room', style: const pw.TextStyle(fontSize: 9)),
          if (search != null && search.isNotEmpty)
            pw.Text(
              'Pencarian: $search',
              style: const pw.TextStyle(fontSize: 9),
            ),
        ],
        pw.SizedBox(height: 8),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Container(
            width: 205,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
            ),
            child: pw.Column(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 4,
                  ),
                  child: pw.Text(
                    'Tanggal Cetak / Pengambilan',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                ),
                pw.Container(
                  width: double.infinity,
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      top: pw.BorderSide(color: PdfColors.grey400),
                    ),
                  ),
                  padding: const pw.EdgeInsets.symmetric(vertical: 4),
                  child: pw.Center(
                    child: pw.Text(
                      printedDate,
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        pw.SizedBox(height: 14),
        pw.TableHelper.fromTextArray(
          headers: const [
            'No.',
            'Nama Linen',
            'Kategori Linen',
            'Jumlah',
            'Ruangan',
          ],
          data: reportRows,
          headerStyle: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),
          headerDecoration: pw.BoxDecoration(
            color: PdfColor.fromInt(0xff3158ff),
          ),
          cellStyle: const pw.TextStyle(fontSize: 10),
          cellPadding: const pw.EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 6,
          ),
          border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.6),
          columnWidths: const {
            0: pw.FixedColumnWidth(42),
            1: pw.FlexColumnWidth(1.4),
            2: pw.FlexColumnWidth(1.6),
            3: pw.FixedColumnWidth(65),
            4: pw.FlexColumnWidth(1.1),
          },
        ),
        pw.SizedBox(height: 20),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                children: [
                  pw.Text('Petugas Linen'),
                  pw.SizedBox(height: 55),
                  pw.Text(linenOfficer),
                ],
              ),
            ),
            pw.Expanded(
              child: pw.Column(
                children: [
                  pw.Text('Petugas Laundry'),
                  pw.SizedBox(height: 55),
                  pw.Text(laundryOfficer),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
  return Uint8List.fromList(await document.save());
}
