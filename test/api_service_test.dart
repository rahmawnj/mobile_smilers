import 'package:flutter_test/flutter_test.dart';
import 'package:smile_rs/api/api_service.dart';

void main() {
  group('linen report response parsing', () {
    test('parses Linen Masuk categories from root report payload', () {
      final response = parseLinenMasukResponse({
        'title': 'Laporan Linen Masuk',
        'ruangan': {'nama_ruangan': 'Ruang Mawar'},
        'date': '2026-04-18',
        'petugas_laundry': 'Petugas Laundry',
        'total_keseluruhan': 12,
        'kategori_linen': [
          {'no': 1, 'nama_kategori_linen': 'Set OK', 'total': 12},
        ],
      });

      expect(response.data, hasLength(1));
      expect(response.data.single.namaKategoriLinen, 'Set OK');
      expect(response.data.single.jumlah, '12');
      expect(response.data.single.dariRuangan, 'Ruang Mawar');
      expect(response.data.single.tanggal, '2026-04-18');
      expect(response.data.single.petugasLaundry, 'Petugas Laundry');
      expect(response.meta.total, 12);
    });

    test('parses Linen Keluar linens from nested report payload', () {
      final response = parseLinenKeluarResponse({
        'data': {
          'ruangan': 'Ruang Melati',
          'date': '2026-04-18',
          'petugas_laundry': 'Petugas Laundry',
          'total_keseluruhan': 7,
          'linens': [
            {'no': 1, 'kategori_linen': 'Selimut', 'jumlah': 7},
          ],
        },
      });

      expect(response.data, hasLength(1));
      expect(response.data.single.namaKategoriLinen, 'Selimut');
      expect(response.data.single.jumlah, '7');
      expect(response.data.single.keRuangan, 'Ruang Melati');
      expect(response.data.single.tanggal, '2026-04-18');
      expect(response.data.single.user, 'Petugas Laundry');
      expect(response.meta.total, 7);
    });

    test('returns an empty list for an empty report', () {
      final response = parseLinenMasukResponse({
        'data': {'total_keseluruhan': 0, 'kategori_linen': []},
      });

      expect(response.data, isEmpty);
      expect(response.meta.total, 0);
    });

    test('keeps compatibility with the legacy paginated list format', () {
      final response = parseLinenMasukResponse({
        'data': [
          {
            'id': 42,
            'nama_linen': 'Linen Bersih',
            'kategori_linen': 'Set OK',
            'jumlah': 3,
          },
        ],
        'meta': {
          'current_page': 2,
          'per_page': 10,
          'total': 13,
          'last_page': 2,
        },
      });

      expect(response.data, hasLength(1));
      expect(response.data.single.id, 42);
      expect(response.data.single.namaLinen, 'Linen Bersih');
      expect(response.meta.currentPage, 2);
      expect(response.meta.lastPage, 2);
      expect(response.meta.total, 13);
    });
  });
}
