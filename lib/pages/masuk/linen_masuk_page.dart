import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:mobile_scanner/mobile_scanner.dart';

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
    if (_scanning) return;
    final value = await Navigator.of(context).push<String>(
      smoothPageRoute<String>((_) => const _ScanLinenMasukCameraPage()),
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

  Future<LinenListResponse<LinenMasukItem>> _getMasukPreviewPage(int page) {
    return ApiService.instance.getLinenMasuk(
      perPage: 500,
      page: page,
      search: _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim(),
      ruangan: _filterRoom,
      date: _selectedDateRange != null && _isSingleDate(_selectedDateRange!)
          ? _date(_selectedDateRange!.start)
          : null,
      daterange: _selectedDateRange != null && !_isSingleDate(_selectedDateRange!)
          ? _range(_selectedDateRange!)
          : null,
    );
  }

  Future<List<LinenMasukItem>> _loadAllMasukRows() async {
    final firstPage = await ApiService.instance.getLinenMasuk(
      perPage: 100,
      page: 1,
      search: _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim(),
      ruangan: _filterRoom,
      date: _selectedDateRange != null && _isSingleDate(_selectedDateRange!)
          ? _date(_selectedDateRange!.start)
          : null,
      daterange: _selectedDateRange != null && !_isSingleDate(_selectedDateRange!)
          ? _range(_selectedDateRange!)
          : null,
    );
    final allRows = <LinenMasukItem>[...firstPage.data];
    for (var page = 2; page <= firstPage.meta.lastPage; page++) {
      final response = await ApiService.instance.getLinenMasuk(
        perPage: 100,
        page: page,
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        ruangan: _filterRoom,
        date: _selectedDateRange != null && _isSingleDate(_selectedDateRange!)
            ? _date(_selectedDateRange!.start)
            : null,
        daterange: _selectedDateRange != null && !_isSingleDate(_selectedDateRange!)
            ? _range(_selectedDateRange!)
            : null,
      );
      allRows.addAll(response.data);
    }
    return allRows;
  }

  Future<void> _downloadMasukPdf(List<LinenMasukItem> rows) async {
    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => [
          pw.Text(
            'DATA LINEN & TIRAI MASUK',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 5),
          pw.Text('Tanggal cetak: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}'),
          if (_filterRoom != null)
            pw.Text('Filter ruangan: ${_rooms.where((room) => room.id == _filterRoom).map((room) => room.nama).firstOrNull ?? '-'}'),
          if (_selectedDateRange != null)
            pw.Text('Periode: ${_isSingleDate(_selectedDateRange!) ? _date(_selectedDateRange!.start) : _range(_selectedDateRange!)}'),
          if (_searchController.text.trim().isNotEmpty)
            pw.Text('Pencarian: ${_searchController.text.trim()}'),
          pw.SizedBox(height: 14),
          pw.TableHelper.fromTextArray(
            headers: ['No', 'Nama Linen', 'Kategori Linen', 'Jumlah', 'Ruangan'],
            data: rows.asMap().entries.map((entry) {
              final item = entry.value;
              return [
                '${entry.key + 1}',
                item.namaLinen.isEmpty ? '-' : item.namaLinen,
                item.namaKategoriLinen.isEmpty ? '-' : item.namaKategoriLinen,
                item.jumlah.isEmpty ? '-' : item.jumlah,
                item.dariRuangan.isEmpty ? '-' : item.dariRuangan,
              ];
            }).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
            cellStyle: const pw.TextStyle(fontSize: 8),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellPadding: const pw.EdgeInsets.all(6),
            border: pw.TableBorder.all(color: PdfColors.grey500, width: .5),
          ),
          pw.SizedBox(height: 42),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(children: [
                  pw.Text('PETUGAS LINEN', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  pw.SizedBox(height: 48),
                  pw.Text(widget.userName.trim().isEmpty ? '-' : widget.userName.trim(), style: const pw.TextStyle(fontSize: 10)),
                ]),
              ),
              pw.Expanded(
                child: pw.Column(children: [
                  pw.Text('PETUGAS LAUNDRY', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  pw.SizedBox(height: 48),
                  pw.Text('____________________________', style: const pw.TextStyle(fontSize: 10)),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
    final bytes = Uint8List.fromList(await document.save());
    await FilePicker.saveFile(
      dialogTitle: 'Simpan PDF Linen & Tirai Masuk',
      fileName: 'linen_tirai_masuk.pdf',
      mimeType: 'application/pdf',
      bytes: bytes,
    );
  }

  Future<void> _previewDownload() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => _LinenMasukPreviewDialog(
        userName: widget.userName,
        loadPage: _getMasukPreviewPage,
        downloadAll: _loadAllMasukRows,
        downloadPdf: _downloadMasukPdf,
      ),
    );
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
                      const SizedBox(width: 4),
                      IconButton(
                        onPressed: _previewDownload,
                        tooltip: 'Preview dan download',
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xffeaf2ff),
                          foregroundColor: const Color(0xff1261dc),
                          minimumSize: const Size(44, 44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.preview_rounded, size: 21),
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
        DataColumn(label: Text('Ruangan')),
      ],
      rows: rows.asMap().entries.map((entry) {
        final item = entry.value;
        final no = (meta == null ? 0 : (meta.currentPage - 1) * meta.perPage) + entry.key + 1;
        return DataRow(cells: [
          DataCell(Text(no.toString())),
          DataCell(Text(item.namaLinen.isEmpty ? '-' : item.namaLinen)),
          DataCell(Text(item.namaKategoriLinen.isEmpty ? '-' : item.namaKategoriLinen)),
          DataCell(Text(item.jumlah.isEmpty ? '-' : item.jumlah)),
          DataCell(Text(item.dariRuangan.isEmpty ? '-' : item.dariRuangan)),
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


class _LinenMasukPreviewDialog extends StatefulWidget {
  const _LinenMasukPreviewDialog({
    required this.userName,
    required this.loadPage,
    required this.downloadAll,
    required this.downloadPdf,
  });

  final String userName;
  final Future<LinenListResponse<LinenMasukItem>> Function(int page) loadPage;
  final Future<List<LinenMasukItem>> Function() downloadAll;
  final Future<void> Function(List<LinenMasukItem>) downloadPdf;

  @override
  State<_LinenMasukPreviewDialog> createState() => _LinenMasukPreviewDialogState();
}

class _LinenMasukPreviewDialogState extends State<_LinenMasukPreviewDialog> {
  final ScrollController _scrollController = ScrollController();
  final List<LinenMasukItem> _rows = [];
  int _nextPage = 1;
  int _lastPage = 1;
  int? _total;
  bool _loading = true;
  bool _loadingMore = false;
  bool _downloadingPdf = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadNextPage();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _loadingMore || _loading) return;
    if (_scrollController.position.extentAfter < 240 && _nextPage <= _lastPage) {
      _loadNextPage();
    }
  }

  Future<void> _loadNextPage() async {
    if (_loadingMore || (_nextPage > _lastPage && _rows.isNotEmpty)) return;
    final page = _nextPage;
    setState(() {
      _loading = _rows.isEmpty;
      _loadingMore = _rows.isNotEmpty;
      _error = null;
    });
    try {
      final response = await widget.loadPage(page);
      if (!mounted) return;
      setState(() {
        _rows.addAll(response.data);
        _nextPage = page + 1;
        _lastPage = response.meta.lastPage;
        _total = response.meta.total;
        _loading = false;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        _error = e is ApiException
            ? e.message
            : 'Gagal memuat data. Periksa koneksi lalu coba lagi.';
      });
    }
  }

  Future<void> _downloadPdf() async {
    setState(() => _downloadingPdf = true);
    try {
      final rows = await widget.downloadAll();
      if (!mounted) return;
      if (rows.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak ada data untuk diunduh.')),
        );
        return;
      }
      await widget.downloadPdf(rows);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuat PDF: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _downloadingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Preview Linen & Tirai Masuk'),
      content: SizedBox(
        width: 760,
        height: 520,
        child: Column(
          children: [
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null && _rows.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_error!, textAlign: TextAlign.center),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: _loadNextPage,
                                child: const Text('Coba Lagi'),
                              ),
                            ],
                          ),
                        )
                      : _rows.isEmpty
                          ? const Center(child: Text('Tidak ada data untuk di-preview.'))
                          : SingleChildScrollView(
                              controller: _scrollController,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  headingRowColor: WidgetStateProperty.all(const Color(0xff1261dc)),
                                  headingTextStyle: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  columns: const [
                                    DataColumn(label: Text('No')),
                                    DataColumn(label: Text('Nama Linen')),
                                    DataColumn(label: Text('Kategori Linen')),
                                    DataColumn(label: Text('Jumlah')),
                                    DataColumn(label: Text('Ruangan')),
                                  ],
                                  rows: _rows.asMap().entries.map((entry) {
                                    final item = entry.value;
                                    return DataRow(cells: [
                                      DataCell(Text('${entry.key + 1}')),
                                      DataCell(Text(item.namaLinen.isEmpty ? '-' : item.namaLinen)),
                                      DataCell(Text(item.namaKategoriLinen.isEmpty ? '-' : item.namaKategoriLinen)),
                                      DataCell(Text(item.jumlah.isEmpty ? '-' : item.jumlah)),
                                      DataCell(Text(item.dariRuangan.isEmpty ? '-' : item.dariRuangan)),
                                    ]);
                                  }).toList(),
                                ),
                              ),
                            ),
            ),
            if (_loadingMore)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 8),
                    Text('Memuat data berikutnya...', style: TextStyle(fontSize: 11)),
                  ],
                ),
              ),
            if (_error != null && _rows.isNotEmpty)
              TextButton(onPressed: _loadNextPage, child: const Text('Gagal memuat. Coba lagi')),
            const Divider(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(children: [
                    const Text('PETUGAS LINEN', textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    const SizedBox(height: 38),
                    Text(widget.userName.trim().isEmpty ? '-' : widget.userName.trim(),
                        textAlign: TextAlign.center),
                  ]),
                ),
                Expanded(
                  child: Column(children: const [
                    Text('PETUGAS LAUNDRY', textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    SizedBox(height: 38),
                    Text('____________________________', textAlign: TextAlign.center),
                  ]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Menampilkan ${_rows.length}${_total == null ? '' : ' dari $_total'} data • muat saat scroll',
              style: const TextStyle(color: Color(0xff7d8c99), fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _downloadingPdf ? null : () => Navigator.of(context).pop(),
          child: const Text('Tutup'),
        ),
        ElevatedButton.icon(
          onPressed: _downloadingPdf || _loading ? null : _downloadPdf,
          icon: _downloadingPdf
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.picture_as_pdf_rounded),
          label: Text(_downloadingPdf ? 'Menyiapkan PDF...' : 'Download PDF'),
        ),
      ],
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

class _ScanLinenMasukCameraPage extends StatefulWidget {
  const _ScanLinenMasukCameraPage();

  @override
  State<_ScanLinenMasukCameraPage> createState() => _ScanLinenMasukCameraPageState();
}

class _ScanLinenMasukCameraPageState extends State<_ScanLinenMasukCameraPage>
    with SingleTickerProviderStateMixin {
  late final MobileScannerController _controller;
  late final AnimationController _lineAnimation;
  bool _detected = false;
  String? _cameraError;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      formats: const [BarcodeFormat.qrCode],
    );
    _lineAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _lineAnimation.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_detected) return;
    for (final barcode in capture.barcodes) {
      final code = barcode.rawValue?.trim();
      if (code != null && code.isNotEmpty) {
        _detected = true;
        await _controller.stop();
        if (mounted) Navigator.of(context).pop(code);
        return;
      }
    }
  }

  Future<void> _openManualInput() async {
    await _controller.stop();
    if (!mounted) return;
    final code = await Navigator.of(context).push<String>(
      smoothPageRoute<String>((_) => const _ManualLinenMasukInputPage()),
    );
    if (!mounted) return;
    if (code != null && code.trim().isNotEmpty) {
      Navigator.of(context).pop(code.trim());
    } else {
      try {
        await _controller.start();
      } catch (_) {
        if (mounted) {
          setState(() => _cameraError =
              'Kamera belum aktif. Izinkan akses kamera atau gunakan input teks.');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff101820),
      appBar: AppBar(
        title: const Text('Scan QR Linen Masuk'),
        foregroundColor: Colors.white,
        elevation: 0,
        backgroundColor: const Color(0xff1261dc),
        actions: [
          IconButton(
            tooltip: 'Flash',
            onPressed: () => _controller.toggleTorch(),
            icon: const Icon(Icons.flash_on_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                MobileScanner(
                  controller: _controller,
                  onDetect: _onDetect,
                  errorBuilder: (context, error) => Container(
                    color: const Color(0xfff5f8fc),
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.no_photography_outlined,
                              size: 48, color: Color(0xff7d8c99)),
                          const SizedBox(height: 12),
                          const Text(
                            'Kamera tidak dapat dibuka',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Color(0xff263645),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            error.errorCode == MobileScannerErrorCode.permissionDenied
                                ? 'Izin kamera diperlukan. Aktifkan akses Kamera di pengaturan aplikasi, lalu coba lagi.'
                                : 'Periksa izin kamera atau tutup aplikasi lain yang sedang menggunakan kamera.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Color(0xff7d8c99), fontSize: 12),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: () async {
                              try {
                                await _controller.start();
                                if (mounted) setState(() => _cameraError = null);
                              } catch (_) {
                                if (mounted) {
                                  setState(() => _cameraError =
                                      'Kamera belum diizinkan. Coba input dengan teks.');
                                }
                              }
                            },
                            icon: const Icon(Icons.camera_alt_rounded),
                            label: const Text('Coba kamera lagi'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  placeholderBuilder: (_) => const Center(
                    child: CircularProgressIndicator(color: Color(0xff02c0cc)),
                  ),
                ),
                IgnorePointer(
                  child: Center(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth * .76;
                        final height = width * .76;
                        return Container(
                          width: width,
                          height: height,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white24),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: CustomPaint(painter: _MasukScanCornersPainter()),
                              ),
                              AnimatedBuilder(
                                animation: _lineAnimation,
                                builder: (_, __) => Positioned(
                                  left: 12,
                                  right: 12,
                                  top: 12 + (height - 24) * _lineAnimation.value,
                                  child: Container(
                                    height: 3,
                                    decoration: BoxDecoration(
                                      color: const Color(0xff02e6d0),
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xff02e6d0)
                                              .withValues(alpha: .7),
                                          blurRadius: 12,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                if (_cameraError != null)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xffffe9e9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _cameraError!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xffb42318), fontSize: 12),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 26),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: Column(
              children: [
                const Icon(Icons.qr_code_scanner_rounded,
                    size: 30, color: Color(0xff1261dc)),
                const SizedBox(height: 8),
                const Text(
                  'Arahkan QR Code ke dalam kotak',
                  style: TextStyle(
                    color: Color(0xff263645),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'QR akan terbaca otomatis menggunakan kamera.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xff7d8c99), fontSize: 12),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _openManualInput,
                    icon: const Icon(Icons.keyboard_alt_outlined),
                    label: const Text('Input dengan Teks'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xff1261dc),
                      side: const BorderSide(color: Color(0xff1261dc)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
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

class _ManualLinenMasukInputPage extends StatefulWidget {
  const _ManualLinenMasukInputPage();

  @override
  State<_ManualLinenMasukInputPage> createState() =>
      _ManualLinenMasukInputPageState();
}

class _ManualLinenMasukInputPageState extends State<_ManualLinenMasukInputPage> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(_textController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f8fc),
      appBar: AppBar(
        title: const Text('Input Linen Masuk'),
        foregroundColor: Colors.white,
        elevation: 0,
        backgroundColor: const Color(0xff1261dc),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xffe5ebf1)),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Masukkan kode linen',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xff263645),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Masukkan QR Code atau RFID tanpa menggunakan kamera.',
                    style: TextStyle(fontSize: 12, color: Color(0xff7d8c99)),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _textController,
                    autofocus: true,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: 'QR Code / RFID',
                      hintText: 'Masukkan kode linen',
                      prefixIcon: const Icon(Icons.qr_code_2_rounded),
                      filled: true,
                      fillColor: const Color(0xfff5f8fc),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Kode linen wajib diisi.'
                        : null,
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      label: const Text('Lanjutkan'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xff1261dc),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MasukScanCornersPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const length = 28.0;
    const radius = 3.0;
    final paint = Paint()
      ..color = const Color(0xff02e6d0)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(2, length)
      ..lineTo(2, radius)
      ..quadraticBezierTo(2, 2, radius, 2)
      ..lineTo(length, 2)
      ..moveTo(size.width - length, 2)
      ..lineTo(size.width - radius, 2)
      ..quadraticBezierTo(size.width - 2, 2, size.width - 2, radius)
      ..lineTo(size.width - 2, length)
      ..moveTo(2, size.height - length)
      ..lineTo(2, size.height - radius)
      ..quadraticBezierTo(2, size.height - 2, radius, size.height - 2)
      ..lineTo(length, size.height - 2)
      ..moveTo(size.width - length, size.height - 2)
      ..lineTo(size.width - radius, size.height - 2)
      ..quadraticBezierTo(size.width - 2, size.height - 2, size.width - 2,
          size.height - radius)
      ..lineTo(size.width - 2, size.height - length);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
