import 'package:flutter/material.dart';
import '../api_service.dart';
import 'home_page.dart';
import 'registration_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  final api = ApiService();

  Future<void> _login() async {
    setState(() => _loading = true);
    try {
      final user = _username.text.trim();
      final pass = _password.text.trim();
      if (user.isEmpty || pass.isEmpty) throw Exception('Username/password wajib diisi');

      final token = await api.login(user, pass);
      api.setToken(token);

      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
    } on ApiException catch (e) {
      final msg = (e.status == 401 || e.status == 404) ? 'Username atau password salah' : e.message;
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login gagal: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _username, decoration: const InputDecoration(labelText: 'Username')),
            TextField(controller: _password, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
            const SizedBox(height: 16),
            FilledButton(onPressed: _loading ? null : _login, child: Text(_loading ? 'Masuk...' : 'Masuk')),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegistrationPage())),
              child: const Text('Daftar'),
            ),
          ],
        ),
      ),
    );
  }
}
