import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

class ApiException implements Exception {
  final String message;
  final int? status;
  final dynamic data;
  ApiException(this.message, {this.status, this.data});
  @override
  String toString() => 'ApiException($status): $message';
}

class PaginatedResponse {
  final List<dynamic> data;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  PaginatedResponse({
    required this.data,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory PaginatedResponse.from(dynamic json) {
    if (json is Map && json.containsKey('data') && json.containsKey('current_page')) {
      return PaginatedResponse(
        data: (json['data'] as List?) ?? const [],
        currentPage: json['current_page'] ?? 1,
        lastPage: json['last_page'] ?? 1,
        perPage: json['per_page'] is int ? json['per_page'] : int.tryParse('${json['per_page'] ?? 10}') ?? 10,
        total: json['total'] ?? ((json['data'] is List) ? (json['data'] as List).length : 0),
      );
    }
    return PaginatedResponse(
      data: (json is List) ? json : (json is Map && json['data'] is List ? (json['data'] as List) : []),
      currentPage: 1, lastPage: 1,
      perPage: (json is List) ? json.length : 0,
      total: (json is List) ? json.length : (json is Map && json['data'] is List ? (json['data'] as List).length : 0),
    );
  }
}

class ApiService {
  final Dio _dio;
  final String baseUrl;
  String? _token;

  static String suggestBaseUrl() {
    if (kIsWeb) return 'http://127.0.0.1:8000';
    if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:8000';
    return 'http://127.0.0.1:8000';
  }

  static String baseFromEnv() => const String.fromEnvironment('API_BASE_URL');

  ApiService({String? base})
      : baseUrl = (base ?? (baseFromEnv().isNotEmpty ? baseFromEnv() : suggestBaseUrl())),
        _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 20),
          headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
        )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (!options.path.startsWith('http')) {
          final norm = options.path.startsWith('/api/')
              ? options.path
              : '/api${options.path.startsWith('/') ? '' : '/'}${options.path}';
          options.baseUrl = baseUrl;
          options.path = norm;
        }
        if (_token != null && _token!.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        handler.next(options);
      },
      onError: (e, h) => h.next(e),
    ));
  }

  void setToken(String? token) => _token = token;

  // ---- FILM ----
  Future<PaginatedResponse> films({int page = 1, int perPage = 20, String? search}) async {
    try {
      final res = await _dio.get('/film', queryParameters: {
        'page': page, 'per_page': perPage, if (search != null && search.isNotEmpty) 'search': search,
      });
      return PaginatedResponse.from(res.data);
    } on DioException catch (e) {
      throw _wrap(e);
    }
  }

Future<Map<String, dynamic>> filmDetail(dynamic id) async {
  try {
    final res = await _dio.get('/film/$id');
    final d = res.data;

    if (d is Map) {
      if (d['data'] is Map) return Map<String, dynamic>.from(d['data'] as Map);
      if (d['film'] is Map) return Map<String, dynamic>.from(d['film'] as Map);
      return Map<String, dynamic>.from(d);
    }
    throw ApiException('Format response tidak dikenali', status: res.statusCode, data: d);
  } on DioException catch (e) {
    throw _wrap(e);
  }
}

  Future<Map<String, dynamic>> createFilm(Map<String, dynamic> body) async {
    try {
      final res = await _dio.post('/film', data: body);
      return Map<String, dynamic>.from(res.data as Map);
    } on DioException catch (e) {
      throw _wrap(e);
    }
  }

  Future<void> deleteFilm(dynamic id) async {
    try { await _dio.delete('/film/$id'); }
    on DioException catch (e) { throw _wrap(e); }
  }

  // ---- JADWAL ----
  Future<List<dynamic>> jadwalByFilm(int filmId) async {
    try {
      // pakai endpoint alias yang kita sediakan di api.php
      final res = await _dio.get('/jadwal/by-film/$filmId');
      return (res.data is List) ? res.data as List : (res.data is Map && res.data['data'] is List ? res.data['data'] as List : []);
    } on DioException catch (e) {
      throw _wrap(e);
    }
  }

  // ---- KURSI ----
  Future<List<dynamic>> seatsAvailable(int jadwalId) async {
    try {
      // pakai alias baru; ada alias lama /jadwal/{jadwalId}/seats juga di api.php
      final res = await _dio.get('/jadwal/$jadwalId/kursi-tersedia');
      return (res.data is List) ? res.data as List : (res.data is Map && res.data['data'] is List ? res.data['data'] as List : []);
    } on DioException catch (e) {
      throw _wrap(e);
    }
  }

  // ---- CHECKOUT ----
  Future<Map<String, dynamic>> checkout({
    required int customerId,
    required int jadwalId,
    required List<int> kursiIds,
    int? kasirId,
  }) async {
    try {
      final res = await _dio.post('/checkout', data: {
        'customer_id': customerId,
        'jadwal_id': jadwalId,
        'kursi_ids': kursiIds,
        if (kasirId != null) 'kasir_id': kasirId,
      });
      return Map<String, dynamic>.from(res.data as Map);
    } on DioException catch (e) {
      throw _wrap(e);
    }
  }

  // (opsional) Auth bila perlu
  Future<String> login(String username, String password) async {
    try {
      final res = await _dio.post('/auth/login', data: {'username': username, 'password': password});
      final map = (res.data is Map) ? res.data as Map : {};
      final token = (map['token'] ?? '').toString();
      if (token.isEmpty) throw ApiException('Token kosong dari server', status: res.statusCode, data: map);
      return token;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 404) {
        throw ApiException('Username atau password salah', status: e.response?.statusCode, data: e.response?.data);
      }
      throw _wrap(e);
    }
  }

  Future<Map<String, dynamic>> register(String username, String password, {String? name, String? email}) async {
    try {
      final res = await _dio.post('/auth/register', data: {
        'username': username,
        'password': password,
        if (name != null && name.isNotEmpty) 'name': name,
        if (email != null && email.isNotEmpty) 'email': email,
      });
      return Map<String, dynamic>.from(res.data as Map);
    } on DioException catch (e) {
      throw _wrap(e);
    }
  }

  ApiException _wrap(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    final msg = (data is Map && data['message'] is String) ? data['message'] : e.message ?? 'Request error';
    return ApiException(msg, status: status, data: data);
  }
}
