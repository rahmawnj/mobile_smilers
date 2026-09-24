import 'package:flutter/material.dart';

import '../api/api_service.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/pagination_widget.dart';


class LinenBelumKembaliPage extends StatefulWidget { const LinenBelumKembaliPage({super.key, required this.userName, this.embedded = false}); final String userName; final bool embedded; @override State<LinenBelumKembaliPage> createState()=>_LinenBelumKembaliPageState(); }
class _LinenBelumKembaliPageState extends State<LinenBelumKembaliPage> { bool _loading=true; String? _error; LinenBelumKembaliResponse? _response; List<LinenRoomOption> _rooms=const []; int? _roomId; DateTimeRange? _range; int _page=1; final _searchController=TextEditingController(); @override void initState(){super.initState();_load();_loadRooms();} @override void dispose(){_searchController.dispose();super.dispose();} String _date(DateTime d)=>d.day.toString()+'/'+d.month.toString()+'/'+d.year.toString(); String? get _daterange=>_range==null?null:_date(_range!.start)+' - '+_date(_range!.end);
Future<void> _loadRooms() async {try{final rooms=await ApiService.instance.getLinenBelumKembaliRuangan();if(mounted)setState(()=>_rooms=rooms);}catch(_){}}
Future<void> _load() async {setState((){_loading=true;_error=null;});try{final r=await ApiService.instance.getLinenBelumKembali(perPage:10,page:_page,search:_searchController.text.trim().isEmpty?null:_searchController.text.trim(),ruangan:_roomId,daterange:_daterange);if(!mounted)return;setState((){_response=r;_loading=false;});}on ApiException catch(e){if(mounted)setState((){_error=e.message;_loading=false;});}catch(_){if(mounted)setState((){_error='Tidak dapat mengambil data Linen Belum Kembali.';_loading=false;});}}
Future<void> _pickRange() async {final r=await showDateRangePicker(context:context,firstDate:DateTime(2020),lastDate:DateTime(2100),initialDateRange:_range);if(r!=null){setState(()=>_range=r);_load();}}
@override Widget build(BuildContext context){final rows=_response?.data??const <LinenBelumKembaliItem>[];return AppShell(
      embedded: widget.embedded,userName:widget.userName,activeIndex:4,body:Column(children:[// Header is provided by AppShell so it stays fixed while the body pages slide.
Padding(padding:const EdgeInsets.fromLTRB(16,14,16,8),child:Row(children:[Expanded(child:TextField(controller:_searchController,onSubmitted:(_)=>_load(),decoration:InputDecoration(hintText:'Cari linen / ruangan...',prefixIcon:const Icon(Icons.search_rounded,size:20),filled:true,fillColor:Colors.white,border:OutlineInputBorder(borderRadius:BorderRadius.circular(20),borderSide:BorderSide.none)))),const SizedBox(width:8),IconButton(onPressed:_pickRange,style:IconButton.styleFrom(backgroundColor:const Color(0xff1261dc),foregroundColor:Colors.white),icon:const Icon(Icons.date_range_rounded,size:20))])),Padding(padding:const EdgeInsets.fromLTRB(16,0,16,6),child:DropdownButtonFormField<int?>(value:_roomId,isExpanded:true,decoration:InputDecoration(hintText:'Semua Ruangan',prefixIcon:const Icon(Icons.meeting_room_rounded,size:19),filled:true,fillColor:Colors.white,border:OutlineInputBorder(borderRadius:BorderRadius.circular(20),borderSide:BorderSide.none)),items:[const DropdownMenuItem<int?>(value:null,child:Text('Semua Ruangan')),..._rooms.map((r)=>DropdownMenuItem<int?>(value:r.id,child:Text(r.nama)))],onChanged:(v){setState(()=>_roomId=v);_load();})),if(_range!=null)Padding(padding:const EdgeInsets.symmetric(horizontal:16),child:Row(children:[Expanded(child:Text('Periode: '+_date(_range!.start)+' - '+_date(_range!.end),style:const TextStyle(fontSize:9,color:Color(0xff6f7f8d)))),TextButton(onPressed:(){setState(()=>_range=null);_load();},child:const Text('Reset'))])),Expanded(child:RefreshIndicator(onRefresh:_load,child:SingleChildScrollView(physics:const AlwaysScrollableScrollPhysics(),padding:const EdgeInsets.fromLTRB(16,8,16,20),child:_loading?const Padding(padding:EdgeInsets.all(50),child:Center(child:CircularProgressIndicator())):_error!=null?_BelumKembaliError(message:_error!,onRetry:_load):rows.isEmpty?const Padding(padding:EdgeInsets.all(40),child:Center(child:Text('Tidak ada linen yang belum kembali.'))):Column(children:[_BelumKembaliTable(rows:rows),if(_response!=null)AppPagination(meta:_response!.meta,onPage:(page){setState(()=>_page=page);_load();})]))))]));}}
class _BelumKembaliTable extends StatelessWidget {
  const _BelumKembaliTable({required this.rows});

  final List<LinenBelumKembaliItem> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      
      
      child: LayoutBuilder(builder: (context, constraints) { return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(width: constraints.maxWidth, child: DataTable(
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
        )),
      ); }),
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
