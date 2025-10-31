import 'package:flutter/material.dart';
import '../api_service.dart';
import 'jadwal_list_page.dart';
import '../theme/app_theme.dart';

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

  String? _assetForFilm(Map<String, dynamic>? film) {
    final title = (film?['judul'] ?? film?['title'] ?? '').toString().toLowerCase();
    if (title.contains('avangers') || title.contains('avengers') || title.contains('endgame')) return 'assets/Avangers_EndGame.png';
    if (title.contains('laskar')) return 'assets/LaskarPelangi.png';
    if (title.contains('stupid') || title.contains('my stupid boss')) return 'assets/MyStupidBoss.png';
    if (title.contains('pengabdi') || title.contains('setan')) return 'assets/PengabdiSetan.png';
    if (title.contains('toystory') || title.contains('toy story') || title.contains('toy')) return 'assets/ToyStory_4.png';
    final poster = film?['poster']?.toString();
    if (poster != null && poster.isNotEmpty) return poster;
    return null;
  }

  Widget _buildCoverWidget(String? cover) {
    if (cover == null) return const SizedBox.shrink();
    final isNetwork = cover.startsWith('http://') || cover.startsWith('https://');
    final path = isNetwork ? cover : (cover.startsWith('assets/') ? cover : 'assets/$cover');

    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints.tightFor(width: 260, height: 390),
          child: isNetwork
              ? Image.network(
                  path,
                  width: 260,
                  height: 390,
                  fit: BoxFit.fill,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                )
              : Image.asset(
                  path,
                  width: 260,
                  height: 390,
                  fit: BoxFit.fill,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.light.colorScheme.primary;
    final title = (_film?['judul'] ?? _film?['title'] ?? 'Detail Film').toString();
    final sinopsis = (_film?['sinopsis'] ?? '').toString();
    final durasi = _film?['durasi']?.toString() ?? '-';
    final genreId = _film?['genre_id']?.toString() ?? '-';
    final cover = _assetForFilm(_film);

    return Scaffold(
      appBar: AppBar(title: Text(title), backgroundColor: primary),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            style: ButtonStyle(backgroundColor: MaterialStateProperty.all(primary)),
            onPressed: _film == null ? null : () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => JadwalListPage(filmId: widget.filmId, filmTitle: title)));
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
                      if (cover != null) _buildCoverWidget(cover),
                      if (cover != null) const SizedBox(height: 12),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                      ),
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
