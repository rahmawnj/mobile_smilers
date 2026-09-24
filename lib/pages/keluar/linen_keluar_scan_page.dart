import 'package:flutter/material.dart';

import '../../api/api_service.dart';

class LinenKeluarScanPage extends StatefulWidget {
  const LinenKeluarScanPage({super.key, required this.userName});

  final String userName;

  @override
  State<LinenKeluarScanPage> createState() => _LinenKeluarScanPageState();
}

class _LinenKeluarScanPageState extends State<LinenKeluarScanPage> {
  bool _loading = true;
  LinenScanQueueResponse? _queue;

  @override
  void initState() {
    super.initState();
    _loadQueue();
  }

  Future<void> _loadQueue() async {
    if (mounted) setState(() => _loading = true);
    try {
      final queue = await ApiService.instance.getLinenKeluarScanQueue();
      if (!mounted) return;
      setState(() => _queue = queue);
    } catch (_) {
      if (!mounted) return;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _scan() async {
    final controller = TextEditingController();

    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scan Linen Keluar'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'RFID / QR Code',
          ),
          onSubmitted: (value) {
            Navigator.of(context).pop(value.trim());
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(controller.text.trim());
            },
            child: const Text('Scan'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (value == null || value.isEmpty) return;

    try {
      final response = await ApiService.instance.scanLinenKeluar(value);

      if (!mounted) return;
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

  @override
  Widget build(BuildContext context) {
    final items = _queue?.data ?? const <LinenScanQueueItem>[];

    return Scaffold(
      backgroundColor: const Color(0xfff5f8fc),
      appBar: AppBar(
        title: const Text('Scan Linen Keluar'),
        leading: const BackButton(),
      ),
      body: RefreshIndicator(
        onRefresh: _loadQueue,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _scan,
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: const Text('Scan Linen'),
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
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: Text('Belum ada linen yang discan.'),
                      ),
                    )
                  else
                    SingleChildScrollView(
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
                        rows: items.asMap().entries.map((entry) {
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
