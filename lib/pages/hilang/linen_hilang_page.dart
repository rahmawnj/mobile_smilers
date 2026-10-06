import 'package:flutter/material.dart';

import '../../api/api_service.dart';
import '../../widgets/pagination_widget.dart';
import '../../widgets/shared_widgets.dart';
import 'linen_hilang_create_page.dart';

class LinenHilangPage extends StatefulWidget {
  const LinenHilangPage({super.key, required this.userName});

  final String userName;

  @override
  State<LinenHilangPage> createState() => _LinenHilangPageState();
}

class _LinenHilangPageState extends State<LinenHilangPage> {
  bool _loading = true;
  bool _roomsLoading = true;
  bool _categoriesLoading = true;
  String? _error;

  LinenListResponse<LinenHilangItem>? _response;
  List<LinenHilangRuanganOption> _rooms = const [];
  List<Map<String, dynamic>> _categories = const [];

  int _page = 1;
  int _perPage = 10;
  int? _filterRoom;
  int? _filterCategory;
  DateTimeRange? _dateRange;

  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _loadRooms();
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _date(DateTime d) => '${d.month}/${d.day}/${d.year}';

  String? get _daterange {
    if (_dateRange == null) return null;
    return '${_date(_dateRange!.start)} - ${_date(_dateRange!.end)}';
  }

  Future<void> _loadRooms() async {
    try {
      final rooms = await ApiService.instance.getLinenHilangRuanganDropdown();
      if (!mounted) return;
      setState(() => _rooms = rooms);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _roomsLoading = false);
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await ApiService.instance.getLinenCategoryDropdown();
      if (!mounted) return;
      setState(() => _categories = categories);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _categoriesLoading = false);
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await ApiService.instance.getLinenHilang(
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        perPage: _perPage,
        page: _page,
        filterRuangan: _filterRoom,
        filterKategori: _filterCategory,
        daterange: _daterange,
      );

      if (!mounted) return;
      setState(() {
        _response = response;
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
        _error = 'Tidak dapat mengambil data Linen & Tirai Hilang.';
        _loading = false;
      });
    }
  }

  Future<void> _pickRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: _dateRange,
    );
    if (range == null) return;
    setState(() {
      _dateRange = range;
      _page = 1;
    });
    _load();
  }

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _filterRoom = null;
      _filterCategory = null;
      _dateRange = null;
      _page = 1;
    });
    _load();
  }

  Future<void> _openCreateForm() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => LinenHilangCreatePage(
          userName: widget.userName,
          initialRoomId: _filterRoom,
        ),
      ),
    );

    if (result == true) {
      _page = 1;
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Linen hilang berhasil ditambahkan.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = _response?.data ?? const <LinenHilangItem>[];
    final meta = _response?.meta;

    return Scaffold(
      backgroundColor: const Color(0xfff5f8fc),
      body: SafeArea(
        child: Column(
          children: [
            DetailHeader(
              title: 'Linen & Tirai Hilang',
              userName: widget.userName,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onSubmitted: (_) {
                        setState(() => _page = 1);
                        _load();
                      },
                      decoration: InputDecoration(
                        hintText: 'Cari ruangan, linen, RFID, QR Code...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _openCreateForm,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xff1261dc),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Tambah',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    DropdownButtonHideUnderline(
                      child: DropdownButton<int?>(
                        value: _filterRoom,
                        hint: const Text('Ruangan'),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Semua Ruangan'),
                          ),
                          ..._rooms.map(
                            (room) => DropdownMenuItem<int?>(
                              value: room.id,
                              child: Text(room.namaRuangan),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _filterRoom = value;
                            _page = 1;
                          });
                          _load();
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<int?>(
                        value: _filterCategory,
                        hint: const Text('Kategori'),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Semua Kategori'),
                          ),
                          ..._categories.map(
                            (category) => DropdownMenuItem<int?>(
                              value: _toInt(category['id']),
                              child: Text(
                                category['nama_kategori_linen']?.toString() ??
                                    category['nama']?.toString() ??
                                    '-',
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _filterCategory = value;
                            _page = 1;
                          });
                          _load();
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    IconButton(
                      onPressed: _pickRange,
                      tooltip: 'Pilih rentang tanggal',
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xff1261dc),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.date_range_rounded, size: 20),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      tooltip: 'Reset filter',
                      onPressed: _resetFilters,
                      icon: const Icon(Icons.filter_alt_off_rounded),
                    ),
                  ],
                ),
              ),
            ),
            if (_dateRange != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    const Icon(Icons.date_range_rounded, size: 15, color: Color(0xff6f7f8d)),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        'Periode: $_daterange',
                        style: const TextStyle(fontSize: 9, color: Color(0xff6f7f8d)),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: AppRefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  children: [
                    if (_roomsLoading || _categoriesLoading)
                      const LinearProgressIndicator(minHeight: 2),
                    if (_loading)
                      const AppPageLoading()
                  else if (_error != null)
                      _buildError()
                    else if (rows.isEmpty)
                      _buildEmpty()
                    else
                      _buildTable(rows, meta),
                    if (!_loading && _error == null && meta != null) ...[
                      const SizedBox(height: 10),                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Total ${meta.total} linen hilang',
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
                                  color: Color(0xff7d8c99),
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(width: 6),
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
                        ],
                      ),
                      AppPagination(
                        meta: meta,
                        onPage: (page) {
                          setState(() => _page = page);
                          _load();
                        },
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

  Widget _buildTable(
    List<LinenHilangItem> rows,
    LinenMeta? meta,
  ) {
    return AppDataTable(
      headingColor: const Color(0xffff4d94),
      columns: const [
        DataColumn(label: Text('No')),
        DataColumn(label: Text('Ruangan')),
        DataColumn(label: Text('Kategori')),
        DataColumn(label: Text('Jenis Linen')),
        DataColumn(label: Text('QR Code')),
        DataColumn(label: Text('RFID')),
        DataColumn(label: Text('Terakhir Transaksi')),
        DataColumn(label: Text('Tanggal Hilang')),
      ],
      rows: rows.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final number = meta == null
            ? index + 1
            : (meta.currentPage - 1) * meta.perPage + index + 1;
        return DataRow(
          cells: [
            DataCell(Text(number.toString())),
            DataCell(Text(item.namaRuangan.isEmpty ? '-' : item.namaRuangan)),
            DataCell(Text(item.kategoriLinen.isEmpty ? '-' : item.kategoriLinen)),
            DataCell(Text(item.jenisLinen.isEmpty ? '-' : item.jenisLinen)),
            DataCell(Text(item.qrCode.isEmpty ? '-' : item.qrCode)),
            DataCell(Text(item.tagRfid.isEmpty ? '-' : item.tagRfid)),
            DataCell(Text(item.tanggalTerakhirTransaksi.isEmpty ? '-' : item.tanggalTerakhirTransaksi)),
            DataCell(Text(item.tanggalHilang.isEmpty ? '-' : item.tanggalHilang)),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, size: 34),
          const SizedBox(height: 10),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _load,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return const Padding(
      padding: EdgeInsets.all(40),
      child: Center(child: Text('Belum ada data Linen & Tirai Hilang.')),
    );
  }

  int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
