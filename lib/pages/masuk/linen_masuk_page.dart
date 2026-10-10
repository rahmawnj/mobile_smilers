import 'dart:async';

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
  Timer? _searchDebounce;
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
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  String _date(DateTime d) => '${d.month}/${d.day}/${d.year}';

  String _range(DateTimeRange r) =>
      '${_date(r.start)} - ${_date(r.end)}';

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

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      setState(() => _page = 1);
      _load();
    });
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
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => const _ScanLinenMasukDialog(),
    );

    if (!mounted || value == null || value.isEmpty || _scanning) return;

    setState(() => _scanning = true);
    try {
      final linen = await ApiService.instance.checkLinenQr(value);

      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xffe29c02).withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.qr_code_2_rounded,
                  color: Color(0xffe29c02),
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'QR Code Check',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Container(
              width: double.maxFinite,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xfff7f9fc),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xffe3e9ef)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          linen.namaLinen.isEmpty ? '-' : linen.namaLinen,
                          style: const TextStyle(
                            color: Color(0xff263645),
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xff0e57ed).withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          linen.status.isEmpty ? '-' : linen.status,
                          style: const TextStyle(
                            color: Color(0xff0e57ed),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _ScanDetailRow(label: 'QR Code', value: linen.qrCode),
                  _ScanDetailRow(label: 'Tag RFID', value: linen.tagRfid),
                  _ScanDetailRow(label: 'Kategori', value: linen.kategori),
                  _ScanDetailRow(label: 'Berat', value: linen.berat + ' kg'),
                  _ScanDetailRow(
                    label: 'Total Pemakaian',
                    value: linen.totalPemakaian.toString() + ' kali',
                  ),
                  _ScanDetailRow(
                    label: 'Posisi Terakhir',
                    value: linen.lastPosition?.isNotEmpty == true
                        ? linen.lastPosition!
                        : '-',
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Batal'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xffe29c02),
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              icon: const Icon(Icons.check_rounded, size: 20),
              label: const Text(
                'Proses Masuk',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );

      if (!mounted || confirmed != true) return;

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
    _searchDebounce?.cancel();
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
            child: AppRefreshIndicator(
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
                          onChanged: _onSearchChanged,
                          decoration: InputDecoration(
                            hintText: 'Cari nama linen, RFID, QR Code...',
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              size: 20,
                            ),
                            filled: true,
                            fillColor: const Color(0xfff5f8fc),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xffd9e0e7)),
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
                        label: const Text('Scan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff1261dc), foregroundColor: Colors.white, minimumSize: const Size(0, 44), padding: const EdgeInsets.symmetric(horizontal: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
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
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText: 'Ruangan',
                                  isDense: true,
                                  filled: true,
                                  fillColor: const Color(0xfff5f8fc),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 10,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
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
                                      child: Text(
                                        room.nama,
                                        overflow: TextOverflow.ellipsis,
                                      ),
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
                            SizedBox(
                              width: 42,
                              height: 44,
                              child: IconButton(
                                onPressed: _pickRange,
                                tooltip: 'Pilih rentang tanggal',
                                style: IconButton.styleFrom(
                                  backgroundColor: const Color(0xff1261dc),
                                  foregroundColor: Colors.white,
                                  shape: const CircleBorder(),
                                  padding: EdgeInsets.zero,
                                ),
                                icon: const Icon(
                                  Icons.calendar_month_rounded,
                                  size: 19,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            SizedBox(
                              width: 42,
                              height: 44,
                              child: IconButton(
                                onPressed: _resetFilters,
                                tooltip: 'Reset filter',
                                style: IconButton.styleFrom(
                                  foregroundColor: const Color(0xff6f7f8d),
                                  backgroundColor: const Color(0xfff1f4f8),
                                  shape: const CircleBorder(),
                                  padding: EdgeInsets.zero,
                                ),
                                icon: const Icon(
                                  Icons.filter_alt_off_rounded,
                                  size: 19,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_selectedDateRange != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                const Icon(Icons.date_range_rounded, size: 15, color: Color(0xff6f7f8d)),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    'Periode: ' + (_isSingleDate(_selectedDateRange!) ? _date(_selectedDateRange!.start) : _range(_selectedDateRange!)),
                                    style: const TextStyle(fontSize: 9, color: Color(0xff6f7f8d)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_loading)
                    const AppPageLoading()
                  else if (_error != null)
                    _buildError()
                  else if (rows.isEmpty)
                    _buildEmpty()
                  else
                    _buildTable(rows, meta),
                  if (!_loading && _error == null && meta != null) ...[
                    const SizedBox(height: 10),
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Total ${meta.total} linen masuk',
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
                                  value: _perPage,
                                  onChanged: _changePerPage,
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (meta.lastPage > 1)
                          AppPagination(
                            meta: meta,
                            onPage: _changePage,
                            alignment: MainAxisAlignment.center,
                          ),
                      ],
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

  Widget _buildTable(List<LinenMasukItem> rows, LinenMeta? meta) {
    return AppDataTable(
      headingColor: const Color(0xffe29c02),
      columns: const [
        DataColumn(label: Text('No')),
        DataColumn(label: Text('Nama Linen')),
        DataColumn(label: Text('Kategori Linen')),
        DataColumn(label: Text('Jumlah')),
      ],
      rows: rows.asMap().entries.map((entry) {
        final item = entry.value;
        final no = (meta == null ? 0 : (meta.currentPage - 1) * meta.perPage) + entry.key + 1;
        return DataRow(cells: [
          DataCell(Text(no.toString())),
          DataCell(Text(item.namaLinen.isEmpty ? '-' : item.namaLinen)),
          DataCell(Text(item.namaKategoriLinen.isEmpty ? '-' : item.namaKategoriLinen)),
          DataCell(Text(item.jumlah.isEmpty ? '-' : item.jumlah)),
        ]);
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
      child: Center(
        child: Text('Belum ada data Linen & Tirai Masuk.'),
      ),
    );
  }
}

class _ScanDetailRow extends StatelessWidget {
  const _ScanDetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xff7d8c99),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(
                color: Color(0xff465564),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanLinenMasukDialog extends StatefulWidget {
  const _ScanLinenMasukDialog();

  @override
  State<_ScanLinenMasukDialog> createState() => _ScanLinenMasukDialogState();
}

class _ScanLinenMasukDialogState extends State<_ScanLinenMasukDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Scan Linen Masuk'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        decoration: const InputDecoration(
          labelText: 'RFID / QR Code',
          hintText: 'Masukkan RFID atau QR Code',
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.qr_code_scanner_rounded),
          label: const Text('Scan'),
        ),
      ],
    );
  }
}
