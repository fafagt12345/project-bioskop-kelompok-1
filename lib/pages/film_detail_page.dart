import 'package:flutter/material.dart';
import '../api_service.dart';
import 'jadwal_list_page.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';

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
  String? _genreName;

  // COMMENTS
  List<Map<String, dynamic>> _comments = [];
  bool _loadingComments = true;
  final _commentCtl = TextEditingController();
  int? _commentRating;
  String _commentSort = 'newest'; // or 'oldest'
  int? _currentUserId; // users pk dari login (disimpan oleh ApiService)

  @override
  void initState() {
    super.initState();
    _initUser();
    if (widget.initial != null) {
      _film = Map<String, dynamic>.from(widget.initial!);
      _genreName =
          (_film!['genre_name'] ?? _film!['genre_nama'] ?? _film!['genre'])
              ?.toString();
    }
    _load();
  }

  Future<void> _initUser() async {
    final uid = await api.getStoredUserId();
    if (!mounted) return;
    setState(() => _currentUserId = uid);
  }

  Future<void> _loadComments() async {
    setState(() => _loadingComments = true);
    try {
      final list = await api.commentsList(widget.filmId, sort: _commentSort);
      setState(() =>
          _comments = list.map((e) => Map<String, dynamic>.from(e)).toList());
    } catch (e) {
      // ignore or show inline
    } finally {
      if (mounted) setState(() => _loadingComments = false);
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await api.filmDetail(widget.filmId);
      await _loadComments();

      // 1) nama genre dari payload (jika controller sudah join)
      String? gName =
          (data['genre_name'] ?? data['genre_nama'] ?? data['genre'])
              ?.toString();

      // 2) kalau belum ada, ambil dari id
      if (gName == null || gName.isEmpty) {
        final rawId = data['genre_id'] ?? data['id_genre'] ?? data['genreId'];
        final gid = rawId is int ? rawId : int.tryParse('$rawId');
        gName = await api.genreNameById(gid);
      }

      if (!mounted) return;
      setState(() {
        _film = data;
        _genreName = (gName == null || gName.isEmpty) ? null : gName;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  String _fmtDate(String d) {
    if (d.isEmpty) return '';
    try {
      final dt = DateTime.parse(d);
      return DateFormat.yMMMd().format(dt);
    } catch (_) {
      return d;
    }
  }

  String? _assetForFilm(Map<String, dynamic>? film) {
    final title =
        (film?['judul'] ?? film?['title'] ?? '').toString().toLowerCase();
    if (title.contains('avangers') ||
        title.contains('avengers') ||
        title.contains('endgame')) return 'assets/Avangers_EndGame.png';
    if (title.contains('laskar')) return 'assets/LaskarPelangi.png';
    if (title.contains('stupid') || title.contains('my stupid boss'))
      return 'assets/MyStupidBoss.png';
    if (title.contains('pengabdi') || title.contains('setan'))
      return 'assets/PengabdiSetan.png';
    if (title.contains('toystory') ||
        title.contains('toy story') ||
        title.contains('toy')) return 'assets/ToyStory_4.png';
    final poster = film?['poster']?.toString();
    if (poster != null && poster.isNotEmpty) return poster;
    return null;
  }

  Widget _buildCoverWidget(String? cover) {
    if (cover == null) return const SizedBox.shrink();
    final isNetwork =
        cover.startsWith('http://') || cover.startsWith('https://');
    final path = isNetwork
        ? cover
        : (cover.startsWith('assets/') ? cover : 'assets/$cover');

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

  Future<void> _submitComment() async {
    final text = _commentCtl.text.trim();
    if (text.isEmpty) return;
    try {
      final res = await api.postComment(
          filmId: widget.filmId, isi: text, rating: _commentRating);

      // jika server mengembalikan objek komentar, tambahkan ke list lokal langsung
      if (res is Map<String, dynamic>) {
        final newComment = Map<String, dynamic>.from(res);
        setState(() {
          _comments.insert(0, newComment);
        });
      } else {
        // fallback: reload jika respons tidak seperti yang diharapkan
        await _loadComments();
      }

      _commentCtl.clear();
      _commentRating = null;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Komentar terkirim')));
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal kirim komentar: ${e.message}')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal kirim komentar: $e')));
    }
  }

  Future<void> _editComment(Map<String, dynamic> c) async {
    final ctl =
        TextEditingController(text: c['isi_komentar']?.toString() ?? '');
    int? rating = c['rating'] is int
        ? c['rating'] as int
        : (int.tryParse('${c['rating'] ?? ''}') ?? null);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx2, setStateDialog) {
          return AlertDialog(
            title: const Text('Edit Komentar'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: ctl, maxLines: 4),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(5, (i) {
                    final val = i + 1;
                    return IconButton(
                      icon: Icon(
                        val <= (rating ?? 0) ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                      ),
                      onPressed: () => setStateDialog(() => rating = val),
                    );
                  }),
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Batal')),
              FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Simpan')),
            ],
          );
        });
      },
    );
    if (ok != true) return;
    try {
      final res = await api.updateComment(
          id: c['komentar_id'], isi: ctl.text.trim(), rating: rating);

      if (res is Map<String, dynamic>) {
        final updated = Map<String, dynamic>.from(res);
        // set edited flag if server tidak memberikan
        if (!updated.containsKey('edited')) updated['edited'] = true;
        // update lokal: cari index berdasarkan komentar_id dan ganti
        final idx = _comments.indexWhere((e) =>
            (e['komentar_id'] ?? e['id'] ?? e['komentarId']) ==
            (updated['komentar_id'] ?? updated['id'] ?? updated['komentarId']));
        setState(() {
          if (idx >= 0)
            _comments[idx] = updated;
          else
            _comments.insert(0, updated);
        });
      } else {
        // fallback: reload list
        await _loadComments();
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Komentar diperbarui')));
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal update: ${e.message}')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal update: $e')));
    }
  }

  Future<void> _deleteComment(Map<String, dynamic> c) async {
    final sure = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Hapus Komentar'),
            content: const Text('Yakin ingin menghapus komentar ini?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Batal')),
              FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Hapus')),
            ],
          ),
        ) ??
        false;
    if (!sure) return;
    try {
      await api.deleteComment(c['komentar_id']);

      // hapus secara lokal agar update langsung terlihat
      setState(() {
        _comments.removeWhere((e) =>
            (e['komentar_id'] ?? e['id'] ?? e['komentarId']) ==
            (c['komentar_id'] ?? c['id'] ?? c['komentarId']));
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Komentar dihapus')));
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal hapus: ${e.message}')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal hapus: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;
    final infoColor = theme.cardColor;
    final outlineColor = cs.outlineVariant.withOpacity(isLight ? .35 : .55);

    final title =
        (_film?['judul'] ?? _film?['title'] ?? 'Detail Film').toString();
    final sinopsis = (_film?['sinopsis'] ?? '').toString();
    final durasi = _film?['durasi']?.toString() ?? '-';
    final cover = _assetForFilm(_film);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppTheme.buildGradientAppBar(context, title),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            onPressed: _film == null
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => JadwalListPage(
                            filmId: widget.filmId, filmTitle: title),
                      ),
                    );
                  },
            icon: const Icon(Icons.event),
            label: const Text('Lihat Jadwal'),
          ),
        ),
      ),
      body: _loading && _film == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (cover != null) _buildCoverWidget(cover),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: infoColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: outlineColor),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _Chip(label: 'Durasi: ${durasi}m'),
                            if (_genreName != null)
                              _Chip(label: 'Genre: ${_genreName!}'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text('Sinopsis',
                            style:
                                TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text(sinopsis.isEmpty ? '-' : sinopsis),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Komentar',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700)),
                              DropdownButton<String>(
                                value: _commentSort,
                                items: const [
                                  DropdownMenuItem(
                                      value: 'newest',
                                      child: Text('Terbaru')),
                                  DropdownMenuItem(
                                      value: 'oldest',
                                      child: Text('Terlama')),
                                ],
                                onChanged: (v) {
                                  setState(
                                      () => _commentSort = v ?? 'newest');
                                  _loadComments();
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Add comment input
                          TextField(
                            controller: _commentCtl,
                            maxLines: 3,
                            decoration: const InputDecoration(
                                hintText: 'Tulis komentar...'),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              // star rating simple
                              Row(
                                  children: List.generate(5, (i) {
                                final val = i + 1;
                                return IconButton(
                                  icon: Icon(
                                      val <= (_commentRating ?? 0)
                                          ? Icons.star
                                          : Icons.star_border,
                                      color: Colors.amber),
                                  onPressed: () =>
                                      setState(() => _commentRating = val),
                                );
                              })),
                              const Spacer(),
                              FilledButton(
                                  onPressed: _submitComment,
                                  child: const Text('Kirim'))
                            ],
                          ),
                          const Divider(),
                          // Comments list
                          if (_loadingComments)
                            const Center(child: CircularProgressIndicator())
                          else if (_comments.isEmpty)
                            const Text(
                                'Belum ada komentar. Jadilah yang pertama!')
                          else
                            Column(
                              children: _comments.map((c) {
                                // prefer commenter_profile from server: display_name + is_admin
                                final cp = (c['commenter_profile'] is Map)
                                    ? Map<String, dynamic>.from(
                                        c['commenter_profile'])
                                    : <String, dynamic>{};
                                final commenterName =
                                    (cp['name'] as String?) ??
                                        (c['commenter_name'] as String?) ??
                                        'Anonim';
                                final displayName =
                                    (cp['display_name'] as String?) ??
                                        commenterName;
                                final isAdmin = (cp['is_admin'] == true);
                                final edited = (c['edited'] == true);
                                final uid = cp['id'] ?? c['users_id'];
                                final date = _fmtDate(
                                    c['tanggal']?.toString() ?? '');
                                final content =
                                    c['isi_komentar']?.toString() ?? '';
                                final rating = c['rating'];
                                final isOwner = _currentUserId != null &&
                                    (c['users_id'] != null) &&
                                    (_currentUserId ==
                                        (c['users_id'] is int
                                            ? c['users_id']
                                            : int.tryParse(
                                                '${c['users_id']}')));
                                // avatar inisial dari nama
                                String initials(String s) {
                                  final parts = s.trim().split(' ');
                                  if (parts.length >= 2)
                                    return '${parts[0][0]}${parts[1][0]}'
                                        .toUpperCase();
                                  return s.isNotEmpty
                                      ? s[0].toUpperCase()
                                      : '?';
                                }

                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.grey.shade200,
                                    child: Text(initials(commenterName),
                                        style: TextStyle(
                                            color: Colors.black87)),
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                          child: Text(displayName,
                                              style: const TextStyle(
                                                  fontWeight:
                                                      FontWeight.w600))),
                                      if (edited)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              left: 8.0),
                                          child: Text('(diedit)',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors
                                                      .grey.shade600)),
                                        ),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (rating != null)
                                        Row(
                                            children: List.generate(
                                                5,
                                                (i) => Icon(
                                                    i < (rating as int)
                                                        ? Icons.star
                                                        : Icons.star_border,
                                                    size: 16,
                                                    color: Colors.amber))),
                                      const SizedBox(height: 4),
                                      Text(content),
                                      const SizedBox(height: 6),
                                      Text(date,
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600)),
                                    ],
                                  ),
                                  trailing: isOwner
                                      ? PopupMenuButton<String>(
                                          onSelected: (v) {
                                            if (v == 'edit')
                                              _editComment(c);
                                            if (v == 'delete')
                                              _deleteComment(c);
                                          },
                                          itemBuilder: (_) => const [
                                            PopupMenuItem(
                                                value: 'edit',
                                                child: Text('Edit')),
                                            PopupMenuItem(
                                                value: 'delete',
                                                child: Text('Hapus')),
                                          ],
                                        )
                                      : null,
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
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
