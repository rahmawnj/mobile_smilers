import 'package:flutter/material.dart';

import '../../api/api_service.dart';
import '../../widgets/pagination_widget.dart';
import '../../widgets/shared_widgets.dart';

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
  List<LinenDropdownSubCategory> _subCategoryOptions = [];
  String? _selectedSubCategory;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _loadFilterOptions();
    _load();
  }

  Future<void> _loadFilterOptions() async {
    try {
      final options = await ApiService.instance.getLinenSubCategoryDropdown();
      if (!mounted) return;
      setState(() {
        _subCategoryOptions = options
            .where((item) => item.subKategoriLinen.trim().isNotEmpty)
            .toList();
      });
    } catch (_) {}
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        ApiService.instance.getLinenCategory(widget.category.id),
        ApiService.instance.getLinenItems(
          widget.category.id,
          perPage: 10,
          page: _page,
          subKategori: _selectedSubCategory,
        ),
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

    return Scaffold(
      backgroundColor: const Color(0xfff5f8fc),
      body: SafeArea(
        bottom: false,
        child: Column(
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
                              _buildSubCategoryFilter(),
                              const SizedBox(height: 12),
                              if (_items!.data.isEmpty)
                                const _EmptyDetail(message: 'Tidak ada item linen ready.')
                              else
                                DetailTable(
                                  columns: const [
                                    'No.',
                                    'QR Code',
                                    'Tag RFID',
                                    'Nama Linen',
                                  ],
                                  rows: _items!.data.asMap().entries
                                      .map(
                                        (entry) => [
                                          entry.key + 1,
                                          entry.value.qrCode,
                                          entry.value.tagRfid,
                                          entry.value.namaLinen,
                                        ],
                                      )
                                      .toList(),
                                ),
                              const SizedBox(height: 12),
                              Text(
                                'Total ' + _items!.meta.total.toString() + ' item',
                                style: const TextStyle(color: Color(0xff8b99a5), fontSize: 9),
                              ),
                              AppPagination(meta: _items!.meta, onPage: (page) { setState(() => _page = page); _load(); }),
                            ],
                          ),
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildSubCategoryFilter() {
    return _FilterDropdown<String>(
      label: 'Sub Kategori',
      value: _selectedSubCategory,
      items: _subCategoryOptions.map((item) {
        return DropdownMenuItem<String>(
          value: item.subKategoriLinen,
          child: Text(
            item.subKategoriLinen,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedSubCategory = value;
          _page = 1;
        });
        _load();
      },
      onClear: _selectedSubCategory == null
          ? null
          : () {
              setState(() {
                _selectedSubCategory = null;
                _page = 1;
              });
              _load();
            },
    );
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
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
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
        borderRadius: BorderRadius.circular(20),
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
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(message, textAlign: TextAlign.center),
    );
  }
}
