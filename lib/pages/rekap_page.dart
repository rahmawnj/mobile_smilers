import 'package:flutter/material.dart';

import '../api/api_service.dart';
import '../widgets/shared_widgets.dart';

class RekapanTransaksiPage extends StatefulWidget {
  const RekapanTransaksiPage({super.key, required this.userName, this.embedded = false});
  final String userName;
  final bool embedded;
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
      embedded: widget.embedded,
      userName: widget.userName,
      activeIndex: 3,
      body: Column(
        children: [
          // Header is provided by AppShell so it stays fixed while the body pages slide.

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
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
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
  Widget build(BuildContext context)=>Container(padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(20)),child:Column(children:[Icon(icon,size:20,color:const Color(0xff1261dc)),const SizedBox(height:6),Text(value,style:const TextStyle(fontSize:18,fontWeight:FontWeight.w800)),const SizedBox(height:2),Text(title,textAlign:TextAlign.center,style:const TextStyle(fontSize:8,color:Color(0xff6f7f8d))) ]));
}
class _RekapTable extends StatelessWidget {
  const _RekapTable({required this.rows}); final List<RekapanTransaksiItem> rows;
  @override
  Widget build(BuildContext context)=>Container(width:double.infinity,hild:SingleChildScrollView(scrollDirection:Axis.horizontal,child:DataTable(
    headingRowColor:WidgetStateProperty.all(const Color(0xff1261dc)),
    headingTextStyle:const TextStyle(color:Colors.white,fontSize:9,fontWeight:FontWeight.w700),
    dataTextStyle:const TextStyle(color:Color(0xff465564),fontSize:9),
    columns:const [DataColumn(label:Text('Tanggal')),DataColumn(label:Text('Keluar')),DataColumn(label:Text('Masuk')),DataColumn(label:Text('Berat Masuk'))],
    rows:rows.map((r)=>DataRow(cells:[DataCell(Text(r.tanggal)),DataCell(Text('${r.jumlahLinenKeluar}')),DataCell(Text('${r.jumlahLinenMasuk}')),DataCell(Text('${r.beratLinenMasuk}'))])).toList(),
  )));
}
