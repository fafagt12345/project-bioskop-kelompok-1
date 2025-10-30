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
  int? _harga;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final rows = await api.seatsAvailable(widget.jadwalId);
      final parsed = rows.map((e) => Map<String, dynamic>.from(e as Map)).toList();

      // ambil harga (jika ada di seat); kalau tidak ada, biarkan null (total dihitung di backend)
      final firstWithPrice = parsed.firstWhere(
        (e) => e.containsKey('harga'),
        orElse: () => {},
      );

      setState(() {
        _seats = parsed;
        _harga = (firstWithPrice['harga'] is int)
            ? firstWithPrice['harga'] as int
            : int.tryParse('${firstWithPrice['harga'] ?? ''}');
      });
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

  @override
  Widget build(BuildContext context) {
    final total = (_harga ?? 0) * _selected.length;
    return Scaffold(
      appBar: AppBar(title: Text('Pilih Kursi • ${widget.filmTitle}')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Expanded(child: Text('Dipilih: ${_selected.length}  |  Total: Rp $total')),
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
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
                childAspectRatio: 1.3,
              ),
              itemCount: _seats.length,
              itemBuilder: (context, i) {
                final s = _seats[i];
                final idRaw = s['kursi_id'] ?? s['id'] ?? s.values.first;
                final kursiId = (idRaw is int) ? idRaw : (int.tryParse('$idRaw') ?? -1);
                final selected = _selected.contains(kursiId);
                final sold = (s['status'] ?? '').toString().toLowerCase() == 'sold';

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
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: sold
                            ? Colors.redAccent
                            : (selected ? Colors.indigo : Colors.grey.shade300),
                        width: 2,
                      ),
                      color: sold
                          ? Colors.redAccent.withOpacity(0.08)
                          : (selected ? Colors.indigo.withOpacity(0.1) : Colors.white),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _label(s),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: sold
                            ? Colors.redAccent
                            : (selected ? Colors.indigo : Colors.black),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _checkout() async {
    try {
      // TODO: ganti customerId sesuai user yang login (sementara pakai 1)
      final res = await api.checkout(
        customerId: 1,
        jadwalId: widget.jadwalId,
        kursiIds: _selected.toList(),
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => CheckoutSuccessPage(data: res)),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Checkout gagal: $e')));
      }
    }
  }
}
