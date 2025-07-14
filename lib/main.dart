import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'صاحب Com',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        fontFamily: 'Arabic',
      ),
      home: const HomeScreen(),
    );
  }
}