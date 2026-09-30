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
  LinenListResponse<LinenCategory>? _response;
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
      final response = await ApiService.instance.getLinen(
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
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
        _error = 'Tidak dapat mengambil data Linen & Tirai Ready.';
        _loading = false;
      });
    }
  }

  void _search() {
    setState(() => _page = 1);
    _load();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 450), _search);
  }

  void _resetSearch() {
    _searchController.clear();
    _searchDebounce?.cancel();
    setState(() => _page = 1);
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
    final allRows = _response?.data ?? const <LinenCategory>[];
    final rows = allRows.where((category) {
      final categoryMatches =
          _selectedCategoryId == null || category.id == _selectedCategoryId;
      return categoryMatches;
    }).toList();
    final meta = _response?.meta;

    return Scaffold(
      backgroundColor: const Color(0xfff5f8fc),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            DetailHeader(
              title: 'Linen & Tirai Ready',
              userName: widget.userName,
            ),
            Expanded(
              child: AppRefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
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
                    if (!_loading && _error == null && meta != null) ...[
                      const SizedBox(height: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                'Menampilkan ${rows.length} dari ${meta.total} kategori',
                                style: const TextStyle(
                                  color: Color(0xff8b99a5),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 18),
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
                          if (meta.lastPage > 1)
                            AppPagination(
                              meta: meta,
                              onPage: _changePage,
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
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
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
          child: _FilterDropdown<int>(
            label: 'Kategori',
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

  Widget _buildTable(List<LinenCategory> rows) {
    return AppDataTable(
      columns: const [
        DataColumn(label: Text('No')),
        DataColumn(label: Text('Nama Kategori')),
        DataColumn(label: Text('Nama Item')),
        DataColumn(label: Text('Stok Ready')),
        DataColumn(label: Text('Action')),
      ],
      rows: rows.asMap().entries.map((entry) {
        final index = entry.key;
        final category = entry.value;
        final sub = category.subKategoriLinen.trim().isEmpty
            ? '-'
            : category.subKategoriLinen;

        return DataRow(
          cells: [
            DataCell(Text((index + 1).toString())),
            DataCell(Text(category.namaKategoriLinen)),
            DataCell(Text(sub)),
            DataCell(Text(category.jumlahStok.toString())),
            DataCell(
              IconButton(
                tooltip: 'Detail',
                onPressed: () => _openDetail(category),
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

class _FilterDropdown<T> extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.onClear,
  });

  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xffe5ebf1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                isExpanded: true,
                isDense: true,
                hint: Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xff7f8c98),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: Color(0xff7f8c98),
                ),
                items: items,
                onChanged: onChanged,
              ),
            ),
          ),
          if (onClear != null)
            IconButton(
              tooltip: 'Reset $label',
              onPressed: onClear,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 24,
                minHeight: 24,
              ),
              icon: const Icon(
                Icons.close_rounded,
                size: 15,
                color: Color(0xff9aa8b5),
              ),
            ),
        ],
      ),
    );
  }
}
