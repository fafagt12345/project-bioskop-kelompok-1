import 'package:flutter/material.dart';
import '../../api_service.dart';
import '../../theme/app_theme.dart';
import '../film_list_page.dart';
import '../login_page.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});
  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  final api = ApiService();
  bool _signingOut = false;

  Future<void> _logout() async {
    if (_signingOut) return;
    setState(() => _signingOut = true);
    await api.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.light.colorScheme.primary;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: primary,
        actions: [
          IconButton(
            onPressed: _signingOut ? null : _logout,
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
              leading: Icon(Icons.movie_creation_outlined, color: primary),
              title: const Text('Kelola Film'),
              subtitle: const Text('Tambah, ubah, dan hapus film'),
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
