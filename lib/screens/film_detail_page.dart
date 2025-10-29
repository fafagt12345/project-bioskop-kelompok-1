import 'package:flutter/material.dart';
import '../models/film.dart';
import 'schedule_page.dart';

class FilmDetailPage extends StatelessWidget {
  final Film film;
  FilmDetailPage({required this.film});

  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(film.title)),
      body: Padding(
        padding: EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Icon(Icons.movie, size:120)),
          SizedBox(height:12),
          Text('Durasi: ${film.duration} menit', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height:8),
          Text('Sinopsis:'),
          Text(film.synopsis),
          Spacer(),
          Center(
            child: ElevatedButton(
              child: Text('Lihat Jadwal'),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SchedulePage(filmId: film.id))),
            ),
          )
        ]),
      ),
    );
  }
}
