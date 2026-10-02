import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../api/api_service.dart';
import '../../widgets/shared_widgets.dart';

class LinenHilangCreatePage extends StatefulWidget {
  const LinenHilangCreatePage({
    super.key,
    required this.userName,
    this.initialRoomId,
  });

  final String userName;
  final int? initialRoomId;

  @override
  State<LinenHilangCreatePage> createState() => _LinenHilangCreatePageState();
}

class _LinenHilangCreatePageState extends State<LinenHilangCreatePage> {
  bool _loadingRooms = true;
  bool _loadingItems = false;
  bool _submitting = false;
  bool _pickingFile = false;
  String? _error;

  List<LinenHilangRuanganOption> _rooms = const [];
  List<LinenHilangRuanganItem> _items = const [];
  int? _roomId;
  DateTime _date = DateTime.now();
  final Set<int> _selected = {};
  final _itemSearchController = TextEditingController();
  PlatformFile? _file;
  Uint8List? _fileBytes;

  @override
  void initState() {
    super.initState();
    _roomId = widget.initialRoomId;
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    try {
      final rooms = await ApiService.instance.getLinenHilangRuanganDropdown();
      if (!mounted) return;
      setState(() {
        _rooms = rooms;
        _loadingRooms = false;
      });
      if (_roomId != null) {
        await _loadItems();
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingRooms = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingRooms = false;
        _error = 'Gagal mengambil data ruangan.';
      });
    }
  }

  Future<void> _loadItems() async {
    if (_roomId == null) return;
    setState(() {
      _loadingItems = true;
      _items = const [];
      _selected.clear();
    });

    try {
      final response = await ApiService.instance.getLinenHilangRuanganList(
        ruanganId: _roomId!,
        perPage: 100,
        page: 1,
      );
      if (!mounted) return;
      setState(() {
        _items = response.data;
        _loadingItems = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingItems = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingItems = false;
        _error = 'Gagal mengambil linen aktif di ruangan.';
      });
    }
  }

  Future<void> _pickFile() async {
    if (_pickingFile || _submitting) return;

    setState(() => _pickingFile = true);
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      );
      if (!mounted || file == null) return;

      final fileSize = file.lengthSync() ?? await file.length();
      if (fileSize != null && fileSize > 10 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ukuran berita acara maksimal 10 MB.')),
        );
        return;
      }

      final bytes = await file.readAsBytes();
      if (!mounted) return;

      setState(() {
        _file = file;
        _fileBytes = bytes;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuka pemilih berkas: $e')),
      );
    } finally {
      if (mounted) setState(() => _pickingFile = false);
    }
  }

  Future<void> _submit() async {
    if (_roomId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih ruangan terlebih dahulu.')),
      );
      return;
    }
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal satu linen.')),
      );
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final response = await ApiService.instance.createLinenHilang(
        tanggal:
            '${_date.year.toString().padLeft(4, '0')}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
        ruanganId: _roomId!,
        linenIds: _selected.toList(),
        beritaAcaraBytes: _fileBytes,
        beritaAcaraName: _file?.name,
        beritaAcaraPath: null,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response['message']?.toString() ??
                'Linen hilang berhasil ditambahkan.',
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan Linen Hilang.')),
      );
    }
  }

  @override
  void dispose() {
    _itemSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f8fc),
      body: SafeArea(
        child: Column(
          children: [
            DetailHeader(
              title: 'Tambah Linen & Tirai Hilang',
              userName: widget.userName,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 110),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
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
                      child: _loadingRooms
                          ? const Padding(
                              padding: EdgeInsets.all(42),
                              child: AppPageLoading(),
                            )
                          : _buildForm(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    if (_error != null && _rooms.isEmpty) {
      return Column(
        children: [
          const Icon(Icons.cloud_off_rounded, size: 36),
          const SizedBox(height: 10),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: _loadRooms,
            child: const Text('Coba Lagi'),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<int>(
          value: _roomId,
          decoration: InputDecoration(
            labelText: 'Ruangan',
            border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xffd9e0e7)),
          ),
          ),
          items: _rooms
              .map(
                (room) => DropdownMenuItem<int>(
                  value: room.id,
                  child: Text(
                    '${room.namaRuangan} • ${room.namaKepalaRuangan}',
                  ),
                ),
              )
              .toList(),
          onChanged: _submitting
              ? null
              : (value) {
                  setState(() => _roomId = value);
                  _loadItems();
                },
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _submitting
              ? null
              : () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (d != null && mounted) setState(() => _date = d);
                },
          icon: const Icon(Icons.event_rounded),
          label: Text(
            'Tanggal: ${_date.day.toString().padLeft(2, '0')}/${_date.month.toString().padLeft(2, '0')}/${_date.year}',
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Pilih Linen Aktif di Ruangan',
          style: TextStyle(
            color: Color(0xff34495e),
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        if (_loadingItems)
          const Padding(
            padding: EdgeInsets.all(24),
            child: AppPageLoading(
              message: 'Memuat linen...',
              subtitle: 'Mengambil linen aktif di ruangan',
            ),
          )
        else if (_items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xfff7f9fc),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('Tidak ada linen aktif di ruangan ini.'),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _itemSearchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Cari nama linen / QR Code / RFID...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _itemSearchController.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _itemSearchController.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.close_rounded, size: 19),
                        ),
                  filled: true,
                  fillColor: const Color(0xfff7f9fc),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xffe1e7ed)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 320),
            decoration: BoxDecoration(
              border: Border.all(color: Color(0xffe1e7ed)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _items.where((item) {
                final query = _itemSearchController.text.trim().toLowerCase();
                if (query.isEmpty) return true;
                return item.namaLinen.toLowerCase().contains(query) ||
                    item.qrCode.toLowerCase().contains(query) ||
                    item.tagRfid.toLowerCase().contains(query) ||
                    item.kategoriLinen.toLowerCase().contains(query);
              }).length,
              itemBuilder: (_, index) {
                final query = _itemSearchController.text.trim().toLowerCase();
                final filteredItems = _items.where((item) {
                  if (query.isEmpty) return true;
                  return item.namaLinen.toLowerCase().contains(query) ||
                      item.qrCode.toLowerCase().contains(query) ||
                      item.tagRfid.toLowerCase().contains(query) ||
                      item.kategoriLinen.toLowerCase().contains(query);
                }).toList();
                if (index >= filteredItems.length) return const SizedBox.shrink();
                final item = filteredItems[index];
                final selected = _selected.contains(item.linenId);
                return CheckboxListTile(
                  dense: true,
                  value: selected,
                  onChanged: _submitting
                      ? null
                      : (checked) {
                          setState(() {
                            if (checked == true) {
                              _selected.add(item.linenId);
                            } else {
                              _selected.remove(item.linenId);
                            }
                          });
                        },
                  title: Text(item.namaLinen),
                  subtitle: Text(
                    '${item.kategoriLinen} • ${item.qrCode} • ${item.tagRfid}',
                  ),
                );
              },
            ),
          ),
            ],
          ),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: _submitting || _pickingFile ? null : _pickFile,
          icon: _pickingFile
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.attach_file_rounded),
          label: Text(
            _pickingFile
                ? 'Membuka pemilih berkas...'
                : _file == null
                    ? 'Pilih Berita Acara'
                    : '${_file!.name} (${((_file!.lengthSync() ?? 0) / 1024 / 1024).toStringAsFixed(2)} MB)',
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'PDF, DOC, DOCX, JPG, JPEG, PNG — maksimal 10 MB.',
          style: TextStyle(fontSize: 10, color: Color(0xff7d8c99)),
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(
            _error!,
            style: const TextStyle(color: Colors.red, fontSize: 11),
          ),
        ],
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_rounded),
              label: const Text('Simpan'),
            ),
          ],
        ),
      ],
    );
  }
}
