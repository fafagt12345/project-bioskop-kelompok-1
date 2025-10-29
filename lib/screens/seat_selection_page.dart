import 'package:flutter/material.dart';
import '../models/seat.dart';

class SeatSelectionPage extends StatefulWidget {
  final int jadwalId;
  SeatSelectionPage({required this.jadwalId});

  @override State<SeatSelectionPage> createState() => _SeatSelectionPageState();
}

class _SeatSelectionPageState extends State<SeatSelectionPage> {
  List<Seat> seats = [];
  List<int> selected = [];

  @override void initState() {
    super.initState();
    // generate dummy seats: A1..A6, B1..B6, C1..C6, D1..D6
    int id = 1;
    for (var r in ['A', 'B', 'C', 'D']) {
      for (int i = 1; i <= 6; i++) {
        // use proper Dart string interpolation so `r` and `i` are used
        seats.add(Seat(ticketId: id, seatNumber: '$r$i', isAvailable: !(id % 7 == 0)));
        id++;
      }
    }
  }

  void toggle(int ticketId) {
    setState(() {
      if(selected.contains(ticketId)) selected.remove(ticketId);
      else selected.add(ticketId);
    });
  }

  void checkout() {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: Text('Pembayaran'),
      content: Text('Pembelian sukses! Jumlah tiket: \${selected.length}'),
      actions: [
        TextButton(onPressed: () => Navigator.of(context)..pop()..pop(), child: Text('OK'))
      ],
    ));
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pilih Kursi')),
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(12),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, mainAxisSpacing:8, crossAxisSpacing:8),
              itemCount: seats.length,
              itemBuilder: (ctx,i){
                final s = seats[i];
                final isSelected = selected.contains(s.ticketId);
                return GestureDetector(
                  onTap: s.isAvailable ? () => toggle(s.ticketId) : null,
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: s.isAvailable ? (isSelected ? Colors.green : Colors.white) : Colors.grey[400],
                      border: Border.all(color: Colors.black26),
                      borderRadius: BorderRadius.circular(6)
                    ),
                    child: Text(s.seatNumber),
                  ),
                );
              }
            ),
          ),
          Padding(
            padding: EdgeInsets.all(12),
            child: Row(children: [
              Expanded(child: Text('Selected: \${selected.length}')),
              ElevatedButton(onPressed: selected.isNotEmpty ? checkout : null, child: Text('Bayar'))
            ]),
          )
        ],
      ),
    );
  }
}
