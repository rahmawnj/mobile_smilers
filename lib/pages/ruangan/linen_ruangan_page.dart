import 'package:flutter/material.dart';

import '../../api/api_service.dart';
import '../../widgets/pagination_widget.dart';
import '../../widgets/shared_widgets.dart';
import 'linen_ruangan_detail_page.dart';

class LinenRuanganPage extends StatefulWidget {
  const LinenRuanganPage({super.key, required this.userName});
  final String userName;

  @override
  State<LinenRuanganPage> createState() => _LinenRuanganPageState();
}

class _LinenRuanganPageState extends State<LinenRuanganPage> {
  bool _loading = true;
  String? _error;
  List<LinenRuanganItem> _items = const [];
  String? _search;
  List<LinenRoomOption> _rooms = const [];
  int? _selectedRoomId;
  LinenMeta? _meta;
  int _page = 1;
  int _perPage = 10;
  final _searchController = TextEditingController();

  @override
  void initState() { super.initState(); _loadRooms(); _load(); }

  Future<void> _loadRooms() async {
    try {
      final rooms = await ApiService.instance.getLinenMasukRuangan();
      if (!mounted) return;
      setState(() => _rooms = rooms);
    } catch (_) {}
  }

  @override
  void dispose() { _searchController.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final response = await ApiService.instance.getLinenRuangan(
        search: _selectedRoomId == null ? _search : _roomName(_selectedRoomId!), perPage: _perPage, page: _page,
      );
      if (!mounted) return;
      setState(() { _items = response.data; _meta = response.meta; _loading = false; });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _error = 'Tidak dapat mengambil data Linen & Tirai di Ruangan.'; _loading = false; });
    }
  }

  String _roomName(int id) => _rooms.firstWhere((room) => room.id == id, orElse: () => LinenRoomOption(id: id, nama: '')).nama;

  void _openDetail(LinenRuanganItem item) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => LinenRuanganDetailPage(
        roomId: item.id, roomName: item.namaRuangan, userName: widget.userName, stokAwal: item.stokAwal, hilang: item.hilang, jumlahLinen: item.linenDiRuangan,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f8fc),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            DetailHeader(title: 'Linen & Tirai di Ruangan', userName: widget.userName),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: TextField(
                controller: _searchController,
                onSubmitted: (value) {
                  _search = value.trim().isEmpty ? null : value.trim();
                  _page = 1;
                  _load();
                },
                decoration: InputDecoration(
                  hintText: 'Cari ruangan...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  filled: true, fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: DropdownButtonFormField<int?>(
                value: _selectedRoomId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Ruangan',
                  prefixIcon: Icon(Icons.meeting_room_outlined, size: 20),
                ),
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('Semua ruangan')),
                  ..._rooms.map((room) => DropdownMenuItem<int?>(value: room.id, child: Text(room.nama))),
                ],
                onChanged: (value) {
                  setState(() { _selectedRoomId = value; _page = 1; });
                  _load();
                },
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
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            children: [
                              if (_items.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(40),
                                  child: Center(child: Text('Tidak ada data Linen & Tirai di Ruangan.')),
                                )
                              else
                                AppDataTable(
                                  columns: const [
                                    DataColumn(label: Text('No')),
                                    DataColumn(label: Text('Nama Ruangan')),
                                    DataColumn(label: Text('Stok Awal')),
                                    DataColumn(label: Text('Hilang')),
                                    DataColumn(label: Text('Linen di Ruangan')),
                                    DataColumn(label: Text('Action')),
                                  ],
                                  rows: _items.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final item = entry.value;
                                    return DataRow(
                                      cells: [
                                        DataCell(
                                          Text(
                                            ((_page - 1) * _perPage + index + 1)
                                                .toString(),
                                          ),
                                        ),
                                        DataCell(Text(item.namaRuangan)),
                                        DataCell(Text(item.stokAwal.toString())),
                                        DataCell(Text(item.hilang.toString())),
                                        DataCell(
                                          Text(item.linenDiRuangan.toString()),
                                        ),
                                        DataCell(
                                          IconButton(
                                            tooltip: 'Lihat detail',
                                            onPressed: () => _openDetail(item),
                                            icon: const Icon(
                                              Icons.visibility_outlined,
                                              size: 18,
                                              color: Color(0xff1261dc),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              if (_meta != null) ...[
                                const SizedBox(height: 8),                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Total ${_meta!.total} ruangan',
                                      style: const TextStyle(
                                        color: Color(0xff7d8c99),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text('Jumlah', style: TextStyle(fontSize: 10)),
                                        const SizedBox(width: 8),
                                        AppPerPageDropdown(
                                          value: _perPage,
                                          onChanged: (v) {
                                            setState(() { _perPage = v; _page = 1; });
                                            _load();
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                AppPagination(
                                  meta: _meta!,
                                  onPage: (page) { setState(() => _page = page); _load(); },
                                  alignment: MainAxisAlignment.center,
                                ),
                              ],
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
