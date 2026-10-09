import 'package:flutter/material.dart';

import '../../api/api_service.dart';
import '../../widgets/pagination_widget.dart';
import '../../widgets/shared_widgets.dart';
import 'permintaan_linen_form_page.dart';

class PermintaanLinenPage extends StatefulWidget {
  const PermintaanLinenPage({super.key, required this.userName});
  final String userName;

  @override
  State<PermintaanLinenPage> createState() => _PermintaanLinenPageState();
}

class _PermintaanLinenPageState extends State<PermintaanLinenPage> {
  bool _loading = true;
  String? _error;
  LinenListResponse<PermintaanLinenItem>? _response;
  int? _roomId;
  List<Map<String, dynamic>> _rooms = [];
  String? _status;
  int _page = 1;
  int _perPage = 10;
  final TextEditingController _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _loadRooms();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Future<void> _loadRooms() async {
    try {
      final rooms =
          await ApiService.instance.getPermintaanLinenRuanganDropdown();
      if (!mounted) return;
      setState(() {
        _rooms = rooms;
      });
    } on ApiException catch (_) {
      // Room filter is optional; keep the list usable if the dropdown fails.
    }
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      final result = await ApiService.instance.getPermintaanLinen(
        perPage: _perPage,
        page: _page,
        search: _search.text.trim().isEmpty ? null : _search.text.trim(),
        ruangan: _roomId,
        status: _status,
      );

      if (!mounted) return;
      setState(() {
        _response = result;
        _loading = false;
        _error = null;
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
        _error = 'Tidak dapat mengambil data Permintaan Linen & Tirai.';
        _loading = false;
      });
    }
  }

  Future<void> _showDetail(int id) async {
    var loadingDialogOpen = true;

    // Tampilkan loading sederhana terlebih dahulu saat detail diambil dari API.
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (loadingContext) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 28, vertical: 26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Color(0xff6e139a),
                  ),
                ),
                SizedBox(height: 18),
                Text(
                  'Memuat Detail Permintaan',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xff263445),
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Mohon tunggu sebentar...',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Color(0xff7b8492)),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final result = await ApiService.instance.getPermintaanLinenDetail(id);
      if (!mounted) return;

      Navigator.of(context, rootNavigator: true).pop();
      loadingDialogOpen = false;

      final data = result.data;
      final rawItems = data['items'];
      final List items = rawItems is List ? rawItems : const [];
      final status = data['status']?.toString() ?? '-';
      final sent = status.trim().toLowerCase() == 'terkirim';
      const accent = Color(0xff6e139a);
      final screen = MediaQuery.sizeOf(context);
      final dialogWidth = screen.width > 820 ? 760.0 : screen.width * 0.92;
      final dialogHeight = screen.height > 850 ? 700.0 : screen.height * 0.82;

      Widget infoCard(IconData icon, String label, String value) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xfff8f6fb),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xffeee6f4)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 19, color: accent),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xff7b8492),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value.isEmpty ? '-' : value,
                      softWrap: true,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xff263445),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }

      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) => Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 18,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: dialogWidth,
            height: dialogHeight,
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 16, 10, 16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xff6e139a), Color(0xff8b35b4)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.receipt_long_rounded,
                        color: Colors.white,
                        size: 27,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Detail Permintaan',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Informasi permintaan linen dan tirai',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Tutup',
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Informasi Permintaan',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xff263445),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: sent
                                    ? const Color(0xffe8f8ef)
                                    : const Color(0xfffff4df),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: sent
                                      ? const Color(0xff18834a)
                                      : const Color(0xffa66a00),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        infoCard(
                          Icons.calendar_month_rounded,
                          'Tanggal Permintaan',
                          data['tanggal_permintaan']?.toString() ?? '-',
                        ),
                        const SizedBox(height: 8),
                        infoCard(
                          Icons.meeting_room_rounded,
                          'Ruangan',
                          data['nama_ruangan']?.toString() ?? '-',
                        ),
                        const SizedBox(height: 8),
                        infoCard(
                          Icons.person_outline_rounded,
                          'Kepala Ruangan',
                          data['nama_kepala_ruangan']?.toString() ?? '-',
                        ),
                        const SizedBox(height: 8),
                        infoCard(
                          Icons.notes_rounded,
                          'Alasan Permintaan',
                          data['alasan_permintaan']?.toString() ?? '-',
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            const Icon(
                              Icons.inventory_2_outlined,
                              color: accent,
                              size: 21,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Daftar Linen',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xff263445),
                                ),
                              ),
                            ),
                            Text(
                              '${items.length} item',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xff7b8492),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (items.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: const Color(0xfff8f6fb),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Belum ada data barang pada permintaan ini.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xff7b8492),
                                fontSize: 12,
                              ),
                            ),
                          )
                        else
                          ...items.map((rawItem) {
                            final item = rawItem is Map
                                ? rawItem
                                : const <String, dynamic>{};
                            return Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xffeee6f4),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 30,
                                    height: 30,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: accent.withValues(alpha: 0.09),
                                      borderRadius: BorderRadius.circular(9),
                                    ),
                                    child: const Icon(
                                      Icons.checkroom_rounded,
                                      color: accent,
                                      size: 17,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['nama_linen']?.toString() ?? '-',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xff263445),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item['kategori_linen']?.toString() ??
                                              '-',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xff7b8492),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'x ${item['jumlah']?.toString() ?? '0'}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: accent,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Color(0xffedf0f5)),
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Selesai'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } on ApiException catch (e) {
      if (mounted) {
        if (loadingDialogOpen) {
          Navigator.of(context, rootNavigator: true).pop();
          loadingDialogOpen = false;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (mounted) {
        if (loadingDialogOpen) {
          Navigator.of(context, rootNavigator: true).pop();
          loadingDialogOpen = false;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Gagal memuat detail permintaan. Silakan coba lagi.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _updateStatus(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Konfirmasi Pengiriman'),
          content: const Text(
            'Apakah permintaan linen ini sudah siap dikirim? '
            'Setelah dikirim, status akan berubah menjadi Terkirim dan '
            'tombol kirim tidak dapat digunakan lagi.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(dialogContext, true),
              icon: const Icon(Icons.send_rounded),
              label: const Text('Ya, Kirim'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    try {
      final result = await ApiService.instance.updatePermintaanLinenStatus(id);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message']?.toString() ?? 'Status berhasil diubah',
          ),
        ),
      );
      await _load();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = _response?.data ?? const <PermintaanLinenItem>[];
    final meta = _response?.meta;

    return AppShell(
      userName: widget.userName,
      activeIndex: -1,
      showBottomNavigation: false,
      body: Column(
        children: [
          DetailHeader(
            title: 'Permintaan Linen & Tirai',
            userName: widget.userName,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 850;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _search,
                            onSubmitted: (_) {
                              setState(() {
                                _page = 1;
                              });
                              _load();
                            },
                            decoration: InputDecoration(
                              hintText: 'Cari permintaan...',
                              prefixIcon: const Icon(Icons.search),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final created =
                                await Navigator.of(context).push<bool>(
                              MaterialPageRoute(
                                builder: (_) => PermintaanLinenFormPage(
                                  userName: widget.userName,
                                ),
                              ),
                            );
                            if (created == true && mounted) {
                              _page = 1;
                              _load();
                            }
                          },
                          icon: const Icon(
                            Icons.add_rounded,
                            size: 20,
                          ),
                          label: const Text(
                            'Buat Permintaan',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff1261dc),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 44),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Card(
                      color: Colors.white,
                      elevation: 2,
                      shadowColor: Colors.black12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Color(0xffedf0f5)),
                      ),
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Filter Data',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xff263445),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: AppFilterDropdown<int>(
                                    value: _roomId,
                                    hint: 'Ruangan',
                                    icon: Icons.meeting_room_outlined,
                                    items: [
                                      const DropdownMenuItem<int>(
                                        value: null,
                                        child: Text('Semua Ruangan'),
                                      ),
                                      ..._rooms.map(
                                        (room) => DropdownMenuItem<int>(
                                          value: _toInt(room['id']),
                                          child: Text(
                                            room['nama_ruangan']?.toString() ?? '-',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _roomId = value;
                                        _page = 1;
                                      });
                                      _load();
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: AppFilterDropdown<String>(
                                    value: _status,
                                    hint: 'Status',
                                    icon: Icons.assignment_outlined,
                                    items: const [
                                      DropdownMenuItem<String>(
                                        value: null,
                                        child: Text('Semua Status'),
                                      ),
                                      DropdownMenuItem<String>(
                                        value: 'belum',
                                        child: Text('Belum'),
                                      ),
                                      DropdownMenuItem<String>(
                                        value: 'terkirim',
                                        child: Text('Terkirim'),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _status = value;
                                        _page = 1;
                                      });
                                      _load();
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Expanded(
            child: AppRefreshIndicator(
              onRefresh: _load,
              child: LayoutBuilder(builder: (context, constraints) { return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: _loading
                    ? const AppPageLoading()
                    : _error != null
                        ? Padding(
                            padding: const EdgeInsets.all(40),
                            child: Center(child: Text(_error!)),
                          )
                        : rows.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(40),
                                child: Center(
                                  child: Text('Tidak ada permintaan linen.'),
                                ),
                              )
                            : Column(
                                children: [
                                  AppDataTable(
                                    columns: const [
                                      DataColumn(label: Text('No')),
                                      DataColumn(label: Text('Tanggal Permintaan')),
                                      DataColumn(label: Text('Nama Ruangan')),
                                      DataColumn(label: Text('Nama Kepala Ruangan')),
                                      DataColumn(label: Text('Status')),
                                      DataColumn(label: Text('Action')),
                                    ],
                                    rows: rows.asMap().entries.map((entry) {
                                      final item = entry.value;
                                      final isSent = item.status.trim().toLowerCase() == 'terkirim';
                                      final number = meta == null
                                          ? entry.key + 1
                                          : (meta.currentPage - 1) * meta.perPage +
                                              entry.key +
                                              1;
                                      return DataRow(cells: [
                                        DataCell(Text('$number')),
                                        DataCell(Text(item.tanggalPermintaan)),
                                        DataCell(Text(item.namaRuangan)),
                                        DataCell(Text(item.namaKepalaRuangan)),
                                        DataCell(Text(item.status)),
                                        DataCell(
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                tooltip: 'Detail',
                                                onPressed: () => _showDetail(item.id),
                                                icon: const Icon(
                                                  Icons.visibility_outlined,
                                                  size: 18,
                                                  color: Color(0xff1261dc),
                                                ),
                                              ),
                                              IconButton(
                                                tooltip: isSent ? 'Sudah terkirim' : 'Kirim permintaan',
                                                onPressed: isSent ? null : () => _updateStatus(item.id),
                                                icon: const Icon(Icons.send_rounded),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ]);
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 10),                                  if (meta != null)
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Text('Total ${meta.total} permintaan', style: const TextStyle(color: Color(0xff7d8c99), fontSize: 10, fontWeight: FontWeight.w600)),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text('Jumlah', style: TextStyle(fontSize: 10)),
                                            const SizedBox(width: 8),
                                            AppPerPageDropdown(
                                              value: _perPage,
                                              onChanged: (value) {
                                                setState(() { _perPage = value; _page = 1; });
                                                _load();
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  if (meta != null)
                                    AppPagination(
                                      meta: meta,
                                      onPage: (page) {
                                        setState(() {
                                          _page = page;
                                        });
                                        _load();
                                      },
                                      alignment: MainAxisAlignment.center,
                                    ),

                                ],
                              ),
              ); }),
            ),
          ),
        ],
      ),
    );
  }
}
