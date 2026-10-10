import 'package:flutter/material.dart';

import '../../api/api_service.dart';
import '../../widgets/pagination_widget.dart';
import '../../widgets/shared_widgets.dart';

class LinenRuanganDetailPage extends StatefulWidget {
  const LinenRuanganDetailPage({
    super.key, required this.roomId, required this.roomName, required this.userName, required this.stokAwal, required this.hilang, required this.jumlahLinen,
  });
  final int roomId;
  final String roomName;
  final String userName;
  final int stokAwal;
  final int hilang;
  final int jumlahLinen;

  @override
  State<LinenRuanganDetailPage> createState() => _LinenRuanganDetailPageState();
}

class _LinenRuanganDetailPageState extends State<LinenRuanganDetailPage> {
  bool _loading = true;
  String? _error;
  LinenRuanganDetailResponse? _response;
  LinenRuanganBaHilangResponse? _baResponse;
  int _detailPage = 1;
  int _baPage = 1;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        ApiService.instance.getLinenRuanganDetail(widget.roomId, perPage: 10, page: _detailPage),
        ApiService.instance.getLinenRuanganBaHilang(widget.roomId, perPage: 10, page: _baPage),
      ]);
      if (!mounted) return;
      setState(() {
        _response = results[0] as LinenRuanganDetailResponse;
        _baResponse = results[1] as LinenRuanganBaHilangResponse;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _error = 'Tidak dapat mengambil detail Linen & Tirai di Ruangan.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailRows = _response?.data ?? const <LinenRuanganDetailItem>[];
    final baRows = _baResponse?.data ?? const <LinenRuanganBaHilangItem>[];
    final roomName = _response?.ruanganName.isNotEmpty == true ? _response!.ruanganName : widget.roomName;

    return Scaffold(
      backgroundColor: const Color(0xfff5f8fc),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            DetailHeader(title: 'Detail Ruangan - $roomName', userName: widget.userName),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: .05), blurRadius: 14, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(child: _SummaryItem(label: 'Nama Ruangan', value: roomName)),
                    Expanded(child: _SummaryItem(label: 'Stok Awal', value: widget.stokAwal.toString())),
                    Expanded(child: _SummaryItem(label: 'Hilang', value: widget.hilang.toString())),
                    Expanded(child: _SummaryItem(label: 'Jumlah Linen', value: widget.jumlahLinen.toString())),
                  ],
                ),
              ),
            ),
            Expanded(
              child: AppRefreshIndicator(
                onRefresh: _load,
                child: _loading
                    ? const AppPageLoading()
                    : _error != null
                        ? ListView(children: [
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(children: [
                                const Icon(Icons.cloud_off_rounded),
                                const SizedBox(height: 10),
                                Text(_error!, textAlign: TextAlign.center),
                                const SizedBox(height: 12),
                                ElevatedButton(onPressed: _load, child: const Text('Coba Lagi')),
                              ]),
                            ),
                          ])
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                            children: [
                              _RoomDetailTable(
                                title: 'Linen di Ruangan',
                                columns: const ['No', 'Nama Linen', 'Kategori Linen', 'Jumlah'],
                                rows: detailRows.asMap().entries.map((entry) => [
                                  ((_detailPage - 1) * 10 + entry.key + 1),
                                  entry.value.namaLinen.isEmpty ? '-' : entry.value.namaLinen,
                                  entry.value.namaKategoriLinen.isEmpty ? '-' : entry.value.namaKategoriLinen,
                                  '-',
                                ]).toList(),
                              ),
                              if (_response != null)
                                AppPagination(
                                  meta: _response!.meta,
                                  onPage: (page) { setState(() => _detailPage = page); _load(); },
                                ),
                              const SizedBox(height: 18),
                              _RoomDetailTable(
                                title: 'BA Hilang',
                                columns: const ['No', 'Waktu Hilang', 'File BA'],
                                rows: baRows.asMap().entries.map((entry) => [
                                  ((_baPage - 1) * 10 + entry.key + 1),
                                  entry.value.waktuHilang,
                                  entry.value.fileUrl.isEmpty ? '-' : entry.value.fileUrl,
                                ]).toList(),
                              ),
                              if (_baResponse != null)
                                AppPagination(
                                  meta: _baResponse!.meta,
                                  onPage: (page) { setState(() => _baPage = page); _load(); },
                                ),
                            ],
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xff8b99a5), fontSize: 9, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(value, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xff334454), fontSize: 12, fontWeight: FontWeight.w800)),
      ],
    ),
  );
}

class _RoomDetailTable extends StatelessWidget {
  const _RoomDetailTable({required this.title, required this.columns, required this.rows});
  final String title;
  final List<String> columns;
  final List<List<dynamic>> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(title: title),
        const SizedBox(height: 8),
        AppDataTable(
          columns: columns.map((column) => DataColumn(label: Text(column))).toList(),
          rows: rows.map((row) => DataRow(
            cells: row.map((value) => DataCell(Text(value.toString()))).toList(),
          )).toList(),
        ),
      ],
    );
  }
}
