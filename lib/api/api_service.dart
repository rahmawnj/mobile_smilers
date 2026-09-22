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
      currentPage: _toInt(json['current_page']) == 0 ? 1 : _toInt(json['current_page']),
      perPage: _toInt(json['per_page']) == 0 ? 10 : _toInt(json['per_page']),
      total: _toInt(json['total']),
      lastPage: _toInt(json['last_page']) == 0 ? 1 : _toInt(json['last_page']),
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


int _toInt(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

class LinenLaundryItem {
  const LinenLaundryItem({required this.id, required this.namaLinen, required this.namaKategoriLinen, required this.ready});
  final int id; final String namaLinen; final String namaKategoriLinen; final dynamic ready;
  factory LinenLaundryItem.fromJson(Map<String,dynamic> j) => LinenLaundryItem(id:_toInt(j['id']),namaLinen:j['nama_linen']?.toString()??'',namaKategoriLinen:j['nama_kategori_linen']?.toString()??'',ready:j['ready']);
}
class LinenLaundryDetailItem {
  const LinenLaundryDetailItem({required this.id,required this.kodeLinen,required this.namaLinen,required this.namaKategoriLinen,required this.jumlahPencucian});
  final int id; final String kodeLinen; final String namaLinen; final String namaKategoriLinen; final int jumlahPencucian;
  factory LinenLaundryDetailItem.fromJson(Map<String,dynamic> j)=>LinenLaundryDetailItem(id:_toInt(j['id']),kodeLinen:j['kode_linen']?.toString()??'',namaLinen:j['nama_linen']?.toString()??'',namaKategoriLinen:j['nama_kategori_linen']?.toString()??'',jumlahPencucian:_toInt(j['jumlah_pencucian']));
}
class LinenLaundryDetailResponse {
  const LinenLaundryDetailResponse({required this.data,required this.meta});
  final List<LinenLaundryDetailItem> data; final LinenMeta meta;
  factory LinenLaundryDetailResponse.fromJson(Map<String,dynamic> j)=>LinenLaundryDetailResponse(data:(j['data'] as List? ?? const []).whereType<Map>().map((e)=>LinenLaundryDetailItem.fromJson(Map<String,dynamic>.from(e))).toList(),meta:LinenMeta.fromJson(Map<String,dynamic>.from((j['meta'] as Map?)??const {})));
}
class LinenRuanganItem {
  const LinenRuanganItem({required this.id,required this.namaRuangan,required this.stokAwal,required this.hilang,required this.linenDiRuangan});
  final int id; final String namaRuangan; final int stokAwal; final int hilang; final int linenDiRuangan;
  factory LinenRuanganItem.fromJson(Map<String,dynamic> j)=>LinenRuanganItem(id:_toInt(j['id']),namaRuangan:j['nama_ruangan']?.toString()??'',stokAwal:_toInt(j['stok_awal']),hilang:_toInt(j['hilang']),linenDiRuangan:_toInt(j['linen_di_ruangan']));
}
class LinenRuanganDetailItem {
  const LinenRuanganDetailItem({required this.id,required this.linenId,required this.namaLinen,required this.namaKategoriLinen,required this.status,required this.tanggalKeluar,required this.jamKeluar});
  final int id,linenId; final String namaLinen,namaKategoriLinen,status,tanggalKeluar,jamKeluar;
  factory LinenRuanganDetailItem.fromJson(Map<String,dynamic> j)=>LinenRuanganDetailItem(id:_toInt(j['id']),linenId:_toInt(j['linen_id']),namaLinen:j['nama_linen']?.toString()??'',namaKategoriLinen:j['nama_kategori_linen']?.toString()??'',status:j['status']?.toString()??'',tanggalKeluar:j['tanggal_keluar']?.toString()??'',jamKeluar:j['jam_keluar']?.toString()??'');
}
class LinenRuanganDetailResponse {
  const LinenRuanganDetailResponse({
    required this.ruanganId,
    required this.ruanganName,
    required this.data,
    required this.meta,
  });
  final int ruanganId;
  final String ruanganName;
  final List<LinenRuanganDetailItem> data;
  final LinenMeta meta;

  factory LinenRuanganDetailResponse.fromJson(Map<String,dynamic> j) {
    final room = Map<String,dynamic>.from((j['ruangan'] as Map?) ?? const {});
    return LinenRuanganDetailResponse(
      ruanganId: _toInt(room['id']),
      ruanganName: room['nama_ruangan']?.toString() ?? '',
      data: (j['data'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => LinenRuanganDetailItem.fromJson(Map<String,dynamic>.from(e)))
          .toList(),
      meta: LinenMeta.fromJson(
        Map<String,dynamic>.from((j['meta'] as Map?) ?? const {}),
      ),
    );
  }
}
class LinenRuanganBaHilangItem {
  const LinenRuanganBaHilangItem({required this.id,required this.waktuHilang,required this.fileUrl});
  final int id; final String waktuHilang,fileUrl;
  factory LinenRuanganBaHilangItem.fromJson(Map<String,dynamic> j)=>LinenRuanganBaHilangItem(id:_toInt(j['id']),waktuHilang:j['waktu_hilang']?.toString()??'',fileUrl:j['file_url']?.toString()??'');
}
class LinenRuanganBaHilangResponse {
  const LinenRuanganBaHilangResponse({required this.ruangan,required this.data,required this.meta});
  final String ruangan; final List<LinenRuanganBaHilangItem> data; final LinenMeta meta;
  factory LinenRuanganBaHilangResponse.fromJson(Map<String,dynamic> j)=>LinenRuanganBaHilangResponse(ruangan:j['ruangan']?.toString()??'',data:(j['data'] as List? ?? const []).whereType<Map>().map((e)=>LinenRuanganBaHilangItem.fromJson(Map<String,dynamic>.from(e))).toList(),meta:LinenMeta.fromJson(Map<String,dynamic>.from((j['meta'] as Map?)??const {})));
}
class LinenRusakItem {
  const LinenRusakItem({required this.id,required this.linenId,required this.namaLinen,required this.tagRfid,required this.qrCode,required this.jam,required this.tanggal,required this.tahunPembuatan});
  final int id,linenId; final String namaLinen,tagRfid,qrCode,jam,tanggal,tahunPembuatan;
  factory LinenRusakItem.fromJson(Map<String,dynamic> j)=>LinenRusakItem(id:_toInt(j['id']),linenId:_toInt(j['linen_id']),namaLinen:j['nama_linen']?.toString()??'',tagRfid:j['tag_rfid']?.toString()??'',qrCode:j['qr_code']?.toString()??'',jam:j['jam']?.toString()??'',tanggal:j['tanggal']?.toString()??'',tahunPembuatan:j['tahun_pembuatan']?.toString()??'');
}
class LinenHilangItem {
  const LinenHilangItem({
    required this.id,
    required this.namaRuangan,
    required this.kategoriLinen,
    required this.jenisLinen,
    required this.qrCode,
    required this.tagRfid,
    required this.tanggalTerakhirTransaksi,
    required this.tanggalHilang,
  });
  final int id;
  final String namaRuangan, kategoriLinen, jenisLinen, qrCode, tagRfid;
  final String tanggalTerakhirTransaksi, tanggalHilang;
  factory LinenHilangItem.fromJson(Map<String,dynamic> j)=>LinenHilangItem(
    id:_toInt(j['id']),
    namaRuangan:j['nama_ruangan']?.toString()??'',
    kategoriLinen:j['kategori_linen']?.toString()??'',
    jenisLinen:j['jenis_linen']?.toString()??'',
    qrCode:j['qr_code']?.toString()??'',
    tagRfid:j['tag_rfid']?.toString()??'',
    tanggalTerakhirTransaksi:j['tanggal_terakhir_transaksi']?.toString()??'',
    tanggalHilang:j['tanggal_hilang']?.toString()??'',
  );
}
class LinenHilangRuanganItem {
  const LinenHilangRuanganItem({
    required this.transaksiId,
    required this.linenId,
    required this.namaLinen,
    required this.kategoriLinen,
    required this.qrCode,
    required this.tagRfid,
    required this.tanggalKeluar,
  });
  final int transaksiId, linenId;
  final String namaLinen, kategoriLinen, qrCode, tagRfid, tanggalKeluar;
  factory LinenHilangRuanganItem.fromJson(Map<String,dynamic> j)=>LinenHilangRuanganItem(
    transaksiId:_toInt(j['transaksi_id']),
    linenId:_toInt(j['linen_id']),
    namaLinen:j['nama_linen']?.toString()??'',
    kategoriLinen:j['kategori_linen']?.toString()??'',
    qrCode:j['qr_code']?.toString()??'',
    tagRfid:j['tag_rfid']?.toString()??'',
    tanggalKeluar:j['tanggal_keluar']?.toString()??'',
  );
}
class LinenKeluarItem {
  const LinenKeluarItem({required this.id,required this.namaLinen,required this.qrCode,required this.tagRfid,required this.keRuangan,required this.jam,required this.tanggal,required this.user});
  final int id; final String namaLinen,qrCode,tagRfid,keRuangan,jam,tanggal,user;
  factory LinenKeluarItem.fromJson(Map<String,dynamic> j)=>LinenKeluarItem(
    id:_toInt(j['id']),namaLinen:j['nama_linen']?.toString()??'',qrCode:j['qr_code']?.toString()??'',tagRfid:j['tag_rfid']?.toString()??'',
    keRuangan:j['ke_ruangan']?.toString()??j['ruangan']?.toString()??'',jam:j['jam']?.toString()??'',tanggal:j['tanggal']?.toString()??'',user:j['user']?.toString()??'');
}
class LinenKeluarRoomOption {
  const LinenKeluarRoomOption({required this.id,required this.namaRuangan}); final int id; final String namaRuangan;
  factory LinenKeluarRoomOption.fromJson(Map<String,dynamic> j)=>LinenKeluarRoomOption(id:_toInt(j['id']),namaRuangan:j['nama_ruangan']?.toString()??'');
}
class LinenKeluarUserOption {
  const LinenKeluarUserOption({required this.id,required this.name,required this.username}); final int id; final String name,username;
  factory LinenKeluarUserOption.fromJson(Map<String,dynamic> j)=>LinenKeluarUserOption(id:_toInt(j['id']),name:j['name']?.toString()??'',username:j['username']?.toString()??'');
}
class LinenKeluarOptions {
  const LinenKeluarOptions({required this.ruangan,required this.users}); final List<LinenKeluarRoomOption> ruangan; final List<LinenKeluarUserOption> users;
  factory LinenKeluarOptions.fromJson(Map<String,dynamic> j){
    final d=Map<String,dynamic>.from((j['data'] as Map?)??j);
    return LinenKeluarOptions(
      ruangan:(d['ruangan'] as List? ?? const []).whereType<Map>().map((e)=>LinenKeluarRoomOption.fromJson(Map<String,dynamic>.from(e))).toList(),
      users:(d['users'] as List? ?? const []).whereType<Map>().map((e)=>LinenKeluarUserOption.fromJson(Map<String,dynamic>.from(e))).toList());
  }
}
class LinenScanQueueItem {
  const LinenScanQueueItem({required this.linenKeluarId,required this.linenId,required this.namaKategoriLinen,required this.qrCode,required this.tagRfid,required this.waktuScan});
  final int linenKeluarId,linenId; final String namaKategoriLinen,qrCode,tagRfid,waktuScan;
  factory LinenScanQueueItem.fromJson(Map<String,dynamic> j)=>LinenScanQueueItem(
    linenKeluarId:_toInt(j['linen_keluar_id']),linenId:_toInt(j['linen_id']),namaKategoriLinen:j['nama_kategori_linen']?.toString()??'',
    qrCode:j['qr_code']?.toString()??'',tagRfid:j['tag_rfid']?.toString()??'',waktuScan:j['waktu_scan']?.toString()??'');
}
class LinenScanQueueResponse {
  const LinenScanQueueResponse({required this.total,required this.data}); final int total; final List<LinenScanQueueItem> data;
  factory LinenScanQueueResponse.fromJson(Map<String,dynamic> j)=>LinenScanQueueResponse(
    total:_toInt(j['total']),
    data:(j['data'] as List? ?? const []).whereType<Map>().map((e)=>LinenScanQueueItem.fromJson(Map<String,dynamic>.from(e))).toList());
}
class LinenMasukItem {
  const LinenMasukItem({required this.id,required this.linenId,required this.namaLinen,required this.ruangan,required this.tanggal,required this.jam});
  final int id,linenId; final String namaLinen,ruangan,tanggal,jam;
  factory LinenMasukItem.fromJson(Map<String,dynamic> j)=>LinenMasukItem(id:_toInt(j['id']),linenId:_toInt(j['linen_id']),namaLinen:j['nama_linen']?.toString()??'',ruangan:j['ruangan']?.toString()??'',tanggal:j['tanggal']?.toString()??'',jam:j['jam']?.toString()??'');
}
class LinenRoomOption {
  const LinenRoomOption({required this.id,required this.nama}); final int id; final String nama;
  factory LinenRoomOption.fromJson(Map<String,dynamic> j)=>LinenRoomOption(id:_toInt(j['id']??j['ruangan_id']),nama:j['nama_ruangan']?.toString()??j['ruangan']?.toString()??j['nama']?.toString()??'');
}
class PermintaanLinenItem {
  const PermintaanLinenItem({required this.id,required this.tanggalPermintaan,required this.ruangan,required this.status});
  final int id; final String tanggalPermintaan,ruangan,status;
  factory PermintaanLinenItem.fromJson(Map<String,dynamic> j)=>PermintaanLinenItem(id:_toInt(j['id']),tanggalPermintaan:j['tanggal_permintaan']?.toString()??'',ruangan:j['ruangan']?.toString()??j['nama_ruangan']?.toString()??'',status:j['status']?.toString()??'');
}
class PermintaanLinenFormData {
  const PermintaanLinenFormData({required this.data}); final Map<String,dynamic> data;
  factory PermintaanLinenFormData.fromJson(Map<String,dynamic> j)=>PermintaanLinenFormData(data:j);
}
class PermintaanLinenDetail {
  const PermintaanLinenDetail({required this.data}); final Map<String,dynamic> data;
  factory PermintaanLinenDetail.fromJson(Map<String,dynamic> j)=>PermintaanLinenDetail(data:j);
}
class InOutResponse {
  const InOutResponse({required this.data,required this.meta}); final List<Map<String,dynamic>> data; final LinenMeta meta;
  factory InOutResponse.fromJson(Map<String,dynamic> j)=>InOutResponse(data:(j['data'] as List? ?? const []).whereType<Map>().map((e)=>Map<String,dynamic>.from(e)).toList(),meta:LinenMeta.fromJson(Map<String,dynamic>.from((j['meta'] as Map?)??const {})));
}
class RekapanTransaksiSummary {
  const RekapanTransaksiSummary({required this.totalLinenKeluar,required this.totalLinenMasuk,required this.totalBeratMasuk});
  final int totalLinenKeluar,totalLinenMasuk; final double totalBeratMasuk;
  factory RekapanTransaksiSummary.fromJson(Map<String,dynamic> j)=>RekapanTransaksiSummary(totalLinenKeluar:_toInt(j['total_linen_keluar']),totalLinenMasuk:_toInt(j['total_linen_masuk']),totalBeratMasuk:double.tryParse(j['total_berat_masuk']?.toString()??'')??0);
}
class RekapanTransaksiItem {
  const RekapanTransaksiItem({required this.tanggalRaw,required this.tanggal,required this.jumlahLinenKeluar,required this.jumlahLinenMasuk,required this.beratLinenMasuk});
  final String tanggalRaw,tanggal; final int jumlahLinenKeluar,jumlahLinenMasuk; final double beratLinenMasuk;
  factory RekapanTransaksiItem.fromJson(Map<String,dynamic> j)=>RekapanTransaksiItem(tanggalRaw:j['tanggal_raw']?.toString()??'',tanggal:j['tanggal']?.toString()??'',jumlahLinenKeluar:_toInt(j['jumlah_linen_keluar']),jumlahLinenMasuk:_toInt(j['jumlah_linen_masuk']),beratLinenMasuk:double.tryParse(j['berat_linen_masuk']?.toString()??'')??0);
}
class RekapanTransaksiResponse {
  const RekapanTransaksiResponse({required this.ringkasan,required this.data});
  final RekapanTransaksiSummary ringkasan; final List<RekapanTransaksiItem> data;
  factory RekapanTransaksiResponse.fromJson(Map<String,dynamic> j)=>RekapanTransaksiResponse(
    ringkasan: RekapanTransaksiSummary.fromJson(Map<String,dynamic>.from((j['ringkasan'] as Map?)??const {})),
    data:(j['data'] as List? ?? const []).whereType<Map>().map((e)=>RekapanTransaksiItem.fromJson(Map<String,dynamic>.from(e))).toList(),
  );
}
class LinenBelumKembaliItem {
  const LinenBelumKembaliItem({
    required this.id,
    required this.qrCode,
    required this.namaLinen,
    required this.tagRfid,
    required this.namaRuangan,
    required this.namaKategori,
    required this.tanggalKeluar,
    required this.jamKeluar,
  });

  final int id;
  final String qrCode;
  final String namaLinen;
  final String tagRfid;
  final String namaRuangan;
  final String namaKategori;
  final String tanggalKeluar;
  final String jamKeluar;

  factory LinenBelumKembaliItem.fromJson(Map<String, dynamic> j) {
    return LinenBelumKembaliItem(
      id: _toInt(j['id']),
      qrCode: j['qr_code']?.toString() ?? '',
      namaLinen: j['nama_linen']?.toString() ?? '',
      tagRfid: j['tag_rfid']?.toString() ?? '',
      namaRuangan: j['nama_ruangan']?.toString() ?? '',
      namaKategori: j['nama_kategori']?.toString() ?? '',
      tanggalKeluar: j['tanggal_keluar']?.toString() ?? '',
      jamKeluar: j['jam_keluar']?.toString() ?? '',
    );
  }
}

class LinenBelumKembaliResponse {
  const LinenBelumKembaliResponse({
    required this.data,
    required this.meta,
  });

  final List<LinenBelumKembaliItem> data;
  final LinenMeta meta;

  factory LinenBelumKembaliResponse.fromJson(Map<String, dynamic> j) {
    return LinenBelumKembaliResponse(
      data: (j['data'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => LinenBelumKembaliItem.fromJson(
                Map<String, dynamic>.from(e),
              ))
          .toList(),
      meta: LinenMeta.fromJson(
        Map<String, dynamic>.from((j['meta'] as Map?) ?? const {}),
      ),
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
    int? page,
  }) async {
    final query = <String, String>{};
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }
    if (perPage != null) query['per_page'] = perPage.toString();
    if (page != null) query['page'] = page.toString();

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
    int? page,
  }) async {
    final query = <String, String>{};
    if (perPage != null) query['per_page'] = perPage.toString();
    if (page != null) query['page'] = page.toString();

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


  Future<LinenListResponse<LinenLaundryItem>> getLinenLaundry({String? search,int? perPage,int? page}) async {
    final d=await _get('/linen-laundry',query:_query({'search':search,'per_page':perPage,'page':page}));
    return _listResponse(d,(e)=>LinenLaundryItem.fromJson(e));
  }
  Future<LinenLaundryDetailResponse> getLinenLaundryCategory(int kategoriLinen,{int? perPage,int? page}) async => LinenLaundryDetailResponse.fromJson(await _get('/linen-laundry/$kategoriLinen',query:_query({'per_page':perPage,'page':page})));
  Future<LinenListResponse<LinenRuanganItem>> getLinenRuangan({String? search,int? perPage,int? page}) async {
    final d=await _get('/linen-ruangan',query:_query({'search':search,'per_page':perPage,'page':page}));
    return _listResponse(d,(e)=>LinenRuanganItem.fromJson(e));
  }
  Future<LinenRuanganDetailResponse> getLinenRuanganDetail(int ruangan,{int? perPage,int? page}) async => LinenRuanganDetailResponse.fromJson(await _get('/linen-ruangan/$ruangan',query:_query({'per_page':perPage,'page':page})));
  Future<LinenRuanganBaHilangResponse> getLinenRuanganBaHilang(int ruangan,{int? perPage,int? page}) async => LinenRuanganBaHilangResponse.fromJson(await _get('/linen-ruangan/$ruangan/ba-hilang',query:_query({'per_page':perPage,'page':page})));
  Future<LinenListResponse<LinenRusakItem>> getLinenRusak({String? search,int? perPage,int? page}) async {
    final d=await _get('/linen-rusak',query:_query({'search':search,'per_page':perPage,'page':page}));
    return _listResponse(d,(e)=>LinenRusakItem.fromJson(e));
  }
  Future<Map<String,dynamic>> scanLinenRusak(String rfid)=>_post('/linen-rusak/scan',{'rfid':rfid});

  Future<LinenListResponse<LinenHilangItem>> getLinenHilang({String? search,int? perPage,int? filterRuangan,int? filterKategori,String? daterange,int? page}) async {
    final d=await _get('/linen-hilang',query:_query({'per_page':perPage,'search':search,'filter_ruangan':filterRuangan,'filter_kategori':filterKategori,'daterange':daterange,'page':page}));
    return _listResponse(d,(e)=>LinenHilangItem.fromJson(e));
  }
  Future<LinenListResponse<LinenHilangRuanganItem>> getLinenHilangRuanganList({required int ruanganId,int? perPage,int? page}) async {
    final d=await _get('/linen-hilang/ruangan-list',query:_query({'ruangan_id':ruanganId,'per_page':perPage??20,'page':page}));
    return _listResponse(d,(e)=>LinenHilangRuanganItem.fromJson(e));
  }
  Future<Map<String,dynamic>> createLinenHilang({
    required String tanggal,
    required int ruanganId,
    required List<int> linenIds,
    List<int>? beritaAcaraBytes,
    String? beritaAcaraName,
    String? beritaAcaraPath,
  }) async {
    final token=await _requiredToken();
    final r=http.MultipartRequest('POST',Uri.parse('${await ApiConfig.getMobileUrl()}/linen-hilang'));
    r.headers['Authorization']='Bearer $token'; r.headers['Accept']='application/json';
    r.fields['tanggal']=tanggal; r.fields['ruangan_id']=ruanganId.toString();
    for(var i=0;i<linenIds.length;i++){r.fields['linen_id[$i]']=linenIds[i].toString();}
    if(beritaAcaraBytes!=null&&beritaAcaraBytes.isNotEmpty){
      r.files.add(http.MultipartFile.fromBytes('berita_acara',beritaAcaraBytes,filename:beritaAcaraName??'berita_acara'));
    } else if(beritaAcaraPath!=null&&beritaAcaraPath.trim().isNotEmpty){
      r.files.add(await http.MultipartFile.fromPath('berita_acara',beritaAcaraPath));
    }
    return _handleResponse(await http.Response.fromStream(await r.send()));
  }

  Future<LinenListResponse<LinenKeluarItem>> getLinenKeluar({String? search,int? perPage,int? ruangan,String? date,String? daterange,int? page}) async {
    final d=await _get('/linen-keluar',query:_query({'per_page':perPage,'search':search,'ruangan':ruangan,'date':date,'daterange':daterange,'page':page}));
    return _listResponse(d,(e)=>LinenKeluarItem.fromJson(e));
  }
  Future<LinenKeluarOptions> getLinenKeluarOptions() async {
    final d=await _get('/linen-keluar/options'); return LinenKeluarOptions.fromJson(Map<String,dynamic>.from((d['data'] as Map?)??const {}));
  }
  Future<LinenScanQueueResponse> getLinenKeluarScanQueue() async=>LinenScanQueueResponse.fromJson(await _get('/linen-keluar/scan-queue'));
  Future<Map<String,dynamic>> scanLinenKeluar(String rfid)=>_post('/linen-keluar/scan',{'rfid':rfid});
  Future<Map<String,dynamic>> deleteLinenKeluarScan(int linenKeluar)=>_delete('/linen-keluar/scan/$linenKeluar');
  Future<Map<String,dynamic>> saveLinenKeluar({required List<int> linens,required int ruanganId,required int userId})=>_post('/linen-keluar/save',{'linens':linens,'ruangan_id':ruanganId,'user_id':userId});

  Future<LinenListResponse<LinenMasukItem>> getLinenMasuk({String? search,int? perPage,int? ruangan,String? date,String? daterange,int? page}) async {
    final d=await _get('/linen-masuk',query:_query({'per_page':perPage,'search':search,'ruangan':ruangan,'date':date,'daterange':daterange}));
    return _listResponse(d,(e)=>LinenMasukItem.fromJson(e));
  }
  Future<List<LinenRoomOption>> getLinenMasukRuangan() async=>_roomOptions(await _get('/linen-masuk/ruangan'));
  Future<Map<String,dynamic>> scanLinenMasuk(String rfid)=>_post('/linen-masuk/scan',{'rfid':rfid});

  Future<LinenListResponse<PermintaanLinenItem>> getPermintaanLinen({String? search,int? perPage,int? ruangan,String? status,int? page}) async {
    final d=await _get('/permintaan-linen',query:_query({'per_page':perPage,'search':search,'ruangan':ruangan,'status':status}));
    return _listResponse(d,(e)=>PermintaanLinenItem.fromJson(e));
  }
  Future<PermintaanLinenFormData> getPermintaanLinenFormData() async=>PermintaanLinenFormData.fromJson(Map<String,dynamic>.from((await _get('/permintaan-linen/form-data'))['data'] as Map));
  Future<Map<String,dynamic>> createPermintaanLinen({required String tanggalPermintaan,required int ruanganId,required String alasanPermintaan,required List<Map<String,dynamic>> items})=>_post('/permintaan-linen',{'tanggal_permintaan':tanggalPermintaan,'ruangan_id':ruanganId,'alasan_permintaan':alasanPermintaan,'items':items});
  Future<PermintaanLinenDetail> getPermintaanLinenDetail(int id) async=>PermintaanLinenDetail.fromJson(Map<String,dynamic>.from((await _get('/permintaan-linen/$id'))['data'] as Map));
  Future<Map<String,dynamic>> updatePermintaanLinenStatus(int id)=>_patch('/permintaan-linen/$id/status');

  Future<InOutResponse> getInOut({String? search,int? perPage,int? ruangan,String? date,String? daterange,int? page}) async=>InOutResponse.fromJson(await _get('/inout',query:_query({'per_page':perPage,'search':search,'ruangan':ruangan,'date':date,'daterange':daterange})));
  Future<Map<String,dynamic>> getInOutDetail(int ruangan,{String? date,String? daterange})=>_get('/inout/$ruangan',query:_query({'date':date,'daterange':daterange}));
  Future<LinenBelumKembaliResponse> getLinenBelumKembali({
    String? search,
    int? perPage,
    int? ruangan,
    String? date,
    String? daterange,
    int? page,
  }) async {
    final data = await _get(
      '/linen-belum-kembali',
      query: _query({
        'per_page': perPage,
        'search': search,
        'ruangan': ruangan,
        'date': date,
        'daterange': daterange,
        'page': page,
      }),
    );
    return LinenBelumKembaliResponse.fromJson(data);
  }

  Future<List<LinenRoomOption>> getLinenBelumKembaliRuangan() async {
    return _roomOptions(await _get('/linen-belum-kembali/ruangan'));
  }

  Future<RekapanTransaksiResponse> getRekapanTransaksi({String? daterange,int? ruangan,int? page}) async=>RekapanTransaksiResponse.fromJson(await _get('/rekapan-transaksi',query:_query({'daterange':daterange,'ruangan':ruangan,'page':page})));
  Future<List<LinenRoomOption>> getRekapanTransaksiRuangan() async=>_roomOptions(await _get('/rekapan-transaksi/ruangan'));

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

  Map<String, dynamic> _handleResponse(http.Response response) {
    final data = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300 || data['status'] == 'error') {
      throw ApiException(data['message']?.toString() ?? 'Request API gagal.', statusCode: response.statusCode);
    }
    return data;
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
