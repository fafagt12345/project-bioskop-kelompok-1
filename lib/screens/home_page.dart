import 'package:flutter/material.dart';
import '../models/film.dart';
import 'film_detail_page.dart';

class HomePage extends StatelessWidget {
  final List<Film> films = [
    Film(id:1, title:'The Example: Action', duration:'120', synopsis:'Film aksi contoh', poster:''),
    Film(id:2, title:'Drama Contoh', duration:'105', synopsis:'Film drama contoh', poster:''),
    Film(id:3, title:'Komedi Ringan', duration:'95', synopsis:'Film komedi contoh', poster:''),
  ];

  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Bioskop - Film')),
      body: ListView.builder(
        itemCount: films.length,
        itemBuilder: (ctx,i){
          final f = films[i];
          return ListTile(
            leading: Icon(Icons.movie),
            title: Text(f.title),
            subtitle: Text('${f.duration} menit'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FilmDetailPage(film: f))),
          );
        }
      ),
    );
  }
}
