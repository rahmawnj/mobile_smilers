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
      final results = await Future.wait([
        ApiService.instance.getLinenCategory(widget.category.id),
        ApiService.instance.getLinenItems(widget.category.id, perPage: 10, page: _page),
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

    return AppShell(
      userName: widget.userName,
      activeIndex: 0,
      body: Column(
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
                              if (_items!.data.isEmpty)
                                const _EmptyDetail(message: 'Tidak ada item linen ready.')
                              else
                                DetailTable(
                                  columns: const [
                                    'ID',
                                    'Kode Linen',
                                    'Tag RFID',
                                    'QR Code',
                                    'Status',
                                  ],
                                  rows: _items!.data
                                      .map(
                                        (item) => [
                                          item.id,
                                          item.kodeLinen,
                                          item.tagRfid,
                                          item.qrCode,
                                          item.status,
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
