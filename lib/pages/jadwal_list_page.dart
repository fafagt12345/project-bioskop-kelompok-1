import 'package:flutter/material.dart';
import '../api_service.dart';
import 'seat_selection_page.dart';

class JadwalListPage extends StatefulWidget {
  final int filmId;
  final String filmTitle;
  const JadwalListPage({super.key, required this.filmId, required this.filmTitle});

  @override
  State<JadwalListPage> createState() => _JadwalListPageState();
}

class _JadwalListPageState extends State<JadwalListPage> {
  final api = ApiService();
  bool _loading = true;
  List<dynamic> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final rows = await api.jadwalByFilm(widget.filmId);
      setState(() => _items = rows);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal load jadwal: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Jadwal • ${widget.filmTitle}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final j = _items[i] as Map<String, dynamic>;
                final id = j['jadwal_id'] ?? j['id'] ?? j.values.first;
                final tanggal = (j['tanggal'] ?? '').toString();
                final mulai = (j['jam_mulai'] ?? '').toString();
                final selesai = (j['jam_selesai'] ?? '').toString();
                final studio = (j['studio_id'] ?? j['studio'] ?? '').toString();
                return ListTile(
                  title: Text('$tanggal  $mulai - $selesai'),
                  subtitle: Text('Studio: $studio'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    final jid = id is int ? id : int.tryParse('$id') ?? 0;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SeatSelectionPage(
                          jadwalId: jid,
                          filmTitle: widget.filmTitle,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
