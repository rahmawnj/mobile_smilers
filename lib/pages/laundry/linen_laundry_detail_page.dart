import 'package:flutter/material.dart';

import '../../api/api_service.dart';
import '../../widgets/pagination_widget.dart';
import '../../widgets/shared_widgets.dart';

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

    return Scaffold(
      backgroundColor: const Color(0xfff5f8fc),
      body: SafeArea(
        child: Column(
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
                                    child: Center(
                                      child: Text(
                                        'Belum ada detail linen di laundry.',
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : ListView(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  14,
                                  16,
                                  24,
                                ),
                                children: [
                                  TableSurface(
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        return SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: SizedBox(
                                            width: constraints.maxWidth,
                                            child: DataTable(
                                              headingRowColor:
                                                  WidgetStateProperty.all(
                                                const Color(0xff1261dc),
                                              ),
                                              headingTextStyle:
                                                  const TextStyle(
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
                                                  label: Text('Kategori'),
                                                ),
                                                DataColumn(
                                                  label: Text('Jumlah Pencucian'),
                                                ),
                                              ],
                                              rows: rows.map((item) {
                                                return DataRow(
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
                                                            : item
                                                                .namaKategoriLinen,
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Text(
                                                        item.jumlahPencucian
                                                            .toString(),
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
                                  AppPagination(
                                    meta: _response!.meta,
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
      ),
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
                                        borderRadius: BorderRadius.circular(20),
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
                            TableSurface(child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final tableWidth = constraints.maxWidth;
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
                              AppPagination(
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

