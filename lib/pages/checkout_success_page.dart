import 'package:flutter/material.dart';

class CheckoutSuccessPage extends StatelessWidget {
  final Map<String, dynamic> data;
  const CheckoutSuccessPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final trxId = data['transaksi_id'] ?? data['id'] ?? '-';
    final total = data['total_harga'] ?? 0;
    final kursi = (data['kursi_terbeli'] is List) ? (data['kursi_terbeli'] as List).join(', ') : '-';

    return Scaffold(
      appBar: AppBar(title: const Text('Berhasil Checkout')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Transaksi ID: $trxId', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Total Bayar: Rp $total'),
            const SizedBox(height: 8),
            Text('Kursi: $kursi'),
            const Spacer(),
            FilledButton(
              onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
              child: const Text('Kembali ke awal'),
            ),
          ],
        ),
      ),
    );
  }
}