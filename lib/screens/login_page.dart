import 'package:flutter/material.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  @override State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final String _user = 'admin';
  final String _pass = 'admin123@gmail.com';
  String? _error;

  void _login() {
    if(_userCtrl.text == _user && _passCtrl.text == _pass) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomePage()));
    } else {
      setState(() { _error = 'Username atau password salah'; });
    }
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(children: [
          Image.asset('assets/logo.png', width: 120, height: 120),
          SizedBox(height: 12),
          TextField(controller: _userCtrl, decoration: InputDecoration(labelText: 'Username')),
          TextField(controller: _passCtrl, decoration: InputDecoration(labelText: 'Password'), obscureText: true),
          SizedBox(height: 12),
          ElevatedButton(onPressed: _login, child: Text('Login')),
          if(_error!=null) Padding(padding: EdgeInsets.only(top:12), child: Text(_error!, style: TextStyle(color: Colors.red)))
        ]),
      ),
    );
  }
}
