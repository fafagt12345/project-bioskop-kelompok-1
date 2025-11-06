import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'pages/splash_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  static _MyAppState? of(BuildContext c) =>
      c.findAncestorStateOfType<_MyAppState>();
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _mode = ThemeMode.light;
  void toggleTheme() => setState(() {
        _mode = _mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
      });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bioskop',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _mode,
      home: SplashScreen(),
    );
  }
}
