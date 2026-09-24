import 'package:flutter/material.dart';

import '../api/api_service.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/pagination_widget.dart';


class InOutPage extends StatefulWidget {
  const InOutPage({super.key, required this.userName, this.embedded = false});
  final String userName;
  final bool embedded;
  @override
  State<InOutPage> createState() => _InOutPageState();
}

class _InOutPageState extends State<InOutPage> {
  bool _loading = true;
  String? _error;
  InOutResponse? _response;
  final _searchController = TextEditingController();
  DateTime? _selectedDate;
  int _page = 1;

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

  String _dateParam(DateTime d) =>
      '${d.month}/${d.day}/${d.year} - ${d.month}/${d.day}/${d.year}';

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final r = await ApiService.instance.getInOut(
        perPage: 10,
        page: _page,
        search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        daterange: _selectedDate == null ? null : _dateParam(_selectedDate!),
      );
      if (!mounted) return;
      setState(() { _response = r; _loading = false; });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _error = 'Tidak dapat mengambil data Keluar Masuk dari server.'; _loading = false; });
    }
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d != null) {
      setState(() => _selectedDate = d);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = _response?.data ?? const <Map<String,dynamic>>[];
    return AppShell(
      embedded: widget.embedded,
      userName: widget.userName,
      activeIndex: 1,
      body: Column(
        children: [
          // Header is provided by AppShell so it stays fixed while the body pages slide.

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: (_) => _load(),
                    decoration: InputDecoration(
                      hintText: 'Cari ruangan...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _pickDate,
                  tooltip: 'Pilih tanggal',
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xff1261dc),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.calendar_month_rounded, size: 20),
                ),
              ],
            ),
          ),
          if (_selectedDate != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: Row(
                children: [
                  Text(
                    'Tanggal: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                    style: const TextStyle(fontSize: 9, color: Color(0xff6f7f8d)),
                  ),
                  const Spacer(),
                  TextButton(onPressed: () { setState(() => _selectedDate = null); _load(); }, child: const Text('Reset')),
                ],
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: _loading
                    ? const Padding(padding: EdgeInsets.all(50), child: Center(child: CircularProgressIndicator()))
                    : _error != null
                        ? _InOutError(message: _error!, onRetry: _load)
                        : rows.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(40),
                                child: Center(child: Text('Tidak ada data Keluar Masuk Linen & Tirai.')),
                              )
                            : Column(children: [
                                _InOutTable(rows: rows),
                                if (_response != null) AppPagination(meta: _response!.meta, onPage: (page) { setState(() => _page = page); _load(); }),
                              ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InOutTable extends StatelessWidget {
  const _InOutTable({required this.rows});
  final List<Map<String,dynamic>> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      
      
      child: LayoutBuilder(builder: (context, constraints) { return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(width: constraints.maxWidth, child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xff1261dc)),
          headingTextStyle: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
          dataTextStyle: const TextStyle(color: Color(0xff465564), fontSize: 9),
          columnSpacing: 28,
          columns: const [
            DataColumn(label: Text('Ruangan')),
            DataColumn(label: Text('Masuk')),
            DataColumn(label: Text('Keluar')),
            DataColumn(label: Text('Selisih')),
          ],
          rows: rows.map((r) => DataRow(cells: [
            DataCell(Text(r['nama_ruangan']?.toString() ?? '-')),
            DataCell(Text(r['linen_masuk']?.toString() ?? '0')),
            DataCell(Text(r['linen_keluar']?.toString() ?? '0')),
            DataCell(Text(r['selisih']?.toString() ?? '0')),
          ])).toList(),
        )),
      ); }),
    );
  }
}

class _InOutError extends StatelessWidget {
  const _InOutError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      children: [
        const SizedBox(height: 40),
        const Icon(Icons.cloud_off_rounded, size: 36, color: Color(0xffef6c6c)),
        const SizedBox(height: 10),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: onRetry, child: const Text('Coba Lagi')),
      ],
    ),
  );
}
