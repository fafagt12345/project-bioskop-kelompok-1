import 'package:flutter/material.dart';
import '../api_service.dart';
import 'home_page.dart';
import 'registration_page.dart';
import '../theme/app_theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
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
    final primary = AppTheme.light.colorScheme.primary;
    return Scaffold(
      // body with gradient background (not white)
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primary.withOpacity(0.12), const Color(0xFFEFF6FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header welcome
                  Column(
                    children: [
                      // small logo circle
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: primary,
                        child: const Icon(Icons.movie, color: Colors.white, size: 36),
                      ),
                      const SizedBox(height: 14),
                      Text('Selamat datang di BioskopKu',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: primary)),
                      const SizedBox(height: 6),
                      Text('Silahkan login dahulu.', style: TextStyle(color: Colors.grey.shade700)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Bubble container form
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withOpacity(0.08),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _username,
                          decoration: const InputDecoration(
                            hintText: 'Username',
                            prefixIcon: Icon(Icons.person),
                          ),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _password,
                          decoration: InputDecoration(
                            hintText: 'Password',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          obscureText: _obscurePassword,
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all(primary),
                              shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                            ),
                            onPressed: _loading ? null : _login,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text(_loading ? 'Masuk...' : 'Masuk'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegistrationPage())),
                          child: const Text('Lupa password?'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),
                  // footer prompt
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Tidak punya akun? ', style: TextStyle(color: Colors.grey.shade700)),
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegistrationPage())),
                        child: const Text('Daftar dulu.'),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
