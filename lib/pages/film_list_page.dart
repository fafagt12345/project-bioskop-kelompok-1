import 'package:flutter/material.dart';
import '../api_service.dart';
import 'film_detail_page.dart';

class FilmListPage extends StatefulWidget {
  const FilmListPage({super.key});
  @override
  State<FilmListPage> createState() => _FilmListPageState();
}

class _FilmListPageState extends State<FilmListPage> {
  final api = ApiService();
  final _search = TextEditingController();
  bool _loading = false;
  List<dynamic> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final page = await api.films(
        perPage: 50,
        search: _search.text.trim().isEmpty ? null : _search.text.trim(),
      );
      setState(() => _items = page.data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Load error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Film')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    decoration: const InputDecoration(
                      hintText: 'Cari judul...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (_) => _load(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Reload')),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final f = Map<String, dynamic>.from(_items[i] as Map);
                        final idRaw = f['film_id'] ?? f['id'] ?? f.values.first;
                        final filmId = (idRaw is int) ? idRaw : (int.tryParse('$idRaw') ?? 0);
                        final title = (f['judul'] ?? f['title'] ?? 'Tanpa Judul').toString();
                        final sinopsis = (f['sinopsis'] ?? '').toString();

                        return ListTile(
                          title: Text(title),
                          subtitle: Text(sinopsis, maxLines: 2, overflow: TextOverflow.ellipsis),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => FilmDetailPage(filmId: filmId, initial: f)),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
