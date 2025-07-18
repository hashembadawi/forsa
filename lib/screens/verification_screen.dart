import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'home_screen.dart';

class VerificationScreen extends StatefulWidget {
  final String phoneNumber;
  const VerificationScreen({super.key, required this.phoneNumber});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final codeController = TextEditingController();
  bool _isLoading = false;

  Future<void> verifyCode() async {
    if (codeController.text.isEmpty) {
      _showError('يرجى إدخال رمز التحقق');
      return;
    }
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('https://sahbo-app-api.onrender.com/api/auth/verify-phone'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phoneNumber': widget.phoneNumber,
          'code': codeController.text.trim(),
        }),
      );

      final res = jsonDecode(response.body);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم التحقق بنجاح!')),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      } else {
        _showError(res['message'] ?? 'رمز التحقق غير صحيح');
      }
    } catch (e) {
      _showError('حدث خطأ في الاتصال بالخادم');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تأكيد رقم الهاتف'),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'أدخل رمز التحقق المرسل إلى واتساب:',
                style: TextStyle(fontSize: 18, color: Colors.deepPurple[800]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: codeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'رمز التحقق',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: verifyCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'تأكيد',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}