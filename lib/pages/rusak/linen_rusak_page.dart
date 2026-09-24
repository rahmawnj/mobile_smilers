import 'package:flutter/material.dart';

import '../../api/api_service.dart';
import '../../widgets/pagination_widget.dart';
import '../../widgets/shared_widgets.dart';

class LinenRusakPage extends StatefulWidget {
  const LinenRusakPage({super.key, required this.userName});
  final String userName;

  @override
  State<LinenRusakPage> createState() => _LinenRusakPageState();
}

class _LinenRusakPageState extends State<LinenRusakPage> {
  final _searchController = TextEditingController();
  final _scanController = TextEditingController();
  LinenListResponse<LinenRusakItem>? _response;
  bool _loading = true;
  bool _scanning = false;
  String? _error;
  int _page = 1;
  int _perPage = 10;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final response = await ApiService.instance.getLinenRusak(
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        perPage: _perPage,
        page: _page,
      );
      if (!mounted) return;
      setState(() { _response = response; _loading = false; });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Tidak dapat mengambil data Linen & Tirai Rusak.';
        _loading = false;
      });
    }
  }

  Future<void> _scan() async {
    final value = _scanController.text.trim();
    if (value.isEmpty || _scanning) return;
    FocusScope.of(context).unfocus();
    setState(() => _scanning = true);

    try {
      final result = await ApiService.instance.scanLinenRusak(value);
      if (!mounted) return;
      _scanController.clear();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              result['message']?.toString() ??
                  'Linen rusak berhasil ditambahkan',
            ),
          ),
        );
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Gagal memproses scan linen rusak.')),
        );
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  void _search() {
    setState(() => _page = 1);
    _load();
  }

  void _changePage(int page) {
    setState(() => _page = page);
    _load();
  }

  void _changePerPage(int value) {
    setState(() { _perPage = value; _page = 1; });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final rows = _response?.data ?? const <LinenRusakItem>[];
    final meta = _response?.meta;

    return Scaffold(
      backgroundColor: const Color(0xfff5f8fc),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
                  children: [
                    _buildScanCard(),
                    const SizedBox(height: 12),
                    _buildSearchBar(),
                    const SizedBox(height: 14),
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.all(44),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_error != null)
                      _buildError()
                    else if (rows.isEmpty)
                      _buildEmpty()
                    else
                      _buildTable(rows),
                    if (!_loading && _error == null && meta != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'Total ' + meta.total.toString() + ' linen rusak',
                            style: const TextStyle(
                              color: Color(0xff7d8c99),
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 14),
                          DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _perPage,
                              isDense: true,
                              items: const [
                                DropdownMenuItem(value: 10, child: Text('10')),
                                DropdownMenuItem(value: 20, child: Text('20')),
                                DropdownMenuItem(value: 50, child: Text('50')),
                              ],
                              onChanged: (value) {
                                if (value != null) _changePerPage(value);
                              },
                            ),
                          ),
                        ],
                      ),
                      AppPagination(meta: meta, onPage: _changePage),
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

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 12, 18, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff5cc9bd), Color(0xff159cf1)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        children: [
          const AppBackButton(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Linen & Tirai Rusak',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.userName,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .75),
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff1261dc), Color(0xff159cf1)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
              SizedBox(width: 9),
              Text(
                'Scan Linen Rusak',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Masukkan RFID atau QR Code linen yang rusak.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: .78),
              fontSize: 9,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _scanController,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _scan(),
            decoration: InputDecoration(
              hintText: 'RFID / QR Code',
              prefixIcon: const Icon(Icons.nfc_rounded),
              suffixIcon: IconButton(
                onPressed: _scanning ? null : _scan,
                icon: _scanning
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onSubmitted: (_) => _search(),
      decoration: InputDecoration(
        hintText: 'Cari nama linen / RFID / QR Code...',
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        suffixIcon: IconButton(
          onPressed: _search,
          icon: const Icon(Icons.arrow_forward_rounded),
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildTable(List<LinenRusakItem> rows) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xff1261dc)),
            headingTextStyle: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
            dataTextStyle: const TextStyle(
              color: Color(0xff465564),
              fontSize: 9,
            ),
            columnSpacing: 26,
            horizontalMargin: 14,
            columns: const [
              DataColumn(label: Text('ID')),
              DataColumn(label: Text('Nama Linen')),
              DataColumn(label: Text('RFID')),
              DataColumn(label: Text('QR Code')),
              DataColumn(label: Text('Jam')),
              DataColumn(label: Text('Tanggal')),
              DataColumn(label: Text('Tahun Pembuatan')),
            ],
            rows: rows.map((item) {
              return DataRow(
                cells: [
                  DataCell(Text(item.id.toString())),
                  DataCell(Text(item.namaLinen.isEmpty ? '-' : item.namaLinen)),
                  DataCell(Text(item.tagRfid.isEmpty ? '-' : item.tagRfid)),
                  DataCell(Text(item.qrCode.isEmpty ? '-' : item.qrCode)),
                  DataCell(Text(item.jam.isEmpty ? '-' : item.jam)),
                  DataCell(Text(item.tanggal.isEmpty ? '-' : item.tanggal)),
                  DataCell(
                    Text(
                      item.tahunPembuatan.isEmpty
                          ? '-'
                          : item.tahunPembuatan,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, size: 34),
          const SizedBox(height: 10),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _load, child: const Text('Coba Lagi')),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return const Padding(
      padding: EdgeInsets.all(40),
      child: Center(child: Text('Belum ada data Linen & Tirai Rusak.')),
    );
  }
}
