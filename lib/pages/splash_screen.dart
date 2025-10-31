import 'dart:async';
import 'package:flutter/material.dart';
import 'login_page.dart';
import 'home_page.dart';
import '../theme/app_theme.dart';
import '../api_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key}); // <-- tambahkan const constructor

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final api = ApiService();
    final token = await api.getStoredToken();

    if (!mounted) return;
    if (token != null) {
      api.setToken(token); // set untuk penggunaan selanjutnya
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.light.colorScheme.primary;
    return Scaffold(
      body: Container(
        color: primary, // gunakan warna utama AppTheme
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pastikan path asset benar dan sudah didaftarkan di pubspec.yaml
            Image.asset('assets/logo.png', width: 160, height: 160),
            const SizedBox(height: 16),
            const Text(
              'BioskopKu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: .5,
              ),
            ),
            const SizedBox(height: 8),
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
