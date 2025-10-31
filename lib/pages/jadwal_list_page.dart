import 'package:flutter/material.dart';
import '../api_service.dart';
import '../theme/app_theme.dart';
import 'jadwal_form_page.dart';
import 'seat_selection_page.dart'; // ✅ tambahkan

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
  String? _error;
  List<Map<String, dynamic>> _rows = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await api.jadwalList(filmId: widget.filmId);
      setState(() => _rows = list);
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _studioName(Map<String, dynamic> m) =>
      (m['nama_studio'] ?? m['studio_nama'] ?? m['studio'] ?? 'Studio ${m['studio_id'] ?? '-'}').toString();

  String _timeHHmm(String t) {
    if (t.isEmpty) return t;
    final p = t.split(':');
    return p.length >= 2 ? '${p[0]}:${p[1]}' : t;
  }

  Future<void> _create() async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => JadwalFormPage(filmId: widget.filmId, filmTitle: widget.filmTitle),
      ),
    );
    if (ok == true) _load();
  }

  Future<void> _edit(Map<String, dynamic> row) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => JadwalFormPage(
          filmId: widget.filmId,
          filmTitle: widget.filmTitle,
          initial: row,
          jadwalId: (row['jadwal_id'] is num)
              ? (row['jadwal_id'] as num).toInt()
              : int.tryParse('${row['jadwal_id']}'),
        ),
      ),
    );
    if (ok == true) _load();
  }

  Future<void> _delete(int id) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Jadwal'),
        content: const Text('Yakin ingin menghapus jadwal ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
        ],
      ),
    ) ?? false;
    if (!sure) return;
    try {
      await api.jadwalDelete(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Jadwal terhapus')));
      }
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal hapus: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.light.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text('Jadwal • ${widget.filmTitle}'),
        backgroundColor: primary,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Gagal memuat: $_error'))
              : (_rows.isEmpty
                  ? const Center(child: Text('Belum ada jadwal. Tekan tombol “Tambah”.'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _rows.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final m = _rows[i];
                          final id = (m['jadwal_id'] is num)
                              ? (m['jadwal_id'] as num).toInt()
                              : int.tryParse('${m['jadwal_id']}') ?? 0;
                          final tgl = (m['tanggal'] ?? '').toString();
                          final jm  = _timeHHmm((m['jam_mulai'] ?? '').toString());
                          final js  = _timeHHmm((m['jam_selesai'] ?? '').toString());
                          final studio = _studioName(m);
                          final studioId = (m['studio_id'] is num)
                              ? (m['studio_id'] as num).toInt()
                              : int.tryParse('${m['studio_id']}');

                          return Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              onTap: () {
                                // ✅ klik item → pilih kursi
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SeatSelectionPage(
                                      jadwalId: id,
                                      filmTitle: widget.filmTitle,
                                      studioId: studioId, // penting buat generate kursi
                                    ),
                                  ),
                                );
                              },
                              title: Text('$tgl  •  $jm–$js', style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(studio),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'Edit',
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _edit(m),
                                  ),
                                  IconButton(
                                    tooltip: 'Hapus',
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () => _delete(id),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    )),
    );
  }
}
