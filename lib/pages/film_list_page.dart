import 'package:flutter/material.dart';
import '../api_service.dart';
import 'film_detail_page.dart';
import '../theme/app_theme.dart';

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

  // helper untuk memilih asset cover berdasarkan judul / field poster
  String? _assetForFilm(Map<String, dynamic> f) {
    final title = (f['judul'] ?? f['title'] ?? '').toString().toLowerCase();
    if (title.contains('avangers') || title.contains('avengers') || title.contains('endgame')) return 'assets/Avangers_EndGame.png';
    if (title.contains('laskar')) return 'assets/LaskarPelangi.png';
    if (title.contains('stupid') || title.contains('my stupid boss')) return 'assets/MyStupidBoss.png';
    if (title.contains('pengabdi') || title.contains('setan')) return 'assets/PengabdiSetan.png';
    if (title.contains('toystory') || title.contains('toy story') || title.contains('toy')) return 'assets/ToyStory_4.png';
    final poster = f['poster']?.toString();
    if (poster != null && poster.isNotEmpty) return poster.startsWith('http') ? poster : (poster.startsWith('assets/') ? poster : 'assets/$poster');
    return null;
  }

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

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.light.colorScheme.primary;
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Film'), backgroundColor: primary),
      backgroundColor: primary.withOpacity(0.04),
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
                        final title = (f['judul'] ?? f['title'] ?? 'Tanpa Judul').toString();
                        final sinopsis = (f['sinopsis'] ?? '').toString();
                        final filmId = _toInt(f['film_id'] ?? f['id']);
                        final cover = _assetForFilm(f);
                        Widget leading;
                        if (cover != null) {
                          final isNetwork = cover.startsWith('http://') || cover.startsWith('https://');
                          leading = ClipRRect(
                            borderRadius: BorderRadius.circular(6), // lebih kecil untuk thumbnail kecil
                            child: SizedBox(
                              width: 40,  // lebih kecil dari 50
                              height: 60, // lebih kecil dari 75, tetap rasio 2:3
                              child: isNetwork
                                  ? Image.network(
                                      cover,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                                    )
                                  : Image.asset(
                                      cover,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                                    ),
                            ),
                          );
                        } else {
                          leading = CircleAvatar(backgroundColor: primary, child: const Icon(Icons.movie, color: Colors.white));
                        }

                        return ListTile(
                          leading: leading,
                          title: Text(title),
                          subtitle: Text(sinopsis, maxLines: 2, overflow: TextOverflow.ellipsis),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FilmDetailPage(filmId: filmId, initial: f))),
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
