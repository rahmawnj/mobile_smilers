import 'package:flutter/material.dart';

import '../../api/api_service.dart';
import '../../widgets/pagination_widget.dart';
import '../../widgets/shared_widgets.dart';
import 'permintaan_linen_form_page.dart';

class PermintaanLinenPage extends StatefulWidget {
  const PermintaanLinenPage({super.key, required this.userName});
  final String userName;

  @override
  State<PermintaanLinenPage> createState() => _PermintaanLinenPageState();
}

class _PermintaanLinenPageState extends State<PermintaanLinenPage> {
  bool _loading = true;
  String? _error;
  LinenListResponse<PermintaanLinenItem>? _response;
  int? _roomId;
  List<Map<String, dynamic>> _rooms = [];
  String? _status;
  int _page = 1;
  int _perPage = 5;
  final TextEditingController _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _loadRooms();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Future<void> _loadRooms() async {
    try {
      final rooms =
          await ApiService.instance.getPermintaanLinenRuanganDropdown();
      if (!mounted) return;
      setState(() {
        _rooms = rooms;
      });
    } on ApiException catch (_) {
      // Room filter is optional; keep the list usable if the dropdown fails.
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
              width: 760,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tanggal: ${data['tanggal_permintaan'] ?? '-'}'),
                    Text('Ruangan: ${data['nama_ruangan'] ?? '-'}'),
                    Text('Kepala Ruangan: ${data['nama_kepala_ruangan'] ?? '-'}'),
                    Text('Alasan: ${data['alasan_permintaan'] ?? '-'}'),
                    Text('Status: ${data['status'] ?? '-'}'),
                    const SizedBox(height: 16),
                    const Text(
                      'Data Barang',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    if (items.isEmpty)
                      const Text('Tidak ada data barang.')
                    else
                      AppDataTable(
      headingColor: const Color(0xff6e139a),
                        columns: const [
                          DataColumn(label: Text('No')),
                          DataColumn(label: Text('Nama Linen')),
                          DataColumn(label: Text('Kategori Linen')),
                          DataColumn(label: Text('Jumlah')),
                        ],
                        rows: items.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          return DataRow(
                            cells: [
                              DataCell(Text('${index + 1}')),
                              DataCell(
                                Text(item['nama_linen']?.toString() ?? '-'),
                              ),
                              DataCell(
                                Text(
                                  item['kategori_linen']?.toString() ?? '-',
                                ),
                              ),
                              DataCell(
                                Text(item['jumlah']?.toString() ?? '0'),
                              ),
                            ],
                          );
                        }).toList(),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Konfirmasi Pengiriman'),
          content: const Text(
            'Apakah permintaan linen ini sudah siap dikirim? '
            'Setelah dikirim, status akan berubah menjadi Terkirim dan '
            'tombol kirim tidak dapat digunakan lagi.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(dialogContext, true),
              icon: const Icon(Icons.send_rounded),
              label: const Text('Ya, Kirim'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

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
      showBottomNavigation: false,
      body: Column(
        children: [
          DetailHeader(
            title: 'Permintaan Linen & Tirai',
            userName: widget.userName,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 850;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: compact ? constraints.maxWidth : 320,
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
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
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
                            child: Text(
                              room['nama_ruangan']?.toString() ?? '-',
                            ),
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
                    ElevatedButton.icon(
                      onPressed: () async {
                        final created =
                            await Navigator.of(context).push<bool>(
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
                );
              },
            ),
          ),
          Expanded(
            child: AppRefreshIndicator(
              onRefresh: _load,
              child: LayoutBuilder(builder: (context, constraints) { return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: _loading
                    ? const AppPageLoading()
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
                                  AppDataTable(
                                    columns: const [
                                      DataColumn(label: Text('No')),
                                      DataColumn(label: Text('Tanggal Permintaan')),
                                      DataColumn(label: Text('Nama Ruangan')),
                                      DataColumn(label: Text('Nama Kepala Ruangan')),
                                      DataColumn(label: Text('Status')),
                                      DataColumn(label: Text('Action')),
                                    ],
                                    rows: rows.asMap().entries.map((entry) {
                                      final item = entry.value;
                                      final isSent = item.status.trim().toLowerCase() == 'terkirim';
                                      final number = meta == null
                                          ? entry.key + 1
                                          : (meta.currentPage - 1) * meta.perPage +
                                              entry.key +
                                              1;
                                      return DataRow(cells: [
                                        DataCell(Text('$number')),
                                        DataCell(Text(item.tanggalPermintaan)),
                                        DataCell(Text(item.namaRuangan)),
                                        DataCell(Text(item.namaKepalaRuangan)),
                                        DataCell(Text(item.status)),
                                        DataCell(
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                tooltip: 'Detail',
                                                onPressed: () => _showDetail(item.id),
                                                icon: const Icon(
                                                  Icons.visibility_outlined,
                                                  size: 18,
                                                  color: Color(0xff1261dc),
                                                ),
                                              ),
                                              IconButton(
                                                tooltip: isSent ? 'Sudah terkirim' : 'Kirim permintaan',
                                                onPressed: isSent ? null : () => _updateStatus(item.id),
                                                icon: const Icon(Icons.send_rounded),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ]);
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 10),
                                  if (meta != null)
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text('Total ${meta.total} permintaan', style: const TextStyle(color: Color(0xff7d8c99), fontSize: 10, fontWeight: FontWeight.w600)),
                                        const SizedBox(width: 14),
                                        AppPerPageDropdown(
                                          value: _perPage,
                                          onChanged: (value) {
                                            setState(() { _perPage = value; _page = 1; });
                                            _load();
                                          },
                                        ),
                                      ],
                                    ),
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
