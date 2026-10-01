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
        _data = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
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

  Map<String, dynamic> get _ruangan {
    final value = _data['ruangan'];
    return value is Map ? Map<String, dynamic>.from(value) : const {};
  }

  Map<String, dynamic> get _ringkasan {
    final value = _data['ringkasan'];
    return value is Map ? Map<String, dynamic>.from(value) : const {};
  }

  List<Map<String, dynamic>> get _transaksi {
    final value = _data['transaksi'];
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  String _value(Map<String, dynamic> data, List<String> keys, {String fallback = '-'}) {
    for (final key in keys) {
      final value = data[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return fallback;
  }

  String _label(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final namaRuangan = _value(
      _ruangan,
      ['nama_ruangan', 'nama'],
      fallback: widget.namaRuangan,
    );
    final totalMasuk = _value(_ringkasan, ['total_masuk'], fallback: '0');
    final totalKeluar = _value(_ringkasan, ['total_keluar'], fallback: '0');
    final selisih = _value(_ringkasan, ['selisih'], fallback: '0');
    final transaksi = _transaksi;

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
                        const SectionTitle(
                          title: 'Detail Keluar Masuk Linen & Tirai',
                        ),
                        const SizedBox(height: 14),
                        TableSurface(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _InfoRow(
                                  label: 'Nama Ruangan',
                                  value: namaRuangan,
                                ),
                                _InfoRow(
                                  label: 'Stok/Linen Masuk',
                                  value: totalMasuk,
                                ),
                                _InfoRow(
                                  label: 'Linen Keluar',
                                  value: totalKeluar,
                                ),
                                _InfoRow(
                                  label: 'Selisih',
                                  value: selisih,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const SectionTitle(title: 'Transaksi'),
                        const SizedBox(height: 8),
                        if (transaksi.isEmpty)
                          TableSurface(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Center(
                                child: Column(
                                  children: const [
                                    Icon(
                                      Icons.inventory_2_outlined,
                                      size: 34,
                                      color: Color(0xff8b99a5),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Belum ada transaksi.',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Color(0xff8b99a5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        else
                          _TransactionTable(rows: transaksi),
                      ],
                    ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

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
  const _TransactionTable({required this.rows});

  final List<Map<String, dynamic>> rows;

  @override
  Widget build(BuildContext context) {
    final excluded = {'id', 'created_at', 'updated_at'};
    final keys = <String>[];

    for (final row in rows) {
      for (final key in row.keys) {
        if (!excluded.contains(key) && !keys.contains(key)) {
          keys.add(key);
        }
      }
    }

    return TableSurface(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                headingRowColor:
                    WidgetStateProperty.all(const Color(0xff1261dc)),
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
                columns: [
                  const DataColumn(label: Text('No.')),
                  ...keys.map(
                    (key) => DataColumn(label: Text(_label(key))),
                  ),
                ],
                rows: rows.asMap().entries.map((entry) {
                  final row = entry.value;
                  return DataRow(
                    cells: [
                      DataCell(Text('${entry.key + 1}')),
                      ...keys.map(
                        (key) => DataCell(
                          Text(row[key]?.toString() ?? '-'),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}
