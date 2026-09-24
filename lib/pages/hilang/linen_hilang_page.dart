import 'dart:ui' show PointerDeviceKind;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../api/api_service.dart';
import '../../widgets/pagination_widget.dart';
import '../../widgets/shared_widgets.dart';

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
  bool _submitting = false;
  String? _error;

  LinenListResponse<LinenHilangItem>? _response;
  List<LinenHilangRuanganOption> _rooms = const [];
  List<Map<String, dynamic>> _categories = const [];
  List<LinenHilangRuanganItem> _roomItems = const [];

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

  Future<void> _loadRoomItems(int roomId) async {
    try {
      final response = await ApiService.instance.getLinenHilangRuanganList(
        ruanganId: roomId,
        perPage: 100,
        page: 1,
      );
      if (!mounted) return;
      setState(() => _roomItems = response.data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _roomItems = const []);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is ApiException
                ? e.message
                : 'Gagal mengambil linen aktif di ruangan.',
          ),
        ),
      );
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
    if (_rooms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data ruangan belum tersedia.')),
      );
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _LinenHilangFormDialog(
        rooms: _rooms,
        initialRoomId: _filterRoom,
        loadRoomItems: _loadRoomItems,
        roomItems: _roomItems,
        submitting: _submitting,
        onSubmit: _submitCreate,
      ),
    );

    if (result == true) {
      _roomItems = const [];
      _page = 1;
      await _load();
    }
  }

  Future<bool> _submitCreate({
    required String tanggal,
    required int ruanganId,
    required List<int> linenIds,
    required PlatformFile? file,
  }) async {
    if (linenIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal satu linen.')),
      );
      return false;
    }

    setState(() => _submitting = true);
    try {
      final response = await ApiService.instance.createLinenHilang(
        tanggal: tanggal,
        ruanganId: ruanganId,
        linenIds: linenIds,
        beritaAcaraBytes: file?.bytes,
        beritaAcaraName: file?.name,
        beritaAcaraPath: file?.path,
      );

      if (!mounted) return false;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response['message']?.toString() ??
                'Linen hilang berhasil ditambahkan.',
          ),
        ),
      );
      return true;
    } on ApiException catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
      return false;
    } catch (_) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan Linen Hilang.')),
      );
      return false;
    } finally {
      if (mounted) setState(() => _submitting = false);
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
                    OutlinedButton.icon(
                      onPressed: _pickRange,
                      icon: const Icon(Icons.date_range_rounded, size: 18),
                      label: Text(
                        _dateRange == null
                            ? 'Rentang Tanggal'
                            : _daterange!,
                      ),
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
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  children: [
                    if (_roomsLoading || _categoriesLoading)
                      const LinearProgressIndicator(minHeight: 2),
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
                      _buildTable(rows, meta),
                    if (!_loading && _error == null && meta != null) ...[
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'Total ${meta.total} linen hilang',
                            style: const TextStyle(
                              color: Color(0xff7d8c99),
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Text(
                            'Tampilkan',
                            style: TextStyle(
                              color: Color(0xff7d8c99),
                              fontSize: 9,
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
                      AppPagination(meta: meta, onPage: (page) {
                        setState(() => _page = page);
                        _load();
                      }),
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
        child: ScrollConfiguration(
          behavior: const MaterialScrollBehavior().copyWith(
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
            },
          ),
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
              columnSpacing: 26,
              horizontalMargin: 14,
              columns: const [
                DataColumn(label: Text('ID')),
                DataColumn(label: Text('Ruangan')),
                DataColumn(label: Text('Kategori')),
                DataColumn(label: Text('Jenis Linen')),
                DataColumn(label: Text('QR Code')),
                DataColumn(label: Text('RFID')),
                DataColumn(label: Text('Terakhir Transaksi')),
                DataColumn(label: Text('Tanggal Hilang')),
              ],
              rows: rows.map((item) {
                return DataRow(
                  cells: [
                    DataCell(Text(item.id.toString())),
                    DataCell(
                      Text(item.namaRuangan.isEmpty ? '-' : item.namaRuangan),
                    ),
                    DataCell(
                      Text(
                        item.kategoriLinen.isEmpty ? '-' : item.kategoriLinen,
                      ),
                    ),
                    DataCell(
                      Text(item.jenisLinen.isEmpty ? '-' : item.jenisLinen),
                    ),
                    DataCell(Text(item.qrCode.isEmpty ? '-' : item.qrCode)),
                    DataCell(Text(item.tagRfid.isEmpty ? '-' : item.tagRfid)),
                    DataCell(
                      Text(
                        item.tanggalTerakhirTransaksi.isEmpty
                            ? '-'
                            : item.tanggalTerakhirTransaksi,
                      ),
                    ),
                    DataCell(
                      Text(
                        item.tanggalHilang.isEmpty ? '-' : item.tanggalHilang,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
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
      child: Center(child: Text('Belum ada data Linen & Tirai Hilang.')),
    );
  }

  int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class _LinenHilangFormDialog extends StatefulWidget {
  const _LinenHilangFormDialog({
    required this.rooms,
    required this.initialRoomId,
    required this.loadRoomItems,
    required this.roomItems,
    required this.submitting,
    required this.onSubmit,
  });

  final List<LinenHilangRuanganOption> rooms;
  final int? initialRoomId;
  final Future<void> Function(int roomId) loadRoomItems;
  final List<LinenHilangRuanganItem> roomItems;
  final bool submitting;
  final Future<bool> Function({
    required String tanggal,
    required int ruanganId,
    required List<int> linenIds,
    required PlatformFile? file,
  }) onSubmit;

  @override
  State<_LinenHilangFormDialog> createState() => _LinenHilangFormDialogState();
}

class _LinenHilangFormDialogState extends State<_LinenHilangFormDialog> {
  late int? _roomId = widget.initialRoomId;
  DateTime _date = DateTime.now();
  bool _loadingItems = false;
  List<LinenHilangRuanganItem> _items = const [];
  final Set<int> _selected = {};
  PlatformFile? _file;

  @override
  void initState() {
    super.initState();
    if (_roomId != null) _loadItems();
  }

  Future<void> _loadItems() async {
    if (_roomId == null) return;
    setState(() => _loadingItems = true);
    try {
      final response = await ApiService.instance.getLinenHilangRuanganList(
        ruanganId: _roomId!,
        perPage: 100,
        page: 1,
      );
      if (!mounted) return;
      setState(() {
        _items = response.data;
        _selected.clear();
        _loadingItems = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loadingItems = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingItems = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengambil linen aktif di ruangan.')),
      );
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    if (file.size > 10 * 1024 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ukuran berita acara maksimal 10 MB.')),
      );
      return;
    }

    setState(() => _file = file);
  }

  Future<void> _submit() async {
    if (_roomId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih ruangan terlebih dahulu.')),
      );
      return;
    }
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal satu linen.')),
      );
      return;
    }

    final ok = await widget.onSubmit(
      tanggal:
          '${_date.year.toString().padLeft(4, '0')}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
      ruanganId: _roomId!,
      linenIds: _selected.toList(),
      file: _file,
    );
    if (!ok && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah Linen Hilang'),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<int>(
                value: _roomId,
                decoration: const InputDecoration(
                  labelText: 'Ruangan',
                  border: OutlineInputBorder(),
                ),
                items: widget.rooms
                    .map(
                      (room) => DropdownMenuItem<int>(
                        value: room.id,
                        child: Text(
                          '${room.namaRuangan} • ${room.namaKepalaRuangan}',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: widget.submitting
                    ? null
                    : (value) {
                        setState(() {
                          _roomId = value;
                          _items = const [];
                          _selected.clear();
                        });
                        if (value != null) _loadItems();
                      },
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: widget.submitting
                          ? null
                          : () async {
                              final d = await showDatePicker(
                                context: context,
                                initialDate: _date,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );
                              if (d != null) setState(() => _date = d);
                            },
                      icon: const Icon(Icons.event_rounded),
                      label: Text(
                        'Tanggal: ${_date.day.toString().padLeft(2, '0')}/${_date.month.toString().padLeft(2, '0')}/${_date.year}',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'Pilih Linen Aktif di Ruangan',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              if (_loadingItems)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_items.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(14),
                  child: Text('Tidak ada linen aktif di ruangan ini.'),
                )
              else
                Container(
                  constraints: const BoxConstraints(maxHeight: 260),
                  decoration: BoxDecoration(
                    border: Border.all(color: Color(0xffe1e7ed)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _items.length,
                    itemBuilder: (_, index) {
                      final item = _items[index];
                      final selected = _selected.contains(item.linenId);
                      return CheckboxListTile(
                        dense: true,
                        value: selected,
                        onChanged: widget.submitting
                            ? null
                            : (checked) {
                                setState(() {
                                  if (checked == true) {
                                    _selected.add(item.linenId);
                                  } else {
                                    _selected.remove(item.linenId);
                                  }
                                });
                              },
                        title: Text(item.namaLinen),
                        subtitle: Text(
                          '${item.kategoriLinen} • ${item.qrCode} • ${item.tagRfid}',
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: widget.submitting ? null : _pickFile,
                icon: const Icon(Icons.attach_file_rounded),
                label: Text(
                  _file == null
                      ? 'Pilih Berita Acara'
                      : '${_file!.name} (${(_file!.size / 1024 / 1024).toStringAsFixed(2)} MB)',
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'PDF, DOC, DOCX, JPG, JPEG, PNG — maksimal 10 MB.',
                style: TextStyle(fontSize: 9, color: Color(0xff7d8c99)),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: widget.submitting
              ? null
              : () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        ElevatedButton.icon(
          onPressed: widget.submitting ? null : _submit,
          icon: widget.submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_rounded),
          label: const Text('Simpan'),
        ),
      ],
    );
  }
}
