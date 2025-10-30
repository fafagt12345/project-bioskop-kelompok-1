import 'package:flutter/material.dart';
import '../api_service.dart';
import 'checkout_success_page.dart';

class SeatSelectionPage extends StatefulWidget {
  final int jadwalId;
  final String filmTitle;
  const SeatSelectionPage({super.key, required this.jadwalId, required this.filmTitle});

  @override
  State<SeatSelectionPage> createState() => _SeatSelectionPageState();
}

class _SeatSelectionPageState extends State<SeatSelectionPage> {
  final api = ApiService();
  bool _loading = true;
  List<Map<String, dynamic>> _seats = [];
  final Set<int> _selected = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.round();
    return int.tryParse('$v') ?? 0;
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final rows = await api.seatsAvailable(widget.jadwalId);
      final parsed = rows.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      setState(() => _seats = parsed);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal load kursi: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _label(Map<String, dynamic> s) {
    return (s['nama_kursi'] ?? s['nomor_kursi'] ?? s['label'] ?? s['kursi_id'] ?? '').toString();
  }

  bool _isSold(Map<String, dynamic> s) {
    final st = (s['status'] ?? '').toString().toLowerCase();
    return st == 'terjual' || st == 'sold';
  }

  int _priceOf(int kursiId) {
    final m = _seats.firstWhere(
      (e) => (e['kursi_id'] is num ? (e['kursi_id'] as num).toInt() : int.tryParse('${e['kursi_id']}') ?? -1) == kursiId,
      orElse: () => const {},
    );
    return _asInt(m['harga']);
  }

  int get _total {
    int sum = 0;
    for (final id in _selected) {
      sum += _priceOf(id);
    }
    return sum;
  }

  Future<void> _checkout() async {
    try {
      // TODO: ganti customerId sesuai user yg login
      final res = await api.checkout(
        customerId: 1,
        jadwalId: widget.jadwalId,
        kursiIds: _selected.toList(),
      );
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => CheckoutSuccessPage(data: res)));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Checkout gagal: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pilih Kursi • ${widget.filmTitle}')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Expanded(child: Text('Dipilih: ${_selected.length}  |  Total: Rp ${_total}')),
              FilledButton.icon(
                onPressed: _selected.isEmpty ? null : _checkout,
                icon: const Icon(Icons.payment),
                label: const Text('Checkout'),
              ),
            ],
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _seats.map((s) {
                  final kursiId = (s['kursi_id'] is num) ? (s['kursi_id'] as num).toInt() : int.tryParse('${s['kursi_id']}') ?? 0;
                  final sold    = _isSold(s);
                  final selected = _selected.contains(kursiId);
                  final price   = _asInt(s['harga']);

                  return InkWell(
                    onTap: sold
                        ? null
                        : () {
                            setState(() {
                              if (selected) _selected.remove(kursiId);
                              else _selected.add(kursiId);
                            });
                          },
                    child: Container(
                      width: 90, height: 70,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: sold
                              ? Colors.grey.shade300
                              : selected ? Colors.indigo : Colors.grey.shade400,
                          width: 2,
                        ),
                        color: sold
                            ? Colors.grey.shade200
                            : selected ? Colors.indigo.withOpacity(0.08) : Colors.white,
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_label(s),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: sold ? Colors.grey : (selected ? Colors.indigo : Colors.black),
                              )),
                          const SizedBox(height: 4),
                          Text('Rp $price',
                              style: TextStyle(
                                fontSize: 12,
                                color: sold ? Colors.grey : Colors.black87,
                              )),
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
