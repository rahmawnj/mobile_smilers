import 'package:flutter/material.dart';

import '../../api/api_service.dart';
import '../../widgets/pagination_widget.dart';
import '../../widgets/shared_widgets.dart';

class LinenMasukPage extends StatefulWidget {
  const LinenMasukPage({super.key, required this.userName});

  final String userName;

  @override
  State<LinenMasukPage> createState() => _LinenMasukPageState();
}

class _LinenMasukPageState extends State<LinenMasukPage> {
  final _searchController = TextEditingController();
  LinenListResponse<LinenMasukItem>? _response;
  List<LinenRoomOption> _rooms = const [];
  bool _loading = true;
  bool _roomsLoading = true;
  bool _scanning = false;
  String? _error;
  int _page = 1;
  int _perPage = 10;
  int? _filterRoom;
  DateTimeRange? _selectedDateRange;

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

  String _date(DateTime d) => '\${d.month}/\${d.day}/\${d.year}';

  String _range(DateTimeRange r) =>
      '\${_date(r.start)} - \${_date(r.end)}';

  bool _isSingleDate(DateTimeRange r) =>
      r.start.year == r.end.year &&
      r.start.month == r.end.month &&
      r.start.day == r.end.day;

  Future<void> _loadRooms() async {
    try {
      final rooms = await ApiService.instance.getLinenMasukRuangan();
      if (!mounted) return;
      setState(() => _rooms = rooms);
    } catch (_) {
      // Filter ruangan bersifat opsional.
    } finally {
      if (mounted) setState(() => _roomsLoading = false);
    }
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final response = await ApiService.instance.getLinenMasuk(
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        perPage: _perPage,
        page: _page,
        ruangan: _filterRoom,
        date: _selectedDateRange != null &&
                _isSingleDate(_selectedDateRange!)
            ? _date(_selectedDateRange!.start)
            : null,
        daterange: _selectedDateRange != null &&
                !_isSingleDate(_selectedDateRange!)
            ? _range(_selectedDateRange!)
            : null,
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
        _error = 'Tidak dapat mengambil data Linen & Tirai Masuk.';
        _loading = false;
      });
    }
  }

  Future<void> _scan() async {
    final controller = TextEditingController();

    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Scan Linen Masuk'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'RFID / QR Code',
              hintText: 'Masukkan RFID atau QR Code',
            ),
            onSubmitted: (value) {
              Navigator.of(dialogContext).pop(value.trim());
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop(controller.text.trim());
              },
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: const Text('Scan'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (value == null || value.isEmpty || _scanning) return;

    setState(() => _scanning = true);
    try {
      final result = await ApiService.instance.scanLinenMasuk(value);

      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              result['message']?.toString() ??
                  'Data linen masuk berhasil dicatat.',
            ),
          ),
        );

      _page = 1;
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Gagal memproses scan linen masuk.')),
        );
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _pickRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: _selectedDateRange,
    );

    if (range == null) return;

    setState(() {
      _selectedDateRange = range;
      _page = 1;
    });
    _load();
  }

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _filterRoom = null;
      _selectedDateRange = null;
      _page = 1;
    });
    _load();
  }

  void _changePage(int page) {
    setState(() => _page = page);
    _load();
  }

  void _changePerPage(int value) {
    setState(() {
      _perPage = value;
      _page = 1;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final rows = _response?.data ?? const <LinenMasukItem>[];
    final meta = _response?.meta;

    return AppShell(
      userName: widget.userName,
      activeIndex: -1,
      showBottomNavigation: false,
      body: Column(
        children: [
          DetailHeader(
            title: 'Linen & Tirai Masuk',
            userName: widget.userName,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
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
                            hintText: 'Cari nama linen, RFID, QR Code...',
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              size: 20,
                            ),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() => _page = 1);
                                _load();
                              },
                              icon: const Icon(Icons.arrow_forward_rounded),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _scanning ? null : _scan,
                        icon: _scanning
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.qr_code_scanner_rounded),
                        label: const Text('Scan'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .05),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Filter Data',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (_roomsLoading)
                          const LinearProgressIndicator(minHeight: 2),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<int?>(
                                value: _filterRoom,
                                decoration: const InputDecoration(
                                  labelText: 'Ruangan',
                                  filled: true,
                                  fillColor: Color(0xfff5f8fc),
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide.none,
                                  ),
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
                                    _filterRoom = value;
                                    _page = 1;
                                  });
                                  _load();
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _pickRange,
                                icon: const Icon(
                                  Icons.date_range_rounded,
                                  size: 18,
                                ),
                                label: Text(
                                  _selectedDateRange == null
                                      ? 'Tanggal'
                                      : _isSingleDate(_selectedDateRange!)
                                          ? _date(
                                              _selectedDateRange!.start,
                                            )
                                          : _range(_selectedDateRange!),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: _resetFilters,
                              tooltip: 'Reset filter',
                              icon: const Icon(
                                Icons.filter_alt_off_rounded,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.all(44),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_error != null)
                    _buildError()
                  else if (rows.isEmpty)
                    _buildEmpty()
                  else
                    _buildTable(rows),
                  if (!_loading && _error == null && meta != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Total \${meta.total} linen masuk',
                          style: const TextStyle(
                            color: Color(0xff7d8c99),
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 14),
                        AppPerPageDropdown(
                          value: _perPage,
                          onChanged: _changePerPage,
                        ),
                      ],
                    ),
                    AppPagination(
                      meta: meta,
                      onPage: _changePage,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(List<LinenMasukItem> rows) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
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
            horizontalMargin: 14,
            columns: const [
              DataColumn(label: Text('ID')),
              DataColumn(label: Text('Nama Linen')),
              DataColumn(label: Text('Kategori')),
              DataColumn(label: Text('QR Code')),
              DataColumn(label: Text('RFID')),
              DataColumn(label: Text('Dari Ruangan')),
              DataColumn(label: Text('Jam')),
              DataColumn(label: Text('Tanggal')),
              DataColumn(label: Text('Keterangan')),
            ],
            rows: rows.map((item) {
              return DataRow(
                cells: [
                  DataCell(Text(item.id.toString())),
                  DataCell(Text(
                    item.namaLinen.isEmpty ? '-' : item.namaLinen,
                  )),
                  DataCell(Text(
                    item.namaKategoriLinen.isEmpty
                        ? '-'
                        : item.namaKategoriLinen,
                  )),
                  DataCell(Text(
                    item.qrCode.isEmpty ? '-' : item.qrCode,
                  )),
                  DataCell(Text(
                    item.tagRfid.isEmpty ? '-' : item.tagRfid,
                  )),
                  DataCell(Text(
                    item.dariRuangan.isEmpty ? '-' : item.dariRuangan,
                  )),
                  DataCell(Text(item.jam.isEmpty ? '-' : item.jam)),
                  DataCell(
                    Text(item.tanggal.isEmpty ? '-' : item.tanggal),
                  ),
                  DataCell(
                    Text(
                      item.keterangan.isEmpty ? '-' : item.keterangan,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
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
      child: Center(
        child: Text('Belum ada data Linen & Tirai Masuk.'),
      ),
    );
  }
}
