import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static const defaultBaseUrl = 'https://smilers.co.id';
  static const _baseUrlKey = 'api_base_url';

  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_baseUrlKey)?.trim();

    if (saved == null || saved.isEmpty) {
      return defaultBaseUrl;
    }

    return normalize(saved);
  }

  static Future<void> saveBaseUrl(String value) async {
    final normalized = normalize(value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, normalized);
  }

  static String normalize(String value) {
    var url = value.trim();
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    if (url.endsWith('/api/mobile')) {
      url = url.substring(0, url.length - '/api/mobile'.length);
    } else if (url.endsWith('/api')) {
      url = url.substring(0, url.length - '/api'.length);
    }
    return url;
  }

  static Future<String> getMobileUrl() async {
    final baseUrl = await getBaseUrl();
    return '$baseUrl/api/mobile';
  }
}

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.username,
    required this.foto,
    required this.roles,
  });

  final int id;
  final String name;
  final String username;
  final String? foto;
  final List<String> roles;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      foto: json['foto']?.toString(),
      roles: (json['roles'] as List?)
              ?.map((role) => role.toString())
              .toList() ??
          const [],
    );
  }
}

class AuthResponse {
  const AuthResponse({required this.token, required this.user});

  final String token;
  final AuthUser user;
}

class LinenCategory {
  const LinenCategory({
    required this.id,
    required this.namaKategoriLinen,
    required this.subKategoriLinen,
    required this.jumlahStok,
    required this.jumlahHilang,
  });

  final int id;
  final String namaKategoriLinen;
  final String subKategoriLinen;
  final int jumlahStok;
  final int jumlahHilang;

  factory LinenCategory.fromJson(Map<String, dynamic> json) {
    return LinenCategory(
      id: (json['id'] as num?)?.toInt() ?? 0,
      namaKategoriLinen: json['nama_kategori_linen']?.toString() ?? '',
      subKategoriLinen: json['sub_kategori_linen']?.toString() ?? '',
      jumlahStok: _toInt(json['jumlah_stok']),
      jumlahHilang: _toInt(json['jumlah_hilang']),
    );
  }
}

class LinenItem {
  const LinenItem({
    required this.id,
    required this.kodeLinen,
    required this.tagRfid,
    required this.qrCode,
    required this.status,
  });

  final int id;
  final String kodeLinen;
  final String tagRfid;
  final String qrCode;
  final String status;

  factory LinenItem.fromJson(Map<String, dynamic> json) {
    return LinenItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      kodeLinen: json['kode_linen']?.toString() ?? '',
      tagRfid: json['tag_rfid']?.toString() ?? '',
      qrCode: json['qr_code']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }
}

class LinenMeta {
  const LinenMeta({
    required this.currentPage,
    required this.perPage,
    required this.total,
    required this.lastPage,
  });

  final int currentPage;
  final int perPage;
  final int total;
  final int lastPage;

  factory LinenMeta.fromJson(Map<String, dynamic> json) {
    return LinenMeta(
      currentPage: (json['current_page'] as num?)?.toInt() ?? 1,
      perPage: (json['per_page'] as num?)?.toInt() ?? 10,
      total: (json['total'] as num?)?.toInt() ?? 0,
      lastPage: (json['last_page'] as num?)?.toInt() ?? 1,
    );
  }
}

class LinenListResponse<T> {
  const LinenListResponse({required this.data, required this.meta});

  final List<T> data;
  final LinenMeta meta;
}

class LinenItemsResponse {
  const LinenItemsResponse({required this.data, required this.meta});

  final List<LinenItem> data;
  final LinenMeta meta;
}

class LinenDropdownSubCategory {
  const LinenDropdownSubCategory({required this.subKategoriLinen});

  final String subKategoriLinen;

  factory LinenDropdownSubCategory.fromJson(Map<String, dynamic> json) {
    return LinenDropdownSubCategory(
      subKategoriLinen: json['sub_kategori_linen']?.toString() ?? '',
    );
  }
}

class ApiService {
  static final ApiService instance = ApiService._();

  ApiService._();

  Future<AuthResponse> login({
    required String username,
    required String password,
    String deviceName = 'mobile-app',
  }) async {
    final response = await http.post(
      Uri.parse('${await ApiConfig.getMobileUrl()}/login'),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'username': username,
        'password': password,
        'device_name': deviceName,
      }),
    );

    final data = _decode(response);

    if (response.statusCode != 200 || data['status'] != 'success') {
      throw ApiException(
        data['message']?.toString() ?? 'Login gagal.',
        statusCode: response.statusCode,
      );
    }

    final token = data['token']?.toString();
    final userJson = data['user'];

    if (token == null || token.isEmpty || userJson is! Map) {
      throw const ApiException('Response login dari server tidak valid.');
    }

    final user = AuthUser.fromJson(Map<String, dynamic>.from(userJson));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('auth_user', jsonEncode(data['user']));

    return AuthResponse(token: token, user: user);
  }

  Future<AuthUser> me() async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw const ApiException('Token autentikasi tidak ditemukan.', statusCode: 401);
    }

    final response = await http.get(
      Uri.parse('${await ApiConfig.getMobileUrl()}/me'),
      headers: _authHeaders(token),
    );

    final data = _decode(response);

    if (response.statusCode != 200 || data['status'] != 'success') {
      throw ApiException(
        data['message']?.toString() ?? 'Gagal mengambil data user.',
        statusCode: response.statusCode,
      );
    }

    final userJson = data['data'];

    if (userJson is! Map) {
      throw const ApiException('Response /me dari server tidak valid.');
    }

    final user = AuthUser.fromJson(Map<String, dynamic>.from(userJson));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_user', jsonEncode(userJson));

    return user;
  }

  Future<LinenListResponse<LinenCategory>> getLinen({
    String? search,
    int? perPage,
  }) async {
    final query = <String, String>{};
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }
    if (perPage != null) query['per_page'] = perPage.toString();

    final data = await _get('/linen', query: query);
    final items = (data['data'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => LinenCategory.fromJson(Map<String, dynamic>.from(item)))
        .toList();

    return LinenListResponse(
      data: items,
      meta: LinenMeta.fromJson(
        Map<String, dynamic>.from((data['meta'] as Map?) ?? const {}),
      ),
    );
  }

  Future<LinenCategory> getLinenCategory(int kategoriLinen) async {
    final data = await _get('/linen/$kategoriLinen');
    final category = data['data'];

    if (category is! Map) {
      throw const ApiException('Response detail linen tidak valid.');
    }

    return LinenCategory.fromJson(Map<String, dynamic>.from(category));
  }

  Future<LinenItemsResponse> getLinenItems(
    int kategoriLinen, {
    int? perPage,
  }) async {
    final query = <String, String>{};
    if (perPage != null) query['per_page'] = perPage.toString();

    final data = await _get('/linen/$kategoriLinen/items', query: query);
    final items = (data['data'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => LinenItem.fromJson(Map<String, dynamic>.from(item)))
        .toList();

    return LinenItemsResponse(
      data: items,
      meta: LinenMeta.fromJson(
        Map<String, dynamic>.from((data['meta'] as Map?) ?? const {}),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> getLinenCategoryDropdown() async {
    final data = await _get('/linen-dropdown/category');
    return (data['data'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<List<LinenDropdownSubCategory>> getLinenSubCategoryDropdown() async {
    final data = await _get('/linen-dropdown/sub-category');
    return (data['data'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => LinenDropdownSubCategory.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList();
  }


  Future<LinenListResponse<LinenLaundryItem>> getLinenLaundry({String? search,int? perPage}) async {
    final d=await _get('/linen-laundry',query:_query({'search':search,'per_page':perPage}));
    return _listResponse(d,(e)=>LinenLaundryItem.fromJson(e));
  }
  Future<LinenLaundryDetailResponse> getLinenLaundryCategory(int kategoriLinen,{int? perPage}) async => LinenLaundryDetailResponse.fromJson(await _get('/linen-laundry/$kategoriLinen',query:_query({'per_page':perPage})));\n  Future<LinenListResponse<LinenRuanganItem>> getLinenRuangan({String? search,int? perPage}) async {
    final d=await _get('/linen-ruangan',query:_query({'search':search,'per_page':perPage}));
    return _listResponse(d,(e)=>LinenRuanganItem.fromJson(e));
  }
  Future<LinenRuanganDetailResponse> getLinenRuanganDetail(int ruangan,{int? perPage}) async => LinenRuanganDetailResponse.fromJson(await _get('/linen-ruangan/$ruangan',query:_query({'per_page':perPage})));
  Future<LinenRuanganBaHilangResponse> getLinenRuanganBaHilang(int ruangan,{int? perPage}) async => LinenRuanganBaHilangResponse.fromJson(await _get('/linen-ruangan/$ruangan/ba-hilang',query:_query({'per_page':perPage})));
  Future<LinenListResponse<LinenRusakItem>> getLinenRusak({String? search,int? perPage}) async {
    final d=await _get('/linen-rusak',query:_query({'search':search,'per_page':perPage}));
    return _listResponse(d,(e)=>LinenRusakItem.fromJson(e));
  }
  Future<Map<String,dynamic>> scanLinenRusak(String rfid)=>_post('/linen-rusak/scan',{'rfid':rfid});

  Future<LinenListResponse<LinenHilangItem>> getLinenHilang({String? search,int? perPage,int? filterRuangan,int? filterKategori,String? daterange}) async {
    final d=await _get('/linen-hilang',query:_query({'per_page':perPage,'search':search,'filter_ruangan':filterRuangan,'filter_kategori':filterKategori,'daterange':daterange}));
    return _listResponse(d,(e)=>LinenHilangItem.fromJson(e));
  }
  Future<LinenListResponse<LinenHilangRuanganItem>> getLinenHilangRuanganList({required int ruanganId,int? perPage}) async {
    final d=await _get('/linen-hilang/ruangan-list',query:_query({'ruangan_id':ruanganId,'per_page':perPage??20}));
    return _listResponse(d,(e)=>LinenHilangRuanganItem.fromJson(e));
  }
  Future<Map<String,dynamic>> createLinenHilang({required String tanggal,required int ruanganId,required List<int> linenIds,String? beritaAcaraPath}) async {
    final token=await _requiredToken();
    final r=http.MultipartRequest('POST',Uri.parse('${await ApiConfig.getMobileUrl()}/linen-hilang'));
    r.headers['Authorization']='Bearer $token'; r.headers['Accept']='application/json';
    r.fields['tanggal']=tanggal; r.fields['ruangan_id']=ruanganId.toString();
    for(var i=0;i<linenIds.length;i++){r.fields['linen_id[$i]']=linenIds[i].toString();}
    if(beritaAcaraPath!=null&&beritaAcaraPath.trim().isNotEmpty){r.files.add(await http.MultipartFile.fromPath('berita_acara',beritaAcaraPath));}
    return _handleResponse(await http.Response.fromStream(await r.send()));
  }

  Future<LinenListResponse<LinenKeluarItem>> getLinenKeluar({String? search,int? perPage,int? ruangan,String? date,String? daterange}) async {
    final d=await _get('/linen-keluar',query:_query({'per_page':perPage,'search':search,'ruangan':ruangan,'date':date,'daterange':daterange}));
    return _listResponse(d,(e)=>LinenKeluarItem.fromJson(e));
  }
  Future<LinenKeluarOptions> getLinenKeluarOptions() async {
    final d=await _get('/linen-keluar/options'); return LinenKeluarOptions.fromJson(Map<String,dynamic>.from((d['data'] as Map?)??const {}));
  }
  Future<LinenScanQueueResponse> getLinenKeluarScanQueue() async=>LinenScanQueueResponse.fromJson(await _get('/linen-keluar/scan-queue'));
  Future<Map<String,dynamic>> scanLinenKeluar(String rfid)=>_post('/linen-keluar/scan',{'rfid':rfid});
  Future<Map<String,dynamic>> deleteLinenKeluarScan(int linenKeluar)=>_delete('/linen-keluar/scan/$linenKeluar');
  Future<Map<String,dynamic>> saveLinenKeluar({required List<int> linens,required int ruanganId,required int userId})=>_post('/linen-keluar/save',{'linens':linens,'ruangan_id':ruanganId,'user_id':userId});

  Future<LinenListResponse<LinenMasukItem>> getLinenMasuk({String? search,int? perPage,int? ruangan,String? date,String? daterange}) async {
    final d=await _get('/linen-masuk',query:_query({'per_page':perPage,'search':search,'ruangan':ruangan,'date':date,'daterange':daterange}));
    return _listResponse(d,(e)=>LinenMasukItem.fromJson(e));
  }
  Future<List<LinenRoomOption>> getLinenMasukRuangan() async=>_roomOptions(await _get('/linen-masuk/ruangan'));
  Future<Map<String,dynamic>> scanLinenMasuk(String rfid)=>_post('/linen-masuk/scan',{'rfid':rfid});

  Future<LinenListResponse<PermintaanLinenItem>> getPermintaanLinen({String? search,int? perPage,int? ruangan,String? status}) async {
    final d=await _get('/permintaan-linen',query:_query({'per_page':perPage,'search':search,'ruangan':ruangan,'status':status}));
    return _listResponse(d,(e)=>PermintaanLinenItem.fromJson(e));
  }
  Future<PermintaanLinenFormData> getPermintaanLinenFormData() async=>PermintaanLinenFormData.fromJson(Map<String,dynamic>.from((await _get('/permintaan-linen/form-data'))['data'] as Map));
  Future<Map<String,dynamic>> createPermintaanLinen({required String tanggalPermintaan,required int ruanganId,required String alasanPermintaan,required List<Map<String,dynamic>> items})=>_post('/permintaan-linen',{'tanggal_permintaan':tanggalPermintaan,'ruangan_id':ruanganId,'alasan_permintaan':alasanPermintaan,'items':items});
  Future<PermintaanLinenDetail> getPermintaanLinenDetail(int id) async=>PermintaanLinenDetail.fromJson(Map<String,dynamic>.from((await _get('/permintaan-linen/$id'))['data'] as Map));
  Future<Map<String,dynamic>> updatePermintaanLinenStatus(int id)=>_patch('/permintaan-linen/$id/status');

  Future<InOutResponse> getInOut({String? search,int? perPage,int? ruangan,String? date,String? daterange}) async=>InOutResponse.fromJson(await _get('/inout',query:_query({'per_page':perPage,'search':search,'ruangan':ruangan,'date':date,'daterange':daterange})));
  Future<Map<String,dynamic>> getInOutDetail(int ruangan,{String? date,String? daterange})=>_get('/inout/$ruangan',query:_query({'date':date,'daterange':daterange}));
  Future<RekapanTransaksiResponse> getRekapanTransaksi({String? daterange,int? ruangan}) async=>RekapanTransaksiResponse.fromJson(await _get('/rekapan-transaksi',query:_query({'daterange':daterange,'ruangan':ruangan})));
  Future<List<LinenRoomOption>> getRekapanTransaksiRuangan() async=>_roomOptions(await _get('/rekapan-transaksi/ruangan'));

  Future<LinenListResponse<LinenBelumKembaliItem>> getLinenBelumKembali({String? search,int? perPage,int? ruangan,String? date,String? daterange}) async {
    final d=await _get('/linen-belum-kembali',query:_query({'per_page':perPage,'search':search,'ruangan':ruangan,'date':date,'daterange':daterange}));
    return _listResponse(d,(e)=>LinenBelumKembaliItem.fromJson(e));
  }
  Future<List<LinenRoomOption>> getLinenBelumKembaliRuangan() async=>_roomOptions(await _get('/linen-belum-kembali/ruangan'));

  Map<String,String>? _query(Map<String,dynamic> v){final q=<String,String>{};v.forEach((k,x){if(x!=null&&x.toString().trim().isNotEmpty)q[k]=x.toString();});return q.isEmpty?null:q;}
  Future<String> _requiredToken() async {final t=await getToken();if(t==null||t.isEmpty)throw const ApiException('Token autentikasi tidak ditemukan.',statusCode:401);return t;}
  Future<Map<String,dynamic>> _post(String path,Map<String,dynamic> body) async {final r=await http.post(Uri.parse('${await ApiConfig.getMobileUrl()}$path'),headers:_authHeaders(await _requiredToken()),body:jsonEncode(body));return _handleResponse(r);}
  Future<Map<String,dynamic>> _patch(String path) async {final r=await http.patch(Uri.parse('${await ApiConfig.getMobileUrl()}$path'),headers:_authHeaders(await _requiredToken()));return _handleResponse(r);}
  Future<Map<String,dynamic>> _delete(String path) async {final r=await http.delete(Uri.parse('${await ApiConfig.getMobileUrl()}$path'),headers:_authHeaders(await _requiredToken()));return _handleResponse(r);}
  List<LinenRoomOption> _roomOptions(Map<String,dynamic> d)=>(d['data'] as List? ?? const []).whereType<Map>().map((e)=>LinenRoomOption.fromJson(Map<String,dynamic>.from(e))).toList();
  LinenListResponse<T> _listResponse<T>(Map<String,dynamic> d,T Function(Map<String,dynamic>) parser)=>LinenListResponse<T>(data:(d['data'] as List? ?? const []).whereType<Map>().map((e)=>parser(Map<String,dynamic>.from(e))).toList(),meta:LinenMeta.fromJson(Map<String,dynamic>.from((d['meta'] as Map?)??const {})));

  Future<Map<String, dynamic>> _get(
    String path, {
    Map<String, String>? query,
  }) async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw const ApiException('Token autentikasi tidak ditemukan.', statusCode: 401);
    }

    final uri = Uri.parse('${await ApiConfig.getMobileUrl()}$path').replace(
      queryParameters: query == null || query.isEmpty ? null : query,
    );

    final response = await http.get(uri, headers: _authHeaders(token));
    final data = _decode(response);

    if (response.statusCode != 200 || data['status'] != 'success') {
      throw ApiException(
        data['message']?.toString() ?? 'Request API gagal.',
        statusCode: response.statusCode,
      );
    }

    return data;
  }

  Future<void> logout() async {
    final token = await getToken();

    if (token != null && token.isNotEmpty) {
      try {
        final response = await http.post(
          Uri.parse('${await ApiConfig.getMobileUrl()}/logout'),
          headers: _authHeaders(token),
        );

        final data = _decode(response);

        if (response.statusCode != 200 || data['status'] != 'success') {
          throw ApiException(
            data['message']?.toString() ?? 'Logout gagal.',
            statusCode: response.statusCode,
          );
        }
      } finally {
        await clearSession();
      }
    } else {
      await clearSession();
    }
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<AuthUser?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('auth_user');

    if (raw == null || raw.isEmpty) return null;

    try {
      return AuthUser.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_user');
  }

  Map<String, String> _authHeaders(String token) {
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
  }

  Map<String, dynamic> _decode(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}

    return {
      'status': 'error',
      'message': response.body.isEmpty
          ? 'Server tidak memberikan response yang valid.'
          : 'Server mengembalikan response yang tidak valid.',
    };
  }
}
