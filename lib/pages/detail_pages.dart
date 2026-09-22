import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../api/api_service.dart';
import '../widgets/shared_widgets.dart';

class _MetaPagination extends StatelessWidget {
  const _MetaPagination({required this.meta, required this.onPage});
  final LinenMeta meta;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    if (meta.lastPage <= 1) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 100),
      child: Material(
        color: Colors.transparent,
        child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          OutlinedButton(
            onPressed: meta.currentPage > 1 ? () => onPage(meta.currentPage - 1) : null,
            child: const Text('Sebelumnya'),
          ),
          const SizedBox(width: 12),
          Text(
            'Halaman ${meta.currentPage} dari ${meta.lastPage}',
            style: const TextStyle(fontSize: 9, color: Color(0xff6f7f8d)),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: meta.currentPage < meta.lastPage ? () => onPage(meta.currentPage + 1) : null,
            child: const Text('Berikutnya'),
          ),
        ],
        ),
      ),
    );
  }
}

class LinenCategoryDetailPage extends StatefulWidget {
  const LinenCategoryDetailPage({
    super.key,
    required this.category,
    required this.userName,
  });

  final LinenCategory category;
  final String userName;

  @override
  State<LinenCategoryDetailPage> createState() => _LinenCategoryDetailPageState();
}

class _LinenCategoryDetailPageState extends State<LinenCategoryDetailPage> {
  bool _loading = true;
  String? _error;
  LinenCategory? _detail;
  LinenItemsResponse? _items;
  int _page = 1;

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
        ApiService.instance.getLinenCategory(widget.category.id),
        ApiService.instance.getLinenItems(widget.category.id, perPage: 10, page: _page),
      ]);

      if (!mounted) return;
      setState(() {
        _detail = results[0] as LinenCategory;
        _items = results[1] as LinenItemsResponse;
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
        _error = 'Tidak dapat mengambil detail linen dari server.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail ?? widget.category;

    return AppShell(
      userName: widget.userName,
      activeIndex: 0,
      body: Column(
        children: [
          DetailHeader(
            title: detail.namaKategoriLinen,
            userName: widget.userName,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: _loading
                    ? const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : _error != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
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
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _CategoryInfo(detail: detail),
                              const SizedBox(height: 18),
                              const SectionTitle(title: 'Detail Linen Ready'),
                              const SizedBox(height: 8),
                              if (_items!.data.isEmpty)
                                const _EmptyDetail(message: 'Tidak ada item linen ready.')
                              else
                                DetailTable(
                                  columns: const [
                                    'ID',
                                    'Kode Linen',
                                    'Tag RFID',
                                    'QR Code',
                                    'Status',
                                  ],
                                  rows: _items!.data
                                      .map(
                                        (item) => [
                                          item.id,
                                          item.kodeLinen,
                                          item.tagRfid,
                                          item.qrCode,
                                          item.status,
                                        ],
                                      )
                                      .toList(),
                                ),
                              const SizedBox(height: 12),
                              Text(
                                'Total ' + _items!.meta.total.toString() + ' item',
                                style: const TextStyle(color: Color(0xff8b99a5), fontSize: 9),
                              ),
                              _MetaPagination(meta: _items!.meta, onPage: (page) { setState(() => _page = page); _load(); }),
                            ],
                          ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryInfo extends StatelessWidget {
  const _CategoryInfo({required this.detail});

  final LinenCategory detail;

  @override
  Widget build(BuildContext context) {
    final sub = detail.subKategoriLinen.trim().isEmpty
        ? 'Tidak ada sub kategori'
        : detail.subKategoriLinen;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kategori Linen',
            style: TextStyle(
              color: Color(0xff8b99a5),
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            detail.namaKategoriLinen,
            style: const TextStyle(
              color: Color(0xff34495e),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: const TextStyle(
              color: Color(0xff8b99a5),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyDetail extends StatelessWidget {
  const _EmptyDetail({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(message, textAlign: TextAlign.center),
    );
  }
}


class InOutPage extends StatefulWidget {
  const InOutPage({super.key, required this.userName});
  final String userName;
  @override
  State<InOutPage> createState() => _InOutPageState();
}

class _InOutPageState extends State<InOutPage> {
  bool _loading = true;
  String? _error;
  InOutResponse? _response;
  final _searchController = TextEditingController();
  DateTime? _selectedDate;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _dateParam(DateTime d) =>
      '${d.month}/${d.day}/${d.year} - ${d.month}/${d.day}/${d.year}';

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final r = await ApiService.instance.getInOut(
        perPage: 10,
        page: _page,
        search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        daterange: _selectedDate == null ? null : _dateParam(_selectedDate!),
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

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d != null) {
      setState(() => _selectedDate = d);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = _response?.data ?? const <Map<String,dynamic>>[];
    return AppShell(
      userName: widget.userName,
      activeIndex: 1,
      body: Column(
        children: [
          DetailHeader(title: 'Keluar Masuk Linen & Tirai', userName: widget.userName),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: (_) => _load(),
                    decoration: InputDecoration(
                      hintText: 'Cari ruangan...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _pickDate,
                  tooltip: 'Pilih tanggal',
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xff1261dc),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.calendar_month_rounded, size: 20),
                ),
              ],
            ),
          ),
          if (_selectedDate != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: Row(
                children: [
                  Text(
                    'Tanggal: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                    style: const TextStyle(fontSize: 9, color: Color(0xff6f7f8d)),
                  ),
                  const Spacer(),
                  TextButton(onPressed: () { setState(() => _selectedDate = null); _load(); }, child: const Text('Reset')),
                ],
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: _loading
                    ? const Padding(padding: EdgeInsets.all(50), child: Center(child: CircularProgressIndicator()))
                    : _error != null
                        ? _InOutError(message: _error!, onRetry: _load)
                        : rows.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(40),
                                child: Center(child: Text('Tidak ada data Keluar Masuk Linen & Tirai.')),
                              )
                            : Column(children: [
                                _InOutTable(rows: rows),
                                if (_response != null) _MetaPagination(meta: _response!.meta, onPage: (page) { setState(() => _page = page); _load(); }),
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
  const _InOutTable({required this.rows});
  final List<Map<String,dynamic>> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .05), blurRadius: 18, offset: const Offset(0, 7))],
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xff1261dc)),
          headingTextStyle: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
          dataTextStyle: const TextStyle(color: Color(0xff465564), fontSize: 9),
          columnSpacing: 28,
          columns: const [
            DataColumn(label: Text('Ruangan')),
            DataColumn(label: Text('Masuk')),
            DataColumn(label: Text('Keluar')),
            DataColumn(label: Text('Selisih')),
          ],
          rows: rows.map((r) => DataRow(cells: [
            DataCell(Text(r['nama_ruangan']?.toString() ?? '-')),
            DataCell(Text(r['linen_masuk']?.toString() ?? '0')),
            DataCell(Text(r['linen_keluar']?.toString() ?? '0')),
            DataCell(Text(r['selisih']?.toString() ?? '0')),
          ])).toList(),
        ),
      ),
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
                filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
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
            decoration: InputDecoration(hintText: 'Semua Ruangan', prefixIcon: const Icon(Icons.meeting_room_rounded, size: 19), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none)),
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
                  _MetaPagination(meta: _response!.meta, onPage: (p) { setState(() => _page = p); _load(); }),
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
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .05), blurRadius: 18, offset: const Offset(0, 7))]),
    clipBehavior: Clip.antiAlias,
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
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
      ),
    ),
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

class PermintaanLinenPage extends StatefulWidget {
  const PermintaanLinenPage({super.key, required this.userName});
  final String userName;

  @override
  State<PermintaanLinenPage> createState() => _PermintaanLinenPageState();
}

class _PermintaanLinenPageState extends State<PermintaanLinenPage> {
  bool _loading = true;
  bool _saving = false;
  String? _error;
  LinenListResponse<PermintaanLinenItem>? _response;
  Map<String, dynamic> _formData = {};
  int? _roomId;
  String? _status;
  int _page = 1;
  int _perPage = 10;
  final TextEditingController _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _loadFormData();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _rooms {
    final value = _formData['ruangan'];
    if (value is! List) return <Map<String, dynamic>>[];
    return value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  List<Map<String, dynamic>> get _linens {
    final value = _formData['linen'];
    if (value is! List) return <Map<String, dynamic>>[];
    return value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  int _toInt(dynamic value) => int.tryParse(value?.toString() ?? '') ?? 0;

  Future<void> _loadFormData() async {
    try {
      // Gunakan endpoint sumber data yang memang sudah menyediakan
      // daftar ruangan dan linen untuk transaksi mobile.
      final results = await Future.wait([
        ApiService.instance.getLinenKeluarOptions(),
        ApiService.instance.getLinenLaundry(
          perPage: 100,
          page: 1,
        ),
      ]);

      final options = results[0] as LinenKeluarOptions;
      final laundry = results[1] as LinenListResponse<LinenLaundryItem>;

      if (!mounted) return;

      setState(() {
        _formData = {
          'ruangan': options.ruangan
              .map((room) => {
                    'id': room.id,
                    'nama_ruangan': room.namaRuangan,
                  })
              .toList(),
          'linen': laundry.data
              .map((linen) => {
                    'id': linen.id,
                    'nama_linen': linen.namaLinen,
                    'nama_kategori_linen': linen.namaKategoriLinen,
                    'ready': linen.ready,
                  })
              .toList(),
        };
      });
    } catch (_) {}
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      final result = await ApiService.instance.getPermintaanLinen(
        perPage: _perPage,
        page: _page,
        search: _search.text.trim().isEmpty ? null : _search.text.trim(),
        ruangan: _roomId,
        status: _status,
      );

      if (!mounted) return;
      setState(() {
        _response = result;
        _loading = false;
        _error = null;
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
        _error = 'Tidak dapat mengambil data Permintaan Linen & Tirai.';
        _loading = false;
      });
    }
  }

  Future<void> _create() async {
    // Form data bisa saja belum selesai dimuat ketika tombol ditekan.
    // Pastikan data form tersedia sebelum membuka dialog.
    if (_rooms.isEmpty || _linens.isEmpty) {
      try {
        final result = await ApiService.instance.getPermintaanLinenFormData();
        if (!mounted) return;
        setState(() {
          _formData = result.data;
        });
      } on ApiException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message)),
          );
        }
        return;
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data form Permintaan Linen belum dapat dimuat.'),
            ),
          );
        }
        return;
      }
    }

    if (_rooms.isEmpty || _linens.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data ruangan atau linen untuk form belum tersedia.'),
        ),
      );
      return;
    }

    DateTime selectedDate = DateTime.now();
    int? selectedRoom = _roomId ?? _toInt(_rooms.first['id']);
    final reasonController = TextEditingController();
    final quantities = <int, int>{};

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Buat Permintaan Linen'),
              content: SizedBox(
                width: 600,
                height: 500,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Tanggal: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.calendar_month),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: dialogContext,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setDialogState(() {
                                selectedDate = picked;
                              });
                            }
                          },
                        ),
                      ),
                      DropdownButtonFormField<int>(
                        value: selectedRoom,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Ruangan'),
                        items: _rooms.map((room) {
                          final id = _toInt(room['id']);
                          final name = room['nama_ruangan']?.toString() ??
                              room['nama']?.toString() ??
                              '-';
                          return DropdownMenuItem<int>(
                            value: id,
                            child: Text(name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedRoom = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: reasonController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Alasan Permintaan',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Item Linen',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._linens.map((linen) {
                        final id = _toInt(linen['id'] ?? linen['linen_id']);
                        final name = linen['nama_linen']?.toString() ??
                            linen['nama']?.toString() ??
                            '-';
                        final category = linen['kategori_linen']?.toString() ??
                            linen['nama_kategori_linen']?.toString() ??
                            '';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  category.isEmpty ? name : '$name • $category',
                                ),
                              ),
                              SizedBox(
                                width: 90,
                                child: TextFormField(
                                  initialValue: quantities[id]?.toString() ?? '',
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Jumlah',
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (value) {
                                    quantities[id] = _toInt(value);
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true || selectedRoom == null) {
      reasonController.dispose();
      return;
    }

    final items = quantities.entries
        .where((entry) => entry.value > 0)
        .map((entry) => <String, dynamic>{
              'linen_id': entry.key,
              'jumlah': entry.value,
            })
        .toList();

    if (items.isEmpty) {
      reasonController.dispose();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal satu linen.')),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final date =
          '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';

      final result = await ApiService.instance.createPermintaanLinen(
        tanggalPermintaan: date,
        ruanganId: selectedRoom!,
        alasanPermintaan: reasonController.text.trim(),
        items: items,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message']?.toString() ?? 'Permintaan berhasil dibuat',
          ),
        ),
      );
      _page = 1;
      await _load();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      reasonController.dispose();
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _showDetail(int id) async {
    try {
      final result = await ApiService.instance.getPermintaanLinenDetail(id);
      if (!mounted) return;

      final data = result.data;
      final items = data['items'] is List ? data['items'] as List : const [];

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text('Permintaan #$id'),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tanggal: ${data['tanggal_permintaan'] ?? '-'}'),
                    Text('Ruangan: ${data['nama_ruangan'] ?? '-'}'),
                    Text('Kepala Ruangan: ${data['nama_kepala_ruangan'] ?? '-'}'),
                    Text('Alasan: ${data['alasan_permintaan'] ?? '-'}'),
                    Text('Status: ${data['status'] ?? '-'}'),
                    const Divider(),
                    ...items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          '${item['nama_linen'] ?? '-'} • ${item['kategori_linen'] ?? '-'} • Jumlah: ${item['jumlah'] ?? 0}',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Tutup'),
              ),
            ],
          );
        },
      );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }

  Future<void> _updateStatus(int id) async {
    try {
      final result = await ApiService.instance.updatePermintaanLinenStatus(id);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message']?.toString() ?? 'Status berhasil diubah',
          ),
        ),
      );
      await _load();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = _response?.data ?? const <PermintaanLinenItem>[];
    final meta = _response?.meta;

    return AppShell(
      userName: widget.userName,
      activeIndex: -1,
      body: Column(
        children: [
          DetailHeader(
            title: 'Permintaan Linen & Tirai',
            userName: widget.userName,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    onSubmitted: (_) {
                      setState(() {
                        _page = 1;
                      });
                      _load();
                    },
                    decoration: InputDecoration(
                      hintText: 'Cari permintaan...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<int?>(
                  value: _roomId,
                  hint: const Text('Ruangan'),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Semua'),
                    ),
                    ..._rooms.map(
                      (room) => DropdownMenuItem<int?>(
                        value: _toInt(room['id']),
                        child: Text(room['nama_ruangan']?.toString() ?? '-'),
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
                const SizedBox(width: 8),
                DropdownButton<String?>(
                  value: _status,
                  hint: const Text('Status'),
                  items: const [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Semua'),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'belum',
                      child: Text('Belum'),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'terkirim',
                      child: Text('Terkirim'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _status = value;
                      _page = 1;
                    });
                    _load();
                  },
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _saving ? null : _create,
                  icon: const Icon(Icons.add),
                  label: const Text('Buat Permintaan'),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: _loading
                    ? const Padding(
                        padding: EdgeInsets.all(50),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : _error != null
                        ? Padding(
                            padding: const EdgeInsets.all(40),
                            child: Center(child: Text(_error!)),
                          )
                        : rows.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(40),
                                child: Center(
                                  child: Text('Tidak ada permintaan linen.'),
                                ),
                              )
                            : Column(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: DataTable(
                                        headingRowColor:
                                            WidgetStateProperty.all(
                                          const Color(0xff1261dc),
                                        ),
                                        headingTextStyle: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        dataTextStyle: const TextStyle(
                                          fontSize: 9,
                                        ),
                                        columns: const [
                                          DataColumn(label: Text('No.')),
                                          DataColumn(label: Text('Tanggal')),
                                          DataColumn(label: Text('Ruangan')),
                                          DataColumn(
                                            label: Text('Kepala Ruangan'),
                                          ),
                                          DataColumn(label: Text('Alasan')),
                                          DataColumn(label: Text('Status')),
                                          DataColumn(label: Text('Aksi')),
                                        ],
                                        rows: rows.asMap().entries.map((entry) {
                                          final item = entry.value;
                                          final number = meta == null
                                              ? entry.key + 1
                                              : (meta.currentPage - 1) *
                                                      meta.perPage +
                                                  entry.key +
                                                  1;

                                          return DataRow(
                                            cells: [
                                              DataCell(Text('$number')),
                                              DataCell(
                                                Text(item.tanggalPermintaan),
                                              ),
                                              DataCell(Text(item.namaRuangan)),
                                              DataCell(
                                                Text(item.namaKepalaRuangan),
                                              ),
                                              DataCell(
                                                Text(item.alasanPermintaan),
                                              ),
                                              DataCell(Text(item.status)),
                                              DataCell(
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    IconButton(
                                                      tooltip: 'Detail',
                                                      onPressed: () =>
                                                          _showDetail(item.id),
                                                      icon: const Icon(
                                                        Icons.visibility,
                                                      ),
                                                    ),
                                                    IconButton(
                                                      tooltip: 'Ubah status',
                                                      onPressed: () =>
                                                          _updateStatus(item.id),
                                                      icon: const Icon(
                                                        Icons.local_shipping,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  if (meta != null)
                                    _MetaPagination(
                                      meta: meta,
                                      onPage: (page) {
                                        setState(() {
                                          _page = page;
                                        });
                                        _load();
                                      },
                                    ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [10, 25, 50, 100].map((value) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 3,
                                        ),
                                        child: ChoiceChip(
                                          label: Text('$value'),
                                          selected: _perPage == value,
                                          onSelected: (_) {
                                            setState(() {
                                              _perPage = value;
                                              _page = 1;
                                            });
                                            _load();
                                          },
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LinenBelumKembaliPage extends StatefulWidget { const LinenBelumKembaliPage({super.key, required this.userName}); final String userName; @override State<LinenBelumKembaliPage> createState()=>_LinenBelumKembaliPageState(); }
class _LinenBelumKembaliPageState extends State<LinenBelumKembaliPage> { bool _loading=true; String? _error; LinenBelumKembaliResponse? _response; List<LinenRoomOption> _rooms=const []; int? _roomId; DateTimeRange? _range; int _page=1; final _searchController=TextEditingController(); @override void initState(){super.initState();_load();_loadRooms();} @override void dispose(){_searchController.dispose();super.dispose();} String _date(DateTime d)=>d.day.toString()+'/'+d.month.toString()+'/'+d.year.toString(); String? get _daterange=>_range==null?null:_date(_range!.start)+' - '+_date(_range!.end);
Future<void> _loadRooms() async {try{final rooms=await ApiService.instance.getLinenBelumKembaliRuangan();if(mounted)setState(()=>_rooms=rooms);}catch(_){}}
Future<void> _load() async {setState((){_loading=true;_error=null;});try{final r=await ApiService.instance.getLinenBelumKembali(perPage:10,page:_page,search:_searchController.text.trim().isEmpty?null:_searchController.text.trim(),ruangan:_roomId,daterange:_daterange);if(!mounted)return;setState((){_response=r;_loading=false;});}on ApiException catch(e){if(mounted)setState((){_error=e.message;_loading=false;});}catch(_){if(mounted)setState((){_error='Tidak dapat mengambil data Linen Belum Kembali.';_loading=false;});}}
Future<void> _pickRange() async {final r=await showDateRangePicker(context:context,firstDate:DateTime(2020),lastDate:DateTime(2100),initialDateRange:_range);if(r!=null){setState(()=>_range=r);_load();}}
@override Widget build(BuildContext context){final rows=_response?.data??const <LinenBelumKembaliItem>[];return AppShell(userName:widget.userName,activeIndex:4,body:Column(children:[DetailHeader(title:'Linen Belum Kembali',userName:widget.userName),Padding(padding:const EdgeInsets.fromLTRB(16,14,16,8),child:Row(children:[Expanded(child:TextField(controller:_searchController,onSubmitted:(_)=>_load(),decoration:InputDecoration(hintText:'Cari linen / ruangan...',prefixIcon:const Icon(Icons.search_rounded,size:20),filled:true,fillColor:Colors.white,border:OutlineInputBorder(borderRadius:BorderRadius.circular(14),borderSide:BorderSide.none)))),const SizedBox(width:8),IconButton(onPressed:_pickRange,style:IconButton.styleFrom(backgroundColor:const Color(0xff1261dc),foregroundColor:Colors.white),icon:const Icon(Icons.date_range_rounded,size:20))])),Padding(padding:const EdgeInsets.fromLTRB(16,0,16,6),child:DropdownButtonFormField<int?>(value:_roomId,isExpanded:true,decoration:InputDecoration(hintText:'Semua Ruangan',prefixIcon:const Icon(Icons.meeting_room_rounded,size:19),filled:true,fillColor:Colors.white,border:OutlineInputBorder(borderRadius:BorderRadius.circular(14),borderSide:BorderSide.none)),items:[const DropdownMenuItem<int?>(value:null,child:Text('Semua Ruangan')),..._rooms.map((r)=>DropdownMenuItem<int?>(value:r.id,child:Text(r.nama)))],onChanged:(v){setState(()=>_roomId=v);_load();})),if(_range!=null)Padding(padding:const EdgeInsets.symmetric(horizontal:16),child:Row(children:[Expanded(child:Text('Periode: '+_date(_range!.start)+' - '+_date(_range!.end),style:const TextStyle(fontSize:9,color:Color(0xff6f7f8d)))),TextButton(onPressed:(){setState(()=>_range=null);_load();},child:const Text('Reset'))])),Expanded(child:RefreshIndicator(onRefresh:_load,child:SingleChildScrollView(physics:const AlwaysScrollableScrollPhysics(),padding:const EdgeInsets.fromLTRB(16,8,16,20),child:_loading?const Padding(padding:EdgeInsets.all(50),child:Center(child:CircularProgressIndicator())):_error!=null?_BelumKembaliError(message:_error!,onRetry:_load):rows.isEmpty?const Padding(padding:EdgeInsets.all(40),child:Center(child:Text('Tidak ada linen yang belum kembali.'))):Column(children:[_BelumKembaliTable(rows:rows),if(_response!=null)_MetaPagination(meta:_response!.meta,onPage:(page){setState(()=>_page=page);_load();})]))))]));}}
class _BelumKembaliTable extends StatelessWidget {
  const _BelumKembaliTable({required this.rows});

  final List<LinenBelumKembaliItem> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xff1261dc)),
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
          columns: const [
            DataColumn(label: Text('ID')),
            DataColumn(label: Text('QR Code')),
            DataColumn(label: Text('Nama Linen')),
            DataColumn(label: Text('RFID')),
            DataColumn(label: Text('Ruangan')),
            DataColumn(label: Text('Kategori')),
            DataColumn(label: Text('Tanggal Keluar')),
            DataColumn(label: Text('Jam')),
          ],
          rows: rows.map((item) {
            return DataRow(
              cells: [
                DataCell(Text(item.id.toString())),
                DataCell(Text(item.qrCode.isEmpty ? '-' : item.qrCode)),
                DataCell(Text(item.namaLinen.isEmpty ? '-' : item.namaLinen)),
                DataCell(Text(item.tagRfid.isEmpty ? '-' : item.tagRfid)),
                DataCell(Text(item.namaRuangan.isEmpty ? '-' : item.namaRuangan)),
                DataCell(Text(item.namaKategori.isEmpty ? '-' : item.namaKategori)),
                DataCell(Text(item.tanggalKeluar.isEmpty ? '-' : item.tanggalKeluar)),
                DataCell(Text(item.jamKeluar.isEmpty ? '-' : item.jamKeluar)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _BelumKembaliError extends StatelessWidget {
  const _BelumKembaliError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          const Icon(
            Icons.cloud_off_rounded,
            size: 36,
            color: Color(0xffef6c6c),
          ),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}

class RekapanTransaksiPage extends StatefulWidget {
  const RekapanTransaksiPage({super.key, required this.userName});
  final String userName;
  @override
  State<RekapanTransaksiPage> createState() => _RekapanTransaksiPageState();
}

class _RekapanTransaksiPageState extends State<RekapanTransaksiPage> {
  bool _loading = true;
  String? _error;
  RekapanTransaksiResponse? _response;
  List<LinenRoomOption> _rooms = const [];
  int? _roomId;
  DateTimeRange? _range;

  @override
  void initState() { super.initState(); _load(); _loadRooms(); }

  String _date(DateTime d) => '${d.month}/${d.day}/${d.year}';
  String? get _daterange => _range == null ? null : '${_date(_range!.start)} - ${_date(_range!.end)}';

  Future<void> _loadRooms() async {
    try {
      final rooms = await ApiService.instance.getRekapanTransaksiRuangan();
      if (mounted) setState(() => _rooms = rooms);
    } catch (_) {}
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final r = await ApiService.instance.getRekapanTransaksi(daterange: _daterange, ruangan: _roomId);
      if (!mounted) return;
      setState(() { _response = r; _loading = false; });
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _error = 'Tidak dapat mengambil Rekapan Transaksi.'; _loading = false; });
    }
  }

  Future<void> _pickRange() async {
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: _range,
    );
    if (r != null) { setState(() => _range = r); _load(); }
  }

  @override
  Widget build(BuildContext context) {
    final summary = _response?.ringkasan;
    final rows = _response?.data ?? const <RekapanTransaksiItem>[];
    return AppShell(
      userName: widget.userName,
      activeIndex: 3,
      body: Column(
        children: [
          DetailHeader(title: 'Rekapan Transaksi', userName: widget.userName),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(children: [
              Expanded(
                child: DropdownButtonFormField<int?>(
                  value: _roomId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    hintText: 'Semua Ruangan',
                    prefixIcon: const Icon(Icons.meeting_room_rounded, size: 19),
                    filled: true, fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('Semua Ruangan')),
                    ..._rooms.map((r) => DropdownMenuItem<int?>(value: r.id, child: Text(r.nama))),
                  ],
                  onChanged: (v) { setState(() => _roomId = v); _load(); },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _pickRange,
                tooltip: 'Pilih rentang tanggal',
                style: IconButton.styleFrom(backgroundColor: const Color(0xff1261dc), foregroundColor: Colors.white),
                icon: const Icon(Icons.date_range_rounded, size: 20),
              ),
            ]),
          ),
          if (_range != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                Expanded(child: Text('Periode: ${_date(_range!.start)} - ${_date(_range!.end)}', style: const TextStyle(fontSize: 9, color: Color(0xff6f7f8d)))),
                TextButton(onPressed: () { setState(() => _range = null); _load(); }, child: const Text('Reset')),
              ]),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: _loading
                  ? const Padding(padding: EdgeInsets.all(50), child: Center(child: CircularProgressIndicator()))
                  : _error != null
                    ? Center(child: Column(children: [const SizedBox(height:40), const Icon(Icons.cloud_off_rounded,size:36), const SizedBox(height:10), Text(_error!,textAlign:TextAlign.center), const SizedBox(height:12), ElevatedButton(onPressed:_load,child:const Text('Coba Lagi'))]))
                    : Column(children: [
                        if (summary != null) _RekapSummary(summary: summary),
                        const SizedBox(height: 12),
                        if (rows.isEmpty) const Padding(padding: EdgeInsets.all(40),child: Text('Tidak ada data Rekapan Transaksi.'))
                        else _RekapTable(rows: rows),
                      ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RekapSummary extends StatelessWidget {
  const _RekapSummary({required this.summary});
  final RekapanTransaksiSummary summary;
  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: _RekapCard(title:'Linen Keluar',value:'${summary.totalLinenKeluar}',icon:Icons.arrow_upward_rounded)),
    const SizedBox(width:8),
    Expanded(child: _RekapCard(title:'Linen Masuk',value:'${summary.totalLinenMasuk}',icon:Icons.arrow_downward_rounded)),
    const SizedBox(width:8),
    Expanded(child: _RekapCard(title:'Berat Masuk',value:'${summary.totalBeratMasuk}',icon:Icons.scale_rounded)),
  ]);
}
class _RekapCard extends StatelessWidget {
  const _RekapCard({required this.title,required this.value,required this.icon});
  final String title,value; final IconData icon;
  @override
  Widget build(BuildContext context)=>Container(padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(16)),child:Column(children:[Icon(icon,size:20,color:const Color(0xff1261dc)),const SizedBox(height:6),Text(value,style:const TextStyle(fontSize:18,fontWeight:FontWeight.w800)),const SizedBox(height:2),Text(title,textAlign:TextAlign.center,style:const TextStyle(fontSize:8,color:Color(0xff6f7f8d))) ]));
}
class _RekapTable extends StatelessWidget {
  const _RekapTable({required this.rows}); final List<RekapanTransaksiItem> rows;
  @override
  Widget build(BuildContext context)=>Container(decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(18)),clipBehavior:Clip.antiAlias,child:SingleChildScrollView(scrollDirection:Axis.horizontal,child:DataTable(
    headingRowColor:WidgetStateProperty.all(const Color(0xff1261dc)),
    headingTextStyle:const TextStyle(color:Colors.white,fontSize:9,fontWeight:FontWeight.w700),
    dataTextStyle:const TextStyle(color:Color(0xff465564),fontSize:9),
    columns:const [DataColumn(label:Text('Tanggal')),DataColumn(label:Text('Keluar')),DataColumn(label:Text('Masuk')),DataColumn(label:Text('Berat Masuk'))],
    rows:rows.map((r)=>DataRow(cells:[DataCell(Text(r.tanggal)),DataCell(Text('${r.jumlahLinenKeluar}')),DataCell(Text('${r.jumlahLinenMasuk}')),DataCell(Text('${r.beratLinenMasuk}'))])).toList(),
  )));
}


class LinenLaundryPage extends StatefulWidget {
  const LinenLaundryPage({super.key, required this.userName});
  final String userName;
  @override State<LinenLaundryPage> createState() => _LinenLaundryPageState();
}

class _LinenLaundryPageState extends State<LinenLaundryPage> {
  bool _loading = true; String? _error; List<LinenLaundryItem> _items = const []; String? _selectedCategory; LinenMeta? _meta; int _page = 1;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final response = await ApiService.instance.getLinenLaundry(perPage: 10, page: _page);
      if (!mounted) return;
      setState(() { _items = response.data; _meta = response.meta; _loading = false; });
    } on ApiException catch (e) {
      if (!mounted) return; setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      if (!mounted) return; setState(() { _error = 'Tidak dapat mengambil data Linen & Tirai di Laundry.'; _loading = false; });
    }
  }
  void _openDetail(LinenLaundryItem item) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => LinenLaundryDetailPage(categoryId: item.id, categoryName: item.namaKategoriLinen, userName: widget.userName)));
  }
  @override Widget build(BuildContext context) {
    final categoryNames = _items.map((i) => i.namaKategoriLinen.trim()).where((n) => n.isNotEmpty).toSet().toList()..sort();
    final filtered = _selectedCategory == null ? _items : _items.where((i) => i.namaKategoriLinen.trim() == _selectedCategory).toList();
    return AppShell(userName: widget.userName, activeIndex: 0, body: Column(children: [
      DetailHeader(title: 'Linen & Tirai di Laundry', userName: widget.userName),
      Expanded(child: RefreshIndicator(onRefresh: _load, child: _loading ? const Center(child: CircularProgressIndicator()) : _error != null ? ListView(children: [Padding(padding: const EdgeInsets.all(24), child: Column(children: [const Icon(Icons.cloud_off_rounded), const SizedBox(height: 10), Text('_error!', textAlign: TextAlign.center), const SizedBox(height: 12), ElevatedButton(onPressed: _load, child: const Text('Coba Lagi'))]))]) : ListView(padding: const EdgeInsets.fromLTRB(16,14,16,24), children: [
        Container(width: double.infinity, padding: const EdgeInsets.fromLTRB(14,4,14,4), decoration: BoxDecoration(color: Colors.white,borderRadius: BorderRadius.circular(14)), child: DropdownButtonHideUnderline(child: DropdownButton<String?>(value: _selectedCategory,isExpanded:true,hint:const Text('Filter Kategori'),items:[const DropdownMenuItem<String?>(value:null,child:Text('Semua Kategori')),...categoryNames.map((n)=>DropdownMenuItem<String?>(value:n,child:Text(n)))],onChanged:(v)=>setState(()=>_selectedCategory=v)))),
        const SizedBox(height: 12),
        Container(width: double.infinity, decoration: BoxDecoration(color: Colors.white,borderRadius: BorderRadius.circular(18),boxShadow:[BoxShadow(color:Colors.black.withValues(alpha:.05),blurRadius:18,offset:const Offset(0,7))]),clipBehavior:Clip.antiAlias, child: LayoutBuilder(builder:(context,constraints){ final width=constraints.maxWidth<680?680.0:constraints.maxWidth; return SingleChildScrollView(scrollDirection:Axis.horizontal,child:SizedBox(width:width,child:DataTable(headingRowColor:WidgetStateProperty.all(const Color(0xff1261dc)),headingTextStyle:const TextStyle(color:Colors.white,fontSize:9,fontWeight:FontWeight.w700),dataTextStyle:const TextStyle(color:Color(0xff465564),fontSize:9),columnSpacing:28,horizontalMargin:16,columns:const [DataColumn(label:Text('Nama Category')),DataColumn(label:Text('Nama Linen')),DataColumn(label:Text('Ready')),DataColumn(label:Text('Action'))],rows:filtered.map((item)=>DataRow(cells:[DataCell(Text(item.namaKategoriLinen)),DataCell(Text(item.namaLinen)),DataCell(Text(item.ready.toString())),DataCell(TextButton(onPressed:()=>_openDetail(item),child:const Text('Detail')))])).toList()))); })),
        if(filtered.isEmpty) const Padding(padding:EdgeInsets.all(24),child:Center(child:Text('Tidak ada data untuk kategori ini.'))),
        if(_meta!=null) _MetaPagination(meta:_meta!,onPage:(page){setState(()=>_page=page);_load();}),
      ]))),
    ]));
  }
}

class LinenLaundryDetailPage extends StatefulWidget {
  const LinenLaundryDetailPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.userName,
  });

  final int categoryId;
  final String categoryName;
  final String userName;

  @override
  State<LinenLaundryDetailPage> createState() =>
      _LinenLaundryDetailPageState();
}

class _LinenLaundryDetailPageState extends State<LinenLaundryDetailPage> {
  bool _loading = true;
  String? _error;
  LinenLaundryDetailResponse? _response;
  int _page = 1;

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
      final response = await ApiService.instance.getLinenLaundryCategory(
        widget.categoryId,
        perPage: 10,
        page: _page,
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
        _error = 'Tidak dapat mengambil detail Linen & Tirai di Laundry.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = _response?.data ?? const <LinenLaundryDetailItem>[];

    return AppShell(
      userName: widget.userName,
      activeIndex: 0,
      body: Column(
        children: [
          DetailHeader(
            title: 'Detail Laundry - ${widget.categoryName}',
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
                      : rows.isEmpty
                          ? ListView(
                              children: const [
                                Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Text(
                                    'Belum ada detail linen di laundry.',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            )
                          : ListView(
                              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                              children: [
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      const tableWidth = 900.0;

                                      return SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: SizedBox(
                                          width: tableWidth,
                                          child: DataTable(
                                            headingRowColor:
                                                WidgetStateProperty.all(
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
                                            columnSpacing: 28,
                                            horizontalMargin: 16,
                                            columns: const [
                                              DataColumn(label: Text('ID')),
                                              DataColumn(
                                                label: Text('Kode Linen'),
                                              ),
                                              DataColumn(
                                                label: Text('Nama Linen'),
                                              ),
                                              DataColumn(
                                                label: Text('Nama Category'),
                                              ),
                                              DataColumn(
                                                label: Text('Jumlah Pencucian'),
                                              ),
                                            ],
                                            rows: rows
                                                .map(
                                                  (item) => DataRow(
                                                    cells: [
                                                      DataCell(
                                                        Text(item.id.toString()),
                                                      ),
                                                      DataCell(
                                                        Text(
                                                          item.kodeLinen.isEmpty
                                                              ? '-'
                                                              : item.kodeLinen,
                                                        ),
                                                      ),
                                                      DataCell(
                                                        Text(
                                                          item.namaLinen.isEmpty
                                                              ? '-'
                                                              : item.namaLinen,
                                                        ),
                                                      ),
                                                      DataCell(
                                                        Text(
                                                          item.namaKategoriLinen
                                                                  .isEmpty
                                                              ? '-'
                                                              : item.namaKategoriLinen,
                                                        ),
                                                      ),
                                                      DataCell(
                                                        Text(
                                                          item.jumlahPencucian
                                                              .toString(),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                )
                                                .toList(),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                _MetaPagination(meta: _response!.meta, onPage: (page) { setState(() => _page = page); _load(); }),
                              ],
                            ),
            ),
          ),
        ],
      ),
    );
  }
}

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
  LinenMeta? _meta;
  int _page = 1;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await ApiService.instance.getLinenRuangan(
        search: _search,
        perPage: 10,
        page: _page,
      );
      if (!mounted) return;
      setState(() {
        _items = response.data;
        _meta = response.meta;
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
        _error = 'Tidak dapat mengambil data Linen & Tirai di Ruangan.';
        _loading = false;
      });
    }
  }

  void _openDetail(LinenRuanganItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LinenRuanganDetailPage(
          roomId: item.id,
          roomName: item.namaRuangan,
          userName: widget.userName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      userName: widget.userName,
      activeIndex: 0,
      body: Column(
        children: [
          DetailHeader(
            title: 'Linen & Tirai di Ruangan',
            userName: widget.userName,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: TextField(
              controller: _searchController,
              onSubmitted: (value) {
                _search = value.trim().isEmpty ? null : value.trim();
                _load();
              },
              decoration: InputDecoration(
                hintText: 'Cari ruangan...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
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
                      : _items.isEmpty
                          ? ListView(
                              children: const [
                                Padding(
                                  padding: EdgeInsets.all(40),
                                  child: Center(
                                    child: Text(
                                      'Tidak ada data Linen & Tirai di Ruangan.',
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : ListView(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              children: [
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: .05),
                                        blurRadius: 18,
                                        offset: const Offset(0, 7),
                                      ),
                                    ],
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      final tableWidth =
                                          constraints.maxWidth < 680
                                              ? 680.0
                                              : constraints.maxWidth;
                                      return SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: SizedBox(
                                          width: tableWidth,
                                          child: DataTable(
                                            headingRowColor:
                                                WidgetStateProperty.all(
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
                                            columnSpacing: 28,
                                            horizontalMargin: 16,
                                            columns: const [
                                              DataColumn(
                                                label: Text('Nama Ruangan'),
                                              ),
                                              DataColumn(
                                                label: Text('Stok Awal'),
                                              ),
                                              DataColumn(label: Text('Hilang')),
                                              DataColumn(
                                                label: Text('Linen di Ruangan'),
                                              ),
                                              DataColumn(label: Text('Action')),
                                            ],
                                            rows: _items.map((item) {
                                              return DataRow(
                                                cells: [
                                                  DataCell(Text(item.namaRuangan)),
                                                  DataCell(Text(item.stokAwal.toString())),
                                                  DataCell(Text(item.hilang.toString())),
                                                  DataCell(Text(item.linenDiRuangan.toString())),
                                                  DataCell(
                                                    TextButton(
                                                      onPressed: () => _openDetail(item),
                                                      child: const Text('Detail'),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                if (_meta != null) _MetaPagination(meta: _meta!, onPage: (page) { setState(() => _page = page); _load(); }),
                              ],
                            ),
            ),
          ),
        ],
      ),
    );
  }
}

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
                            if (_response != null) _MetaPagination(meta: _response!.meta, onPage: (page) { setState(() => _detailPage = page); _load(); }),
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
                            if (_baResponse != null) _MetaPagination(meta: _baResponse!.meta, onPage: (page) { setState(() => _baPage = page); _load(); }),
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
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .05),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: LayoutBuilder(
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

class LinenHilangPage extends StatefulWidget {
  const LinenHilangPage({super.key, required this.userName});
  final String userName;
  @override
  State<LinenHilangPage> createState() => _LinenHilangPageState();
}

class _LinenHilangPageState extends State<LinenHilangPage> {
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  List<LinenHilangItem> _items = const [];
  LinenMeta? _meta;
  List<LinenRuanganItem> _rooms = const [];
  List<LinenCategory> _categories = const [];
  List<LinenHilangRuanganItem> _roomItems = const [];
  int _page = 1;
  int? _selectedRoom;
  int? _selectedCategory;
  String? _dateRange;
  final _searchController = TextEditingController();
  final Set<int> _selectedLinenIds = {};
  PlatformFile? _beritaAcara;

  @override
  void initState() {
    super.initState();
    _loadFilters();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFilters() async {
    try {
      final results = await Future.wait([
        ApiService.instance.getLinenRuangan(perPage: 1000),
        ApiService.instance.getLinen(perPage: 1000),
      ]);
      if (!mounted) return;
      setState(() {
        _rooms = (results[0] as LinenListResponse<LinenRuanganItem>).data;
        _categories = (results[1] as LinenListResponse<LinenCategory>).data;
      });
    } catch (_) {}
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await ApiService.instance.getLinenHilang(
        search: _searchController.text.trim(),
        perPage: 10,
        filterRuangan: _selectedRoom,
        filterKategori: _selectedCategory,
        daterange: _dateRange,
        page: _page,
      );
      if (!mounted) return;
      setState(() {
        _items = response.data;
        _meta = response.meta;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _error = 'Tidak dapat mengambil data Linen & Tirai Hilang.'; _loading = false; });
    }
  }

  void _applyFilters() {
    setState(() => _page = 1);
    _load();
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDateRange: DateTimeRange(
        start: now.subtract(const Duration(days: 30)),
        end: now,
      ),
    );
    if (picked == null) return;
    String two(int v) => v.toString().padLeft(2, '0');
    setState(() {
      _dateRange =
          '${two(picked.start.month)}/${two(picked.start.day)}/${picked.start.year} - '
          '${two(picked.end.month)}/${two(picked.end.day)}/${picked.end.year}';
    });
    _applyFilters();
  }

  Future<void> _loadRoomItems(int roomId) async {
    try {
      final response = await ApiService.instance.getLinenHilangRuanganList(
        ruanganId: roomId,
        perPage: 1000,
      );
      if (!mounted) return;
      setState(() {
        _roomItems = response.data;
        _selectedLinenIds.clear();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is ApiException ? e.message : 'Gagal mengambil linen aktif di ruangan.')),
      );
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _beritaAcara = result.files.single);
    }
  }

  Future<void> _showAddForm() async {
    int? roomId;
    DateTime tanggal = DateTime.now();
    List<LinenHilangRuanganItem> roomItems = const [];
    final selected = <int>{};
    PlatformFile? file;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        bool loadingItems = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> loadItems(int id) async {
              setDialogState(() => loadingItems = true);
              try {
                final response = await ApiService.instance.getLinenHilangRuanganList(
                  ruanganId: id,
                  perPage: 1000,
                );
                roomItems = response.data;
                selected.clear();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e is ApiException ? e.message : 'Gagal mengambil linen aktif di ruangan.')),
                  );
                }
              } finally {
                if (context.mounted) setDialogState(() => loadingItems = false);
              }
            }

            return AlertDialog(
              title: const Text('Tambah Linen Hilang'),
              content: SizedBox(
                width: 560,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<int>(
                        value: roomId,
                        decoration: const InputDecoration(labelText: 'Ruangan'),
                        items: _rooms.map((room) => DropdownMenuItem(
                          value: room.id,
                          child: Text(room.namaRuangan),
                        )).toList(),
                        onChanged: (value) {
                          roomId = value;
                          if (value != null) loadItems(value);
                          setDialogState(() {});
                        },
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Tanggal: ${tanggal.day.toString().padLeft(2, '0')}/${tanggal.month.toString().padLeft(2, '0')}/${tanggal.year}'),
                        trailing: const Icon(Icons.calendar_month_rounded),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: tanggal,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(DateTime.now().year + 1),
                          );
                          if (picked != null) setDialogState(() => tanggal = picked);
                        },
                      ),
                      const SizedBox(height: 8),
                      const Text('Pilih linen yang hilang', style: TextStyle(fontWeight: FontWeight.w700)),
                      if (loadingItems)
                        const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (roomId == null)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text('Pilih ruangan terlebih dahulu.'),
                        )
                      else if (roomItems.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text('Tidak ada linen aktif di ruangan ini.'),
                        )
                      else
                        ...roomItems.map((item) => CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          value: selected.contains(item.linenId),
                          title: Text(item.namaLinen),
                          subtitle: Text('${item.kategoriLinen} • ${item.qrCode} • ${item.tagRfid}'),
                          onChanged: (checked) => setDialogState(() {
                            if (checked == true) {
                              selected.add(item.linenId);
                            } else {
                              selected.remove(item.linenId);
                            }
                          }),
                        )),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
                            withData: true,
                          );
                          if (result != null && result.files.isNotEmpty) {
                            file = result.files.single;
                            setDialogState(() {});
                          }
                        },
                        icon: const Icon(Icons.attach_file_rounded),
                        label: Text(file?.name ?? 'Lampirkan Berita Acara'),
                      ),
                      if (file != null)
                        Text('Maksimal 10 MB • PDF/DOC/DOCX/JPG/JPEG/PNG',
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: roomId == null || selected.isEmpty || loadingItems
                      ? null
                      : () async {
                          if (file != null && (file!.size > 10 * 1024 * 1024)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('File maksimal 10 MB.')),
                            );
                            return;
                          }
                          Navigator.of(dialogContext).pop();
                          await _submitHilang(
                            tanggal,
                            roomId!,
                            selected.toList(),
                            file,
                          );
                        },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submitHilang(
    DateTime tanggal,
    int roomId,
    List<int> linenIds,
    PlatformFile? file,
  ) async {
    setState(() => _submitting = true);
    try {
      String two(int v) => v.toString().padLeft(2, '0');
      await ApiService.instance.createLinenHilang(
        tanggal: '${tanggal.year}-${two(tanggal.month)}-${two(tanggal.day)}',
        ruanganId: roomId,
        linenIds: linenIds,
        beritaAcaraBytes: file?.bytes,
        beritaAcaraName: file?.name,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Linen hilang berhasil ditambahkan.')),
      );
      setState(() => _page = 1);
      await _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menambahkan linen hilang.')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      userName: widget.userName,
      activeIndex: 0,
      body: Column(
        children: [
          DetailHeader(title: 'Linen & Tirai Hilang', userName: widget.userName),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? ListView(children: [
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                const Icon(Icons.cloud_off_rounded),
                                const SizedBox(height: 10),
                                Text(_error!, textAlign: TextAlign.center),
                                const SizedBox(height: 12),
                                ElevatedButton(onPressed: _load, child: const Text('Coba Lagi')),
                              ],
                            ),
                          ),
                        ])
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    onSubmitted: (_) => _applyFilters(),
                                    decoration: InputDecoration(
                                      hintText: 'Cari ruangan, kategori, linen, RFID, atau QR Code',
                                      prefixIcon: const Icon(Icons.search_rounded),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  tooltip: 'Pilih tanggal',
                                  onPressed: _pickDateRange,
                                  icon: const Icon(Icons.date_range_rounded),
                                ),
                                IconButton(
                                  tooltip: 'Reset filter',
                                  onPressed: _selectedRoom == null && _selectedCategory == null && _dateRange == null && _searchController.text.isEmpty
                                      ? null
                                      : () {
                                          _searchController.clear();
                                          setState(() {
                                            _selectedRoom = null;
                                            _selectedCategory = null;
                                            _dateRange = null;
                                            _page = 1;
                                          });
                                          _load();
                                        },
                                  icon: const Icon(Icons.filter_alt_off_rounded),
                                ),
                                ElevatedButton.icon(
                                  onPressed: _submitting ? null : _showAddForm,
                                  icon: const Icon(Icons.add_rounded),
                                  label: const Text('Tambah'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<int?>(
                                    value: _selectedRoom,
                                    decoration: const InputDecoration(
                                      labelText: 'Filter Ruangan',
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(borderSide: BorderSide.none),
                                    ),
                                    items: [
                                      const DropdownMenuItem<int?>(value: null, child: Text('Semua Ruangan')),
                                      ..._rooms.map((r) => DropdownMenuItem(value: r.id, child: Text(r.namaRuangan))),
                                    ],
                                    onChanged: (v) {
                                      setState(() { _selectedRoom = v; _page = 1; });
                                      _load();
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: DropdownButtonFormField<int?>(
                                    value: _selectedCategory,
                                    decoration: const InputDecoration(
                                      labelText: 'Filter Kategori',
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(borderSide: BorderSide.none),
                                    ),
                                    items: [
                                      const DropdownMenuItem<int?>(value: null, child: Text('Semua Kategori')),
                                      ..._categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.namaKategoriLinen))),
                                    ],
                                    onChanged: (v) {
                                      setState(() { _selectedCategory = v; _page = 1; });
                                      _load();
                                    },
                                  ),
                                ),
                              ],
                            ),
                            if (_dateRange != null) ...[
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Chip(
                                  label: Text(_dateRange!),
                                  onDeleted: () {
                                    setState(() { _dateRange = null; _page = 1; });
                                    _load();
                                  },
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withValues(alpha: .05), blurRadius: 18, offset: const Offset(0, 7)),
                                ],
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final tableWidth = constraints.maxWidth < 980 ? 980.0 : constraints.maxWidth;
                                  return SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    physics: const ClampingScrollPhysics(),
                                    child: SizedBox(
                                      width: tableWidth,
                                      child: DataTable(
                                        headingRowColor: WidgetStateProperty.all(const Color(0xff1261dc)),
                                        headingTextStyle: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                                        dataTextStyle: const TextStyle(color: Color(0xff465564), fontSize: 9),
                                        columnSpacing: 22,
                                        horizontalMargin: 16,
                                        columns: const [
                                          DataColumn(label: Text('ID')),
                                          DataColumn(label: Text('Ruangan')),
                                          DataColumn(label: Text('Kategori')),
                                          DataColumn(label: Text('Jenis Linen')),
                                          DataColumn(label: Text('QR Code')),
                                          DataColumn(label: Text('RFID')),
                                          DataColumn(label: Text('Transaksi Terakhir')),
                                          DataColumn(label: Text('Tanggal Hilang')),
                                        ],
                                        rows: _items.map((item) => DataRow(cells: [
                                          DataCell(Text(item.id.toString())),
                                          DataCell(Text(item.namaRuangan)),
                                          DataCell(Text(item.kategoriLinen)),
                                          DataCell(Text(item.jenisLinen)),
                                          DataCell(Text(item.qrCode)),
                                          DataCell(Text(item.tagRfid)),
                                          DataCell(Text(item.tanggalTerakhirTransaksi)),
                                          DataCell(Text(item.tanggalHilang)),
                                        ])).toList(),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                            if (_items.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(24),
                                child: Center(child: Text('Tidak ada data Linen & Tirai Hilang.')),
                              ),
                            if (_meta != null)
                              _MetaPagination(
                                meta: _meta!,
                                onPage: (page) {
                                  setState(() => _page = page);
                                  _load();
                                },
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

class LinenRusakPage extends StatefulWidget {
  const LinenRusakPage({super.key, required this.userName});

  final String userName;

  @override
  State<LinenRusakPage> createState() => _LinenRusakPageState();
}

class _LinenRusakPageState extends State<LinenRusakPage> {
  bool _loading = true;
  String? _error;
  List<LinenRusakItem> _items = const [];
  LinenMeta? _meta;
  int _page = 1;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await ApiService.instance.getLinenRusak(
        search: _searchController.text,
        perPage: 10,
        page: _page,
      );
      if (!mounted) return;
      setState(() {
        _items = response.data;
        _meta = response.meta;
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
        _error = 'Tidak dapat mengambil data Linen & Tirai Rusak.';
        _loading = false;
      });
    }
  }

  void _search() {
    setState(() => _page = 1);
    _load();
  }

  Future<void> _scan() async {
    final controller = TextEditingController();
    final rfid = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scan Linen Rusak'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'RFID / QR Code',
            hintText: 'Masukkan RFID atau QR Code',
          ),
          onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Scan'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (rfid == null || rfid.isEmpty) return;

    try {
      final result = await ApiService.instance.scanLinenRusak(rfid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']?.toString() ?? 'Linen rusak berhasil ditambahkan.')),
      );
      setState(() => _page = 1);
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      userName: widget.userName,
      activeIndex: 0,
      body: Column(
        children: [
          DetailHeader(
            title: 'Linen & Tirai Rusak',
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
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    onSubmitted: (_) => _search(),
                                    decoration: InputDecoration(
                                      hintText: 'Cari nama linen, RFID, atau QR Code',
                                      prefixIcon: const Icon(Icons.search_rounded),
                                      suffixIcon: _searchController.text.isEmpty
                                          ? null
                                          : IconButton(
                                              onPressed: () {
                                                _searchController.clear();
                                                _search();
                                              },
                                              icon: const Icon(Icons.clear_rounded),
                                            ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton.icon(
                                  onPressed: _scan,
                                  icon: const Icon(Icons.qr_code_scanner_rounded),
                                  label: const Text('Scan'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: .05),
                                    blurRadius: 18,
                                    offset: const Offset(0, 7),
                                  ),
                                ],
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final tableWidth = constraints.maxWidth < 980 ? 980.0 : constraints.maxWidth;
                                  return SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    physics: const ClampingScrollPhysics(),
                                    child: SizedBox(
                                      width: tableWidth,
                                      child: DataTable(
                                        headingRowColor: WidgetStateProperty.all(const Color(0xff1261dc)),
                                        headingTextStyle: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                                        dataTextStyle: const TextStyle(color: Color(0xff465564), fontSize: 9),
                                        columnSpacing: 24,
                                        horizontalMargin: 16,
                                        columns: const [
                                          DataColumn(label: Text('No.')),
                                          DataColumn(label: Text('Linen ID')),
                                          DataColumn(label: Text('Nama Linen')),
                                          DataColumn(label: Text('RFID')),
                                          DataColumn(label: Text('QR Code')),
                                          DataColumn(label: Text('Jam')),
                                          DataColumn(label: Text('Tanggal')),
                                          DataColumn(label: Text('Tahun Pembuatan')),
                                        ],
                                        rows: _items.asMap().entries.map((entry) {
                                          final index = entry.key;
                                          final item = entry.value;
                                          final number = ((_meta?.currentPage ?? _page) - 1) *
                                                  (_meta?.perPage ?? 10) +
                                              index +
                                              1;

                                          return DataRow(cells: [
                                            DataCell(Text(number.toString())),
                                            DataCell(Text(item.linenId.toString())),
                                            DataCell(Text(item.namaLinen)),
                                            DataCell(Text(item.tagRfid)),
                                            DataCell(Text(item.qrCode)),
                                            DataCell(Text(item.jam)),
                                            DataCell(Text(item.tanggal)),
                                            DataCell(Text(item.tahunPembuatan)),
                                          ]);
                                        }).toList(),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                            if (_items.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(24),
                                child: Center(child: Text('Tidak ada data Linen & Tirai Rusak.')),
                              ),
                            if (_meta != null)
                              _MetaPagination(
                                meta: _meta!,
                                onPage: (page) {
                                  setState(() => _page = page);
                                  _load();
                                },
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

class LinenReadyPage extends StatefulWidget {
  const LinenReadyPage({super.key, required this.userName});
  final String userName;

  @override
  State<LinenReadyPage> createState() => _LinenReadyPageState();
}

class _LinenReadyPageState extends State<LinenReadyPage> {
  bool _loading = true;
  String? _error;
  List<LinenCategory> _categories = const [];
  String? _selectedCategory;
  LinenMeta? _meta;
  int _page = 1;

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
      final response = await ApiService.instance.getLinen(perPage: 10, page: _page);
      if (!mounted) return;

      setState(() {
        _categories = response.data;
        _meta = response.meta;
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
        _error = 'Tidak dapat mengambil data Linen & Tirai Ready.';
        _loading = false;
      });
    }
  }

  void _openDetail(LinenCategory category) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LinenCategoryDetailPage(
          category: category,
          userName: widget.userName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoryNames = _categories
        .map((item) => item.namaKategoriLinen.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    final filteredCategories = _selectedCategory == null
        ? _categories
        : _categories
            .where((item) => item.namaKategoriLinen.trim() == _selectedCategory)
            .toList();

    return AppShell(
      userName: widget.userName,
      activeIndex: 0,
      body: Column(
        children: [
          DetailHeader(
            title: 'Linen & Tirai Ready',
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
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String?>(
                                  value: _selectedCategory,
                                  isExpanded: true,
                                  hint: const Text('Filter Kategori'),
                                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                                  items: [
                                    const DropdownMenuItem<String?>(
                                      value: null,
                                      child: Text('Semua Kategori'),
                                    ),
                                    ...categoryNames.map(
                                      (name) => DropdownMenuItem<String?>(
                                        value: name,
                                        child: Text(name),
                                      ),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(() => _selectedCategory = value);
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: .05),
                                    blurRadius: 18,
                                    offset: const Offset(0, 7),
                                  ),
                                ],
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final tableWidth = constraints.maxWidth < 680
                                      ? 680.0
                                      : constraints.maxWidth;

                                  return SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: SizedBox(
                                      width: tableWidth,
                                      child: DataTable(
                                        headingRowColor:
                                            WidgetStateProperty.all(
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
                                        columnSpacing: 28,
                                        horizontalMargin: 16,
                                        columns: const [
                                          DataColumn(
                                            label: Text('Nama Category'),
                                          ),
                                          DataColumn(
                                            label: Text('Nama Linen'),
                                          ),
                                          DataColumn(
                                            label: Text('Stock Ready'),
                                          ),
                                          DataColumn(
                                            label: Text('Action'),
                                          ),
                                        ],
                                        rows: filteredCategories.map((category) {
                                          final namaLinen =
                                              category.subKategoriLinen.trim().isEmpty
                                                  ? '-'
                                                  : category.subKategoriLinen;

                                          return DataRow(
                                            cells: [
                                              DataCell(
                                                Text(category.namaKategoriLinen),
                                              ),
                                              DataCell(Text(namaLinen)),
                                              DataCell(
                                                Text(category.jumlahStok.toString()),
                                              ),
                                              DataCell(
                                                TextButton(
                                                  onPressed: () =>
                                                      _openDetail(category),
                                                  child: const Text('Detail'),
                                                ),
                                              ),
                                            ],
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            if (filteredCategories.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(24),
                                child: Center(
                                  child: Text('Tidak ada data untuk kategori ini.'),
                                ),
                              ),
                            if (_meta != null) _MetaPagination(meta: _meta!, onPage: (page) { setState(() => _page = page); _load(); }),
                          ],
                        ),
            ),
          ),
        ],
      ),
    );
  }
}


class LinenKeluarPage extends StatefulWidget {
  const LinenKeluarPage({super.key, required this.userName});
  final String userName;
  @override State<LinenKeluarPage> createState() => _LinenKeluarPageState();
}
class _LinenKeluarPageState extends State<LinenKeluarPage> {
  bool _loading=true,_optionsLoading=true,_queueLoading=true;
  String? _error;
  LinenListResponse<LinenKeluarItem>? _response;
  LinenKeluarOptions? _options;
  LinenScanQueueResponse? _queue;
  final _searchController=TextEditingController();
  int _page=1,_perPage=10;
  int? _selectedRoom,_selectedUser;
  DateTime? _selectedDate;
  DateTimeRange? _selectedDateRange;

  @override void initState(){super.initState();_loadOptions();_load();_loadQueue();}
  @override void dispose(){_searchController.dispose();super.dispose();}
  String _date(DateTime d)=>'${d.month}/${d.day}/${d.year}';
  String _range(DateTimeRange r)=>'${_date(r.start)} - ${_date(r.end)}';

  Future<void> _loadOptions() async {
    try {
      final o=await ApiService.instance.getLinenKeluarOptions();
      if(!mounted)return;
      setState(()=>_options=o);
    } catch (_) {} finally { if(mounted)setState(()=>_optionsLoading=false); }
  }
  Future<void> _load() async {
    setState(()=>_loading=true);
    try {
      final r=await ApiService.instance.getLinenKeluar(
        perPage:_perPage,page:_page,
        search:_searchController.text.trim().isEmpty?null:_searchController.text.trim(),
        ruangan:_selectedRoom,date:_selectedDate==null?null:_date(_selectedDate!),
        daterange:_selectedDateRange==null?null:_range(_selectedDateRange!));
      if(!mounted)return;
      setState(()=>{_response=r,_error=null,_loading=false});
    } on ApiException catch(e) {
      if(!mounted)return; setState(()=>{_error=e.message,_loading=false});
    } catch(_) { if(!mounted)return; setState(()=>{_error='Tidak dapat mengambil data Linen & Tirai Keluar dari server.',_loading=false}); }
  }
  Future<void> _loadQueue() async {
    if(mounted)setState(()=>_queueLoading=true);
    try { final q=await ApiService.instance.getLinenKeluarScanQueue(); if(mounted)setState(()=>_queue=q); }
    catch(_) {} finally { if(mounted)setState(()=>_queueLoading=false); }
  }
  Future<void> _scan() async {
    final c=TextEditingController();
    final v=await showDialog<String>(context:context,builder:(context)=>AlertDialog(
      title:const Text('Scan Linen Keluar'),
      content:TextField(controller:c,autofocus:true,decoration:const InputDecoration(labelText:'RFID / QR Code'),
        onSubmitted:(v)=>Navigator.of(context).pop(v.trim())),
      actions:[TextButton(onPressed:()=>Navigator.of(context).pop(),child:const Text('Batal')),
        ElevatedButton(onPressed:()=>Navigator.of(context).pop(c.text.trim()),child:const Text('Scan'))]));
    c.dispose(); if(v==null||v.isEmpty)return;
    try { final r=await ApiService.instance.scanLinenKeluar(v); if(!mounted)return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(r['message']?.toString()??'Item ditambahkan ke antrean.'))); await _loadQueue();
    } on ApiException catch(e) { if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.message))); }
  }
  Future<void> _deleteQueue(LinenScanQueueItem item) async {
    try { final r=await ApiService.instance.deleteLinenKeluarScan(item.linenKeluarId); if(!mounted)return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(r['message']?.toString()??'Item dihapus.'))); await _loadQueue();
    } on ApiException catch(e) { if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.message))); }
  }
  Future<void> _saveQueue() async {
    final items=_queue?.data??const <LinenScanQueueItem>[];
    if(items.isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Antrean scan masih kosong.')));return;}
    if(_selectedRoom==null||_selectedUser==null){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Pilih ruangan dan user terlebih dahulu.')));return;}
    try { final r=await ApiService.instance.saveLinenKeluar(linens:items.map((e)=>e.linenId).toList(),ruanganId:_selectedRoom!,userId:_selectedUser!);
      if(!mounted)return; ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(r['message']?.toString()??'Transaksi berhasil disimpan.')));
      await Future.wait([_load(),_loadQueue()]);
    } on ApiException catch(e) { if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.message))); }
  }
  Future<void> _pickDate() async {
    final d=await showDatePicker(context:context,initialDate:_selectedDate??DateTime.now(),firstDate:DateTime(2020),lastDate:DateTime(2100));
    if(d!=null){setState(()=>{_selectedDate=d,_selectedDateRange=null,_page=1});_load();}
  }
  Future<void> _pickRange() async {
    final r=await showDateRangePicker(context:context,firstDate:DateTime(2020),lastDate:DateTime(2100),initialDateRange:_selectedDateRange);
    if(r!=null){setState(()=>{_selectedDateRange=r,_selectedDate=null,_page=1});_load();}
  }
  void _reset(){_searchController.clear();setState(()=>{_selectedRoom=null,_selectedUser=null,_selectedDate=null,_selectedDateRange=null,_page=1});_load();}

  @override Widget build(BuildContext context) {
    final rows=_response?.data??const <LinenKeluarItem>[];
    final meta=_response?.meta;
    return AppShell(userName:widget.userName,activeIndex:5,body:Column(children:[
      DetailHeader(title:'Linen & Tirai Keluar',userName:widget.userName),
      Expanded(child:RefreshIndicator(onRefresh:() async=>Future.wait([_load(),_loadQueue()]),child:ListView(padding:const EdgeInsets.fromLTRB(16,14,16,100),children:[
        Row(children:[
          Expanded(child:TextField(controller:_searchController,onSubmitted:(_){setState(()=>_page=1);_load();},decoration:InputDecoration(
            hintText:'Cari nama linen, RFID, QR Code, user...',prefixIcon:const Icon(Icons.search_rounded),filled:true,fillColor:Colors.white,
            border:OutlineInputBorder(borderRadius:BorderRadius.circular(14),borderSide:BorderSide.none)))),
          const SizedBox(width:8),ElevatedButton.icon(onPressed:_scan,icon:const Icon(Icons.qr_code_scanner_rounded),label:const Text('Scan'))]),
        const SizedBox(height:10),
        if(_optionsLoading)const LinearProgressIndicator(minHeight:2),
        Row(children:[
          Expanded(child:DropdownButtonFormField<int?>(value:_selectedRoom,decoration:const InputDecoration(labelText:'Ruangan',filled:true,fillColor:Colors.white,border:OutlineInputBorder(borderSide:BorderSide.none)),
            items:[const DropdownMenuItem<int?>(value:null,child:Text('Semua Ruangan')), ...?_options?.ruangan.map((r)=>DropdownMenuItem<int?>(value:r.id,child:Text(r.namaRuangan)))],
            onChanged:(v){setState(()=>{_selectedRoom=v,_page=1});_load();})),
          const SizedBox(width:8),
          Expanded(child:DropdownButtonFormField<int?>(value:_selectedUser,decoration:const InputDecoration(labelText:'User',filled:true,fillColor:Colors.white,border:OutlineInputBorder(borderSide:BorderSide.none)),
            items:[const DropdownMenuItem<int?>(value:null,child:Text('Semua User')), ...?_options?.users.map((u)=>DropdownMenuItem<int?>(value:u.id,child:Text('${u.name} (${u.username})')))],
            onChanged:(v){setState(()=>{_selectedUser=v,_page=1});_load();})),
        ]),
        const SizedBox(height:8),
        Row(children:[
          Expanded(child:OutlinedButton.icon(onPressed:_pickDate,icon:const Icon(Icons.event_rounded),label:Text(_selectedDate==null?'Tanggal':_date(_selectedDate!)))),
          const SizedBox(width:8),Expanded(child:OutlinedButton.icon(onPressed:_pickRange,icon:const Icon(Icons.date_range_rounded),label:Text(_selectedDateRange==null?'Rentang Tanggal':_range(_selectedDateRange!)))),
          IconButton(onPressed:_reset,tooltip:'Reset filter',icon:const Icon(Icons.filter_alt_off_rounded))]),
        const SizedBox(height:12),
        Container(padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(18)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Row(children:[Expanded(child:Text('Antrean Scan (${_queue?.total??0})',style:const TextStyle(fontSize:13,fontWeight:FontWeight.w800))),ElevatedButton.icon(onPressed:_saveQueue,icon:const Icon(Icons.save_rounded,size:18),label:const Text('Simpan Keluar'))]),
          const SizedBox(height:8),
          _queueLoading?const Padding(padding:EdgeInsets.all(16),child:Center(child:CircularProgressIndicator())):(_queue?.data.isEmpty??true)?const Padding(padding:EdgeInsets.all(12),child:Text('Antrean scan kosong.')):
          SingleChildScrollView(scrollDirection:Axis.horizontal,child:DataTable(
            headingRowColor:WidgetStateProperty.all(const Color(0xff1261dc)),headingTextStyle:const TextStyle(color:Colors.white,fontSize:9,fontWeight:FontWeight.w700),dataTextStyle:const TextStyle(fontSize:9),
            columns:const [DataColumn(label:Text('No.')),DataColumn(label:Text('Linen ID')),DataColumn(label:Text('Kategori')),DataColumn(label:Text('QR Code')),DataColumn(label:Text('RFID')),DataColumn(label:Text('Waktu Scan')),DataColumn(label:Text('Aksi'))],
            rows:_queue!.data.asMap().entries.map((e)=>DataRow(cells:[DataCell(Text('${e.key+1}')),DataCell(Text('${e.value.linenId}')),DataCell(Text(e.value.namaKategoriLinen)),DataCell(Text(e.value.qrCode)),DataCell(Text(e.value.tagRfid)),DataCell(Text(e.value.waktuScan)),DataCell(IconButton(onPressed:()=>_deleteQueue(e.value),tooltip:'Hapus',icon:const Icon(Icons.delete_outline_rounded)))] )).toList(),
          )),
        ])),
        const SizedBox(height:12),
        if(_loading)const Center(child:Padding(padding:EdgeInsets.all(30),child:CircularProgressIndicator()))
        else if(_error!=null)Padding(padding:const EdgeInsets.all(24),child:Column(children:[const Icon(Icons.cloud_off_rounded),const SizedBox(height:10),Text(_error!,textAlign:TextAlign.center),const SizedBox(height:12),ElevatedButton(onPressed:_load,child:const Text('Coba Lagi'))]))
        else Container(clipBehavior:Clip.antiAlias,decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(18)),child:SingleChildScrollView(scrollDirection:Axis.horizontal,child:DataTable(
          headingRowColor:WidgetStateProperty.all(const Color(0xff1261dc)),headingTextStyle:const TextStyle(color:Colors.white,fontSize:9,fontWeight:FontWeight.w700),dataTextStyle:const TextStyle(fontSize:9),columnSpacing:22,
          columns:const [DataColumn(label:Text('No.')),DataColumn(label:Text('Nama Linen')),DataColumn(label:Text('QR Code')),DataColumn(label:Text('RFID')),DataColumn(label:Text('Ke Ruangan')),DataColumn(label:Text('Jam')),DataColumn(label:Text('Tanggal')),DataColumn(label:Text('User'))],
          rows:rows.asMap().entries.map((e){final n=((meta?.currentPage??_page)-1)*(meta?.perPage??_perPage)+e.key+1;return DataRow(cells:[DataCell(Text('${n}')),DataCell(Text(e.value.namaLinen)),DataCell(Text(e.value.qrCode)),DataCell(Text(e.value.tagRfid)),DataCell(Text(e.value.keRuangan)),DataCell(Text(e.value.jam)),DataCell(Text(e.value.tanggal)),DataCell(Text(e.value.user))]);}).toList(),
        ))),
        if(!_loading&&_error==null&&rows.isEmpty)const Padding(padding:EdgeInsets.all(24),child:Center(child:Text('Tidak ada data Linen & Tirai Keluar.'))),
        if(meta!=null)Row(children:[const Text('Tampilkan',style:TextStyle(fontSize:9)),const SizedBox(width:8),DropdownButton<int>(value:_perPage,items:const [10,25,50,100].map((v)=>DropdownMenuItem(value:v,child:Text('${v}'))).toList(),onChanged:(v){if(v==null)return;setState(()=>{_perPage=v,_page=1});_load();}),const Spacer(),Text('Total ${meta.total}',style:const TextStyle(fontSize:9))]),
        if(meta!=null)_MetaPagination(meta:meta,onPage:(p){setState(()=>_page=p);_load();}),
      ]))),
    ]));
  }
}
