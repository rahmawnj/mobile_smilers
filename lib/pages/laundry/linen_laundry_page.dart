import 'dart:async';

import 'package:flutter/material.dart';

import '../../api/api_service.dart';
import '../../widgets/pagination_widget.dart';
import '../../widgets/shared_widgets.dart';
import 'linen_laundry_detail_page.dart';

class LinenLaundryPage extends StatefulWidget {
  const LinenLaundryPage({super.key, required this.userName});

  final String userName;

  @override
  State<LinenLaundryPage> createState() => _LinenLaundryPageState();
}

class _LinenLaundryPageState extends State<LinenLaundryPage> {
  bool _loading = true;
  String? _error;
  LinenListResponse<LinenLaundryItem>? _response;
  int _page = 1;
  int _perPage = 10;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  List<Map<String, dynamic>> _categories = const [];
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _load();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await ApiService.instance.getLinenCategoryDropdown();
      if (!mounted) return;
      setState(() => _categories = categories);
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await ApiService.instance.getLinenLaundry(
        search: _selectedCategoryId == null
            ? (_searchController.text.trim().isEmpty ? null : _searchController.text.trim())
            : _categoryName(_selectedCategoryId!),
        perPage: _perPage,
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
        _error = 'Tidak dapat mengambil data Linen & Tirai di Laundry.';
        _loading = false;
      });
    }
  }

  String _categoryName(int id) {
    final item = _categories.firstWhere((e) => _toInt(e['id'] ?? e['kategori_linen']) == id, orElse: () => {});
    return item['nama_kategori_linen']?.toString() ?? item['nama']?.toString() ?? '';
  }

  int _toInt(dynamic value) => int.tryParse(value?.toString() ?? '') ?? 0;

  void _search() {
    setState(() => _page = 1);
    _load();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 450), _search);
  }

  void _openDetail(LinenLaundryItem item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LinenLaundryDetailPage(
          categoryId: item.id,
          categoryName: item.namaKategoriLinen,
          userName: widget.userName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rows = _response?.data ?? const <LinenLaundryItem>[];

    return Scaffold(
      backgroundColor: const Color(0xfff5f8fc),
      body: SafeArea(
        child: Column(
          children: [
            DetailHeader(
              title: 'Linen & Tirai di Laundry',
              userName: widget.userName,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                onSubmitted: (_) => _search(),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Cari linen / kategori...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Bersihkan',
                          onPressed: () {
                            _searchController.clear();
                            _searchDebounce?.cancel();
                            setState(() => _page = 1);
                            _load();
                          },
                          icon: const Icon(Icons.close_rounded, size: 18),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: AppCategoryFilterDropdown<int>(
                value: _selectedCategoryId,
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Semua kategori'),
                  ),
                  ..._categories.map((item) {
                    final id = _toInt(item['id'] ?? item['kategori_linen']);
                    final name = item['nama_kategori_linen']?.toString() ??
                        item['nama']?.toString() ??
                        '-';
                    return DropdownMenuItem<int?>(
                      value: id,
                      child: Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCategoryId = value;
                    _page = 1;
                  });
                  _load();
                },
              ),
            ),
            Expanded(
              child: AppRefreshIndicator(
                onRefresh: _load,
                child: _loading
                    ? const AppPageLoading()
                    : _error != null
                        ? ListView(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  children: [
                                    const Icon(Icons.cloud_off_rounded),
                                    const SizedBox(height: 10),
                                    Text(
                                      _error!,
                                      textAlign: TextAlign.center,
                                    ),
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
                            padding: const EdgeInsets.fromLTRB(
                              16,
                              8,
                              16,
                              24,
                            ),
                            children: [
                              AppDataTable(
                                columns: const [
                                  DataColumn(label: Text('No')),
                                  DataColumn(label: Text('Nama Linen')),
                                  DataColumn(label: Text('Nama Kategori Linen')),
                                  DataColumn(label: Text('Ready')),
                                  DataColumn(label: Text('Action')),
                                ],
                                rows: rows.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final item = entry.value;

                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        Text(
                                          ((_page - 1) * _perPage + index + 1)
                                              .toString(),
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
                                          item.namaKategoriLinen.isEmpty
                                              ? '-'
                                              : item.namaKategoriLinen,
                                        ),
                                      ),
                                      DataCell(Text(item.ready.toString())),
                                      DataCell(
                                        IconButton(
                                          tooltip: 'Detail',
                                          onPressed: () => _openDetail(item),
                                          icon: const Icon(
                                            Icons.visibility_outlined,
                                            size: 18,
                                            color: Color(0xff1261dc),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                              if (rows.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Center(
                                    child: Text(
                                      'Tidak ada data Linen & Tirai di Laundry.',
                                    ),
                                  ),
                                ),
                              if (_response != null) ...[
                                const SizedBox(height: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Total ${_response!.meta.total} linen',
                                          style: const TextStyle(
                                            color: Color(0xff7d8c99),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text('Jumlah', style: TextStyle(fontSize: 10)),
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
                                      ],
                                    ),
                                    AppPagination(
                                      meta: _response!.meta,
                                      onPage: (page) {
                                        setState(() => _page = page);
                                        _load();
                                      },
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
      ),
    );
  }
}
