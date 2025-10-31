import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:shared_preferences/shared_preferences.dart';

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
        perPage: json['per_page'] is int
            ? json['per_page']
            : int.tryParse('${json['per_page'] ?? 10}') ?? 10,
        total: json['total'] ?? (json['data'] is List ? (json['data'] as List).length : 0),
      );
    }
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

  // cache genre: id -> name
  Map<int, String>? _genreCache;

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

  // ===== TOKEN STORAGE =====
  static const _tokenKey = 'auth_token';

  Future<String?> getStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> setToken(String? token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString(_tokenKey, token);
    } else {
      await prefs.remove(_tokenKey);
    }
  }

  Future<void> logout() async {
    try { await _dio.post('/auth/logout'); } catch (_) {}
    await setToken(null);
  }

  // ===== AUTH =====
  Future<Map<String, dynamic>> register(
    String username,
    String password, {
    String? name,
    String? email,
  }) async {
    try {
      final res = await _dio.post('/auth/register', data: {
        'username': username,
        'password': password,
        if (name != null) 'name': name,
        if (email != null) 'email': email,
      });
      return _toMap(res.data);
    } on DioException catch (e) {
      throw _wrap(e);
    }
  }

  Future<String> login(String username, String password) async {
    try {
      final res = await _dio.post('/auth/login', data: {
        'username': username,
        'password': password,
      });
      final m = _toMap(res.data);
      final t = (m['token'] ?? '') as String;
      if (t.isNotEmpty) await setToken(t);
      return t;
    } on DioException catch (e) {
      throw _wrap(e);
    }
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
    } on DioException catch (e) {
      throw _wrap(e);
    }
  }

  Future<Map<String, dynamic>> filmDetail(dynamic id) async {
    try {
      final res = await _dio.get('/film/$id');
      return _toMap(res.data);
    } on DioException catch (e) {
      throw _wrap(e);
    }
  }

  Future<Map<String, dynamic>> createFilm(Map<String, dynamic> body) async {
    try {
      final res = await _dio.post('/film', data: body);
      return _toMap(res.data);
    } on DioException catch (e) {
      throw _wrap(e);
    }
  }

  Future<void> deleteFilm(dynamic id) async {
    try {
      await _dio.delete('/film/$id');
    } on DioException catch (e) {
      throw _wrap(e);
    }
  }

  // ===== JADWAL =====
  Future<List<dynamic>> jadwalByFilm(int filmId) async {
    try {
      final res = await _dio.get('/jadwal/by-film/$filmId');
      final d = res.data;
      if (d is List) return d;
      if (d is Map && d['data'] is List) return d['data'];
      return <dynamic>[];
    } on DioException catch (e) {
      throw _wrap(e);
    }
  }

   // ===== SEATS =====
  Future<List<dynamic>> seatsAvailable(int jadwalId) async {
    try {
      final res = await _dio.get('/jadwal/$jadwalId/seats');

      // Ambil list mentah dari server
      final raw = (res.data is List)
          ? (res.data as List)
          : (res.data is Map && res.data['data'] is List
              ? (res.data['data'] as List)
              : const <dynamic>[]);

      // Normalisasi agar harga selalu numerik dan punya alias
      final normalized = raw.map((e) {
        final m = Map<String, dynamic>.from(e as Map);

        num hargaNum;
        final v = m['harga'];
        if (v is num) {
          hargaNum = v;
        } else {
          // coba parse dari string "50000.00"
          final asInt = int.tryParse('$v');
          if (asInt != null) {
            hargaNum = asInt;
          } else {
            final asDouble = double.tryParse('$v');
            hargaNum = asDouble?.round() ?? 0;
          }
        }

        // fallback ke price dari server jika ada
        if ((hargaNum == 0) && m.containsKey('price')) {
          final pv = m['price'];
          if (pv is num) hargaNum = pv;
          else {
            final pi = int.tryParse('$pv') ?? (double.tryParse('$pv')?.round() ?? 0);
            hargaNum = pi;
          }
        }

        m['harga']     = hargaNum;
        m['price']     = hargaNum;
        m['harga_int'] = hargaNum;

        // rapikan status
        final st = (m['status'] ?? 'tersedia').toString().toLowerCase();
        m['status'] = (st == 'sold' || st == 'terjual') ? 'terjual' : 'tersedia';

        return m;
      }).toList();

      return normalized;
    } on DioException catch (e) {
      throw _wrap(e);
    }
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
        'jadwal_id': jadwalId,
        'kursi_ids': kursiIds,
        if (kasirId != null) 'kasir_id': kasirId,
      });
      return _toMap(res.data);
    } on DioException catch (e) {
      throw _wrap(e);
    }
  }

  // ===== GENRES (cache + fallback detail; tidak melempar ketika list gagal) =====
  Future<Map<int, String>> _ensureGenres() async {
    if (_genreCache != null) return _genreCache!;
    final map = <int, String>{};
    try {
      final res = await _dio.get('/genres');
      final list = (res.data is List)
          ? (res.data as List)
          : (res.data is Map && res.data['data'] is List
              ? res.data['data'] as List
              : const <dynamic>[]);

      for (final it in list) {
        final m = _toMap(it);
        final rawId = m['id_genre'] ?? m['genre_id'] ?? m['id'];
        final name  = (m['nama'] ?? m['nama_genre'] ?? m['name'] ?? m['judul'] ?? '').toString();
        final id = rawId is int ? rawId : int.tryParse('$rawId');
        if (id != null && name.isNotEmpty) {
          map[id] = name;
        }
      }
    } catch (_) {
      // Jangan lempar error—biarkan kosong, nanti fallback /genres/{id}
    }
    _genreCache = map;
    return map;
  }

  Future<String?> genreNameById(int? id) async {
    if (id == null) return null;

    // 1) coba cache/list
    try {
      final map = await _ensureGenres();
      final fromCache = map[id];
      if (fromCache != null && fromCache.isNotEmpty) return fromCache;
    } catch (_) {}

    // 2) fallback GET /genres/{id}
    try {
      final res = await _dio.get('/genres/$id');
      final m = _toMap(res.data);
      final name = (m['nama'] ?? m['nama_genre'] ?? m['name'] ?? m['judul'])?.toString();
      if (name != null && name.isNotEmpty) {
        _genreCache ??= {};
        _genreCache![id] = name;
        return name;
      }
    } catch (_) {}
    return null;
  }

  // ===== Utils =====
  ApiException _wrap(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    final msg = (data is Map && data['message'] is String)
        ? data['message']
        : e.message ?? 'Request error';
    return ApiException(msg, status: status, data: data);
  }

  Map<String, dynamic> _toMap(dynamic d) =>
      (d is Map<String, dynamic>) ? d : Map<String, dynamic>.from(d as Map);
}
