import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static const _storageKey = 'api_base_url';

  static const defaultBaseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: '',
  );

  static String? _savedBaseUrl;

  static Future<String?> getBaseUrl() async {
    if (_savedBaseUrl != null) return _savedBaseUrl;

    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_storageKey)?.trim();
    if (saved != null && saved.isNotEmpty) {
      _savedBaseUrl = normalize(saved);
      return _savedBaseUrl;
    }

    final env = defaultBaseUrl.trim();
    if (env.isNotEmpty) {
      _savedBaseUrl = normalize(env);
      return _savedBaseUrl;
    }

    return null;
  }

  static Future<void> saveBaseUrl(String value) async {
    final normalized = normalize(value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, normalized);
    _savedBaseUrl = normalized;
  }

  static Future<void> clearBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    _savedBaseUrl = null;
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
    final base = await getBaseUrl();
    if (base == null || base.isEmpty) {
      throw const ApiException('Base URL belum dikonfigurasi.');
    }
    return '$base/api/mobile';
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
      jumlahStok: (json['jumlah_stok'] as num?)?.toInt() ?? 0,
      jumlahHilang: (json['jumlah_hilang'] as num?)?.toInt() ?? 0,
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

class LinenListResponse {
  const LinenListResponse({required this.data, required this.meta});

  final List<LinenCategory> data;
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

  Future<LinenListResponse> getLinen({
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
