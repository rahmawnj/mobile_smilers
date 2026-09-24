import 'package:flutter/material.dart';

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
  DateTime? _selectedDate;
  DateTimeRange? _selectedDateRange;

  @override void initState(){super.initState();_loadOptions();_load();_loadQueue();}
  @override void dispose(){_searchController.dispose();super.dispose();}
  String _date(DateTime d)=>'${d.month}/${d.day}/${d.year}';
  String _range(DateTimeRange r)=>'${_date(r.start)} - ${_date(r.end)}';

  Future<void> _loadOptions() async {
    try {
      final o=await ApiService.instance.getLinenKeluarOptions();
      if(!mounted)return;
      setState(()=>_options=o);
    } catch (_) {} finally { if(mounted)setState(()=>_optionsLoading=false); }
  }
  Future<void> _load() async {
    setState(()=>_loading=true);
    try {
      final r=await ApiService.instance.getLinenKeluar(
        perPage:_perPage,page:_page,
        search:_searchController.text.trim().isEmpty?null:_searchController.text.trim(),
        ruangan:_filterRoom,date:_selectedDate==null?null:_date(_selectedDate!),
        daterange:_selectedDateRange==null?null:_range(_selectedDateRange!));
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
  Future<void> _pickDate() async {
    final d=await showDatePicker(context:context,initialDate:_selectedDate??DateTime.now(),firstDate:DateTime(2020),lastDate:DateTime(2100));
    if(d!=null){setState(()=>{_selectedDate=d,_selectedDateRange=null,_page=1});_load();}
  }
  Future<void> _pickRange() async {
    final r=await showDateRangePicker(context:context,firstDate:DateTime(2020),lastDate:DateTime(2100),initialDateRange:_selectedDateRange);
    if(r!=null){setState(()=>{_selectedDateRange=r,_selectedDate=null,_page=1});_load();}
  }
  void _reset(){_searchController.clear();setState(()=>{_filterRoom=null,_selectedDate=null,_selectedDateRange=null,_page=1});_load();}

  @override Widget build(BuildContext context) {
    final rows=_response?.data??const <LinenKeluarItem>[];
    final meta=_response?.meta;
    return AppShell(userName:widget.userName,activeIndex:-1,body:Column(children:[
      DetailHeader(title:'Linen & Tirai Keluar',userName:widget.userName),
      Expanded(child:RefreshIndicator(onRefresh:() async=>Future.wait([_load(),_loadQueue()]),child:ListView(padding:const EdgeInsets.fromLTRB(16,14,16,100),children:[
        Row(children:[
          Expanded(child:TextField(controller:_searchController,onSubmitted:(_){setState(()=>_page=1);_load();},decoration:InputDecoration(
            hintText:'Cari nama linen, RFID, QR Code, user...',prefixIcon:const Icon(Icons.search_rounded),filled:true,fillColor:Colors.white,
            border:OutlineInputBorder(borderRadius:BorderRadius.circular(20),borderSide:BorderSide.none)))),
          const SizedBox(width:8),
          ElevatedButton.icon(
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => LinenKeluarScanPage(userName: widget.userName),
                ),
              );
              if (mounted) await _load();
            },
            icon: const Icon(Icons.qr_code_scanner_rounded),
            label: const Text('Scan'),
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
                items:[const DropdownMenuItem<int?>(value:null,child:Text('Semua Ruangan')), ...?_options?.ruangan.map((r)=>DropdownMenuItem<int?>(value:r.id,child:Text(r.namaRuangan)))],
                onChanged:(v){setState(()=>{_filterRoom=v,_page=1});_load();},
              )),
              const SizedBox(width:8),
              Expanded(child:OutlinedButton.icon(onPressed:_pickDate,icon:const Icon(Icons.event_rounded),label:Text(_selectedDate==null?'Tanggal':_date(_selectedDate!)))),
              const SizedBox(width:8),
              Expanded(child:OutlinedButton.icon(onPressed:_pickRange,icon:const Icon(Icons.date_range_rounded),label:Text(_selectedDateRange==null?'Rentang Tanggal':_range(_selectedDateRange!)))),
              IconButton(onPressed:_reset,tooltip:'Reset filter',icon:const Icon(Icons.filter_alt_off_rounded)),
            ]),
          ]),
        ),
        const SizedBox(height:12),
        InkWell(
          onTap: () async {
            final saved = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => LinenKeluarFormPage(userName: widget.userName),
              ),
            );
            if (saved == true && mounted) {
              await Future.wait([_load(), _loadQueue()]);
            }
          },
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: double.infinity,
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
            child: const Row(
              children: [
                Icon(
                  Icons.assignment_rounded,
                  color: Color(0xff159cf1),
                  size: 26,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Form Linen Keluar',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Isi ruangan tujuan, user, lalu lanjut ke halaman scan.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
        const SizedBox(height:12),
        if(_loading)const Center(child:Padding(padding:EdgeInsets.all(30),child:CircularProgressIndicator()))
        else if(_error!=null)Padding(padding:const EdgeInsets.all(24),child:Column(children:[const Icon(Icons.cloud_off_rounded),const SizedBox(height:10),Text(_error!,textAlign:TextAlign.center),const SizedBox(height:12),ElevatedButton(onPressed:_load,child:const Text('Coba Lagi'))]))
        else Container(width:double.infinity,child:SingleChildScrollView(scrollDirection:Axis.horizontal,child:DataTable(
          headingRowColor:WidgetStateProperty.all(const Color(0xff1261dc)),headingTextStyle:const TextStyle(color:Colors.white,fontSize:9,fontWeight:FontWeight.w700),dataTextStyle:const TextStyle(fontSize:9),columnSpacing:22,
          columns:const [DataColumn(label:Text('No.')),DataColumn(label:Text('Nama Linen')),DataColumn(label:Text('QR Code')),DataColumn(label:Text('RFID')),DataColumn(label:Text('Ke Ruangan')),DataColumn(label:Text('Jam')),DataColumn(label:Text('Tanggal')),DataColumn(label:Text('User'))],
          rows:rows.asMap().entries.map((e){final n=((meta?.currentPage??_page)-1)*(meta?.perPage??_perPage)+e.key+1;return DataRow(cells:[DataCell(Text('${n}')),DataCell(Text(e.value.namaLinen)),DataCell(Text(e.value.qrCode)),DataCell(Text(e.value.tagRfid)),DataCell(Text(e.value.keRuangan)),DataCell(Text(e.value.jam)),DataCell(Text(e.value.tanggal)),DataCell(Text(e.value.user))]);}).toList(),
        ))),
        if(!_loading&&_error==null&&rows.isEmpty)const Padding(padding:EdgeInsets.all(24),child:Center(child:Text('Tidak ada data Linen & Tirai Keluar.'))),
        if(meta!=null)Row(children:[const Text('Tampilkan',style:TextStyle(fontSize:9)),const SizedBox(width:8),DropdownButton<int>(value:_perPage,items:const [10,25,50,100].map((v)=>DropdownMenuItem(value:v,child:Text('${v}'))).toList(),onChanged:(v){if(v==null)return;setState(()=>{_perPage=v,_page=1});_load();}),const Spacer(),Text('Total ${meta.total}',style:const TextStyle(fontSize:9))]),
        if(meta!=null)AppPagination(meta:meta,onPage:(p){setState(()=>_page=p);_load();}),
      ]))),
    ]));
  }
}
