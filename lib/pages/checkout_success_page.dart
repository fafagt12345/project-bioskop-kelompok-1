import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CheckoutSuccessPage extends StatelessWidget {
  final Map<String, dynamic> data;
  const CheckoutSuccessPage({super.key, required this.data});

  String _formatRp(dynamic v) {
    final n = (v is num) ? v.toInt() : int.tryParse('${v ?? 0}') ?? 0;
    final s = n.toString();
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      b.write(s[i]);
      final left = s.length - i - 1;
      if (left > 0 && left % 3 == 0) b.write('.');
    }
    return b.toString();
  }

  /// Ambil label kursi dari berbagai bentuk payload dengan prioritas:
  /// 1) `kursi_labels` (string sudah jadi)
  /// 2) `kursi` (list of map) -> pakai `nomor_kursi`
  /// 3) fallback `kursi_terbeli` (id), jika tak ada nama sama sekali
  String _seatLabels(Map<String, dynamic> d) {
    final direct = d['kursi_labels']?.toString();
    if (direct != null && direct.trim().isNotEmpty) return direct;

    final k = d['kursi'];
    if (k is List && k.isNotEmpty) {
      final labels = k.map((e) {
        if (e is Map) {
          final m = Map<String, dynamic>.from(e);
          return (m['nomor_kursi'] ?? m['label'] ?? m['kursi']).toString();
        }
        return e.toString();
      }).where((s) => s.trim().isNotEmpty).toList();
      if (labels.isNotEmpty) return labels.join(', ');
    }

    final ids = d['kursi_terbeli'];
    if (ids is List) return ids.join(', ');
    return '-';
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.light.colorScheme.primary;
    final trxId  = data['transaksi_id'] ?? data['id'] ?? '-';
    final total  = data['total_harga'] ?? 0;
    final kursiTeks = _seatLabels(data);

    return Scaffold(
      appBar: AppBar(title: const Text('Berhasil Checkout'), backgroundColor: primary),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Transaksi ID: $trxId',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Total Bayar: Rp ${_formatRp(total)}'),
            const SizedBox(height: 8),
            Text('Kursi: $kursiTeks'),
            const Spacer(),
            FilledButton(
              style: ButtonStyle(backgroundColor: MaterialStateProperty.all(primary)),
              onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
              child: const Text('Kembali ke awal'),
            ),
          ],
        ),
      ),
    );
  }
}
