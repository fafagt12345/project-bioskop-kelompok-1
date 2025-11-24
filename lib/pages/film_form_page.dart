import 'package:flutter/material.dart';
import '../api_service.dart';
import '../theme/app_theme.dart';
import '../theme/bubble_container.dart';

class FilmFormPage extends StatefulWidget {
  final int? filmId; // null = create, non-null = update
  final Map<String, dynamic>? initial;

  FilmFormPage({super.key, this.filmId, this.initial});

  @override
  State<FilmFormPage> createState() => _FilmFormPageState();
}

class _FilmFormPageState extends State<FilmFormPage> {
  final api = ApiService();
  final _formKey = GlobalKey<FormState>();

  final _judulC = TextEditingController();
  final _sinopsisC = TextEditingController();
  final _durasiC = TextEditingController();

  bool _saving = false;
  String? _error;

  // genre dropdown
  List<Map<String, dynamic>> _genres = [];
  int? _selectedGenreId;

  @override
  void initState() {
    super.initState();
    // isi awal bila edit
    final m = widget.initial;
    if (m != null) {
      _judulC.text = (m['judul'] ?? m['title'] ?? '').toString();
      _sinopsisC.text = (m['sinopsis'] ?? '').toString();
      _durasiC.text = (m['durasi'] ?? '').toString();
      final gidRaw = m['genre_id'] ?? m['id_genre'];
      _selectedGenreId = gidRaw is int ? gidRaw : int.tryParse('$gidRaw');
    }
    _loadGenres();
  }

  @override
  void dispose() {
    _judulC.dispose();
    _sinopsisC.dispose();
    _durasiC.dispose();
    super.dispose();
  }

  Future<void> _loadGenres() async {
    try {
      final list = await api.genresList(); // [{id, nama}, ...]
      setState(() =>
          _genres = list.map((e) => Map<String, dynamic>.from(e)).toList());

      // kalau edit & genre belum cocok id-nya (mis. kolom beda), coba selaraskan
      if (_selectedGenreId == null && widget.initial != null) {
        final nameFromPayload = (widget.initial!['genre_name'] ??
                widget.initial!['genre_nama'] ??
                widget.initial!['genre'])
            ?.toString();
        if (nameFromPayload != null && nameFromPayload.isNotEmpty) {
          final found = _genres.firstWhere(
            (g) =>
                (g['nama'] ?? g['name'] ?? g['judul'] ?? '')
                    .toString()
                    .toLowerCase() ==
                nameFromPayload.toLowerCase(),
            orElse: () => {},
          );
          if (found.isNotEmpty) {
            setState(() => _selectedGenreId = (found['id'] is int)
                ? found['id'] as int
                : int.tryParse('${found['id']}'));
          }
        }
      }
    } catch (e) {
      setState(() => _error = 'Gagal memuat genre: $e');
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGenreId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih genre terlebih dahulu')));
      return;
    }

    final body = <String, dynamic>{
      'judul': _judulC.text.trim(),
      'sinopsis': _sinopsisC.text.trim(),
      'durasi': int.tryParse(_durasiC.text.trim()) ?? 0,
      'genre_id': _selectedGenreId,
    };

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (widget.filmId == null) {
        await api.createFilm(body);
      } else {
        await api.updateFilm(widget.filmId!, body);
      }
      if (!mounted) return;
      Navigator.pop(context, true); // return true -> reload list
    } catch (e) {
      setState(() => _error = 'Gagal menyimpan: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppTheme.buildGradientAppBar(
        context,
        widget.filmId == null ? 'Tambah Film' : 'Edit Film',
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('SIMPAN', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  if (_error != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        border: Border.all(color: Colors.red.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_error!,
                          style: TextStyle(color: Colors.red.shade800)),
                    ),
                  TextFormField(
                    controller: _judulC,
                    decoration: const InputDecoration(
                      labelText: 'Judul',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Judul wajib' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _sinopsisC,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Sinopsis',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _durasiC,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Durasi (menit)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      final n = int.tryParse(v?.trim() ?? '');
                      if (n == null || n <= 0) return 'Durasi tidak valid';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: _selectedGenreId,
                    items: _genres.map((g) {
                      final id = (g['id'] is int)
                          ? g['id'] as int
                          : int.tryParse('${g['id']}');
                      final name =
                          (g['nama'] ?? g['name'] ?? g['judul'] ?? 'Tanpa Nama')
                              .toString();
                      return DropdownMenuItem<int>(value: id, child: Text(name));
                    }).toList(),
                    onChanged: (v) => setState(() => _selectedGenreId = v),
                    decoration: const InputDecoration(
                      labelText: 'Genre',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: const Icon(Icons.save),
                      label: Text(_saving ? 'Menyimpan...' : 'Simpan'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
