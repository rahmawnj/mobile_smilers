import 'package:flutter/material.dart';

import '../api/api_service.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/pagination_widget.dart';
import 'keluar_masuk_detail_page.dart';


class InOutPage extends StatefulWidget {
  const InOutPage({super.key, required this.userName, this.embedded = false});
  final String userName;
  final bool embedded;
  @override
  State<InOutPage> createState() => _InOutPageState();
}

class _InOutPageState extends State<InOutPage> {
  bool _loading = true;
  String? _error;
  InOutResponse? _response;
  final _searchController = TextEditingController();
  List<LinenRoomOption> _rooms = const [];
  int? _roomId;
  DateTimeRange? _range;
  int _page = 1;
  int _perPage = 10;

  @override
  void initState() {
    super.initState();
    _load();
    _loadRooms();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _date(DateTime d) => '${d.month}/${d.day}/${d.year}';

  String? get _daterange {
    if (_range == null) return null;
    return '${_date(_range!.start)} - ${_date(_range!.end)}';
  }

  Future<void> _loadRooms() async {
    try {
      final rooms = await ApiService.instance.getRekapanTransaksiRuangan();
      if (!mounted) return;
      setState(() => _rooms = rooms);
    } catch (_) {}
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final r = await ApiService.instance.getInOut(
        perPage: _perPage,
        page: _page,
        search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        ruangan: _roomId,
        daterange: _daterange,
      );
      if (!mounted) return;
      setState(() { _response = r; _loading = false; });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _error = 'Tidak dapat mengambil data Keluar Masuk dari server.'; _loading = false; });
    }
  }

  Future<void> _pickRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: _range,
    );
    if (range != null) {
      setState(() {
        _range = range;
        _page = 1;
      });
      _load();
    }
  }

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _roomId = null;
      _range = null;
      _page = 1;
    });
    _load();
  }

  bool get _hasFilters =>
      _searchController.text.trim().isNotEmpty ||
      _roomId != null ||
      _range != null;

  @override
  Widget build(BuildContext context) {
    final rows = _response?.data ?? const <Map<String,dynamic>>[];
    return AppShell(
      embedded: widget.embedded,
      userName: widget.userName,
      activeIndex: 1,
      body: Column(
        children: [
          // Header is provided by AppShell so it stays fixed while the body pages slide.

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onSubmitted: (_) {
                          setState(() => _page = 1);
                          _load();
                        },
                        decoration: InputDecoration(
                          hintText: 'Cari ruangan...',
                          prefixIcon: const Icon(Icons.search_rounded, size: 20),
                          suffixIcon: _searchController.text.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Hapus pencarian',
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _page = 1);
                                    _load();
                                  },
                                  icon: const Icon(Icons.close_rounded, size: 18),
                                ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _pickRange,
                      tooltip: 'Pilih rentang tanggal',
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xff1261dc),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.date_range_rounded, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int?>(
                        value: _roomId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          hintText: 'Semua Ruangan',
                          prefixIcon: const Icon(Icons.meeting_room_rounded, size: 19),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Semua Ruangan'),
                          ),
                          ..._rooms.map(
                            (room) => DropdownMenuItem<int?>(
                              value: room.id,
                              child: Text(room.nama),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _roomId = value;
                            _page = 1;
                          });
                          _load();
                        },
                      ),
                    ),
                    if (_hasFilters) ...[
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: _resetFilters,
                        icon: const Icon(Icons.refresh_rounded, size: 17),
                        label: const Text('Reset'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xff1261dc),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (_range != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Row(
                children: [
                  const Icon(Icons.date_range_rounded, size: 15, color: Color(0xff6f7f8d)),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      'Periode: ${_date(_range!.start)} - ${_date(_range!.end)}',
                      style: const TextStyle(fontSize: 9, color: Color(0xff6f7f8d)),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: AppRefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: _loading
                    ? const AppPageLoading()
                    : _error != null
                        ? _InOutError(message: _error!, onRetry: _load)
                        : rows.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(40),
                                child: Center(child: Text('Tidak ada data Keluar Masuk Linen & Tirai.')),
                              )
                            : Column(children: [
                                _InOutTable(rows: rows, userName: widget.userName, page: _page, perPage: _perPage),
                                if (_response != null) ...[
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Total ${_response!.meta.total} data',
                                        style: const TextStyle(
                                          color: Color(0xff7d8c99),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      AppPerPageDropdown(
                                        value: _perPage,
                                        onChanged: (value) {
                                          setState(() {
                                            _perPage = value;
                                            _page = 1;
                                          });
                                          _load();
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  AppPagination(
                                    meta: _response!.meta,
                                    alignment: MainAxisAlignment.center,
                                    onPage: (page) {
                                      setState(() => _page = page);
                                      _load();
                                    },
                                  ),
                                ],
                              ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InOutTable extends StatelessWidget {
  const _InOutTable({required this.rows, required this.userName, required this.page, required this.perPage});
  final List<Map<String,dynamic>> rows;
  final String userName;
  final int page;
  final int perPage;

  @override
  Widget build(BuildContext context) {
    return AppDataTable(
      columns: const [
        DataColumn(label: Text('No.')),
        DataColumn(label: Text('Nama Ruangan')),
        DataColumn(label: Text('Linen Masuk')),
        DataColumn(label: Text('Linen Keluar')),
        DataColumn(label: Text('Selisih')),
        DataColumn(label: Text('Action')),
      ],
      rows: rows.asMap().entries.map((entry) {
        final index = entry.key;
        final r = entry.value;
        final no = (page - 1) * perPage + index + 1;
        final ruanganId = int.tryParse(
          (r['ruangan_id'] ?? r['ruangan_id_ruangan'] ?? r['id_ruangan'] ??
                  r['ruangan'] ?? r['id'])?.toString() ?? '',
        );
        return DataRow(cells: [
          DataCell(Text('$no')),
          DataCell(Text(r['nama_ruangan']?.toString() ?? '-')),
          DataCell(Text(r['linen_masuk']?.toString() ?? '0')),
          DataCell(Text(r['linen_keluar']?.toString() ?? '0')),
          DataCell(Text(r['selisih']?.toString() ?? '0')),
          DataCell(
            IconButton(
              tooltip: 'Detail',
              onPressed: () {
                if (ruanganId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ID ruangan tidak tersedia pada data.')),
                  );
                  return;
                }
                Navigator.of(context).push(
                  smoothPageRoute<void>((_) => InOutDetailPage(
                    userName: userName,
                    ruanganId: ruanganId,
                    namaRuangan: r['nama_ruangan']?.toString() ?? '-',
                  )),
                );
              },
              icon: const Icon(
                Icons.visibility_outlined,
                size: 18,
                color: Color(0xff1261dc),
              ),
            ),
          ),
        ]);
      }).toList(),
    );
  }
}
class _InOutError extends StatelessWidget {
  const _InOutError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      children: [
        const SizedBox(height: 40),
        const Icon(Icons.cloud_off_rounded, size: 36, color: Color(0xffef6c6c)),
        const SizedBox(height: 10),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: onRetry, child: const Text('Coba Lagi')),
      ],
    ),
  );
}
