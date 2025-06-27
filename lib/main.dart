import 'package:flutter/material.dart';
import 'package:sahbo_app/screens/start_screen.dart';
import 'package:sahbo_app/screens/login_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginScreen(), // home page
    );
  }
}
