import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(BioskopApp());
}

class BioskopApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bioskop App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
