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

    return Scaffold(
      backgroundColor: const Color(0xfff5f8fc),
      body: SafeArea(
        bottom: false,
        child: Column(
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
                                'No',
                                'Nama Linen',
                                'Nama Kategori Linen',
                                'Status',
                                'Tanggal Keluar',
                                'Jam Keluar',
                              ],
                              rows: detailRows.asMap().entries
                                  .map(
                                    (entry) => [
                                      ((_detailPage - 1) * 10 + entry.key + 1),
                                      entry.value.namaLinen,
                                      entry.value.namaKategoriLinen,
                                      entry.value.status,
                                      entry.value.tanggalKeluar,
                                      entry.value.jamKeluar,
                                    ],
                                  )
                                  .toList(),columns: const [
                                'No',
                                'Waktu Hilang',
                                'File BA',
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
                                'No',
                                'Nama Linen',
                                'Nama Kategori Linen',
                                'Status',
                                'Tanggal Keluar',
                                'Jam Keluar',
                              ],
                              rows: detailRows.asMap().entries
                                  .map(
                                    (entry) => [
                                      ((_detailPage - 1) * 10 + entry.key + 1),
                                      entry.value.namaLinen,
                                      entry.value.namaKategoriLinen,
                                      entry.value.status,
                                      entry.value.tanggalKeluar,
                                      entry.value.jamKeluar,
                                    ],
                                  )
                                  .toList(),rows: baRows.asMap().entries
                                  .map(
                                    (entry) => [
                                      ((_baPage - 1) * 10 + entry.key + 1),
                                      entry.value.waktuHilang,
                                      entry.value.fileUrl.isEmpty ? '-' : entry.value.fileUrl,
                                    ],
                                  )
                                  .toList(),                              ),
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
                                'No',
                                'Nama Linen',
                                'Nama Kategori Linen',
                                'Status',
                                'Tanggal Keluar',
                                'Jam Keluar',
                              ],
                              rows: detailRows.asMap().entries
                                  .map(
                                    (entry) => [
                                      ((_detailPage - 1) * 10 + entry.key + 1),
                                      entry.value.namaLinen,
                                      entry.value.namaKategoriLinen,
                                      entry.value.status,
                                      entry.value.tanggalKeluar,
                                      entry.value.jamKeluar,
                                    ],
                                  )
                                  .toList(),columns: const [
                                'No',
                                'Waktu Hilang',
                                'File BA',
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
                                'No',
                                'Nama Linen',
                                'Nama Kategori Linen',
                                'Status',
                                'Tanggal Keluar',
                                'Jam Keluar',
                              ],
                              rows: detailRows.asMap().entries
                                  .map(
                                    (entry) => [
                                      ((_detailPage - 1) * 10 + entry.key + 1),
                                      entry.value.namaLinen,
                                      entry.value.namaKategoriLinen,
                                      entry.value.status,
                                      entry.value.tanggalKeluar,
                                      entry.value.jamKeluar,
                                    ],
                                  )
                                  .toList(),
