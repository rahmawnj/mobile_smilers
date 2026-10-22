import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../api/api_service.dart';
import '../../widgets/pagination_widget.dart';
import '../../widgets/shared_widgets.dart';
import 'linen_keluar_form_page.dart';
import 'linen_keluar_scan_page.dart';

class LinenKeluarPage extends StatefulWidget {
  const LinenKeluarPage({super.key, required this.userName});
  final String userName;
  @override State<LinenKeluarPage> createState() => _LinenKeluarPageState();
}
class _LinenKeluarPageState extends State<LinenKeluarPage> {
  bool _loading=true,_optionsLoading=true,_queueLoading=true;
  String? _error;
  LinenListResponse<LinenKeluarItem>? _response;
  LinenKeluarOptions? _options;
  LinenScanQueueResponse? _queue;
  final _searchController=TextEditingController();
  int _page=1,_perPage=10;
  int? _filterRoom,_selectedRoom,_selectedUser;
  DateTimeRange? _selectedDateRange;

  @override void initState(){super.initState();_loadOptions();_load();_loadQueue();}
  @override void dispose(){_searchController.dispose();super.dispose();}
  String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  String _range(DateTimeRange r) => '${_date(r.start)} - ${_date(r.end)}';
  bool _isSingleDate(DateTimeRange r) =>
      r.start.year == r.end.year &&
      r.start.month == r.end.month &&
      r.start.day == r.end.day;

  Future<void> _loadOptions() async {
    try {
      final o=await ApiService.instance.getLinenKeluarOptions();
      if(!mounted)return;
      setState(()=>_options=o);
    } catch (_) {} finally { if(mounted)setState(()=>_optionsLoading=false); }
  }
  Future<void> _load() async {
    if (_filterRoom == null) {
      if (!mounted) return;
      setState(() {
        _response = null;
        _error = null;
        _loading = false;
        _page = 1;
      });
      return;
    }

    setState(()=>_loading=true);
    try {
      final r=await ApiService.instance.getLinenKeluar(
        perPage:_perPage,page:_page,
        search:_searchController.text.trim().isEmpty?null:_searchController.text.trim(),
        ruangan:_filterRoom,
        date: null,
        daterange: _selectedDateRange == null
            ? null
            : _range(_selectedDateRange!));
      if(!mounted)return;
      setState(()=>{_response=r,_error=null,_loading=false});
    } on ApiException catch(e) {
      if(!mounted)return; setState(()=>{_error=e.message,_loading=false});
    } catch(_) { if(!mounted)return; setState(()=>{_error='Tidak dapat mengambil data Linen & Tirai Keluar dari server.',_loading=false}); }
  }
  Future<void> _loadQueue() async {
    if(mounted)setState(()=>_queueLoading=true);
    try { final q=await ApiService.instance.getLinenKeluarScanQueue(); if(mounted)setState(()=>_queue=q); }
    catch(_) {} finally { if(mounted)setState(()=>_queueLoading=false); }
  }
  Future<void> _scan() async {
    final c=TextEditingController();
    final v=await showDialog<String>(context:context,builder:(context)=>AlertDialog(
      title:const Text('Scan Linen Keluar'),
      content:TextField(controller:c,autofocus:true,decoration:const InputDecoration(labelText:'RFID / QR Code'),
        onSubmitted:(v)=>Navigator.of(context).pop(v.trim())),
      actions:[TextButton(onPressed:()=>Navigator.of(context).pop(),child:const Text('Batal')),
        ElevatedButton(onPressed:()=>Navigator.of(context).pop(c.text.trim()),child:const Text('Scan'))]));
    c.dispose(); if(v==null||v.isEmpty)return;
    try { final r=await ApiService.instance.scanLinenKeluar(v); if(!mounted)return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(r['message']?.toString()??'Item ditambahkan ke antrean.'))); await _loadQueue();
    } on ApiException catch(e) { if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.message))); }
  }
  Future<void> _deleteQueue(LinenScanQueueItem item) async {
    try { final r=await ApiService.instance.deleteLinenKeluarScan(item.linenKeluarId); if(!mounted)return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(r['message']?.toString()??'Item dihapus.'))); await _loadQueue();
    } on ApiException catch(e) { if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.message))); }
  }
  Future<void> _saveQueue() async {
    final items=_queue?.data??const <LinenScanQueueItem>[];
    if(items.isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Antrean scan masih kosong.')));return;}
    if(_selectedRoom==null||_selectedUser==null){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Pilih ruangan dan user terlebih dahulu.')));return;}
    try { final r=await ApiService.instance.saveLinenKeluar(linens:items.map((e)=>e.linenId).toList(),ruanganId:_selectedRoom!,userId:_selectedUser!);
      if(!mounted)return; ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(r['message']?.toString()??'Transaksi berhasil disimpan.')));
      await Future.wait([_load(),_loadQueue()]);
    } on ApiException catch(e) { if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.message))); }
  }
  Future<LinenListResponse<LinenKeluarItem>> _getKeluarPage(
    int page, {
    int perPage = 100,
    DateTime? previewDate,
    int? previewRoom,
    bool usePreviewRoom = false,
  }) {
    final room = usePreviewRoom ? previewRoom : _filterRoom;
    if (room == null) {
      throw const ApiException(
        'Pilih ruangan terlebih dahulu untuk menampilkan data Linen Keluar.',
      );
    }

    return ApiService.instance.getLinenKeluar(
      perPage: perPage,
      page: page,
      search: _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim(),
      ruangan: room,
      date: null,
      daterange: previewDate == null
          ? (_selectedDateRange == null ? null : _range(_selectedDateRange!))
          : '${_date(previewDate)} - ${_date(previewDate)}',
    );
  }

  Future<List<LinenKeluarItem>> _loadAllKeluarRows(DateTime? previewDate, int? previewRoom) async {
    const maxRows = 5000;
    final rows = <LinenKeluarItem>[];
    var page = 1;
    var lastPage = 1;
    do {
      final response = await _getKeluarPage(page, previewDate: previewDate, previewRoom: previewRoom, usePreviewRoom: true);
      lastPage = response.meta.lastPage;
      rows.addAll(response.data.take(maxRows - rows.length));
      page++;
    } while (page <= lastPage && rows.length < maxRows);
    return rows;
  }

  Future<void> _downloadKeluarPdf(
    List<LinenKeluarItem> rows, [
    DateTime? previewDate,
    int? previewRoom,
  ]) async {
    // Pecah PDF menjadi halaman kecil agar layout ribuan baris tidak membekukan UI.
    final document = pw.Document();
    final tableRows = rows.asMap().entries.map((entry) {
      final item = entry.value;
      return <String>[
        '${entry.key + 1}',
        item.namaLinen.isEmpty ? '-' : item.namaLinen,
        item.namaKategoriLinen.isEmpty ? '-' : item.namaKategoriLinen,
        item.jumlah.isEmpty ? '-' : item.jumlah,
        item.keRuangan.isEmpty ? '-' : item.keRuangan,
      ];
    }).toList(growable: false);
    final roomName = _options?.ruangan.where((r) => r.id == previewRoom).map((r) => r.namaRuangan).firstOrNull ?? '-';
    final searchText = _searchController.text.trim();
    const rowsPerPage = 25;
    final pageCount = (tableRows.length / rowsPerPage).ceil();

    for (var pageIndex = 0; pageIndex < pageCount; pageIndex++) {
      final startIndex = pageIndex * rowsPerPage;
      final endIndex = (startIndex + rowsPerPage < tableRows.length)
          ? startIndex + rowsPerPage
          : tableRows.length;
      final pageRows = tableRows.sublist(startIndex, endIndex);
      final isLastPage = pageIndex == pageCount - 1;

      document.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(24),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'DATA LINEN & TIRAI KELUAR',
                style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                'Halaman ${pageIndex + 1} dari $pageCount • Tanggal cetak: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                style: const pw.TextStyle(fontSize: 7),
              ),
              if (previewRoom != null)
                pw.Text('Filter ruangan: $roomName', style: const pw.TextStyle(fontSize: 7)),
              if (previewDate != null)
                pw.Text('Filter tanggal: ${_date(previewDate)}', style: const pw.TextStyle(fontSize: 7)),
              if (searchText.isNotEmpty)
                pw.Text('Pencarian: $searchText', style: const pw.TextStyle(fontSize: 7)),
              pw.SizedBox(height: 7),
              pw.TableHelper.fromTextArray(
                headers: const ['No', 'Nama Linen', 'Kategori Linen', 'Jumlah', 'Ruangan'],
                data: pageRows,
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 8,
                  color: PdfColors.white,
                ),
                cellStyle: const pw.TextStyle(fontSize: 7),
                headerDecoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(0xff02c0cc),
                ),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                border: pw.TableBorder.all(color: PdfColors.grey500, width: .4),
              ),
              if (isLastPage) ...[
                pw.SizedBox(height: 18),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(children: [
                        pw.Text('PETUGAS LINEN', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                        pw.SizedBox(height: 28),
                        pw.Text(widget.userName.trim().isEmpty ? '-' : widget.userName.trim(), style: const pw.TextStyle(fontSize: 8)),
                      ]),
                    ),
                    pw.Expanded(
                      child: pw.Column(children: [
                        pw.Text('PETUGAS LAUNDRY', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                        pw.SizedBox(height: 28),
                        pw.Text(
                          previewRoom == null
                              ? ''
                              : rows.firstWhere((item) => item.user.trim().isNotEmpty, orElse: () => rows.first).user.trim().isEmpty
                                  ? '-'
                                  : rows.firstWhere((item) => item.user.trim().isNotEmpty, orElse: () => rows.first).user.trim(),
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                      ]),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      );

      // Beri kesempatan event loop memperbarui indikator loading dan menerima input.
      if (pageIndex % 4 == 3) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    final bytes = Uint8List.fromList(await document.save());
    await FilePicker.saveFile(
      dialogTitle: 'Simpan PDF Linen & Tirai Keluar',
      fileName: 'linen_tirai_keluar.pdf',
      mimeType: 'application/pdf',
      bytes: bytes,
    );
  }

  Future<LinenListResponse<LinenKeluarItem>> _getKeluarPreviewPage(
    int page,
    DateTime? previewDate,
    int? previewRoom,
  ) {
    return _getKeluarPage(page, perPage: 500, previewDate: previewDate, previewRoom: previewRoom, usePreviewRoom: true);
  }

  Future<void> _previewDownload() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => _LinenKeluarPreviewDialog(
        userName: widget.userName,
        loadPage: _getKeluarPreviewPage,
        downloadAll: _loadAllKeluarRows,
        downloadPdf: _downloadKeluarPdf,
        rooms: (_options?.ruangan ?? []).map((room) => MapEntry(room.id, room.namaRuangan)).toList(),
      ),
    );
  }

  Future<void> _pickRange() async {
    final r=await showDateRangePicker(
      context:context,
      firstDate:DateTime(2020),
      lastDate:DateTime(2100),
      initialDateRange:_selectedDateRange,
    );
    if(r!=null){
      setState(()=>{_selectedDateRange=r,_page=1});
      _load();
    }
  }
  void _reset(){_searchController.clear();setState(()=>{_filterRoom=null,_selectedDateRange=null,_page=1});_load();}

  @override Widget build(BuildContext context) {
    final rows=_response?.data??const <LinenKeluarItem>[];
    final meta=_response?.meta;
    return AppShell(userName:widget.userName,activeIndex:-1,body: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(22),
                ),
              ),
            ),
          ),
          Column(children:[
      DetailHeader(title:'Linen & Tirai Keluar',userName:widget.userName, transparentBottom: true),
      Expanded(child:AppRefreshIndicator(onRefresh:() async=>Future.wait([_load(),_loadQueue()]),child:ListView(padding:const EdgeInsets.fromLTRB(16,14,16,100),children:[
        Row(children:[
          Expanded(child:TextField(controller:_searchController,onSubmitted:(_){setState(()=>_page=1);_load();},decoration:InputDecoration(
            hintText:'Cari nama linen, RFID, QR Code, user...',prefixIcon:const Icon(Icons.search_rounded),filled:true,fillColor:Colors.white,
            border:OutlineInputBorder(borderRadius:BorderRadius.circular(20),borderSide:BorderSide.none)))),
          const SizedBox(width:8),
          ElevatedButton.icon(
            onPressed: () async {
              final saved = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => LinenKeluarFormPage(userName: widget.userName),
                ),
              );
              if (saved == true && mounted) {
                await Future.wait([_load(), _loadQueue()]);
              }
            },
            icon: const Icon(Icons.assignment_rounded, size: 20),
            label: const Text('Form', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff1261dc), foregroundColor: Colors.white, minimumSize: const Size(0, 44), padding: const EdgeInsets.symmetric(horizontal: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: _previewDownload,
            tooltip: 'Preview dan download',
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xffeaf2ff),
              foregroundColor: const Color(0xff1261dc),
              minimumSize: const Size(44, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.preview_rounded, size: 21),
          ),
        ]),
        const SizedBox(height:10),
        Container(
          width:double.infinity,
          padding:const EdgeInsets.all(14),
          decoration:BoxDecoration(
            color:Colors.white,
            borderRadius:BorderRadius.circular(18),
            boxShadow:[BoxShadow(color:Colors.black.withValues(alpha:.05),blurRadius:12,offset:const Offset(0,4))],
          ),
          child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            const Text('Filter Data',style:TextStyle(fontSize:13,fontWeight:FontWeight.w800)),
            const SizedBox(height:10),
            if(_optionsLoading)const LinearProgressIndicator(minHeight:2),
            const SizedBox(height:8),
            Row(children:[
              Expanded(child:DropdownButtonFormField<int?>(
                value:_filterRoom,
                decoration:const InputDecoration(labelText:'Ruangan',filled:true,fillColor:Color(0xfff5f8fc),border:OutlineInputBorder(borderSide:BorderSide.none)),
                items:[const DropdownMenuItem<int?>(value:null,child:Text('Pilih Ruangan')), ...?_options?.ruangan.map((r)=>DropdownMenuItem<int?>(value:r.id,child:Text(r.namaRuangan)))],
                onChanged:(v){setState(()=>{_filterRoom=v,_page=1});_load();},
              )),
              const SizedBox(width:8),
              IconButton(
                onPressed: _pickRange,
                tooltip: 'Pilih rentang tanggal',
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xff1261dc),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.date_range_rounded, size: 20),
              ),
              IconButton(onPressed:_reset,tooltip:'Reset filter',icon:const Icon(Icons.filter_alt_off_rounded)),
            ]),
            if (_selectedDateRange != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(Icons.date_range_rounded, size: 15, color: Color(0xff6f7f8d)),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        'Periode: ' + (_isSingleDate(_selectedDateRange!) ? _date(_selectedDateRange!.start) : _range(_selectedDateRange!)),
                        style: const TextStyle(fontSize: 9, color: Color(0xff6f7f8d)),
                      ),
                    ),
                  ],
                ),
              ),
          ]),
        ),
        const SizedBox(height:12),
        const SizedBox(height:12),
        if (_filterRoom == null)
          const Padding(
            padding: EdgeInsets.all(28),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.meeting_room_outlined, size: 38, color: Color(0xff7d8c99)),
                  SizedBox(height: 10),
                  Text(
                    'Pilih ruangan terlebih dahulu untuk menampilkan data Linen & Tirai Keluar.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xff7d8c99), fontSize: 12),
                  ),
                ],
              ),
            ),
          )
        else if (_loading) const AppPageLoading()
        else if(_error!=null)Padding(padding:const EdgeInsets.all(24),child:Column(children:[const Icon(Icons.cloud_off_rounded),const SizedBox(height:10),Text(_error!,textAlign:TextAlign.center),const SizedBox(height:12),ElevatedButton(onPressed:_load,child:const Text('Coba Lagi'))]))
        else AppDataTable(
      headingColor: const Color(0xff02c0cc),
          columns: const [
            DataColumn(label: Text('No')),
            DataColumn(label: Text('Nama Linen')),
            DataColumn(label: Text('Kategori Linen')),
            DataColumn(label: Text('Jumlah')),
            DataColumn(label: Text('Ruangan')),
          ],
          rows: rows.asMap().entries.map((e) {
            final n = ((meta?.currentPage ?? _page) - 1) *
                    (meta?.perPage ?? _perPage) +
                e.key +
                1;
            return DataRow(cells: [
              DataCell(Text(n.toString())),
              DataCell(Text(e.value.namaLinen.isEmpty ? '-' : e.value.namaLinen)),
              DataCell(Text(e.value.namaKategoriLinen.isEmpty ? '-' : e.value.namaKategoriLinen)),
              DataCell(Text(e.value.jumlah.isEmpty ? '-' : e.value.jumlah)),
              DataCell(Text(e.value.keRuangan.isEmpty ? '-' : e.value.keRuangan)),
            ]);
          }).toList(),
        ),
        if(_filterRoom != null && !_loading && _error==null && rows.isEmpty)const Padding(padding:EdgeInsets.all(24),child:Center(child:Text('Tidak ada data Linen & Tirai Keluar.'))),
        if(meta!=null) ...[
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Total ${meta.total} linen keluar',
                    style: const TextStyle(
                      color: Color(0xff7d8c99),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Jumlah',
                        style: TextStyle(
                          color: Color(0xff8b99a5),
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(width: 6),
                      AppPerPageDropdown(
                        value: _perPage,
                        onChanged: (n) {
                          setState(() { _perPage = n; _page = 1; });
                          _load();
                        },
                      ),
                    ],
                  ),
                ],
              ),
              if (meta.lastPage > 1)
                AppPagination(
                  meta: meta,
                  onPage: (p){setState(()=>_page=p);_load();},
                  alignment: MainAxisAlignment.center,
                ),
            ],
          ),

        ],
      ]))),
    ]),
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            height: 60,
            child: IgnorePointer(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(22),
                  ),
                ),
              ),
            ),
          ),
        ],
      ));
  }
}


class _LinenKeluarPreviewDialog extends StatefulWidget {
  const _LinenKeluarPreviewDialog({
    required this.userName,
    required this.loadPage,
    required this.downloadAll,
    required this.downloadPdf,
    required this.rooms,
  });

  final String userName;
  final List<MapEntry<int, String>> rooms;
  final Future<LinenListResponse<LinenKeluarItem>> Function(
    int page,
    DateTime? previewDate,
    int? previewRoom,
  ) loadPage;
  final Future<List<LinenKeluarItem>> Function(DateTime? previewDate, int? previewRoom) downloadAll;
  final Future<void> Function(List<LinenKeluarItem>, [DateTime? previewDate, int? previewRoom]) downloadPdf;

  @override
  State<_LinenKeluarPreviewDialog> createState() => _LinenKeluarPreviewDialogState();
}

class _LinenKeluarPreviewDialogState extends State<_LinenKeluarPreviewDialog> {
  final ScrollController _scrollController = ScrollController();
  final List<LinenKeluarItem> _rows = [];
  int _nextPage = 1;
  int _lastPage = 1;
  int? _total;
  bool _loading = true;
  bool _loadingMore = false;
  bool _downloadingPdf = false;
  String? _error;
  DateTime? _filterDate;
  int? _filterRoom;
  String _petugasLaundryFromResponse = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _loadingMore || _loading) return;
    if (_scrollController.position.extentAfter < 240 &&
        _nextPage <= _lastPage &&
        _rows.length < 5000) {
      _loadNextPage();
    }
  }

  Future<void> _loadNextPage() async {
    if (_filterRoom == null) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
          _rows.clear();
          _total = null;
          _error = null;
        });
      }
      return;
    }
    if (_loadingMore || _nextPage > _lastPage && _rows.isNotEmpty) return;
    final page = _nextPage;
    setState(() {
      _loading = _rows.isEmpty;
      _loadingMore = _rows.isNotEmpty;
      _error = null;
    });
    try {
      final response = await widget.loadPage(page, _filterDate, _filterRoom);
      if (!mounted) return;
      setState(() {
        _rows.addAll(response.data.take(5000 - _rows.length));
        if (response.meta.petugasLaundry.trim().isNotEmpty) {
          _petugasLaundryFromResponse = response.meta.petugasLaundry.trim();
        } else if (response.data.isNotEmpty) {
          final name = response.data.map((item) => item.user.trim()).firstWhere((value) => value.isNotEmpty, orElse: () => '');
          if (name.isNotEmpty) _petugasLaundryFromResponse = name;
        }
        _nextPage = page + 1;
        _lastPage = response.meta.lastPage;
        _total = response.meta.total;
        _loading = false;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        _error = e is ApiException ? e.message : 'Gagal memuat data. Periksa koneksi lalu coba lagi.';
      });
    }
  }

  Future<void> _applyPreviewFilters({DateTime? date, int? room, bool resetDate = false, bool resetRoom = false}) async {
    final nextRoom = resetRoom ? null : (room ?? _filterRoom);
    setState(() {
      if (date != null) _filterDate = DateTime(date.year, date.month, date.day);
      if (resetDate) _filterDate = null;
      _filterRoom = nextRoom;
      _rows.clear();
      _nextPage = 1;
      _lastPage = 1;
      _total = null;
      _error = null;
      _loading = nextRoom != null;
      _loadingMore = false;
      _petugasLaundryFromResponse = '';
    });
    if (nextRoom != null) {
      await _loadNextPage();
    }
  }

  Future<void> _pickPreviewDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _filterDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Pilih tanggal transaksi',
      cancelText: 'Batal',
      confirmText: 'Terapkan',
    );
    if (picked == null || !mounted) return;
    await _applyPreviewFilters(date: picked);
  }

  void _resetPreviewFilters() {
    _applyPreviewFilters(resetDate: true, resetRoom: true);
  }

  String get _petugasLaundry {
    if (_petugasLaundryFromResponse.isNotEmpty) return _petugasLaundryFromResponse;
    if (_filterRoom == null) return '';
    for (final item in _rows) {
      final name = item.user.trim();
      if (name.isNotEmpty) return name;
    }
    return '-';
  }

  Future<void> _downloadPdf() async {
    setState(() => _downloadingPdf = true);
    try {
      final rows = await widget.downloadAll(_filterDate, _filterRoom);
      if (!mounted) return;
      if (rows.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak ada data untuk diunduh.')),
        );
        return;
      }
      await widget.downloadPdf(rows, _filterDate, _filterRoom);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuat PDF: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _downloadingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Preview Linen & Tirai Keluar'),
      content: SizedBox(
        width: 760,
        height: 520,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int?>(
                      value: _filterRoom,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Ruangan',
                        prefixIcon: const Icon(Icons.meeting_room_rounded, size: 18),
                        filled: true,
                        fillColor: const Color(0xfff7faff),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xffd8e4f5)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xffd8e4f5)),
                        ),
                      ),
                      items: [
                        const DropdownMenuItem<int?>(value: null, child: Text('Pilih Ruangan')),
                        ...widget.rooms.map((room) => DropdownMenuItem<int?>(
                              value: room.key,
                              child: Text(room.value, overflow: TextOverflow.ellipsis),
                            )),
                      ],
                      onChanged: _loading || _downloadingPdf
                          ? null
                          : (value) => _applyPreviewFilters(
                                room: value,
                                resetRoom: value == null,
                              ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: _filterDate == null
                        ? 'Pilih tanggal'
                        : 'Tanggal: ${_filterDate!.day.toString().padLeft(2, '0')}/${_filterDate!.month.toString().padLeft(2, '0')}/${_filterDate!.year}',
                    onPressed: _loading || _downloadingPdf ? null : _pickPreviewDate,
                    icon: const Icon(Icons.calendar_month_rounded, size: 20),
                    style: IconButton.styleFrom(
                      foregroundColor: const Color(0xff1261dc),
                      backgroundColor: const Color(0xfff7faff),
                      shape: const CircleBorder(),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: 'Reset filter',
                    onPressed: (_filterDate == null && _filterRoom == null) ||
                            _loading ||
                            _downloadingPdf
                        ? null
                        : _resetPreviewFilters,
                    icon: const Icon(Icons.filter_alt_off_rounded, size: 20),
                    style: IconButton.styleFrom(
                      foregroundColor: const Color(0xff1261dc),
                      backgroundColor: const Color(0xfff7faff),
                      shape: const CircleBorder(),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _filterRoom == null
                  ? const Center(
                      child: Text(
                        'Pilih ruangan melalui dropdown di atas untuk menampilkan preview.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xff7d8c99), fontSize: 12),
                      ),
                    )
                  : _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null && _rows.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_error!, textAlign: TextAlign.center),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: _loadNextPage,
                                child: const Text('Coba Lagi'),
                              ),
                            ],
                          ),
                        )
                      : _rows.isEmpty
                          ? const Center(child: Text('Tidak ada data untuk di-preview.'))
                          : SingleChildScrollView(
                              controller: _scrollController,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  horizontalMargin: 6,
                                  columnSpacing: 8,
                                  headingRowHeight: 36,
                                  dataRowMinHeight: 32,
                                  dataRowMaxHeight: 36,
                                  headingRowColor: WidgetStateProperty.all(const Color(0xff02c0cc)),
                                  headingTextStyle: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  dataTextStyle: const TextStyle(
                                    color: Color(0xff465564),
                                    fontSize: 10,
                                  ),
                                  columns: const [
                                    DataColumn(label: Text('No')),
                                    DataColumn(label: Text('Nama Linen')),
                                    DataColumn(label: Text('Kategori Linen')),
                                    DataColumn(label: Text('Jumlah')),
                                    DataColumn(label: Text('Ruangan')),
                                  ],
                                  rows: _rows.asMap().entries.map((entry) {
                                    final item = entry.value;
                                    return DataRow(
                                      color: WidgetStateProperty.resolveWith<Color?>(
                                        (states) => entry.key.isEven
                                            ? const Color(0xfff5f6f8)
                                            : Colors.white,
                                      ),
                                      cells: [
                                      DataCell(Text('${entry.key + 1}', style: const TextStyle(fontSize: 10))),
                                      DataCell(Text(item.namaLinen.isEmpty ? '-' : item.namaLinen, style: const TextStyle(fontSize: 10))),
                                      DataCell(Text(item.namaKategoriLinen.isEmpty ? '-' : item.namaKategoriLinen, style: const TextStyle(fontSize: 10))),
                                      DataCell(Text(item.jumlah.isEmpty ? '-' : item.jumlah, style: const TextStyle(fontSize: 10))),
                                      DataCell(Text(item.keRuangan.isEmpty ? '-' : item.keRuangan, style: const TextStyle(fontSize: 10))),
                                    ]);
                                  }).toList(),
                                ),
                              ),
                            ),
            ),
            if (_loadingMore) const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 8),
                  Text('Memuat data berikutnya...', style: TextStyle(fontSize: 11)),
                ],
              ),
            ),
            if (_error != null && _rows.isNotEmpty)
              TextButton(onPressed: _loadNextPage, child: Text('Gagal memuat. Coba lagi')),
            const Divider(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Column(children: [
                  const Text('PETUGAS LINEN', textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  const SizedBox(height: 38),
                  Text(widget.userName.trim().isEmpty ? '-' : widget.userName.trim(),
                      textAlign: TextAlign.center),
                ])),
                Expanded(child: Column(children: [
                  const Text('PETUGAS LAUNDRY', textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  const SizedBox(height: 38),
                  Text(_petugasLaundry, textAlign: TextAlign.center),
                ])),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Menampilkan ${_rows.length}${_total == null ? '' : ' dari $_total'} data • maksimal 5.000 data',
              style: const TextStyle(color: Color(0xff7d8c99), fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _downloadingPdf ? null : () => Navigator.of(context).pop(),
          child: const Text('Tutup'),
        ),
        ElevatedButton.icon(
          onPressed: _downloadingPdf || _loading || _filterRoom == null ? null : _downloadPdf,
          icon: _downloadingPdf
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.picture_as_pdf_rounded),
          label: Text(_downloadingPdf ? 'Menyiapkan PDF...' : 'Download PDF'),
        ),
      ],
    );
  }
}
