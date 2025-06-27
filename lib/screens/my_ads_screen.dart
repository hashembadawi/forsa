import 'package:flutter/material.dart';
import 'package:flutter/material.dart';

class MyAdsScreen extends StatelessWidget {
  const MyAdsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('إعلاناتي'),
        centerTitle: true,
      ),
      body: Center(
        child: Text(
          'لم تقم بإضافة أي إعلان بعد.',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}