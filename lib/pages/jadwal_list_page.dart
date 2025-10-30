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
  List<Map<String, dynamic>> _rows = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await api.jadwalByFilm(widget.filmId);
      final parsed = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      setState(() => _rows = parsed);
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _timeOf(Map<String, dynamic> j) {
    return (j['tanggal_waktu'] ?? j['waktu'] ?? j['jam_tayang'] ?? j['tanggal'] ?? '-').toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Jadwal • ${widget.filmTitle}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Gagal memuat: $_error'))
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _rows.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final j = _rows[i];
                    final idRaw = j['jadwal_id'] ?? j['id'] ?? j.values.first;
                    final jadwalId = (idRaw is int) ? idRaw : (int.tryParse('$idRaw') ?? 0);
                    final studio = (j['studio_id'] ?? j['studio'] ?? '-').toString();

                    return ListTile(
                      title: Text(_timeOf(j)),
                      subtitle: Text('Studio: $studio • ID: $jadwalId'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SeatSelectionPage(
                            jadwalId: jadwalId,
                            filmTitle: widget.filmTitle,
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
