import 'package:dio/dio.dart';

class ApiClient {
  final Dio dio;
  ApiClient(String baseUrl)
      : dio = Dio(BaseOptions(baseUrl: baseUrl, connectTimeout: const Duration(seconds: 10)));

  Future<List<dynamic>> list(String table, {int page=1, int perPage=10, String? search}) async {
    final res = await dio.get('/api/$table', queryParameters: {
      'page': page, 'per_page': perPage, if (search != null && search.isNotEmpty) 'search': search
    });
    return res.data['data'] ?? (res.data is List ? res.data : []);
  }

  Future<Map<String,dynamic>> getOne(String table, dynamic id) async {
    final res = await dio.get('/api/$table/$id');
    return Map<String,dynamic>.from(res.data);
  }

  Future<Map<String,dynamic>> create(String table, Map<String,dynamic> body) async {
    final res = await dio.post('/api/$table', data: body);
    return Map<String,dynamic>.from(res.data);
  }

  Future<Map<String,dynamic>> update(String table, dynamic id, Map<String,dynamic> body) async {
    final res = await dio.put('/api/$table/$id', data: body);
    return Map<String,dynamic>.from(res.data);
  }

  Future<void> delete(String table, dynamic id) async {
    await dio.delete('/api/$table/$id');
  }
}
