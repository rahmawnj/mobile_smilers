import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../api/api_service.dart';
import '../../widgets/pagination_widget.dart';
import '../../widgets/shared_widgets.dart';
import '../../utils/linen_pdf_report.dart';
import 'linen_keluar_form_page.dart';

class LinenKeluarPage extends StatefulWidget {
  const LinenKeluarPage({super.key, required this.userName});
  final String userName;
  @override State<LinenKeluarPage> createState() => _LinenKeluarPageState();
}
class _LinenKeluarPageState extends State<LinenKeluarPage> {
  bool _loading=true,_optionsLoading=true,_queueLoading=true;
  bool _exporting=false;
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
  Future<List<LinenKeluarItem>> _loadAllKeluarRows(
    DateTimeRange? selectedRange,
    int? selectedRoom,
  ) async {
    if (selectedRoom == null) {
      throw const ApiException(
        'Pilih ruangan terlebih dahulu untuk mengunduh data Linen Keluar.',
      );
    }
    const maxRows = 5000;
    final rows = <LinenKeluarItem>[];
    var page = 1;
    var lastPage = 1;
    final search = _searchController.text.trim();
    do {
      final response = await ApiService.instance.getLinenKeluar(
        perPage: 100,
        page: page,
        search: search.isEmpty ? null : search,
        ruangan: selectedRoom,
        date: null,
        daterange: selectedRange == null ? null : _range(selectedRange),
      );
      lastPage = response.meta.lastPage;
      rows.addAll(response.data.take(maxRows - rows.length));
      page++;
    } while (page <= lastPage && rows.length < maxRows);
    return rows;
  }

  String _reportDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _reportPeriod(DateTimeRange? range) {
    if (range == null) return 'Semua Periode';
    String format(DateTime date) =>
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    return '${format(range.start)} - ${format(range.end)}';
  }

  Future<void> _downloadPdf() async {
    setState(() => _exporting = true);
    try {
      final rows = await _loadAllKeluarRows(
        _selectedDateRange,
        _filterRoom,
      );
      final appInfo = await ApiService.instance.getStoredAppInfo();
      if (!mounted) return;
      final room = _options?.ruangan
          .where((option) => option.id == _filterRoom)
          .map((option) => option.namaRuangan)
          .firstOrNull;
      final search = _searchController.text.trim();
      final bytes = await createLinenPdfReport(
        title: 'Laporan Linen & Tirai Keluar',
        organizationName: appInfo?.appName.trim().isNotEmpty == true
            ? appInfo!.appName.trim()
            : 'Rumah Sakit',
        organizationAddress: appInfo?.appAddress.trim().isNotEmpty == true
            ? appInfo!.appAddress.trim()
            : 'Alamat rumah sakit',
        period: _reportPeriod(_selectedDateRange),
        printedDate: _reportDate(DateTime.now()),
        linenOfficer: widget.userName.trim().isEmpty ? '-' : widget.userName.trim(),
        laundryOfficer: rows
            .map((item) => item.user.trim())
            .firstWhere((name) => name.isNotEmpty, orElse: () => '-'),
        room: room,
        search: search.isEmpty ? null : search,
        rows: rows.asMap().entries.map((entry) {
          final item = entry.value;
          return [
            '${entry.key + 1}',
            item.namaLinen.isEmpty ? '-' : item.namaLinen,
            item.namaKategoriLinen.isEmpty ? '-' : item.namaKategoriLinen,
            item.jumlah.isEmpty ? '-' : item.jumlah,
            item.keRuangan.isEmpty ? '-' : item.keRuangan,
          ];
        }).toList(growable: false),
      );
      await FilePicker.saveFile(
        dialogTitle: 'Simpan PDF Linen & Tirai Keluar',
        fileName: 'linen_tirai_keluar.pdf',
        mimeType: 'application/pdf',
        bytes: Uint8List.fromList(bytes),
      );
    } catch (e) {
      if (!mounted) return;
      final message =
          e is ApiException ? e.message : 'Gagal mengunduh PDF: $e';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
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
            top: 90,
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
            onPressed: _exporting ? null : _downloadPdf,
            tooltip: 'Download PDF',
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xffeaf2ff),
              foregroundColor: const Color(0xff1261dc),
              minimumSize: const Size(44, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: _exporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf_rounded, size: 21),
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
            top: 90,
            left: 0,
            right: 0,
            height: 30,
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
