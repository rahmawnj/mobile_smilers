import 'package:flutter/material.dart';

import '../../api/api_service.dart';
import '../../widgets/pagination_widget.dart';
import '../../widgets/shared_widgets.dart';

class LinenRuanganDetailPage extends StatefulWidget {
  const LinenRuanganDetailPage({
    super.key,
    required this.roomId,
    required this.roomName,
    required this.userName,
  });

  final int roomId;
  final String roomName;
  final String userName;

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
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Tidak dapat mengambil detail Linen & Tirai di Ruangan.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailRows = _response?.data ?? const <LinenRuanganDetailItem>[];
    final baRows = _baResponse?.data ?? const <LinenRuanganBaHilangItem>[];
    final roomName = _response?.ruanganName.isNotEmpty == true
        ? _response!.ruanganName
        : widget.roomName;

    return AppShell(
      userName: widget.userName,
      activeIndex: 0,
      body: Column(
        children: [
          DetailHeader(
            title: 'Detail Ruangan - $roomName',
            userName: widget.userName,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? ListView(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  const Icon(Icons.cloud_off_rounded),
                                  const SizedBox(height: 10),
                                  Text(_error!, textAlign: TextAlign.center),
                                  const SizedBox(height: 12),
                                  ElevatedButton(
                                    onPressed: _load,
                                    child: const Text('Coba Lagi'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                          children: [
                            _RoomDetailTable(
                              title: 'Linen di Ruangan',
                              columns: const [
                                'ID',
                                'Linen ID',
                                'Nama Linen',
                                'Nama Category',
                                'Status',
                                'Tanggal Keluar',
                                'Jam Keluar',
                              ],
                              rows: detailRows
                                  .map(
                                    (item) => [
                                      item.id,
                                      item.linenId,
                                      item.namaLinen,
                                      item.namaKategoriLinen,
                                      item.status,
                                      item.tanggalKeluar,
                                      item.jamKeluar,
                                    ],
                                  )
                                  .toList(),
                            ),
                            if (_response != null) AppPagination(meta: _response!.meta, onPage: (page) { setState(() => _detailPage = page); _load(); }),
                            const SizedBox(height: 18),
                            _RoomDetailTable(
                              title: 'BA Hilang',
                              columns: const [
                                'ID',
                                'Waktu Hilang',
                                'File BA',
                              ],
                              rows: baRows
                                  .map(
                                    (item) => [
                                      item.id,
                                      item.waktuHilang,
                                      item.fileUrl.isEmpty ? '-' : item.fileUrl,
                                    ],
                                  )
                                  .toList(),
                            ),
                            if (_baResponse != null) AppPagination(meta: _baResponse!.meta, onPage: (page) { setState(() => _baPage = page); _load(); }),
                          ],
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomDetailTable extends StatelessWidget {
  const _RoomDetailTable({
    required this.title,
    required this.columns,
    required this.rows,
  });

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
        TableSurface(child: LayoutBuilder(
            builder: (context, constraints) {
              const tableWidth = 1100.0;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: tableWidth,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                      const Color(0xff1261dc),
                    ),
                    headingTextStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                    dataTextStyle: const TextStyle(
                      color: Color(0xff465564),
                      fontSize: 9,
                    ),
                    columnSpacing: 24,
                    horizontalMargin: 16,
                    columns: columns
                        .map((column) => DataColumn(label: Text(column)))
                        .toList(),
                    rows: rows
                        .map(
                          (row) => DataRow(
                            cells: row
                                .map((value) => DataCell(Text(value.toString())))
                                .toList(),
                          ),
                        )
                        .toList(),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
