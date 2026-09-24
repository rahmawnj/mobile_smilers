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
      final response = await ApiService.instance.getLinenLaundry(
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
        _error = 'Tidak dapat mengambil data Linen & Tirai di Laundry.';
        _loading = false;
      });
    }
  }

  void _search() {
    setState(() => _page = 1);
    _load();
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
                onSubmitted: (_) => _search(),
                decoration: InputDecoration(
                  hintText: 'Cari linen / kategori...',
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
                                              label: Text('Nama Linen'),
                                            ),
                                            DataColumn(
                                              label: Text('Kategori'),
                                            ),
                                            DataColumn(
                                              label: Text('Ready'),
                                            ),
                                            DataColumn(
                                              label: Text('Detail'),
                                            ),
                                          ],
                                          rows: rows.map((item) {
                                            return DataRow(
                                              cells: [
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
                                                DataCell(
                                                  Text(item.ready.toString()),
                                                ),
                                                DataCell(
                                                  IconButton(
                                                    tooltip: 'Detail',
                                                    onPressed: () =>
                                                        _openDetail(item),
                                                    icon: const Icon(
                                                      Icons
                                                          .visibility_outlined,
                                                      size: 18,
                                                      color: Color(0xff1261dc),
                                                    ),
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
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        const Text(
                                          'Jumlah',
                                          style: TextStyle(fontSize: 9),
                                        ),
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
                                      meta: _response!.meta,
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

