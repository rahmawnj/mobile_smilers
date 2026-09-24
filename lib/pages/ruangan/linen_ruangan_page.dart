import 'package:flutter/material.dart';

import '../../api/api_service.dart';
import '../../widgets/pagination_widget.dart';
import '../../widgets/shared_widgets.dart';
import 'linen_ruangan_detail_page.dart';

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
  int _perPage = 10;
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
        perPage: _perPage,
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
    return Scaffold(
      backgroundColor: const Color(0xfff5f8fc),
      body: SafeArea(
        bottom: false,
        child: Column(
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
                  borderRadius: BorderRadius.circular(20),
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
                                TableSurface(child: LayoutBuilder(
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
                                if (_meta != null) ...[
                                  const SizedBox(height: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          const Text('Jumlah', style: TextStyle(fontSize: 9)),
                                          const SizedBox(width: 8),
                                          AppPerPageDropdown(
                                            value: _perPage,
                                            onChanged: (v) {
                                              setState(() {
                                                _perPage = v;
                                                _page = 1;
                                              });
                                              _load();
                                            },
                                          ),
                                        ],
                                      ),
                                      AppPagination(
                                        meta: _meta!,
                                        onPage: (page) {
                                          setState(() => _page = page);
                                          _load();
                                        },
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
      ),
    );
  }
}
