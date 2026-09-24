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
  final Map<int, int> _quantities = {};

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
        ApiService.instance.getPermintaanLinenRuanganDropdown(),
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

  Future<void> _save() async {
    if (_selectedRoom == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih ruangan terlebih dahulu.')),
      );
      return;
    }

    final items = _quantities.entries
        .where((entry) => entry.value > 0)
        .map((entry) => {
              'linen_id': entry.key,
              'jumlah': entry.value,
            })
        .toList();

    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi jumlah minimal satu item linen.')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final date =
          '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

      final result = await ApiService.instance.createPermintaanLinen(
        tanggalPermintaan: date,
        ruanganId: _selectedRoom!,
        alasanPermintaan: _reasonController.text.trim(),
        items: items,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message']?.toString() ?? 'Permintaan berhasil dibuat',
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      userName: widget.userName,
      activeIndex: -1,
      body: Column(
        children: [
          DetailHeader(
            title: 'Form Permintaan Linen & Tirai',
            userName: widget.userName,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: _loading
                          ? const Padding(
                              padding: EdgeInsets.all(40),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    'Tanggal: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.calendar_month),
                                    onPressed: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: _selectedDate,
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime(2100),
                                      );
                                      if (picked != null) {
                                        setState(() => _selectedDate = picked);
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<int>(
                                  value: _selectedRoom,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Ruangan',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: _rooms.map((room) {
                                    final id = _toInt(room['id']);
                                    return DropdownMenuItem<int>(
                                      value: id,
                                      child: Text(
                                        room['nama_ruangan']?.toString() ?? '-',
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) =>
                                      setState(() => _selectedRoom = value),
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _reasonController,
                                  maxLines: 3,
                                  decoration: const InputDecoration(
                                    labelText: 'Alasan Permintaan',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                TextField(
                                  controller: _itemSearchController,
                                  decoration: const InputDecoration(
                                    labelText: 'Cari Item Linen',
                                    hintText: 'Nama kategori atau sub kategori',
                                    prefixIcon: Icon(Icons.search),
                                    border: OutlineInputBorder(),
                                  ),
                                  onSubmitted: (value) =>
                                      _loadOptions(search: value.trim().isEmpty ? null : value.trim()),
                                ),
                                const SizedBox(height: 14),
                                const Text(
                                  'Item Linen',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 10),
                                if (_linens.isEmpty)
                                  const Text('Tidak ada item linen.')
                                else
                                  ..._linens.map((linen) {
                                    final id = _toInt(linen['id'] ?? linen['linen_id']);
                                    final category =
                                        linen['nama_kategori_linen']?.toString() ?? '-';
                                    final subCategory =
                                        linen['sub_kategori_linen']?.toString() ?? '-';

                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text('$category • $subCategory'),
                                          ),
                                          SizedBox(
                                            width: 110,
                                            child: TextFormField(
                                              initialValue:
                                                  _quantities[id]?.toString() ?? '',
                                              keyboardType: TextInputType.number,
                                              decoration: const InputDecoration(
                                                labelText: 'Jumlah',
                                                border: OutlineInputBorder(),
                                              ),
                                              onChanged: (value) {
                                                _quantities[id] = _toInt(value);
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    OutlinedButton(
                                      onPressed: _saving
                                          ? null
                                          : () => Navigator.of(context).pop(false),
                                      child: const Text('Batal'),
                                    ),
                                    const SizedBox(width: 10),
                                    ElevatedButton.icon(
                                      onPressed: _saving ? null : _save,
                                      icon: const Icon(Icons.save),
                                      label: const Text('Simpan Permintaan'),
                                    ),
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
