import 'package:flutter/material.dart';

class AddAdScreen extends StatelessWidget {
  const AddAdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('المفضلة'),
        centerTitle: true,
      ),
      body: Center(
        child: Text(
          'لا توجد عناصر مفضلة حالياً',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}