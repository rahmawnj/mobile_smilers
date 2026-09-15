import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static const baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  static String get mobileUrl => '$baseUrl/api/mobile';
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

class ApiService {
  static final ApiService instance = ApiService._();

  ApiService._();

  Future<AuthResponse> login({
    required String username,
    required String password,
    String deviceName = 'mobile-app',
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.mobileUrl}/login'),
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
      Uri.parse('${ApiConfig.mobileUrl}/me'),
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

  Future<void> logout() async {
    final token = await getToken();

    if (token != null && token.isNotEmpty) {
      try {
        final response = await http.post(
          Uri.parse('${ApiConfig.mobileUrl}/logout'),
          headers: _authHeaders(token),
        );

        if (response.statusCode != 200) {
          final data = _decode(response);
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
