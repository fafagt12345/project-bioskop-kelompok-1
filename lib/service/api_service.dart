import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const baseUrl = 'http://10.0.2.2:8000/api';

  Future<void> addFilm(Map<String, dynamic> film) async {
    final response = await http.post(
      Uri.parse('$baseUrl/films'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(film),
    );

    if (response.statusCode == 201) {
      print('✅ Film berhasil ditambahkan');
    } else {
      print('❌ Gagal menambahkan film: ${response.body}');
    }
  }
}
