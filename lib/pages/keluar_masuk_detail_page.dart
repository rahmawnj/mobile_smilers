import 'package:flutter/material.dart';

import '../api/api_service.dart';
import '../widgets/pagination_widget.dart';
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
  LinenListResponse<LinenKeluarItem>? _keluarResponse;
  LinenListResponse<LinenMasukItem>? _masukResponse;
  int _keluarPage = 1;
  int _masukPage = 1;
  int _keluarPerPage = 10;
  int _masukPerPage = 10;

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
      final results = await Future.wait<dynamic>([
        ApiService.instance.getInOutDetail(widget.ruanganId),
        ApiService.instance.getLinenKeluar(ruangan: widget.ruanganId, perPage: _keluarPerPage, page: _keluarPage),
        ApiService.instance.getLinenMasuk(ruangan: widget.ruanganId, perPage: _masukPerPage, page: _masukPage),
      ]);
      if (!mounted) return;
      final raw = results[0]['data'];
      setState(() {
        _data = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
        _keluarResponse = results[1] as LinenListResponse<LinenKeluarItem>;
        _masukResponse = results[2] as LinenListResponse<LinenMasukItem>;
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

    return Scaffold(
      backgroundColor: const Color(0xfff5f8fc),
      body: SafeArea(
        bottom: false,
        child: AppRefreshIndicator(
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _DetailHeader(
                  namaRuangan: namaRuangan,
                  onBack: () => Navigator.of(context).pop(),
                ),
                Transform.translate(
                  offset: const Offset(0, -30),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 30),
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
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: .055),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: const Color(0xffeaf2ff),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.swap_horiz_rounded,
                                  color: Color(0xff1261dc),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Detail Keluar Masuk Linen & Tirai',
                                  style: TextStyle(
                                    color: Color(0xff172b4d),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _DetailSummaryCard(
                          namaRuangan: namaRuangan,
                          totalMasuk: totalMasuk,
                          totalKeluar: totalKeluar,
                          selisih: selisih,
                        ),
                        const SizedBox(height: 18),
                        const SectionTitle(title: 'Linen & Tirai Keluar'),
                        const SizedBox(height: 8),
                        _LinenKeluarDetailTable(rows: _keluarResponse?.data ?? const []),
                        if (_keluarResponse != null)
                          _DetailPager(
                            meta: _keluarResponse!.meta,
                            perPage: _keluarPerPage,
                            onPage: (page) {
                              setState(() => _keluarPage = page);
                              _load();
                            },
                            onPerPage: (value) {
                              setState(() {
                                _keluarPerPage = value;
                                _keluarPage = 1;
                              });
                              _load();
                            },
                          ),
                        const SizedBox(height: 18),
                        const SectionTitle(title: 'Linen & Tirai Masuk'),
                        const SizedBox(height: 8),
                        _LinenMasukDetailTable(rows: _masukResponse?.data ?? const []),
                        if (_masukResponse != null)
                          _DetailPager(
                            meta: _masukResponse!.meta,
                            perPage: _masukPerPage,
                            onPage: (page) {
                              setState(() => _masukPage = page);
                              _load();
                            },
                            onPerPage: (value) {
                              setState(() {
                                _masukPerPage = value;
                                _masukPage = 1;
                              });
                              _load();
                            },
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

                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.namaRuangan, required this.onBack});
  final String namaRuangan;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 170,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff5cc9bd), Color(0xff159cf1)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -55,
            top: -70,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .10),
              ),
            ),
          ),
          Positioned(
            left: -75,
            bottom: -105,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .08),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 26),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppBackButton(onTap: onBack),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DETAIL KELUAR MASUK',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        namaRuangan,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailPager extends StatelessWidget {
  const _DetailPager({
    required this.meta,
    required this.perPage,
    required this.onPage,
    required this.onPerPage,
  });

  final LinenMeta meta;
  final int perPage;
  final ValueChanged<int> onPage;
  final ValueChanged<int> onPerPage;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total ${meta.total} data',
              style: const TextStyle(
                color: Color(0xff7d8c99),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Jumlah',
                  style: TextStyle(
                    color: Color(0xff8b99a5),
                    fontSize: 10,
                  ),
                ),
                const SizedBox(width: 6),
                AppPerPageDropdown(
                  value: perPage,
                  onChanged: onPerPage,
                ),
              ],
            ),
          ],
        ),
        if (meta.lastPage > 1)
          AppPagination(
            meta: meta,
            onPage: onPage,
            alignment: MainAxisAlignment.center,
          ),
      ],
    );
  }
}

class _DetailSummaryCard extends StatelessWidget {
  const _DetailSummaryCard({
    required this.namaRuangan,
    required this.totalMasuk,
    required this.totalKeluar,
    required this.selisih,
  });

  final String namaRuangan;
  final String totalMasuk;
  final String totalKeluar;
  final String selisih;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .055),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xffeaf2ff),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.meeting_room_rounded,
                  color: Color(0xff1261dc),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nama Ruangan',
                      style: TextStyle(
                        color: Color(0xff7d8c99),
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      namaRuangan,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xff172b4d),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _DetailStatCard(
                icon: Icons.arrow_downward_rounded,
                label: 'Linen Masuk',
                value: totalMasuk,
                iconColor: const Color(0xffe29c02),
                background: const Color(0xfffff7e6),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _DetailStatCard(
                icon: Icons.arrow_upward_rounded,
                label: 'Linen Keluar',
                value: totalKeluar,
                iconColor: const Color(0xff02c0cc),
                background: const Color(0xffe8fbfc),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _DetailStatCard(
                icon: Icons.compare_arrows_rounded,
                label: 'Selisih',
                value: selisih,
                iconColor: const Color(0xff1261dc),
                background: const Color(0xffeaf2ff),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DetailStatCard extends StatelessWidget {
  const _DetailStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    required this.background,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .045),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: iconColor, size: 17),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xff7d8c99),
              fontSize: 8,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xff172b4d),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
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

class _LinenKeluarDetailTable extends StatelessWidget {
  const _LinenKeluarDetailTable({required this.rows});
  final List<LinenKeluarItem> rows;
  @override Widget build(BuildContext context) {
    if (rows.isEmpty) return _emptyTable('Belum ada data Linen & Tirai Keluar.');
    return AppDataTable(
      headingColor: const Color(0xff02c0cc),
      columns: const [DataColumn(label: Text('No')), DataColumn(label: Text('Nama Linen')), DataColumn(label: Text('QR Code')), DataColumn(label: Text('Tag RFID')), DataColumn(label: Text('Ke Ruangan')), DataColumn(label: Text('Jam')), DataColumn(label: Text('Tanggal')), DataColumn(label: Text('User'))],
      rows: rows.asMap().entries.map((entry) { final item=entry.value; return DataRow(cells: [DataCell(Text('${entry.key+1}')), DataCell(Text(item.namaLinen.isEmpty?'-':item.namaLinen)), DataCell(Text(item.qrCode.isEmpty?'-':item.qrCode)), DataCell(Text(item.tagRfid.isEmpty?'-':item.tagRfid)), DataCell(Text(item.keRuangan.isEmpty?'-':item.keRuangan)), DataCell(Text(item.jam.isEmpty?'-':item.jam)), DataCell(Text(item.tanggal.isEmpty?'-':item.tanggal)), DataCell(Text(item.user.isEmpty?'-':item.user))]); }).toList(),
    );
  }
}

class _LinenMasukDetailTable extends StatelessWidget {
  const _LinenMasukDetailTable({required this.rows});
  final List<LinenMasukItem> rows;
  @override Widget build(BuildContext context) {
    if (rows.isEmpty) return _emptyTable('Belum ada data Linen & Tirai Masuk.');
    return AppDataTable(
      headingColor: const Color(0xffe29c02),
      columns: const [DataColumn(label: Text('No')), DataColumn(label: Text('Nama Linen')), DataColumn(label: Text('Nama Kategori Linen')), DataColumn(label: Text('QR Code')), DataColumn(label: Text('Tag RFID')), DataColumn(label: Text('Dari Ruangan')), DataColumn(label: Text('Jam')), DataColumn(label: Text('Tanggal')), DataColumn(label: Text('Keterangan'))],
      rows: rows.asMap().entries.map((entry) { final item=entry.value; return DataRow(cells: [DataCell(Text('${entry.key+1}')), DataCell(Text(item.namaLinen.isEmpty?'-':item.namaLinen)), DataCell(Text(item.namaKategoriLinen.isEmpty?'-':item.namaKategoriLinen)), DataCell(Text(item.qrCode.isEmpty?'-':item.qrCode)), DataCell(Text(item.tagRfid.isEmpty?'-':item.tagRfid)), DataCell(Text(item.dariRuangan.isEmpty?'-':item.dariRuangan)), DataCell(Text(item.jam.isEmpty?'-':item.jam)), DataCell(Text(item.tanggal.isEmpty?'-':item.tanggal)), DataCell(Text(item.keterangan.isEmpty?'-':item.keterangan))]); }).toList(),
    );
  }
}

Widget _emptyTable(String message) {
  return TableSurface(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xff8b99a5),
          ),
        ),
      ),
    ),
  );
}
class _TransactionTable extends StatelessWidget {
  const _TransactionTable({required this.rows});

  static String _label(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

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
