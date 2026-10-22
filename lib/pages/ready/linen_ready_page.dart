import 'dart:async';

import 'package:flutter/material.dart';

import '../../api/api_service.dart';
import '../../widgets/pagination_widget.dart';
import '../../widgets/shared_widgets.dart';
import 'linen_ready_detail_page.dart';

class LinenReadyPage extends StatefulWidget {
  const LinenReadyPage({super.key, required this.userName});

  final String userName;

  @override
  State<LinenReadyPage> createState() => _LinenReadyPageState();
}

class _LinenReadyPageState extends State<LinenReadyPage> {
  bool _loading = true;
  String? _error;
  List<_ReadyLinenRow> _allItems = [];
  List<Map<String, dynamic>> _categoryOptions = [];
  int? _selectedCategoryId;
  int _page = 1;
  int _perPage = 10;

  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _loadFilterOptions();
    _load();
  }

  Future<void> _loadFilterOptions() async {
    try {
      final results = await Future.wait([
        ApiService.instance.getLinenCategoryDropdown(),
      ]);

      if (!mounted) return;

      setState(() {
        _categoryOptions =
            (results[0] as List<Map<String, dynamic>>).where((item) {
          final id = _toOptionId(item);
          final name = _toOptionName(item);
          return id != null && name.isNotEmpty;
        }).toList();
      });
    } catch (_) {
      // Filter options are auxiliary; the main /linen list can still load.
    }
  }

  int? _toOptionId(Map<String, dynamic> item) {
    final value =
        item['id'] ?? item['kategori_linen'] ?? item['kategori_linen_id'];
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  String _toOptionName(Map<String, dynamic> item) {
    return (item['nama_kategori_linen'] ??
            item['nama_kategori'] ??
            item['name'] ??
            item['label'] ??
            '')
        .toString()
        .trim();
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
      final categoriesResponse = await ApiService.instance.getLinen(
        search: null,
        perPage: 100,
        page: 1,
      );
      final categories = <LinenCategory>[...categoriesResponse.data];
      for (var page = 2; page <= categoriesResponse.meta.lastPage; page++) {
        final response = await ApiService.instance.getLinen(
          perPage: 100,
          page: page,
        );
        categories.addAll(response.data);
      }

      final readyRows = <_ReadyLinenRow>[];
      // /linen returns category summaries (about 61 rows), not the individual
      // linen records. Fetch each category's actual item rows before paginating.
      for (final category in categories) {
        final first = await ApiService.instance.getLinenItems(
          category.id,
          perPage: 100,
          page: 1,
        );
        readyRows.addAll(
          first.data.map((item) => _ReadyLinenRow(category: category, item: item)),
        );
        for (var page = 2; page <= first.meta.lastPage; page++) {
          final response = await ApiService.instance.getLinenItems(
            category.id,
            perPage: 100,
            page: page,
          );
          readyRows.addAll(
            response.data.map((item) => _ReadyLinenRow(category: category, item: item)),
          );
        }
      }

      if (!mounted) return;
      setState(() {
        _allItems = readyRows;
        _loading = false;
        final lastPage = (_filteredRows.length / _perPage).ceil();
        if (lastPage > 0 && _page > lastPage) _page = lastPage;
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

  List<_ReadyLinenRow> get _filteredRows {
    final search = _searchController.text.trim().toLowerCase();
    return _allItems.where((row) {
      final categoryMatches =
          _selectedCategoryId == null || row.category.id == _selectedCategoryId;
      final searchMatches = search.isEmpty ||
          row.category.namaKategoriLinen.toLowerCase().contains(search) ||
          row.item.namaLinen.toLowerCase().contains(search) ||
          row.item.kodeLinen.toLowerCase().contains(search) ||
          row.item.subKategoriLinen.toLowerCase().contains(search) ||
          row.item.qrCode.toLowerCase().contains(search) ||
          row.item.tagRfid.toLowerCase().contains(search);
      return categoryMatches && searchMatches;
    }).toList();
  }

  void _search() {
    setState(() => _page = 1);
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 450), _search);
  }

  void _resetSearch() {
    _searchController.clear();
    _searchDebounce?.cancel();
    setState(() => _page = 1);
  }

  void _changePage(int page) {
    setState(() => _page = page);
  }

  void _changePerPage(int value) {
    setState(() {
      _perPage = value;
      _page = 1;
    });
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
    final allRows = _filteredRows;
    final startIndex = (_page - 1) * _perPage;
    final rows = allRows.skip(startIndex).take(_perPage).toList();
    final totalPages = (allRows.length / _perPage).ceil();

    return Scaffold(
      backgroundColor: const Color(0xfff5f8fc),
      body: SafeArea(
        bottom: false,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: 60,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(22),
                  ),
                ),
              ),
            ),
            Column(
          children: [
            DetailHeader(
              title: 'Linen & Tirai Ready',
              userName: widget.userName,
              transparentBottom: true,
            ),
            Expanded(
              child: AppRefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: [
                    _buildSearchBar(),
                    const SizedBox(height: 10),
                    _buildFilters(),
                    const SizedBox(height: 14),
                    if (_loading)
                      const AppPageLoading()
                    else if (_error != null)
                      _buildError()
                    else if (rows.isEmpty)
                      _buildEmpty()
                    else
                      _buildTable(rows),
                    if (!_loading && _error == null) ...[
                      const SizedBox(height: 10),
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Total Linen: ${allRows.length}',
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
                          if (totalPages > 1)
                            AppPagination(
                              meta: LinenMeta(
                                currentPage: _page,
                                perPage: _perPage,
                                total: allRows.length,
                                lastPage: totalPages,
                              ),
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
            // Keep the rounded white card visibly overlapping the blue header.
            Positioned(
              top: 60,
              left: 0,
              right: 0,
              height: 60,
              child: IgnorePointer(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(22),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: _onSearchChanged,
      onSubmitted: (_) => _search(),
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Cari kategori...',
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Bersihkan',
                onPressed: _resetSearch,
                icon: const Icon(Icons.close_rounded, size: 18),
              ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xffd8e1eb),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xffd8e1eb),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xff159cf1),
            width: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Row(
      children: [
        Expanded(
          child: AppCategoryFilterDropdown<int>(
            value: _selectedCategoryId,
            items: _categoryOptions.map((item) {
              return DropdownMenuItem<int>(
                value: _toOptionId(item),
                child: Text(
                  _toOptionName(item),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCategoryId = value;
                _page = 1;
              });
            },
            onClear: _selectedCategoryId == null
                ? null
                : () => setState(() {
                      _selectedCategoryId = null;
                      _page = 1;
                    }),
          ),
        ),
      ],
    );
  }

  Widget _buildTable(List<_ReadyLinenRow> rows) {
    return AppDataTable(
      columns: const [
        DataColumn(label: Text('No')),
        DataColumn(label: Text('Nama Kategori')),
        DataColumn(label: Text('Nama Linen')),
        DataColumn(label: Text('Kode Linen')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Action')),
      ],
      rows: rows.asMap().entries.map((entry) {
        final index = entry.key;
        final row = entry.value;
        final rowNumber = ((_page - 1) * _perPage) + index + 1;
        return DataRow(
          cells: [
            DataCell(Text(rowNumber.toString())),
            DataCell(Text(row.category.namaKategoriLinen)),
            DataCell(Text(row.item.namaLinen)),
            DataCell(Text(row.item.kodeLinen)),
            DataCell(Text(row.item.status)),
            DataCell(
              IconButton(
                tooltip: 'Detail kategori',
                onPressed: () => _openDetail(row.category),
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
    );
  }

  Widget _buildEmpty() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            color: Color(0xff9aa8b5),
            size: 34,
          ),
          SizedBox(height: 10),
          Text(
            'Tidak ada data Linen & Tirai Ready.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xff6f7f8d),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: Color(0xff9aa8b5),
            size: 34,
          ),
          const SizedBox(height: 10),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xff6f7f8d),
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _load,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}


class _ReadyLinenRow {
  const _ReadyLinenRow({required this.category, required this.item});
  final LinenCategory category;
  final LinenItem item;
}
