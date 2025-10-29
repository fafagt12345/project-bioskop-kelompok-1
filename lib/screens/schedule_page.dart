import 'package:flutter/material.dart';
import 'seat_selection_page.dart';

class SchedulePage extends StatelessWidget {
  final int filmId;
  SchedulePage({required this.filmId});

  final List<Map<String,String>> dummy = [
    {'id':'1','date':'2025-11-01','time':'10:00','studio':'Studio 1'},
    {'id':'2','date':'2025-11-01','time':'14:00','studio':'Studio 1'},
    {'id':'3','date':'2025-11-02','time':'19:00','studio':'Studio 2'},
  ];

  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Jadwal')),
      body: ListView.builder(
        itemCount: dummy.length,
        itemBuilder: (ctx,i){
          final j = dummy[i];
          return ListTile(
            title: Text('${j['date']} ${j['time']}'),
            subtitle: Text(j['studio'] ?? ''),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SeatSelectionPage(jadwalId: int.parse(j['id']!)))),
          );
        }
      ),
    );
  }
}
