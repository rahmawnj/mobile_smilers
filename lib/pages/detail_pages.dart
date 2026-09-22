import 'package:flutter/material.dart';

import '../api/api_service.dart';
import '../widgets/shared_widgets.dart';

class LinenCategoryDetailPage extends StatefulWidget {
  const LinenCategoryDetailPage({
    super.key,
    required this.category,
    required this.userName,
  });

  final LinenCategory category;
  final String userName;

  @override
  State<LinenCategoryDetailPage> createState() => _LinenCategoryDetailPageState();
}

class _LinenCategoryDetailPageState extends State<LinenCategoryDetailPage> {
  bool _loading = true;
  String? _error;
  LinenCategory? _detail;
  LinenItemsResponse? _items;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        ApiService.instance.getLinenCategory(widget.category.id),
        ApiService.instance.getLinenItems(widget.category.id, perPage: 10),
      ]);

      if (!mounted) return;
      setState(() {
        _detail = results[0] as LinenCategory;
        _items = results[1] as LinenItemsResponse;
        _loading = false;
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
        _error = 'Tidak dapat mengambil detail linen dari server.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail ?? widget.category;

    return AppShell(
      userName: widget.userName,
      activeIndex: 0,
      body: Column(
        children: [
          DetailHeader(
            title: detail.namaKategoriLinen,
            userName: widget.userName,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: _loading
                    ? const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : _error != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  const Icon(Icons.cloud_off_rounded),
                                  const SizedBox(height: 10),
                                  Text(_error!, textAlign: TextAlign.center),
                                  const SizedBox(height: 12),
                                  ElevatedButton(
                                    onPressed: _load,
                                    child: const Text('Coba Lagi'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _CategoryInfo(detail: detail),
                              const SizedBox(height: 18),
                              const SectionTitle(title: 'Detail Linen Ready'),
                              const SizedBox(height: 8),
                              if (_items!.data.isEmpty)
                                const _EmptyDetail(message: 'Tidak ada item linen ready.')
                              else
                                DetailTable(
                                  columns: const [
                                    'ID',
                                    'Kode Linen',
                                    'Tag RFID',
                                    'QR Code',
                                    'Status',
                                  ],
                                  rows: _items!.data
                                      .map(
                                        (item) => [
                                          item.id,
                                          item.kodeLinen,
                                          item.tagRfid,
                                          item.qrCode,
                                          item.status,
                                        ],
                                      )
                                      .toList(),
                                ),
                              const SizedBox(height: 12),
                              Text(
                                'Halaman ' +
                                    _items!.meta.currentPage.toString() +
                                    ' dari ' +
                                    _items!.meta.lastPage.toString() +
                                    ' • Total ' +
                                    _items!.meta.total.toString() +
                                    ' item',
                                style: const TextStyle(
                                  color: Color(0xff8b99a5),
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryInfo extends StatelessWidget {
  const _CategoryInfo({required this.detail});

  final LinenCategory detail;

  @override
  Widget build(BuildContext context) {
    final sub = detail.subKategoriLinen.trim().isEmpty
        ? 'Tidak ada sub kategori'
        : detail.subKategoriLinen;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kategori Linen',
            style: TextStyle(
              color: Color(0xff8b99a5),
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            detail.namaKategoriLinen,
            style: const TextStyle(
              color: Color(0xff34495e),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: const TextStyle(
              color: Color(0xff8b99a5),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyDetail extends StatelessWidget {
  const _EmptyDetail({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(message, textAlign: TextAlign.center),
    );
  }
}


class InOutPage extends StatefulWidget {
  const InOutPage({super.key, required this.userName});
  final String userName;
  @override
  State<InOutPage> createState() => _InOutPageState();
}

class _InOutPageState extends State<InOutPage> {
  bool _loading = true;
  String? _error;
  InOutResponse? _response;
  final _searchController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _dateParam(DateTime d) =>
      '${d.month}/${d.day}/${d.year} - ${d.month}/${d.day}/${d.year}';

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final r = await ApiService.instance.getInOut(
        perPage: 10,
        search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        daterange: _selectedDate == null ? null : _dateParam(_selectedDate!),
      );
      if (!mounted) return;
      setState(() { _response = r; _loading = false; });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _error = 'Tidak dapat mengambil data Keluar Masuk dari server.'; _loading = false; });
    }
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d != null) {
      setState(() => _selectedDate = d);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = _response?.data ?? const <Map<String,dynamic>>[];
    return AppShell(
      userName: widget.userName,
      activeIndex: 1,
      body: Column(
        children: [
          DetailHeader(title: 'Keluar Masuk Linen & Tirai', userName: widget.userName),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: (_) => _load(),
                    decoration: InputDecoration(
                      hintText: 'Cari ruangan...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _pickDate,
                  tooltip: 'Pilih tanggal',
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xff1261dc),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.calendar_month_rounded, size: 20),
                ),
              ],
            ),
          ),
          if (_selectedDate != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: Row(
                children: [
                  Text(
                    'Tanggal: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                    style: const TextStyle(fontSize: 9, color: Color(0xff6f7f8d)),
                  ),
                  const Spacer(),
                  TextButton(onPressed: () { setState(() => _selectedDate = null); _load(); }, child: const Text('Reset')),
                ],
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: _loading
                    ? const Padding(padding: EdgeInsets.all(50), child: Center(child: CircularProgressIndicator()))
                    : _error != null
                        ? _InOutError(message: _error!, onRetry: _load)
                        : rows.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(40),
                                child: Center(child: Text('Tidak ada data Keluar Masuk Linen & Tirai.')),
                              )
                            : _InOutTable(rows: rows),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InOutTable extends StatelessWidget {
  const _InOutTable({required this.rows});
  final List<Map<String,dynamic>> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .05), blurRadius: 18, offset: const Offset(0, 7))],
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xff1261dc)),
          headingTextStyle: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
          dataTextStyle: const TextStyle(color: Color(0xff465564), fontSize: 9),
          columnSpacing: 28,
          columns: const [
            DataColumn(label: Text('Ruangan')),
            DataColumn(label: Text('Masuk')),
            DataColumn(label: Text('Keluar')),
            DataColumn(label: Text('Selisih')),
          ],
          rows: rows.map((r) => DataRow(cells: [
            DataCell(Text(r['nama_ruangan']?.toString() ?? '-')),
            DataCell(Text(r['linen_masuk']?.toString() ?? '0')),
            DataCell(Text(r['linen_keluar']?.toString() ?? '0')),
            DataCell(Text(r['selisih']?.toString() ?? '0')),
          ])).toList(),
        ),
      ),
    );
  }
}

class _InOutError extends StatelessWidget {
  const _InOutError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      children: [
        const SizedBox(height: 40),
        const Icon(Icons.cloud_off_rounded, size: 36, color: Color(0xffef6c6c)),
        const SizedBox(height: 10),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: onRetry, child: const Text('Coba Lagi')),
      ],
    ),
  );
}




class LinenBelumKembaliPage extends StatefulWidget { const LinenBelumKembaliPage({super.key, required this.userName}); final String userName; @override State<LinenBelumKembaliPage> createState()=>_LinenBelumKembaliPageState(); }
class _LinenBelumKembaliPageState extends State<LinenBelumKembaliPage> { bool _loading=true; String? _error; LinenBelumKembaliResponse? _response; List<LinenRoomOption> _rooms=const []; int? _roomId; DateTimeRange? _range; final _searchController=TextEditingController(); @override void initState(){super.initState();_load();_loadRooms();} @override void dispose(){_searchController.dispose();super.dispose();} String _date(DateTime d)=>d.day.toString()+'/'+d.month.toString()+'/'+d.year.toString(); String? get _daterange=>_range==null?null:_date(_range!.start)+' - '+_date(_range!.end);
Future<void> _loadRooms() async {try{final rooms=await ApiService.instance.getLinenBelumKembaliRuangan();if(mounted)setState(()=>_rooms=rooms);}catch(_){}}
Future<void> _load() async {setState((){_loading=true;_error=null;});try{final r=await ApiService.instance.getLinenBelumKembali(perPage:10,search:_searchController.text.trim().isEmpty?null:_searchController.text.trim(),ruangan:_roomId,daterange:_daterange);if(!mounted)return;setState((){_response=r;_loading=false;});}on ApiException catch(e){if(mounted)setState((){_error=e.message;_loading=false;});}catch(_){if(mounted)setState((){_error='Tidak dapat mengambil data Linen Belum Kembali.';_loading=false;});}}
Future<void> _pickRange() async {final r=await showDateRangePicker(context:context,firstDate:DateTime(2020),lastDate:DateTime(2100),initialDateRange:_range);if(r!=null){setState(()=>_range=r);_load();}}
@override Widget build(BuildContext context){final rows=_response?.data??const <LinenBelumKembaliItem>[];return AppShell(userName:widget.userName,activeIndex:4,body:Column(children:[DetailHeader(title:'Linen Belum Kembali',userName:widget.userName),Padding(padding:const EdgeInsets.fromLTRB(16,14,16,8),child:Row(children:[Expanded(child:TextField(controller:_searchController,onSubmitted:(_)=>_load(),decoration:InputDecoration(hintText:'Cari linen / ruangan...',prefixIcon:const Icon(Icons.search_rounded,size:20),filled:true,fillColor:Colors.white,border:OutlineInputBorder(borderRadius:BorderRadius.circular(14),borderSide:BorderSide.none)))),const SizedBox(width:8),IconButton(onPressed:_pickRange,style:IconButton.styleFrom(backgroundColor:const Color(0xff1261dc),foregroundColor:Colors.white),icon:const Icon(Icons.date_range_rounded,size:20))])),Padding(padding:const EdgeInsets.fromLTRB(16,0,16,6),child:DropdownButtonFormField<int?>(value:_roomId,isExpanded:true,decoration:InputDecoration(hintText:'Semua Ruangan',prefixIcon:const Icon(Icons.meeting_room_rounded,size:19),filled:true,fillColor:Colors.white,border:OutlineInputBorder(borderRadius:BorderRadius.circular(14),borderSide:BorderSide.none)),items:[const DropdownMenuItem<int?>(value:null,child:Text('Semua Ruangan')),..._rooms.map((r)=>DropdownMenuItem<int?>(value:r.id,child:Text(r.nama)))],onChanged:(v){setState(()=>_roomId=v);_load();})),if(_range!=null)Padding(padding:const EdgeInsets.symmetric(horizontal:16),child:Row(children:[Expanded(child:Text('Periode: '+_date(_range!.start)+' - '+_date(_range!.end),style:const TextStyle(fontSize:9,color:Color(0xff6f7f8d)))),TextButton(onPressed:(){setState(()=>_range=null);_load();},child:const Text('Reset'))])),Expanded(child:RefreshIndicator(onRefresh:_load,child:SingleChildScrollView(physics:const AlwaysScrollableScrollPhysics(),padding:const EdgeInsets.fromLTRB(16,8,16,20),child:_loading?const Padding(padding:EdgeInsets.all(50),child:Center(child:CircularProgressIndicator())):_error!=null?_BelumKembaliError(message:_error!,onRetry:_load):rows.isEmpty?const Padding(padding:EdgeInsets.all(40),child:Center(child:Text('Tidak ada linen yang belum kembali.'))):_BelumKembaliTable(rows:rows))))]));}}
class _BelumKembaliTable extends StatelessWidget {
  const _BelumKembaliTable({required this.rows});

  final List<LinenBelumKembaliItem> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xff1261dc)),
          headingTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
          dataTextStyle: const TextStyle(
            color: Color(0xff465564),
            fontSize: 9,
          ),
          columnSpacing: 24,
          columns: const [
            DataColumn(label: Text('ID')),
            DataColumn(label: Text('QR Code')),
            DataColumn(label: Text('Nama Linen')),
            DataColumn(label: Text('RFID')),
            DataColumn(label: Text('Ruangan')),
            DataColumn(label: Text('Kategori')),
            DataColumn(label: Text('Tanggal Keluar')),
            DataColumn(label: Text('Jam')),
          ],
          rows: rows.map((item) {
            return DataRow(
              cells: [
                DataCell(Text(item.id.toString())),
                DataCell(Text(item.qrCode.isEmpty ? '-' : item.qrCode)),
                DataCell(Text(item.namaLinen.isEmpty ? '-' : item.namaLinen)),
                DataCell(Text(item.tagRfid.isEmpty ? '-' : item.tagRfid)),
                DataCell(Text(item.namaRuangan.isEmpty ? '-' : item.namaRuangan)),
                DataCell(Text(item.namaKategori.isEmpty ? '-' : item.namaKategori)),
                DataCell(Text(item.tanggalKeluar.isEmpty ? '-' : item.tanggalKeluar)),
                DataCell(Text(item.jamKeluar.isEmpty ? '-' : item.jamKeluar)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _BelumKembaliError extends StatelessWidget {
  const _BelumKembaliError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          const Icon(
            Icons.cloud_off_rounded,
            size: 36,
            color: Color(0xffef6c6c),
          ),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}

class RekapanTransaksiPage extends StatefulWidget {
  const RekapanTransaksiPage({super.key, required this.userName});
  final String userName;
  @override
  State<RekapanTransaksiPage> createState() => _RekapanTransaksiPageState();
}

class _RekapanTransaksiPageState extends State<RekapanTransaksiPage> {
  bool _loading = true;
  String? _error;
  RekapanTransaksiResponse? _response;
  List<LinenRoomOption> _rooms = const [];
  int? _roomId;
  DateTimeRange? _range;

  @override
  void initState() { super.initState(); _load(); _loadRooms(); }

  String _date(DateTime d) => '${d.month}/${d.day}/${d.year}';
  String? get _daterange => _range == null ? null : '${_date(_range!.start)} - ${_date(_range!.end)}';

  Future<void> _loadRooms() async {
    try {
      final rooms = await ApiService.instance.getRekapanTransaksiRuangan();
      if (mounted) setState(() => _rooms = rooms);
    } catch (_) {}
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final r = await ApiService.instance.getRekapanTransaksi(daterange: _daterange, ruangan: _roomId);
      if (!mounted) return;
      setState(() { _response = r; _loading = false; });
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _error = 'Tidak dapat mengambil Rekapan Transaksi.'; _loading = false; });
    }
  }

  Future<void> _pickRange() async {
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: _range,
    );
    if (r != null) { setState(() => _range = r); _load(); }
  }

  @override
  Widget build(BuildContext context) {
    final summary = _response?.ringkasan;
    final rows = _response?.data ?? const <RekapanTransaksiItem>[];
    return AppShell(
      userName: widget.userName,
      activeIndex: 3,
      body: Column(
        children: [
          DetailHeader(title: 'Rekapan Transaksi', userName: widget.userName),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(children: [
              Expanded(
                child: DropdownButtonFormField<int?>(
                  value: _roomId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    hintText: 'Semua Ruangan',
                    prefixIcon: const Icon(Icons.meeting_room_rounded, size: 19),
                    filled: true, fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('Semua Ruangan')),
                    ..._rooms.map((r) => DropdownMenuItem<int?>(value: r.id, child: Text(r.nama))),
                  ],
                  onChanged: (v) { setState(() => _roomId = v); _load(); },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _pickRange,
                tooltip: 'Pilih rentang tanggal',
                style: IconButton.styleFrom(backgroundColor: const Color(0xff1261dc), foregroundColor: Colors.white),
                icon: const Icon(Icons.date_range_rounded, size: 20),
              ),
            ]),
          ),
          if (_range != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                Expanded(child: Text('Periode: ${_date(_range!.start)} - ${_date(_range!.end)}', style: const TextStyle(fontSize: 9, color: Color(0xff6f7f8d)))),
                TextButton(onPressed: () { setState(() => _range = null); _load(); }, child: const Text('Reset')),
              ]),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: _loading
                  ? const Padding(padding: EdgeInsets.all(50), child: Center(child: CircularProgressIndicator()))
                  : _error != null
                    ? Center(child: Column(children: [const SizedBox(height:40), const Icon(Icons.cloud_off_rounded,size:36), const SizedBox(height:10), Text(_error!,textAlign:TextAlign.center), const SizedBox(height:12), ElevatedButton(onPressed:_load,child:const Text('Coba Lagi'))]))
                    : Column(children: [
                        if (summary != null) _RekapSummary(summary: summary),
                        const SizedBox(height: 12),
                        if (rows.isEmpty) const Padding(padding: EdgeInsets.all(40),child: Text('Tidak ada data Rekapan Transaksi.'))
                        else _RekapTable(rows: rows),
                      ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RekapSummary extends StatelessWidget {
  const _RekapSummary({required this.summary});
  final RekapanTransaksiSummary summary;
  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: _RekapCard(title:'Linen Keluar',value:'${summary.totalLinenKeluar}',icon:Icons.arrow_upward_rounded)),
    const SizedBox(width:8),
    Expanded(child: _RekapCard(title:'Linen Masuk',value:'${summary.totalLinenMasuk}',icon:Icons.arrow_downward_rounded)),
    const SizedBox(width:8),
    Expanded(child: _RekapCard(title:'Berat Masuk',value:'${summary.totalBeratMasuk}',icon:Icons.scale_rounded)),
  ]);
}
class _RekapCard extends StatelessWidget {
  const _RekapCard({required this.title,required this.value,required this.icon});
  final String title,value; final IconData icon;
  @override
  Widget build(BuildContext context)=>Container(padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(16)),child:Column(children:[Icon(icon,size:20,color:const Color(0xff1261dc)),const SizedBox(height:6),Text(value,style:const TextStyle(fontSize:18,fontWeight:FontWeight.w800)),const SizedBox(height:2),Text(title,textAlign:TextAlign.center,style:const TextStyle(fontSize:8,color:Color(0xff6f7f8d))) ]));
}
class _RekapTable extends StatelessWidget {
  const _RekapTable({required this.rows}); final List<RekapanTransaksiItem> rows;
  @override
  Widget build(BuildContext context)=>Container(decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(18)),clipBehavior:Clip.antiAlias,child:SingleChildScrollView(scrollDirection:Axis.horizontal,child:DataTable(
    headingRowColor:WidgetStateProperty.all(const Color(0xff1261dc)),
    headingTextStyle:const TextStyle(color:Colors.white,fontSize:9,fontWeight:FontWeight.w700),
    dataTextStyle:const TextStyle(color:Color(0xff465564),fontSize:9),
    columns:const [DataColumn(label:Text('Tanggal')),DataColumn(label:Text('Keluar')),DataColumn(label:Text('Masuk')),DataColumn(label:Text('Berat Masuk'))],
    rows:rows.map((r)=>DataRow(cells:[DataCell(Text(r.tanggal)),DataCell(Text('${r.jumlahLinenKeluar}')),DataCell(Text('${r.jumlahLinenMasuk}')),DataCell(Text('${r.beratLinenMasuk}'))])).toList(),
  )));
}


class LinenLaundryPage extends StatefulWidget {
  const LinenLaundryPage({super.key, required this.userName});
  final String userName;
  @override State<LinenLaundryPage> createState() => _LinenLaundryPageState();
}

class _LinenLaundryPageState extends State<LinenLaundryPage> {
  bool _loading = true; String? _error; List<LinenLaundryItem> _items = const []; String? _selectedCategory;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final response = await ApiService.instance.getLinenLaundry(perPage: 1000);
      if (!mounted) return;
      setState(() { _items = response.data; _loading = false; });
    } on ApiException catch (e) {
      if (!mounted) return; setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      if (!mounted) return; setState(() { _error = 'Tidak dapat mengambil data Linen & Tirai di Laundry.'; _loading = false; });
    }
  }
  void _openDetail(LinenLaundryItem item) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => LinenLaundryDetailPage(categoryId: item.id, categoryName: item.namaKategoriLinen, userName: widget.userName)));
  }
  @override Widget build(BuildContext context) {
    final categoryNames = _items.map((i) => i.namaKategoriLinen.trim()).where((n) => n.isNotEmpty).toSet().toList()..sort();
    final filtered = _selectedCategory == null ? _items : _items.where((i) => i.namaKategoriLinen.trim() == _selectedCategory).toList();
    return AppShell(userName: widget.userName, activeIndex: 0, body: Column(children: [
      DetailHeader(title: 'Linen & Tirai di Laundry', userName: widget.userName),
      Expanded(child: RefreshIndicator(onRefresh: _load, child: _loading ? const Center(child: CircularProgressIndicator()) : _error != null ? ListView(children: [Padding(padding: const EdgeInsets.all(24), child: Column(children: [const Icon(Icons.cloud_off_rounded), const SizedBox(height: 10), Text('_error!', textAlign: TextAlign.center), const SizedBox(height: 12), ElevatedButton(onPressed: _load, child: const Text('Coba Lagi'))]))]) : ListView(padding: const EdgeInsets.fromLTRB(16,14,16,24), children: [
        Container(width: double.infinity, padding: const EdgeInsets.fromLTRB(14,4,14,4), decoration: BoxDecoration(color: Colors.white,borderRadius: BorderRadius.circular(14)), child: DropdownButtonHideUnderline(child: DropdownButton<String?>(value: _selectedCategory,isExpanded:true,hint:const Text('Filter Kategori'),items:[const DropdownMenuItem<String?>(value:null,child:Text('Semua Kategori')),...categoryNames.map((n)=>DropdownMenuItem<String?>(value:n,child:Text(n)))],onChanged:(v)=>setState(()=>_selectedCategory=v)))),
        const SizedBox(height: 12),
        Container(width: double.infinity, decoration: BoxDecoration(color: Colors.white,borderRadius: BorderRadius.circular(18),boxShadow:[BoxShadow(color:Colors.black.withValues(alpha:.05),blurRadius:18,offset:const Offset(0,7))]),clipBehavior:Clip.antiAlias, child: LayoutBuilder(builder:(context,constraints){ final width=constraints.maxWidth<680?680.0:constraints.maxWidth; return SingleChildScrollView(scrollDirection:Axis.horizontal,child:SizedBox(width:width,child:DataTable(headingRowColor:WidgetStateProperty.all(const Color(0xff1261dc)),headingTextStyle:const TextStyle(color:Colors.white,fontSize:9,fontWeight:FontWeight.w700),dataTextStyle:const TextStyle(color:Color(0xff465564),fontSize:9),columnSpacing:28,horizontalMargin:16,columns:const [DataColumn(label:Text('Nama Category')),DataColumn(label:Text('Nama Linen')),DataColumn(label:Text('Ready')),DataColumn(label:Text('Action'))],rows:filtered.map((item)=>DataRow(cells:[DataCell(Text(item.namaKategoriLinen)),DataCell(Text(item.namaLinen)),DataCell(Text(item.ready.toString())),DataCell(TextButton(onPressed:()=>_openDetail(item),child:const Text('Detail')))])).toList()))); })),
        if(filtered.isEmpty) const Padding(padding:EdgeInsets.all(24),child:Center(child:Text('Tidak ada data untuk kategori ini.'))),
      ]))),
    ]));
  }
}

class LinenLaundryDetailPage extends StatefulWidget {
  const LinenLaundryDetailPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.userName,
  });

  final int categoryId;
  final String categoryName;
  final String userName;

  @override
  State<LinenLaundryDetailPage> createState() =>
      _LinenLaundryDetailPageState();
}

class _LinenLaundryDetailPageState extends State<LinenLaundryDetailPage> {
  bool _loading = true;
  String? _error;
  LinenLaundryDetailResponse? _response;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await ApiService.instance.getLinenLaundryCategory(
        widget.categoryId,
        perPage: 1000,
      );

      if (!mounted) return;

      setState(() {
        _response = response;
        _loading = false;
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
        _error = 'Tidak dapat mengambil detail Linen & Tirai di Laundry.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = _response?.data ?? const <LinenLaundryDetailItem>[];

    return AppShell(
      userName: widget.userName,
      activeIndex: 0,
      body: Column(
        children: [
          DetailHeader(
            title: 'Detail Laundry - ${widget.categoryName}',
            userName: widget.userName,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? ListView(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  const Icon(Icons.cloud_off_rounded),
                                  const SizedBox(height: 10),
                                  Text(_error!, textAlign: TextAlign.center),
                                  const SizedBox(height: 12),
                                  ElevatedButton(
                                    onPressed: _load,
                                    child: const Text('Coba Lagi'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : rows.isEmpty
                          ? ListView(
                              children: const [
                                Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Text(
                                    'Belum ada detail linen di laundry.',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            )
                          : ListView(
                              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                              children: [
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      final tableWidth =
                                          constraints.maxWidth < 680
                                              ? 680.0
                                              : constraints.maxWidth;

                                      return SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: SizedBox(
                                          width: tableWidth,
                                          child: DataTable(
                                            headingRowColor:
                                                WidgetStateProperty.all(
                                              const Color(0xff1261dc),
                                            ),
                                            headingTextStyle: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                            ),
                                            dataTextStyle: const TextStyle(
                                              color: Color(0xff465564),
                                              fontSize: 9,
                                            ),
                                            columnSpacing: 28,
                                            horizontalMargin: 16,
                                            columns: const [
                                              DataColumn(label: Text('ID')),
                                              DataColumn(
                                                label: Text('Kode Linen'),
                                              ),
                                              DataColumn(
                                                label: Text('Nama Linen'),
                                              ),
                                              DataColumn(
                                                label: Text('Nama Category'),
                                              ),
                                              DataColumn(
                                                label: Text('Jumlah Pencucian'),
                                              ),
                                            ],
                                            rows: rows
                                                .map(
                                                  (item) => DataRow(
                                                    cells: [
                                                      DataCell(
                                                        Text(item.id.toString()),
                                                      ),
                                                      DataCell(
                                                        Text(
                                                          item.kodeLinen.isEmpty
                                                              ? '-'
                                                              : item.kodeLinen,
                                                        ),
                                                      ),
                                                      DataCell(
                                                        Text(
                                                          item.namaLinen.isEmpty
                                                              ? '-'
                                                              : item.namaLinen,
                                                        ),
                                                      ),
                                                      DataCell(
                                                        Text(
                                                          item.namaKategoriLinen
                                                                  .isEmpty
                                                              ? '-'
                                                              : item.namaKategoriLinen,
                                                        ),
                                                      ),
                                                      DataCell(
                                                        Text(
                                                          item.jumlahPencucian
                                                              .toString(),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                )
                                                .toList(),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
            ),
          ),
        ],
      ),
    );
  }
}

class LinenRuanganPage extends StatefulWidget {
  const LinenRuanganPage({super.key, required this.userName});
  final String userName;

  @override
  State<LinenRuanganPage> createState() => _LinenRuanganPageState();
}

class _LinenRuanganPageState extends State<LinenRuanganPage> {
  bool _loading = true;
  String? _error;
  List<LinenRuanganItem> _items = const [];
  String? _search;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await ApiService.instance.getLinenRuangan(
        search: _search,
        perPage: 1000,
      );
      if (!mounted) return;
      setState(() {
        _items = response.data;
        _loading = false;
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
        _error = 'Tidak dapat mengambil data Linen & Tirai di Ruangan.';
        _loading = false;
      });
    }
  }

  void _openDetail(LinenRuanganItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LinenRuanganDetailPage(
          roomId: item.id,
          roomName: item.namaRuangan,
          userName: widget.userName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      userName: widget.userName,
      activeIndex: 0,
      body: Column(
        children: [
          DetailHeader(
            title: 'Linen & Tirai di Ruangan',
            userName: widget.userName,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: TextField(
              controller: _searchController,
              onSubmitted: (value) {
                _search = value.trim().isEmpty ? null : value.trim();
                _load();
              },
              decoration: InputDecoration(
                hintText: 'Cari ruangan...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? ListView(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  const Icon(Icons.cloud_off_rounded),
                                  const SizedBox(height: 10),
                                  Text(_error!, textAlign: TextAlign.center),
                                  const SizedBox(height: 12),
                                  ElevatedButton(
                                    onPressed: _load,
                                    child: const Text('Coba Lagi'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : _items.isEmpty
                          ? ListView(
                              children: const [
                                Padding(
                                  padding: EdgeInsets.all(40),
                                  child: Center(
                                    child: Text(
                                      'Tidak ada data Linen & Tirai di Ruangan.',
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : ListView(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              children: [
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: .05),
                                        blurRadius: 18,
                                        offset: const Offset(0, 7),
                                      ),
                                    ],
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      final tableWidth =
                                          constraints.maxWidth < 680
                                              ? 680.0
                                              : constraints.maxWidth;
                                      return SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: SizedBox(
                                          width: tableWidth,
                                          child: DataTable(
                                            headingRowColor:
                                                WidgetStateProperty.all(
                                              const Color(0xff1261dc),
                                            ),
                                            headingTextStyle: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                            ),
                                            dataTextStyle: const TextStyle(
                                              color: Color(0xff465564),
                                              fontSize: 9,
                                            ),
                                            columnSpacing: 28,
                                            horizontalMargin: 16,
                                            columns: const [
                                              DataColumn(
                                                label: Text('Nama Ruangan'),
                                              ),
                                              DataColumn(
                                                label: Text('Stok Awal'),
                                              ),
                                              DataColumn(label: Text('Hilang')),
                                              DataColumn(
                                                label: Text('Linen di Ruangan'),
                                              ),
                                              DataColumn(label: Text('Action')),
                                            ],
                                            rows: _items.map((item) {
                                              return DataRow(
                                                cells: [
                                                  DataCell(Text(item.namaRuangan)),
                                                  DataCell(Text(item.stokAwal.toString())),
                                                  DataCell(Text(item.hilang.toString())),
                                                  DataCell(Text(item.linenDiRuangan.toString())),
                                                  DataCell(
                                                    TextButton(
                                                      onPressed: () => _openDetail(item),
                                                      child: const Text('Detail'),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
            ),
          ),
        ],
      ),
    );
  }
}

class LinenRuanganDetailPage extends StatefulWidget {
  const LinenRuanganDetailPage({
    super.key,
    required this.roomId,
    required this.roomName,
    required this.userName,
  });

  final int roomId;
  final String roomName;
  final String userName;

  @override
  State<LinenRuanganDetailPage> createState() => _LinenRuanganDetailPageState();
}

class _LinenRuanganDetailPageState extends State<LinenRuanganDetailPage> {
  bool _loading = true;
  String? _error;
  LinenRuanganDetailResponse? _response;
  LinenRuanganBaHilangResponse? _baResponse;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        ApiService.instance.getLinenRuanganDetail(widget.roomId, perPage: 1000),
        ApiService.instance.getLinenRuanganBaHilang(widget.roomId, perPage: 1000),
      ]);
      if (!mounted) return;
      setState(() {
        _response = results[0] as LinenRuanganDetailResponse;
        _baResponse = results[1] as LinenRuanganBaHilangResponse;
        _loading = false;
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
        _error = 'Tidak dapat mengambil detail Linen & Tirai di Ruangan.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailRows = _response?.data ?? const <LinenRuanganDetailItem>[];
    final baRows = _baResponse?.data ?? const <LinenRuanganBaHilangItem>[];
    final roomName = _response?.ruanganName.isNotEmpty == true
        ? _response!.ruanganName
        : widget.roomName;

    return AppShell(
      userName: widget.userName,
      activeIndex: 0,
      body: Column(
        children: [
          DetailHeader(
            title: 'Detail Ruangan - $roomName',
            userName: widget.userName,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? ListView(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  const Icon(Icons.cloud_off_rounded),
                                  const SizedBox(height: 10),
                                  Text(_error!, textAlign: TextAlign.center),
                                  const SizedBox(height: 12),
                                  ElevatedButton(
                                    onPressed: _load,
                                    child: const Text('Coba Lagi'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                          children: [
                            _RoomDetailTable(
                              title: 'Linen di Ruangan',
                              columns: const [
                                'ID',
                                'Linen ID',
                                'Nama Linen',
                                'Nama Category',
                                'Status',
                                'Tanggal Keluar',
                                'Jam Keluar',
                              ],
                              rows: detailRows
                                  .map(
                                    (item) => [
                                      item.id,
                                      item.linenId,
                                      item.namaLinen,
                                      item.namaKategoriLinen,
                                      item.status,
                                      item.tanggalKeluar,
                                      item.jamKeluar,
                                    ],
                                  )
                                  .toList(),
                            ),
                            const SizedBox(height: 18),
                            _RoomDetailTable(
                              title: 'BA Hilang',
                              columns: const [
                                'ID',
                                'Waktu Hilang',
                                'File BA',
                              ],
                              rows: baRows
                                  .map(
                                    (item) => [
                                      item.id,
                                      item.waktuHilang,
                                      item.fileUrl.isEmpty ? '-' : item.fileUrl,
                                    ],
                                  )
                                  .toList(),
                            ),
                          ],
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomDetailTable extends StatelessWidget {
  const _RoomDetailTable({
    required this.title,
    required this.columns,
    required this.rows,
  });

  final String title;
  final List<String> columns;
  final List<List<dynamic>> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(title: title),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .05),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tableWidth = constraints.maxWidth < 820
                  ? 820.0
                  : constraints.maxWidth;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: tableWidth,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                      const Color(0xff1261dc),
                    ),
                    headingTextStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                    dataTextStyle: const TextStyle(
                      color: Color(0xff465564),
                      fontSize: 9,
                    ),
                    columnSpacing: 24,
                    horizontalMargin: 16,
                    columns: columns
                        .map((column) => DataColumn(label: Text(column)))
                        .toList(),
                    rows: rows
                        .map(
                          (row) => DataRow(
                            cells: row
                                .map((value) => DataCell(Text(value.toString())))
                                .toList(),
                          ),
                        )
                        .toList(),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class LinenReadyPage extends StatefulWidget {
  const LinenReadyPage({super.key, required this.userName});
  final String userName;

  @override
  State<LinenReadyPage> createState() => _LinenReadyPageState();
}

class _LinenReadyPageState extends State<LinenReadyPage> {
  bool _loading = true;
  String? _error;
  List<LinenCategory> _categories = const [];
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await ApiService.instance.getLinen(perPage: 1000);
      if (!mounted) return;

      setState(() {
        _categories = response.data;
        _loading = false;
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
        _error = 'Tidak dapat mengambil data Linen & Tirai Ready.';
        _loading = false;
      });
    }
  }

  void _openDetail(LinenCategory category) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LinenCategoryDetailPage(
          category: category,
          userName: widget.userName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoryNames = _categories
        .map((item) => item.namaKategoriLinen.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    final filteredCategories = _selectedCategory == null
        ? _categories
        : _categories
            .where((item) => item.namaKategoriLinen.trim() == _selectedCategory)
            .toList();

    return AppShell(
      userName: widget.userName,
      activeIndex: 0,
      body: Column(
        children: [
          DetailHeader(
            title: 'Linen & Tirai Ready',
            userName: widget.userName,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? ListView(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  const Icon(Icons.cloud_off_rounded),
                                  const SizedBox(height: 10),
                                  Text(_error!, textAlign: TextAlign.center),
                                  const SizedBox(height: 12),
                                  ElevatedButton(
                                    onPressed: _load,
                                    child: const Text('Coba Lagi'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String?>(
                                  value: _selectedCategory,
                                  isExpanded: true,
                                  hint: const Text('Filter Kategori'),
                                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                                  items: [
                                    const DropdownMenuItem<String?>(
                                      value: null,
                                      child: Text('Semua Kategori'),
                                    ),
                                    ...categoryNames.map(
                                      (name) => DropdownMenuItem<String?>(
                                        value: name,
                                        child: Text(name),
                                      ),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(() => _selectedCategory = value);
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: .05),
                                    blurRadius: 18,
                                    offset: const Offset(0, 7),
                                  ),
                                ],
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final tableWidth = constraints.maxWidth < 680
                                      ? 680.0
                                      : constraints.maxWidth;

                                  return SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: SizedBox(
                                      width: tableWidth,
                                      child: DataTable(
                                        headingRowColor:
                                            WidgetStateProperty.all(
                                          const Color(0xff1261dc),
                                        ),
                                        headingTextStyle: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        dataTextStyle: const TextStyle(
                                          color: Color(0xff465564),
                                          fontSize: 9,
                                        ),
                                        columnSpacing: 28,
                                        horizontalMargin: 16,
                                        columns: const [
                                          DataColumn(
                                            label: Text('Nama Category'),
                                          ),
                                          DataColumn(
                                            label: Text('Nama Linen'),
                                          ),
                                          DataColumn(
                                            label: Text('Stock Ready'),
                                          ),
                                          DataColumn(
                                            label: Text('Action'),
                                          ),
                                        ],
                                        rows: filteredCategories.map((category) {
                                          final namaLinen =
                                              category.subKategoriLinen.trim().isEmpty
                                                  ? '-'
                                                  : category.subKategoriLinen;

                                          return DataRow(
                                            cells: [
                                              DataCell(
                                                Text(category.namaKategoriLinen),
                                              ),
                                              DataCell(Text(namaLinen)),
                                              DataCell(
                                                Text(category.jumlahStok.toString()),
                                              ),
                                              DataCell(
                                                TextButton(
                                                  onPressed: () =>
                                                      _openDetail(category),
                                                  child: const Text('Detail'),
                                                ),
                                              ),
                                            ],
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            if (filteredCategories.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(24),
                                child: Center(
                                  child: Text('Tidak ada data untuk kategori ini.'),
                                ),
                              ),
                          ],
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
