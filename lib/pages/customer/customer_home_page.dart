import 'package:flutter/material.dart';
import '../../api_service.dart';
import '../../theme/app_theme.dart';
import '../film_list_page.dart';
import '../login_page.dart';

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({super.key});
  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  final api = ApiService();
  bool _signingOut = false;

  Future<void> _confirmAndLogout() async {
    if (_signingOut) return;
    final sure = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Konfirmasi Logout'),
            content: const Text('Apakah Anda yakin ingin keluar dari akun?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Batal')),
              FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Logout')),
            ],
          ),
        ) ??
        false;
    if (!sure) return;
    setState(() => _signingOut = true);
    try {
      await api.logout();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Berhasil logout')));
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Logout gagal')));
      }
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.light.colorScheme.primary;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Home'),
        backgroundColor: primary,
        automaticallyImplyLeading: false, // hilangkan tombol kembali
        actions: [
          IconButton(
            onPressed: _signingOut ? null : _confirmAndLogout,
            icon: _signingOut
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: Icon(Icons.movie_outlined, color: primary),
              title: const Text('Daftar Film'),
              subtitle: const Text('Lihat film dan pesan tiket'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FilmListPage()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
