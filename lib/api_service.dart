import 'dart:async';
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
        total: json['total'] ?? (json['data'] is List ? (json['data'] as List).length : 0),
      );
    }
    // fallback: array biasa
    final list = (json is List)
        ? json
        : (json is Map && json['data'] is List ? (json['data'] as List) : <dynamic>[]);
    return PaginatedResponse(
      data: list,
      currentPage: 1,
      lastPage: 1,
      perPage: list.length,
      total: list.length,
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

  ApiService({String? base})
      : baseUrl = base ?? suggestBaseUrl(),
        _dio = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 20),
            headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
          ),
        ) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (opt, handler) {
        if (!opt.path.startsWith('http')) {
          final prefix = base ?? suggestBaseUrl();
          final norm = opt.path.startsWith('/api/')
              ? opt.path
              : '/api${opt.path.startsWith('/') ? '' : '/'}${opt.path}';
          opt.baseUrl = prefix;
          opt.path = norm;
        }
        if (_token != null && _token!.isNotEmpty) {
          opt.headers['Authorization'] = 'Bearer $_token';
        }
        handler.next(opt);
      },
      onError: (e, h) => h.next(e),
    ));
  }

  void setToken(String? token) => _token = token;

  // ===== AUTH =====
  Future<Map<String, dynamic>> register(String username, String password, {String? name, String? email}) async {
    try {
      final res = await _dio.post('/auth/register', data: {
        'username': username,
        'password': password,
        if (name != null) 'name': name,
        if (email != null) 'email': email,
      });
      return _toMap(res.data);
    } on DioException catch (e) { throw _wrap(e); }
  }

  Future<String> login(String username, String password) async {
    try {
      final res = await _dio.post('/auth/login', data: {'username': username, 'password': password});
      final m = _toMap(res.data);
      final t = (m['token'] ?? '') as String;
      if (t.isNotEmpty) setToken(t);
      return t;
    } on DioException catch (e) { throw _wrap(e); }
  }

  // ===== FILM =====
  Future<PaginatedResponse> films({int page = 1, int perPage = 50, String? search}) async {
    try {
      final qp = <String, dynamic>{
        'page': page,
        'per_page': perPage,
        if (search != null && search.isNotEmpty) 'search': search,
      };
      final res = await _dio.get('/film', queryParameters: qp);
      return PaginatedResponse.from(res.data);
    } on DioException catch (e) { throw _wrap(e); }
  }

  Future<Map<String, dynamic>> filmDetail(dynamic id) async {
    try {
      final res = await _dio.get('/film/$id');
      return _toMap(res.data);
    } on DioException catch (e) { throw _wrap(e); }
  }

  Future<Map<String, dynamic>> createFilm(Map<String, dynamic> body) async {
    try {
      final res = await _dio.post('/film', data: body);
      return _toMap(res.data);
    } on DioException catch (e) { throw _wrap(e); }
  }

  Future<void> deleteFilm(dynamic id) async {
    try { await _dio.delete('/film/$id'); }
    on DioException catch (e) { throw _wrap(e); }
  }

  // ===== JADWAL =====
  Future<List<dynamic>> jadwalByFilm(int filmId) async {
    try {
      final res = await _dio.get('/jadwal/by-film/$filmId');
      final d = res.data;
      if (d is List) return d;
      if (d is Map && d['data'] is List) return d['data'];
      return <dynamic>[];
    } on DioException catch (e) { throw _wrap(e); }
  }

  // ===== SEATS =====
  Future<List<dynamic>> seatsAvailable(int jadwalId) async {
    try {
      final res = await _dio.get('/jadwal/$jadwalId/seats');
      if (res.data is List) return res.data as List;
      if (res.data is Map && res.data['data'] is List) return res.data['data'];
      return <dynamic>[];
    } on DioException catch (e) { throw _wrap(e); }
  }

  // ===== CHECKOUT =====
  Future<Map<String, dynamic>> checkout({
    required int customerId,
    required int jadwalId,
    required List<int> kursiIds,
    int? kasirId,
  }) async {
    try {
      final res = await _dio.post('/checkout', data: {
        'customer_id': customerId,
        'jadwal_id'  : jadwalId,
        'kursi_ids'  : kursiIds,
        if (kasirId != null) 'kasir_id': kasirId,
      });
      return _toMap(res.data);
    } on DioException catch (e) { throw _wrap(e); }
  }

  // ===== Utils =====
  ApiException _wrap(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    final msg = (data is Map && data['message'] is String)
        ? data['message'] : e.message ?? 'Request error';
    return ApiException(msg, status: status, data: data);
  }

  Map<String, dynamic> _toMap(dynamic d) =>
      (d is Map<String, dynamic>) ? d : Map<String, dynamic>.from(d as Map);
}
