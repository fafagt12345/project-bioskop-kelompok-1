import 'package:flutter/material.dart';
import '../api_service.dart';
import '../theme/app_theme.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});
  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  final api = ApiService();

  Future<void> _register() async {
    setState(() => _loading = true);
    try {
      final user = _username.text.trim();
      final pass = _password.text.trim();

      if (user.isEmpty || pass.isEmpty) {
        throw Exception('Username/password wajib diisi');
      }

      // ⬇️ Perubahan di sini: kirim juga "name"
      final res = await api.register(user, pass, name: user);

      if (!mounted) return;
      final msg = (res['message'] ?? 'Registrasi berhasil').toString();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

      // balik ke halaman login
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Pendaftaran gagal: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.light.colorScheme.primary;
    return Scaffold(
      backgroundColor: primary.withOpacity(0.04),
      appBar: AppBar(title: const Text('Daftar'), backgroundColor: primary),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _username,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _password,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              obscureText: _obscurePassword,
              onSubmitted: (_) => _register(),
            ),
            const SizedBox(height: 16),
            FilledButton(
              style: ButtonStyle(backgroundColor: MaterialStateProperty.all(primary)),
              onPressed: _loading ? null : _register,
              child: Text(_loading ? 'Mendaftar...' : 'Daftar'),
            ),
          ],
        ),
      ),
    );
  }
}
