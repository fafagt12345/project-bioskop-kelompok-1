import 'package:flutter/material.dart';
import '../api_service.dart';
import '../theme/app_theme.dart';
import 'film_form_page.dart'; // <-- PENTING: import form
import 'film_detail_page.dart'; // opsional: untuk lihat detail

class FilmListPage extends StatefulWidget {
  const FilmListPage({super.key});

  @override
  State<FilmListPage> createState() => _FilmListPageState();
}

class _FilmListPageState extends State<FilmListPage> {
  final api = ApiService();

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await api.films(perPage: 200);
      final list = res.data.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map)).toList();
      setState(() => _items = list);
    } catch (e) {
      setState(() => _error = 'Gagal memuat film: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  dynamic _filmIdOf(Map<String, dynamic> m) {
    final raw = m['film_id'] ?? m['id'] ?? m['ID'];
    if (raw is int) return raw;
    return int.tryParse('$raw');
  }

  String _titleOf(Map<String, dynamic> m) {
    return (m['judul'] ?? m['title'] ?? 'Tanpa Judul').toString();
  }

  String _subtitleOf(Map<String, dynamic> m) {
    final genreName = (m['genre_name'] ?? m['genre_nama'] ?? m['genre'])?.toString();
    final genreId   = (m['genre_id'] ?? m['id_genre']);
    final durasi    = m['durasi']?.toString();
    final g = (genreName != null && genreName.isNotEmpty)
        ? 'Genre: $genreName'
        : (genreId != null ? 'Genre ID: $genreId' : 'Genre: -');
    final d = (durasi != null && durasi.isNotEmpty) ? ' • $durasi m' : '';
    return '$g$d';
  }

  Future<void> _create() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => FilmFormPage()),
    );
    if (saved == true) _load();
  }

  Future<void> _edit(Map<String, dynamic> film) async {
    final id = _filmIdOf(film);
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ID film tidak valid')));
      return;
    }
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => FilmFormPage(
          filmId: id as int,
          initial: Map<String, dynamic>.from(film),
        ),
      ),
    );
    if (saved == true) _load();
  }

  Future<void> _delete(Map<String, dynamic> film) async {
    final id = _filmIdOf(film);
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ID film tidak valid')));
      return;
    }
    final sure = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Film'),
        content: Text('Yakin ingin menghapus "${_titleOf(film)}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
        ],
      ),
    ) ?? false;

    if (!sure) return;

    try {
      await api.deleteFilm(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Film dihapus')));
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal hapus: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.light.colorScheme.primary;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Film'),
        backgroundColor: primary,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        backgroundColor: primary,
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(_error!, textAlign: TextAlign.center),
                ))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final film = _items[i];
                      return ListTile(
                        title: Text(_titleOf(film), style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(_subtitleOf(film)),
                        onTap: () {
                          final id = _filmIdOf(film);
                          if (id != null) {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (_) => FilmDetailPage(filmId: id as int, initial: film),
                            ));
                          }
                        },
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Edit',
                              icon: const Icon(Icons.edit),
                              onPressed: () => _edit(film),
                            ),
                            IconButton(
                              tooltip: 'Hapus',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _delete(film),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
