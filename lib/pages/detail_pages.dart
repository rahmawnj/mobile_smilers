import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../api/api_service.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/pagination_widget.dart';

class LinenMasukPage extends StatefulWidget {
  const LinenMasukPage({super.key, required this.userName});
  final String userName;
  @override State<LinenMasukPage> createState() => _LinenMasukPageState();
}

class _LinenMasukPageState extends State<LinenMasukPage> {
  bool _loading = true, _scanning = false;
  String? _error;
  LinenListResponse<LinenMasukItem>? _response;
  List<LinenRoomOption> _rooms = const [];
  int? _roomId;
  DateTime? _selectedDate;
  DateTimeRange? _range;
  int _page = 1, _perPage = 10;
  final _searchController = TextEditingController();
  final _rfidController = TextEditingController();

  @override void initState() { super.initState(); _load(); _loadRooms(); }
  @override void dispose() { _searchController.dispose(); _rfidController.dispose(); super.dispose(); }
  String _date(DateTime d) => '${d.month}/${d.day}/${d.year}';
  String? get _daterange => _range == null ? null : '${_date(_range!.start)} - ${_date(_range!.end)}';

  Future<void> _loadRooms() async {
    try { final r = await ApiService.instance.getLinenMasukRuangan(); if (mounted) setState(() => _rooms = r); } catch (_) {}
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final r = await ApiService.instance.getLinenMasuk(
        perPage: _perPage, page: _page,
        search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        ruangan: _roomId,
        date: _selectedDate == null ? null : _date(_selectedDate!),
        daterange: _daterange,
      );
      if (!mounted) return;
      setState(() { _response = r; _loading = false; });
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _error = 'Tidak dapat mengambil data Linen & Tirai Masuk.'; _loading = false; });
    }
  }

  Future<void> _scan() async {
    _rfidController.clear();
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Scan Linen Masuk'),
        content: TextField(
          controller: _rfidController, autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
          decoration: const InputDecoration(labelText: 'RFID / QR Code', hintText: 'Masukkan RFID atau QR Code'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(_rfidController.text.trim()), child: const Text('Proses')),
        ],
      ),
    );
    if (value == null || value.isEmpty || _scanning) return;
    setState(() => _scanning = true);
    try {
      final r = await ApiService.instance.scanLinenMasuk(value);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r['message']?.toString() ?? 'Data linen masuk berhasil dicatat')));
      _page = 1;
      await _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(context: context, initialDate: _selectedDate ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2100));
    if (d != null) {
      setState(() { _selectedDate = d; _range = null; _page = 1; });
      _load();
    }
  }

  Future<void> _pickRange() async {
    final r = await showDateRangePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime(2100), initialDateRange: _range);
    if (r != null) {
      setState(() { _range = r; _selectedDate = null; _page = 1; });
      _load();
    }
  }

  void _reset() {
    setState(() { _roomId = null; _selectedDate = null; _range = null; _searchController.clear(); _page = 1; });
    _load();
  }

  @override Widget build(BuildContext context) {
    final rows = _response?.data ?? const <LinenMasukItem>[];
    return AppShell(
      userName: widget.userName, activeIndex: 1,
      body: Column(children: [
        DetailHeader(title: 'Linen & Tirai Masuk', userName: widget.userName),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(children: [
            Expanded(child: TextField(
              controller: _searchController,
              onSubmitted: (_) { setState(() => _page = 1); _load(); },
              decoration: InputDecoration(
                hintText: 'Cari linen / RFID / QR...', prefixIcon: const Icon(Icons.search_rounded, size: 20),
                filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
              ),
            )),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _scanning ? null : _scan, tooltip: 'Scan Linen',
              style: IconButton.styleFrom(backgroundColor: const Color(0xff159cf1), foregroundColor: Colors.white),
              icon: _scanning ? const SizedBox(width: 20,height: 20,child: CircularProgressIndicator(strokeWidth: 2,color: Colors.white)) : const Icon(Icons.qr_code_scanner_rounded, size: 21),
            ),
            PopupMenuButton<String>(
              tooltip: 'Filter tanggal', icon: const Icon(Icons.calendar_month_rounded),
              onSelected: (v) { if (v == 'date') _pickDate(); else if (v == 'range') _pickRange(); else _reset(); },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'date', child: Text('Pilih tanggal')),
                PopupMenuItem(value: 'range', child: Text('Pilih rentang tanggal')),
                PopupMenuItem(value: 'reset', child: Text('Reset filter')),
              ],
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
          child: DropdownButtonFormField<int?>(
            value: _roomId, isExpanded: true,
            decoration: InputDecoration(hintText: 'Semua Ruangan', prefixIcon: const Icon(Icons.meeting_room_rounded, size: 19), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none)),
            items: [const DropdownMenuItem<int?>(value: null, child: Text('Semua Ruangan')), ..._rooms.map((r) => DropdownMenuItem<int?>(value: r.id, child: Text(r.nama)))],
            onChanged: (v) { setState(() { _roomId = v; _page = 1; }); _load(); },
          ),
        ),
        if (_selectedDate != null || _range != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Row(children: [
              Expanded(child: Text(_range != null ? 'Periode: ${_date(_range!.start)} - ${_date(_range!.end)}' : 'Tanggal: ${_date(_selectedDate!)}', style: const TextStyle(fontSize: 9, color: Color(0xff6f7f8d)))),
              TextButton(onPressed: _reset, child: const Text('Reset')),
            ]),
          ),
        Expanded(child: RefreshIndicator(
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: _loading ? const Padding(padding: EdgeInsets.all(50), child: Center(child: CircularProgressIndicator()))
              : _error != null ? _LinenMasukError(message: _error!, onRetry: _load)
              : rows.isEmpty ? const Padding(padding: EdgeInsets.all(40), child: Center(child: Text('Tidak ada data Linen & Tirai Masuk.')))
              : Column(children: [
                  _LinenMasukTable(rows: rows, page: _response!.meta.currentPage, perPage: _response!.meta.perPage),
                  const SizedBox(height: 10),
                  AppPagination(meta: _response!.meta, onPage: (p) { setState(() => _page = p); _load(); }),
                  const SizedBox(height: 6),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [10,25,50,100].map((n) => Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: ChoiceChip(label: Text('$n'), selected: _perPage == n, onSelected: (_) { setState(() { _perPage = n; _page = 1; }); _load(); }))).toList()),
                ]),
          ),
        )),
      ]),
    );
  }
}

class _LinenMasukTable extends StatelessWidget {
  const _LinenMasukTable({required this.rows, required this.page, required this.perPage});
  final List<LinenMasukItem> rows;
  final int page, perPage;
  @override Widget build(BuildContext context) => Container(
    
    
    child: LayoutBuilder(builder: (context, constraints) { return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(width: constraints.maxWidth, child: DataTable(
        headingRowColor: WidgetStateProperty.all(const Color(0xff1261dc)),
        headingTextStyle: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
        dataTextStyle: const TextStyle(color: Color(0xff465564), fontSize: 9),
        columnSpacing: 24,
        columns: const [
          DataColumn(label: Text('No.')), DataColumn(label: Text('Nama Linen')), DataColumn(label: Text('Kategori')),
          DataColumn(label: Text('QR Code')), DataColumn(label: Text('RFID')), DataColumn(label: Text('Dari Ruangan')),
          DataColumn(label: Text('Jam')), DataColumn(label: Text('Tanggal')), DataColumn(label: Text('Keterangan')),
        ],
        rows: rows.asMap().entries.map((e) {
          final n = (page - 1) * perPage + e.key + 1;
          final i = e.value;
          return DataRow(cells: [
            DataCell(Text(n.toString())), DataCell(Text(i.namaLinen.isEmpty ? '-' : i.namaLinen)),
            DataCell(Text(i.namaKategoriLinen.isEmpty ? '-' : i.namaKategoriLinen)), DataCell(Text(i.qrCode.isEmpty ? '-' : i.qrCode)),
            DataCell(Text(i.tagRfid.isEmpty ? '-' : i.tagRfid)), DataCell(Text(i.dariRuangan.isEmpty ? '-' : i.dariRuangan)),
            DataCell(Text(i.jam.isEmpty ? '-' : i.jam)), DataCell(Text(i.tanggal.isEmpty ? '-' : i.tanggal)),
            DataCell(Text(i.keterangan.isEmpty ? '-' : i.keterangan)),
          ]);
        }).toList(),
      )),
    ); }),
  );
}

class _LinenMasukError extends StatelessWidget {
  const _LinenMasukError({required this.message, required this.onRetry});
  final String message; final VoidCallback onRetry;
  @override Widget build(BuildContext context) => Center(child: Column(children: [
    const SizedBox(height: 40), const Icon(Icons.cloud_off_rounded, size: 36, color: Color(0xffef6c6c)),
    const SizedBox(height: 10), Text(message, textAlign: TextAlign.center),
    const SizedBox(height: 12), ElevatedButton(onPressed: onRetry, child: const Text('Coba Lagi')),
  ]));
}
