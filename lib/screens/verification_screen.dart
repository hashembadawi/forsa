import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class VerificationScreen extends StatefulWidget {
  final String emailOrPhone;

  const VerificationScreen({super.key, required this.emailOrPhone});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final codeController = TextEditingController();
  bool isLoading = false;
  bool isResending = false;

  int _secondsRemaining = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    startCountdown(); // ابدأ العداد عند الدخول
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void startCountdown() {
    setState(() => _secondsRemaining = 60);
    _timer?.cancel(); // ألغِ أي عداد سابق

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        timer.cancel();
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  Future<void> verifyCode() async {
    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('https://sahbo-app-api.onrender.com/api/auth/verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'emailOrPhone': widget.emailOrPhone,
          'code': codeController.text.trim(),
        }),
      );

      setState(() => isLoading = false);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم التحقق من الحساب بنجاح')),
        );
        Navigator.popUntil(context, (route) => route.isFirst);
      } else {
        final resBody = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resBody['message'] ?? 'فشل التحقق')),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('خطأ في الاتصال بالخادم')),
      );
    }
  }

  Future<void> resendCode() async {
    setState(() => isResending = true);

    try {
      final response = await http.post(
        Uri.parse('https://sahbo-app-api.onrender.com/api/auth/resend-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'emailOrPhone': widget.emailOrPhone}),
      );

      setState(() => isResending = false);

      final resBody = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(resBody['message'] ?? 'تمت إعادة الإرسال')),
      );

      // إعادة تشغيل العداد
      startCountdown();
    } catch (e) {
      setState(() => isResending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل إرسال الرمز')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('التحقق من الحساب')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text('أدخل رمز التحقق المرسل إلى بريدك الإلكتروني أو رقم هاتفك'),
              const SizedBox(height: 20),
              TextField(
                controller: codeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'رمز التحقق',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: verifyCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('تحقق', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 20),
              _secondsRemaining > 0
                  ? Text('يمكنك إعادة الإرسال بعد $_secondsRemaining ثانية')
                  : TextButton.icon(
                onPressed: isResending ? null : resendCode,
                icon: const Icon(Icons.refresh),
                label: isResending
                    ? const Text('...جاري الإرسال')
                    : const Text('إعادة إرسال الرمز'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
