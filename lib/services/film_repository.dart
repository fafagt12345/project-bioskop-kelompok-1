import 'package:sqflite/sqflite.dart';
import '../models/film.dart';
import 'db_helper.dart';

class FilmRepository {
  final DBHelper _dbHelper = DBHelper();

  Future<List<Film>> getFilms() async {
    final db = await _dbHelper.db;
    final List<Map<String, dynamic>> maps = await db.query('films', orderBy: 'id ASC');

    if (maps.isEmpty) {
      // Seed sample data jika kosong
      final seed = [
        Film(id: 1, title: 'The Example: Action', duration: '120', synopsis: 'Film aksi contoh', poster: ''),
        Film(id: 2, title: 'Drama Contoh', duration: '105', synopsis: 'Film drama contoh', poster: ''),
        Film(id: 3, title: 'Komedi Ringan', duration: '95', synopsis: 'Film komedi contoh', poster: ''),
      ];
      for (var f in seed) {
        await db.insert('films', f.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      // Ambil lagi setelah seed
      final List<Map<String, dynamic>> maps2 = await db.query('films', orderBy: 'id ASC');
      return maps2.map((m) => Film.fromMap(m)).toList();
    }

    return maps.map((m) => Film.fromMap(m)).toList();
  }

  Future<void> refreshSeedIfNeeded() async {
    // placeholder jika butuh update seed atau sinkronisasi
  }
}
