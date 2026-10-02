import 'package:flutter/material.dart';

import '../../api/api_service.dart';
import '../../widgets/shared_widgets.dart';

class PermintaanLinenFormPage extends StatefulWidget {
  const PermintaanLinenFormPage({super.key, required this.userName});

  final String userName;

  @override
  State<PermintaanLinenFormPage> createState() => _PermintaanLinenFormPageState();
}

class _PermintaanLinenFormPageState extends State<PermintaanLinenFormPage> {
  bool _loading = true;
  bool _saving = false;
  List<Map<String, dynamic>> _rooms = [];
  List<Map<String, dynamic>> _linens = [];
  int? _selectedRoom;
  DateTime _selectedDate = DateTime.now();
  final _reasonController = TextEditingController();
  final _itemSearchController = TextEditingController();
  final List<_RequestItemRow> _rows = [_RequestItemRow()];

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _itemSearchController.dispose();
    super.dispose();
  }

  int _toInt(dynamic value) => int.tryParse(value?.toString() ?? '') ?? 0;

  Future<void> _loadOptions({String? search}) async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _rooms.isEmpty
            ? ApiService.instance.getPermintaanLinenRuanganDropdown()
            : Future.value(_rooms),
        ApiService.instance.getPermintaanLinenItemDropdown(search: search),
      ]);
      if (!mounted) return;
      setState(() {
        _rooms = results[0];
        _linens = results[1];
        _selectedRoom ??= _rooms.isNotEmpty ? _toInt(_rooms.first['id']) : null;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengambil data form.')),
      );
    }
  }

  void _addRow() => setState(() => _rows.add(_RequestItemRow()));

  void _removeRow(int index) {
    if (_rows.length == 1) {
      setState(() => _rows[0] = _RequestItemRow());
      return;
    }
    setState(() => _rows.removeAt(index));
  }

  String _itemLabel(Map<String, dynamic> item) {
    final category = item['nama_kategori_linen']?.toString() ?? '-';
    final sub = item['sub_kategori_linen']?.toString().trim() ?? '';
    return sub.isEmpty ? category : '$category • $sub';
  }

  Future<void> _save() async {
    if (_selectedRoom == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih ruangan terlebih dahulu.')));
      return;
    }
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alasan permintaan wajib diisi.')));
      return;
    }

    final items = <Map<String, dynamic>>[];
    for (var i = 0; i < _rows.length; i++) {
      final row = _rows[i];
      if (row.linenId == null) continue;
      if (row.quantity <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Jumlah item pada baris ${i + 1} harus lebih dari 0.')));
        return;
      }
      items.add({'linen_id': row.linenId, 'jumlah': row.quantity});
    }
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tambahkan minimal satu item linen.')));
      return;
    }
    if (items.map((e) => e['linen_id']).toSet().length != items.length) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item linen yang sama tidak boleh dipilih dua kali.')));
      return;
    }

    setState(() => _saving = true);
    try {
      final date = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
      final result = await ApiService.instance.createPermintaanLinen(
        tanggalPermintaan: date,
        ruanganId: _selectedRoom!,
        alasanPermintaan: _reasonController.text.trim(),
        items: items,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message']?.toString() ?? 'Permintaan berhasil dibuat')));
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildItemTable() {
    final rows = List.generate(_rows.length, (index) {
      final row = _rows[index];
      return DataRow(
        color: WidgetStateProperty.resolveWith<Color?>(
          (states) => index.isEven ? const Color(0xfff5f6f8) : Colors.white,
        ),
        cells: [
          DataCell(Text('${index + 1}')),
          DataCell(SizedBox(
            width: 180,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: row.linenId,
                isExpanded: true,
                hint: const Text('Pilih item'),
                items: _linens.map((item) {
                  final id = _toInt(item['id'] ?? item['linen_id']);
                  return DropdownMenuItem<int>(
                    value: id,
                    child: Text(
                      _itemLabel(item),
                      style: const TextStyle(fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: _saving
                    ? null
                    : (value) {
                        setState(() {
                          row.linenId = value;
                          final item = _linens.firstWhere(
                            (item) =>
                                _toInt(item['id'] ?? item['linen_id']) == value,
                            orElse: () => <String, dynamic>{},
                          );
                          row.category =
                              value == null ? '' : _itemLabel(item);
                        });
                      },
              ),
            ),
          )),
          DataCell(
            SizedBox(
              width: 140,
              child: Text(
                row.category.isEmpty ? '-' : row.category,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          DataCell(
            SizedBox(
              width: 65,
              child: TextFormField(
                key: ValueKey('qty-$index-${row.linenId}'),
                initialValue:
                    row.quantity > 0 ? row.quantity.toString() : '',
                enabled: !_saving,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: '0',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(7),
            borderSide: const BorderSide(color: Color(0xffd9e0e7)),
          ),
                ),
                onChanged: (value) => row.quantity = _toInt(value),
              ),
            ),
          ),
          DataCell(
            IconButton(
              tooltip: 'Hapus baris',
              icon: const Icon(Icons.delete_outline),
              onPressed: _saving ? null : () => _removeRow(index),
            ),
          ),
        ],
      );
    });

    return TableSurface(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                headingRowColor:
                    WidgetStateProperty.all(Colors.black),
                headingTextStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
                dataTextStyle: const TextStyle(
                  color: Color(0xff465564),
                  fontSize: 10,
                ),
                headingRowHeight: 36,
                dataRowMinHeight: 40,
                dataRowMaxHeight: 44,
                columnSpacing: 6,
                horizontalMargin: 6,
                dividerThickness: .4,
                columns: const [
                  DataColumn(label: Text('No')),
                  DataColumn(label: Text('Pilih Item')),
                  DataColumn(label: Text('Kategori Linen')),
                  DataColumn(label: Text('Jumlah')),
                  DataColumn(label: Text('Aksi')),
                ],
                rows: rows,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      userName: widget.userName,
      activeIndex: -1,
      showBottomNavigation: false,
      body: Column(
        children: [
          DetailHeader(title: 'Form Permintaan Linen & Tirai', userName: widget.userName),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: _loading
                          ? const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text('Tanggal: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.calendar_month),
                                    onPressed: _saving ? null : () async {
                                      final picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2020), lastDate: DateTime(2100));
                                      if (picked != null) setState(() => _selectedDate = picked);
                                    },
                                  ),
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<int>(
                                  value: _selectedRoom,
                                  isExpanded: true,
                                  decoration: InputDecoration(
            labelText: 'Ruangan',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
                                  items: _rooms.map((room) {
                                    final id = _toInt(room['id']);
                                    return DropdownMenuItem<int>(
                                      value: id,
                                      child: Text([
                                        room['nama_ruangan']?.toString() ?? '-',
                                        if ((room['nama_kepala_ruangan']?.toString() ?? '').trim().isNotEmpty && room['nama_kepala_ruangan']?.toString() != '-') 'Kepala: ${room['nama_kepala_ruangan']}',
                                      ].join(' • '), overflow: TextOverflow.ellipsis),
                                    );
                                  }).toList(),
                                  onChanged: _saving ? null : (value) => setState(() => _selectedRoom = value),
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _reasonController,
                                  maxLines: 3,
                                  enabled: !_saving,
                                  decoration: const InputDecoration(labelText: 'Alasan Permintaan *', border: OutlineInputBorder()),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Data Item Linen', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                                    ElevatedButton.icon(onPressed: _saving ? null : _addRow, icon: const Icon(Icons.add), label: const Text('Tambah Baris')),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                _buildItemTable(),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    ElevatedButton.icon(onPressed: _saving ? null : _save, icon: const Icon(Icons.save), label: const Text('Simpan Permintaan')),
                                  ],
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestItemRow {
  int? linenId;
  String category = '';
  int quantity = 0;
}
