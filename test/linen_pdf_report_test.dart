import 'package:flutter_test/flutter_test.dart';
import 'package:smile_rs/utils/linen_pdf_report.dart';

void main() {
  test('creates a downloadable PDF when there are no rows', () async {
    final bytes = await createLinenPdfReport(
      title: 'Laporan Linen & Tirai Masuk',
      period: 'Semua Periode',
      printedDate: '22 October 2026',
      linenOfficer: 'Petugas',
      laundryOfficer: '-',
      rows: const [],
    );

    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(bytes.length, greaterThan(500));
  });

  test('creates a PDF report containing supplied table data', () async {
    final bytes = await createLinenPdfReport(
      title: 'Laporan Linen & Tirai Keluar',
      period: '01/09/2026 - 30/09/2026',
      printedDate: '22 October 2026',
      linenOfficer: 'Petugas',
      laundryOfficer: 'Laundry',
      rows: const [
        ['1', 'Tag RFID', 'Set OK', '14', 'IGD'],
      ],
    );

    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(bytes.length, greaterThan(500));
  });
}
