import 'package:flutter/material.dart';
import '../api_service.dart';
import 'checkout_success_page.dart';
import '../theme/app_theme.dart';

class SeatSelectionPage extends StatefulWidget {
  final int jadwalId;
  final String filmTitle;
  final int? studioId; // ✅ dipakai saat kursi kosong untuk generate virtual

  const SeatSelectionPage({
    super.key,
    required this.jadwalId,
    required this.filmTitle,
    this.studioId,
  });

  @override
  State<SeatSelectionPage> createState() => _SeatSelectionPageState();
}

class _SeatSelectionPageState extends State<SeatSelectionPage> {
  final api = ApiService();

  bool _loading = true;
  String? _error;

  // data kursi dari API (atau virtual)
  List<Map<String, dynamic>> _seats = [];

  // lookup & pilihan
  final Set<int> _selected = {};
  final Map<int, Map<String, dynamic>> _byId = {}; // kursi_id -> row

  @override
  void initState() {
    super.initState();
    _load();
  }

  int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.round();
    return int.tryParse(v.toString().split('.').first) ??
        (double.tryParse('$v')?.round() ?? 0);
  }

  void _rebuildIndex(List<Map<String, dynamic>> rows) {
    _byId.clear();
    for (final m in rows) {
      final id = (m['kursi_id'] is num)
          ? (m['kursi_id'] as num).toInt()
          : int.tryParse('${m['kursi_id']}') ?? 0;
      if (id != 0) _byId[id] = m;
    }
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; _selected.clear(); });
    try {
      final rows = await api.seatsAvailable(widget.jadwalId);
      final parsed = rows.map((e) => Map<String, dynamic>.from(e as Map)).toList();

      if (parsed.isEmpty && widget.studioId != null) {
        // ✅ tidak ada kursi: tawarkan generate 15 kursi
        await _offerGenerateSeats();
      } else {
        _rebuildIndex(parsed);
        setState(() => _seats = parsed);
      }
    } catch (e) {
      setState(() => _error = 'Gagal load kursi: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ==== Virtual Seat Generator (saat kursi kosong) ====
  String _studioLetter(int sid) {
    final base = 'A'.codeUnitAt(0);
    final idx = sid - 1;
    final code = base + (idx < 0 ? 0 : idx);
    return String.fromCharCode(code.clamp(base, 'Z'.codeUnitAt(0)));
  }

  int _defaultPrice(int sid) {
    const map = {1: 50000, 2: 100000, 3: 75000};
    return map[sid] ?? 50000;
  }

  Future<void> _offerGenerateSeats() async {
    final sid = widget.studioId!;
    final expectedLetter = _studioLetter(sid);
    String chosen = expectedLetter;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Generate Kursi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Belum ada kursi untuk jadwal ini.\n'
                  'Pilih baris kursi (A–C), lalu kami tampilkan 15 kursi.'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: ['A','B','C'].map((letter) {
                  final selected = chosen == letter;
                  return ChoiceChip(
                    label: Text(letter),
                    selected: selected,
                    onSelected: (_) { setState(() => chosen = letter); },
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Text(
                'Catatan: Studio ini default baris $expectedLetter. '
                'Saat disimpan, label kursi akan mengikuti studio.',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Lanjut')),
          ],
        );
      },
    );

    // Tetap pakai expectedLetter agar konsisten dengan backend
    final prefix = expectedLetter;
    final price = _defaultPrice(sid);

    final virtual = List<Map<String, dynamic>>.generate(15, (i) {
      final nomor = i + 1;
      final label = '$prefix$nomor';
      final negativeId = -(sid * 1000 + nomor); // akan diubah backend menjadi kursi real
      return {
        'kursi_id': negativeId,
        'studio_id': sid,
        'nama_kursi': label,
        'status': 'tersedia',
        'harga': price,
      };
    });

    _rebuildIndex(virtual);
    setState(() => _seats = virtual);
  }

  String _labelOf(Map<String, dynamic> s) {
    return (s['nama_kursi'] ?? s['nomor_kursi'] ?? s['label'] ?? s['kursi_id'] ?? '').toString();
  }

  String _labelById(int id) {
    final m = _byId[id];
    if (m == null) return 'S$id';
    return _labelOf(m);
  }

  bool _isSold(Map<String, dynamic> s) {
    final st = (s['status'] ?? '').toString().toLowerCase();
    return st == 'terjual' || st == 'sold';
  }

  int _priceOfId(int kursiId) {
    final m = _byId[kursiId];
    return _asInt(m?['harga']);
  }

  int get _total {
    int sum = 0;
    for (final id in _selected) {
      sum += _priceOfId(id);
    }
    return sum;
  }

  String get _selectedLabels {
    if (_selected.isEmpty) return '-';
    return _selected.map(_labelById).join(', ');
  }

  Future<void> _checkout() async {
    if (_selected.isEmpty) return;

    try {
      // NOTE: sesuaikan customerId dengan user yang login
      final res = await api.checkout(
        customerId: 1,
        jadwalId: widget.jadwalId,
        kursiIds: _selected.toList(),
      );

      // Fallback label kursi supaya tidak "ID" lagi
      String labels = '';
      final rawList = res['kursi'];
      if (rawList is List && rawList.isNotEmpty) {
        final items = rawList.map((e) => (e is Map ? e['nomor_kursi'] : null))
            .where((x) => x != null && x.toString().isNotEmpty)
            .map((x) => x.toString())
            .toList();
        labels = items.join(', ');
      }
      if (labels.isEmpty) {
        labels = (res['kursi_labels'] ?? '').toString();
      }
      if (labels.isEmpty) {
        labels = _selectedLabels;
      }

      final total = res['total_harga'] ?? _total;

      final data = {
        ...res,
        'kursi_labels': labels,
        'total_harga': total,
        'kursi': (res['kursi'] is List && (res['kursi'] as List).isNotEmpty)
            ? res['kursi']
            : _selected
                .map((id) => {
                      'kursi_id': id,
                      'nomor_kursi': _labelById(id),
                      'harga': _priceOfId(id),
                    })
                .toList(),
      };

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => CheckoutSuccessPage(data: data)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Checkout gagal: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.light.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text('Pilih Kursi • ${widget.filmTitle}'),
        backgroundColor: primary,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Kursi: $_selectedLabels',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(child: Text('Dipilih: ${_selected.length}  |  Total: Rp $_total')),
                  FilledButton.icon(
                    style: ButtonStyle(backgroundColor: MaterialStateProperty.all(primary)),
                    onPressed: _selected.isEmpty ? null : _checkout,
                    icon: const Icon(Icons.payment),
                    label: const Text('Checkout'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(_error!, textAlign: TextAlign.center),
                ))
              : (_seats.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          widget.studioId == null
                              ? 'Belum ada kursi untuk jadwal ini.\nStudioId tidak diketahui, silakan tambah kursi di server.'
                              : 'Belum ada kursi.\nTekan kembali lalu masuk lagi, atau gunakan tombol Checkout setelah memilih kursi virtual.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _seats.map((s) {
                          final kursiId = (s['kursi_id'] is num)
                              ? (s['kursi_id'] as num).toInt()
                              : int.tryParse('${s['kursi_id']}') ?? 0;
                          final sold = _isSold(s);
                          final selected = _selected.contains(kursiId);
                          final price = _asInt(s['harga']);
                          final label = _labelOf(s);

                          return InkWell(
                            onTap: sold
                                ? null
                                : () {
                                    setState(() {
                                      if (selected) {
                                        _selected.remove(kursiId);
                                      } else {
                                        _selected.add(kursiId);
                                      }
                                    });
                                  },
                            child: Container(
                              width: 90, // ✅ ukuran tetap
                              height: 70, // ✅ ukuran tetap
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: sold
                                      ? Colors.grey.shade300
                                      : (selected ? primary : Colors.grey.shade400),
                                  width: 2,
                                ),
                                color: sold
                                    ? Colors.grey.shade200
                                    : (selected
                                        ? primary.withOpacity(0.12)
                                        : Colors.white),
                              ),
                              alignment: Alignment.center,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    label,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: sold
                                          ? Colors.grey
                                          : (selected ? primary : Colors.black87),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Rp $price',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: sold ? Colors.grey : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    )),
    );
  }
}
