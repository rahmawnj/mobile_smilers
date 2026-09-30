import 'package:flutter/material.dart';

import '../../api/api_service.dart';
import '../../widgets/shared_widgets.dart';

class LinenKeluarFormPage extends StatefulWidget {
  const LinenKeluarFormPage({super.key, required this.userName});

  final String userName;

  @override
  State<LinenKeluarFormPage> createState() => _LinenKeluarFormPageState();
}

class _LinenKeluarFormPageState extends State<LinenKeluarFormPage> {
  bool _loading = true;
  bool _queueLoading = true;
  LinenKeluarOptions? _options;
  LinenScanQueueResponse? _queue;
  int? _selectedRoom;
  int? _selectedUser;

  @override
  void initState() {
    super.initState();
    _loadOptions();
    _loadQueue();
  }

  Future<void> _loadOptions() async {
    try {
      final options = await ApiService.instance.getLinenKeluarOptions();
      if (!mounted) return;
      setState(() => _options = options);
    } catch (_) {
      if (!mounted) return;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadQueue() async {
    if (mounted) setState(() => _queueLoading = true);
    try {
      final queue = await ApiService.instance.getLinenKeluarScanQueue();
      if (!mounted) return;
      setState(() => _queue = queue);
    } catch (_) {
      if (!mounted) return;
    } finally {
      if (mounted) setState(() => _queueLoading = false);
    }
  }

  final _scanController = TextEditingController();
  final _scanFocusNode = FocusNode();

  @override
  void dispose() {
    _scanController.dispose();
    _scanFocusNode.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    final value = _scanController.text.trim();
    if (value.isEmpty) return;

    try {
      final response = await ApiService.instance.scanLinenKeluar(value);

      if (!mounted) return;
      _scanController.clear();
      _scanFocusNode.requestFocus();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response['message']?.toString() ??
                'Item ditambahkan ke antrean.',
          ),
        ),
      );
      await _loadQueue();
    } on ApiException catch (e) {
      if (!mounted) return;
      _scanController.clear();
      _scanFocusNode.requestFocus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  Future<void> _deleteQueue(LinenScanQueueItem item) async {
    try {
      final response = await ApiService.instance.deleteLinenKeluarScan(
        item.linenKeluarId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response['message']?.toString() ?? 'Item dihapus.',
          ),
        ),
      );
      await _loadQueue();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  Future<void> _save() async {
    final items = _queue?.data ?? const <LinenScanQueueItem>[];

    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Antrean scan masih kosong.')),
      );
      return;
    }

    if (_selectedRoom == null || _selectedUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih ruangan tujuan dan user terlebih dahulu.'),
        ),
      );
      return;
    }

    try {
      final response = await ApiService.instance.saveLinenKeluar(
        linens: items.map((e) => e.linenId).toList(),
        ruanganId: _selectedRoom!,
        userId: _selectedUser!,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response['message']?.toString() ??
                'Transaksi berhasil disimpan.',
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f8fc),
      appBar: AppBar(
        title: const Text('Form Linen Keluar'),
        leading: const BackButton(),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadQueue,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .05),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Data Transaksi',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<int?>(
                          value: _selectedRoom,
                          decoration: const InputDecoration(
                            labelText: 'Ruangan Tujuan',
                            filled: true,
                            fillColor: Color(0xfff5f8fc),
                            border: OutlineInputBorder(
                              borderSide: BorderSide.none,
                            ),
                          ),
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('Pilih Ruangan'),
                            ),
                            ...?_options?.ruangan.map(
                              (room) => DropdownMenuItem<int?>(
                                value: room.id,
                                child: Text(room.namaRuangan),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() => _selectedRoom = value);
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int?>(
                          value: _selectedUser,
                          decoration: const InputDecoration(
                            labelText: 'User',
                            filled: true,
                            fillColor: Color(0xfff5f8fc),
                            border: OutlineInputBorder(
                              borderSide: BorderSide.none,
                            ),
                          ),
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('Pilih User'),
                            ),
                            ...?_options?.users.map(
                              (user) => DropdownMenuItem<int?>(
                                value: user.id,
                                child: Text(
                                  '${user.name} (${user.username})',
                                ),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() => _selectedUser = value);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .05),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.qr_code_scanner_rounded,
                              color: Color(0xff1261dc),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Scan Linen',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _scanController,
                          focusNode: _scanFocusNode,
                          autofocus: true,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _scan(),
                          decoration: InputDecoration(
                            hintText: 'Scan RFID / QR Code di sini...',
                            prefixIcon: const Icon(Icons.nfc_rounded),
                            suffixIcon: IconButton(
                              onPressed: _scan,
                              tooltip: 'Proses scan',
                              icon: const Icon(Icons.arrow_forward_rounded),
                            ),
                            filled: true,
                            fillColor: const Color(0xfff5f8fc),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xff1261dc),
                                width: 1.2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Arahkan scanner RFID/QR ke linen. Hasil scan akan langsung masuk ke antrean.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .05),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Antrean Scan (${_queue?.total ?? 0})',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (_queueLoading)
                          const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if ((_queue?.data ?? const <LinenScanQueueItem>[]).isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(
                              child: Text('Belum ada linen yang discan.'),
                            ),
                          )
                        else
                          TableSurface(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(
                                  const Color(0xff1261dc),
                                ),
                                headingTextStyle: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                                dataTextStyle: const TextStyle(fontSize: 9),
                                columns: const [
                                  DataColumn(label: Text('No.')),
                                  DataColumn(label: Text('Linen ID')),
                                  DataColumn(label: Text('Kategori')),
                                  DataColumn(label: Text('QR Code')),
                                  DataColumn(label: Text('RFID')),
                                  DataColumn(label: Text('Waktu Scan')),
                                  DataColumn(label: Text('Aksi')),
                                ],
                                rows: (_queue?.data ?? const <LinenScanQueueItem>[])
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                  final item = entry.value;
                                  return DataRow(
                                    cells: [
                                      DataCell(Text('${entry.key + 1}')),
                                      DataCell(Text('${item.linenId}')),
                                      DataCell(Text(item.namaKategoriLinen)),
                                      DataCell(Text(item.qrCode)),
                                      DataCell(Text(item.tagRfid)),
                                      DataCell(Text(item.waktuScan)),
                                      DataCell(
                                        IconButton(
                                          onPressed: () => _deleteQueue(item),
                                          tooltip: 'Hapus',
                                          icon: const Icon(
                                            Icons.delete_outline_rounded,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save_rounded),
                      label: const Text('Simpan Linen Keluar'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
