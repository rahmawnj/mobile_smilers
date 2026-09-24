import 'package:flutter/material.dart';

import '../../api/api_service.dart';
import 'linen_keluar_scan_page.dart';

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

  Future<void> _openScanPage() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LinenKeluarScanPage(userName: widget.userName),
      ),
    );
    await _loadQueue();
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
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _openScanPage,
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
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
                      child: Row(
                        children: [
                          const Icon(
                            Icons.qr_code_scanner_rounded,
                            color: Color(0xff159cf1),
                            size: 26,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Scan Linen',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _queueLoading
                                      ? 'Memuat antrean...'
                                      : '${_queue?.total ?? 0} linen dalam antrean',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded),
                        ],
                      ),
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
