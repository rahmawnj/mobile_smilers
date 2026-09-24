import 'package:flutter/material.dart';

import '../../api/api_service.dart';
import '../../widgets/pagination_widget.dart';
import '../../widgets/shared_widgets.dart';

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
  final TextEditingController _itemSearch = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _loadFormData();
  }

  @override
  void dispose() {
    _search.dispose();
    _itemSearch.dispose();
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
      final results = await Future.wait([
        ApiService.instance.getPermintaanLinenRuanganDropdown(),
        ApiService.instance.getPermintaanLinenItemDropdown(),
      ]);

      if (!mounted) return;

      setState(() {
        _formData = {
          'ruangan': results[0],
          'linen': results[1],
        };
      });
    } catch (_) {}
  }

  Future<void> _loadDropdowns() async {
    try {
      final results = await Future.wait([
        ApiService.instance.getPermintaanLinenRuanganDropdown(),
        ApiService.instance.getPermintaanLinenItemDropdown(),
      ]);

      if (!mounted) return;

      setState(() {
        _formData = {
          'ruangan': results[0],
          'linen': results[1],
        };
      });
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
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
                        borderRadius: BorderRadius.circular(20),
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
                  onPressed: () async {
                    final created = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => PermintaanLinenFormPage(
                          userName: widget.userName,
                        ),
                      ),
                    );
                    if (created == true && mounted) {
                      _page = 1;
                      _load();
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Buat Permintaan'),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: LayoutBuilder(builder: (context, constraints) { return SingleChildScrollView(
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
                                    
                                    
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: SizedBox(width: constraints.maxWidth, child: DataTable(
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
                                      )),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  if (meta != null)
                                    AppPagination(
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
              ); }),
            ),
          ),
        ],
      ),
    );
  }
}
