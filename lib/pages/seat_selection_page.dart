import 'package:flutter/material.dart';
import '../api_service.dart';
import 'checkout_success_page.dart';
import '../theme/app_theme.dart';

class SeatSelectionPage extends StatefulWidget {
  final int jadwalId;
  final String filmTitle;
  const SeatSelectionPage({
    super.key,
    required this.jadwalId,
    required this.filmTitle,
  });

  @override
  State<SeatSelectionPage> createState() => _SeatSelectionPageState();
}

class _SeatSelectionPageState extends State<SeatSelectionPage> {
  final api = ApiService();

  bool _loading = true;
  String? _error;

  // data kursi dari API
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
    // tangani "50000.00"
    final s = v.toString();
    final dot = s.indexOf('.');
    final base = dot >= 0 ? s.substring(0, dot) : s;
    return int.tryParse(base) ?? (double.tryParse(s)?.round() ?? 0);
  }

  String _formatRp(dynamic v) {
    final n = _asInt(v);
    final s = n.toString();
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      b.write(s[i]);
      final left = s.length - i - 1;
      if (left > 0 && left % 3 == 0) b.write('.');
    }
    return b.toString();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await api.seatsAvailable(widget.jadwalId);
      final parsed = rows.map((e) => Map<String, dynamic>.from(e as Map)).toList();

      _byId.clear();
      for (final m in parsed) {
        final id = (m['kursi_id'] is num)
            ? (m['kursi_id'] as num).toInt()
            : int.tryParse('${m['kursi_id']}') ?? 0;
        if (id > 0) _byId[id] = m;
      }

      setState(() => _seats = parsed);
    } catch (e) {
      setState(() => _error = 'Gagal load kursi: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Selalu prioritaskan nomor_kursi (atau nama_kursi dari API),
  /// JANGAN jatuh ke kursi_id agar tidak tampil angka ID.
  String _labelOf(Map<String, dynamic> s) {
    final label = (s['nomor_kursi'] ?? s['nama_kursi'] ?? s['label'])?.toString();
    return (label == null || label.isEmpty) ? '-' : label;
  }

  String _labelById(int id) {
    final m = _byId[id];
    if (m == null) return '-';
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
    final labels = _selected.map(_labelById).toList();
    // optional: urutkan biar rapi (A1, A2, ...)
    labels.sort((a, b) => a.compareTo(b));
    return labels.join(', ');
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

      // ------ Pastikan label kursi ada di payload ke halaman sukses ------
      // 1) coba dari respons backend (kalau sudah kirim)
      String labels = '';
      final rawList = res['kursi'];
      if (rawList is List && rawList.isNotEmpty) {
        final items = rawList
            .map((e) => (e is Map ? (e['nomor_kursi'] ?? e['nama_kursi']) : null))
            .where((x) => x != null && x.toString().isNotEmpty)
            .map((x) => x.toString())
            .toList();
        labels = items.join(', ');
      }
      if (labels.isEmpty) {
        labels = (res['kursi_labels'] ?? '').toString();
      }
      // 2) fallback: pakai label lokal dari pilihan
      if (labels.isEmpty) {
        labels = _selectedLabels;
      }

      final total = res['total_harga'] ?? _total;

      // Susun daftar kursi final (kalau backend tidak kirim)
      final kursiList = (res['kursi'] is List && (res['kursi'] as List).isNotEmpty)
          ? (res['kursi'] as List)
          : _selected
              .map((id) => {
                    'kursi_id': id,
                    'nomor_kursi': _labelById(id),
                    'harga': _priceOfId(id),
                  })
              .toList();

      final data = {
        ...res,
        'kursi_labels': labels,
        'total_harga': total,
        'kursi': kursiList,
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
              // ringkasan kursi terpilih (pakai label, bukan ID)
              Text(
                'Kursi: $_selectedLabels',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Dipilih: ${_selected.length}  |  Total: Rp ${_formatRp(_total)}',
                    ),
                  ),
                  FilledButton.icon(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(primary),
                    ),
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
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(_error!, textAlign: TextAlign.center),
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
                          width: 90, // tetap kecil, sesuai permintaan
                          height: 70,
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
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: sold
                                      ? Colors.grey
                                      : (selected ? primary : Colors.black87),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Rp ${_formatRp(price)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      sold ? Colors.grey : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
    );
  }
}
