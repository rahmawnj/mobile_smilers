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
