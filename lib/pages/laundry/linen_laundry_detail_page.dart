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
    final categoryName = widget.categoryName.trim().isEmpty
        ? (rows.isNotEmpty && rows.first.namaKategoriLinen.trim().isNotEmpty
            ? rows.first.namaKategoriLinen
            : '-')
        : widget.categoryName;
    final totalLinen = _response?.meta.total ?? 0;

    return AppShell(
      userName: widget.userName,
      activeIndex: -1,
      body: Column(
        children: [
          DetailHeader(
            title: 'Linen & Tirai di Laundry',
            userName: widget.userName,
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
                            14,
                            16,
                            90,
                          ),
                          children: [
                            _buildSummaryCard(
                              categoryName: categoryName,
                              totalLinen: totalLinen,
                            ),
                            const SizedBox(height: 18),
                            SectionTitle(title: 'Detail Linen'),
                            const SizedBox(height: 10),
                            if (rows.isEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'Belum ada detail linen di laundry.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xff6f7f8d),
                                    fontSize: 10,
                                  ),
                                ),
                              )
                            else
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
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          dataTextStyle: const TextStyle(
                                            color: Color(0xff465564),
                                            fontSize: 10,
                                          ),
                                          columnSpacing: 18,
                                          horizontalMargin: 16,
                                          columns: const [
                                            DataColumn(label: Text('No')),
                                            DataColumn(
                                              label: Text('Kode Linen'),
                                            ),
                                            DataColumn(
                                              label: Text('Nama Linen'),
                                            ),
                                            DataColumn(
                                              label: Text('Nama Kategori Linen'),
                                            ),
                                            DataColumn(
                                              label: Text('Jumlah Pencucian'),
                                            ),
                                          ],
                                          rows: rows.asMap().entries.map(
                                            (entry) {
                                              final index = entry.key;
                                              final item = entry.value;

                                              return DataRow(
                                                cells: [
                                                  DataCell(
                                                    Text(
                                                      ((_page - 1) * 10 +
                                                              index +
                                                              1)
                                                          .toString(),
                                                    ),
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
                                            },
                                          ).toList(),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            if (_response != null) ...[
                              const SizedBox(height: 8),
                              AppPagination(
                                meta: _response!.meta,
                                onPage: (page) {
                                  setState(() => _page = page);
                                  _load();
                                },
                              ),
                            ],
                          ],
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String categoryName,
    required int totalLinen,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff183b56).withValues(alpha: .07),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xffeaf2ff),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.local_laundry_service_rounded,
              color: Color(0xff1261dc),
              size: 23,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Linen & Tirai di Laundry',
                  style: TextStyle(
                    color: Color(0xff8b99a5),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  categoryName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xff263746),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'JUMLAH LINEN',
                style: TextStyle(
                  color: Color(0xff8b99a5),
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                totalLinen.toString(),
                style: const TextStyle(
                  color: Color(0xff1261dc),
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
