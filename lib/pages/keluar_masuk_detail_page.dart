import 'package:flutter/material.dart';

import '../api/api_service.dart';
import '../widgets/shared_widgets.dart';

class InOutDetailPage extends StatefulWidget {
  const InOutDetailPage({
    super.key,
    required this.userName,
    required this.ruanganId,
    required this.namaRuangan,
  });

  final String userName;
  final int ruanganId;
  final String namaRuangan;

  @override
  State<InOutDetailPage> createState() => _InOutDetailPageState();
}

class _InOutDetailPageState extends State<InOutDetailPage> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _data = const {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await ApiService.instance.getInOutDetail(widget.ruanganId);
      if (!mounted) return;
      final raw = response['data'];
      setState(() {
        _data = raw is Map ? Map<String, dynamic>.from(raw) : response;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Tidak dapat mengambil detail Keluar Masuk dari server.';
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> _list(String key) {
    final value = _data[key];
    if (value is! List) return const [];
    return value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  String _firstValue(List<String> keys, {String fallback = '-'}) {
    for (final key in keys) {
      final value = _data[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return fallback;
  }

  String _itemValue(Map<String, dynamic> item, List<String> keys) {
    for (final key in keys) {
      final value = item[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return '-';
  }

  @override
  Widget build(BuildContext context) {
    final keluar = _list('linen_keluar');
    final masuk = _list('linen_masuk');

    final namaRuangan = _firstValue(
      ['nama_ruangan', 'ruangan'],
      fallback: widget.namaRuangan,
    );
    final kepala = _firstValue(
      ['nama_kepala_ruangan', 'kepala_ruangan'],
    );
    final jumlahMasuk = _firstValue(
      ['jumlah_masuk', 'total_masuk', 'linen_masuk_count'],
      fallback: masuk.length.toString(),
    );
    final jumlahKeluar = _firstValue(
      ['jumlah_keluar', 'total_keluar', 'linen_keluar_count'],
      fallback: keluar.length.toString(),
    );

    return AppShell(
      userName: widget.userName,
      activeIndex: -1,
      showBottomNavigation: false,
      body: AppRefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
          child: _loading
              ? const AppPageLoading()
              : _error != null
                  ? Column(
                      children: [
                        const SizedBox(height: 40),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _load,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SectionTitle(title: 'Detail Keluar Masuk Linen & Tirai'),
                        const SizedBox(height: 14),
                        TableSurface(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _InfoRow(label: 'Nama Ruangan', value: namaRuangan),
                                _InfoRow(label: 'Nama Kepala Ruangan', value: kepala),
                                _InfoRow(label: 'Jumlah Masuk', value: jumlahMasuk),
                                _InfoRow(label: 'Jumlah Keluar', value: jumlahKeluar),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        _TransactionTable(
                          title: 'Linen Keluar',
                          rows: keluar,
                        ),
                        const SizedBox(height: 20),
                        _TransactionTable(
                          title: 'Linen Masuk',
                          rows: masuk,
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 145,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xff6f7f8d),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              ': $value',
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xff34495e),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionTable extends StatelessWidget {
  const _TransactionTable({required this.title, required this.rows});

  final String title;
  final List<Map<String, dynamic>> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(title: title),
        const SizedBox(height: 8),
        TableSurface(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(const Color(0xff1261dc)),
                    headingTextStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                    dataTextStyle: const TextStyle(
                      color: Color(0xff465564),
                      fontSize: 9,
                    ),
                    columnSpacing: 12,
                    horizontalMargin: 8,
                    columns: const [
                      DataColumn(label: Text('No.')),
                      DataColumn(label: Text('Nama Linen')),
                      DataColumn(label: Text('Tag RFID')),
                      DataColumn(label: Text('QR Code')),
                      DataColumn(label: Text('Waktu')),
                    ],
                    rows: rows.asMap().entries.map((entry) {
                      final item = entry.value;
                      String value(List<String> keys) {
                        for (final key in keys) {
                          final v = item[key];
                          if (v != null && v.toString().trim().isNotEmpty) {
                            return v.toString();
                          }
                        }
                        return '-';
                      }

                      return DataRow(
                        cells: [
                          DataCell(Text('${entry.key + 1}')),
                          DataCell(Text(value(['nama_linen', 'nama_kategori_linen', 'linen']))),
                          DataCell(Text(value(['tag_rfid', 'rfid']))),
                          DataCell(Text(value(['qr_code', 'qr']))),
                          DataCell(Text(value(['waktu', 'waktu_transaksi', 'tanggal']))),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ),
        if (rows.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Data Kosong',
              style: TextStyle(
                fontSize: 10,
                color: Color(0xff8b99a5),
              ),
            ),
          ),
      ],
    );
  }
}
