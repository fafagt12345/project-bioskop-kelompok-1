import 'package:flutter/material.dart';
import '../api_service.dart';
import 'jadwal_list_page.dart';

class FilmDetailPage extends StatefulWidget {
  final int filmId;
  final Map<String, dynamic>? initial;
  const FilmDetailPage({super.key, required this.filmId, this.initial});

  @override
  State<FilmDetailPage> createState() => _FilmDetailPageState();
}

class _FilmDetailPageState extends State<FilmDetailPage> {
  final api = ApiService();
  bool _loading = true;
  Map<String, dynamic>? _film;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) _film = Map<String, dynamic>.from(widget.initial!);
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await api.filmDetail(widget.filmId);
      setState(() => _film = data);
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = (_film?['judul'] ?? _film?['title'] ?? 'Detail Film').toString();
    final sinopsis = (_film?['sinopsis'] ?? '').toString();
    final durasi = _film?['durasi']?.toString() ?? '-';
    final genreId = _film?['genre_id']?.toString() ?? '-';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            onPressed: _film == null ? null : () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => JadwalListPage(filmId: widget.filmId, filmTitle: title)),
              );
            },
            icon: const Icon(Icons.event),
            label: const Text('Lihat Jadwal'),
          ),
        ),
      ),
      body: _loading && _film == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Gagal memuat: $_error'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Row(children: [
                        _Chip(label: 'Durasi: ${durasi}m'),
                        const SizedBox(width: 8),
                        _Chip(label: 'Genre ID: $genreId'),
                      ]),
                      const SizedBox(height: 16),
                      const Text('Sinopsis', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text(sinopsis.isEmpty ? '-' : sinopsis),
                    ],
                  ),
                ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip({required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(label),
    );
  }
}
