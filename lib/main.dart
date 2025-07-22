import 'package:flutter/material.dart';
import 'package:sahbo_app/screens/start_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'إعلانك',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        fontFamily: 'Arabic',
      ),
      home: const StartScreen(),
      debugShowCheckedModeBanner: false
    );
  }
}