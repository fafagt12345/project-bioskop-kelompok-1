import 'package:flutter/material.dart';
import '../api_service.dart';
import 'seat_selection_page.dart';
import '../theme/app_theme.dart';

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
    final tw = j['tanggal_waktu'];
    if (tw != null && '$tw'.trim().isNotEmpty) return '$tw';
    final tgl = j['tanggal']?.toString() ?? '';
    final jam = j['jam_mulai']?.toString() ?? '';
    if (tgl.isNotEmpty && jam.isNotEmpty) return '$tgl $jam';
    return tgl.isNotEmpty ? tgl : (jam.isNotEmpty ? jam : '-');
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
      appBar: AppBar(title: Text('Jadwal • ${widget.filmTitle}'), backgroundColor: primary),
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
                    final jadwalId = _toInt(j['jadwal_id'] ?? j['id']);
                    final studio = (j['studio_id'] ?? j['studio'] ?? '-').toString();

                    return ListTile(
                      leading: CircleAvatar(backgroundColor: primary, child: const Icon(Icons.event, color: Colors.white)),
                      title: Text(_timeOf(j)),
                      subtitle: Text('Studio: $studio • ID: $jadwalId'),
                      trailing: Icon(Icons.chevron_right, color: primary),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SeatSelectionPage(jadwalId: jadwalId, filmTitle: widget.filmTitle))),
                    );
                  },
                ),
    );
  }
}
