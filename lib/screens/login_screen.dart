import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import 'my_ads_screen.dart';
import 'add_ad_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final List<Map<String, String>> countries = [
    {'name': 'سوريا', 'code': '+963'},
    {'name': 'تركيا', 'code': '+90'},
    {'name': 'الأردن', 'code': '+962'},
    {'name': 'السعودية', 'code': '+966'},
    {'name': 'مصر', 'code': '+20'},
    {'name': 'العراق', 'code': '+964'},
    {'name': 'لبنان', 'code': '+961'},
    {'name': 'فلسطين', 'code': '+970'},
    {'name': 'الإمارات', 'code': '+971'},
    {'name': 'قطر', 'code': '+974'},
    {'name': 'الكويت', 'code': '+965'},
    {'name': 'عمان', 'code': '+968'},
    {'name': 'البحرين', 'code': '+973'},
  ];
  Map<String, String>? selectedCountry;
  final phoneController = TextEditingController();
  final passwordPhoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedCountry = countries[0];
  }

  bool _isLoading = false;
  bool _showPasswordPhone = false;
  bool _rememberMe = false;

  Future<void> _login() async {
    String apiUrl = 'https://sahbo-app-api.onrender.com/api/auth/login';

    if (phoneController.text.isEmpty || passwordPhoneController.text.isEmpty) {
      _showError('يرجى إدخال رقم الهاتف وكلمة المرور');
      return;
    }

    final body = {
      'phoneNumber': '${selectedCountry?['code'] ?? ''}${phoneController.text.trim()}',
      'password': passwordPhoneController.text,
    };

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final res = jsonDecode(response.body);

      if (response.statusCode == 200 && res['token'] != null) {
        final prefs = await SharedPreferences.getInstance();

        await prefs.setString('token', res['token']);
        await prefs.setBool('rememberMe', _rememberMe);
        await prefs.setString('userName', res['userName'] ?? '');
        await prefs.setString('userEmail', res['userEmail'] ?? '');
        await prefs.setString('userId', res['userId'] ?? '');
        await prefs.setString('userPhone', res['userPhone'] ?? '');

        _navigateAfterLogin(prefs);
      } else {
        _showError(res['message'] ?? 'حدث خطأ أثناء تسجيل الدخول');
      }
    } catch (e) {
      _showError('حدث خطأ في الاتصال بالخادم');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateAfterLogin(SharedPreferences prefs) {
    String? redirect = prefs.getString('redirect_to');
    prefs.remove('redirect_to');

    Widget nextScreen;
    switch (redirect) {
      case 'myAds':
        nextScreen = const MyAdsScreen();
        break;
      case 'addAd':
        nextScreen = const MultiStepAddAdScreen();
        break;
      default:
        nextScreen = const HomeScreen();
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => nextScreen),
      (route) => false,
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFFF7A59),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: const Text('تسجيل الدخول'),
          centerTitle: true,
          backgroundColor: const Color(0xFF1E4A47),
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF7FE8E4),
                Colors.white,
              ],
            ),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Column(
            children: [
              Row(
                children: [
                  // Phone number field (right)
                  Expanded(
                    child: TextField(
                      controller: phoneController,
                      decoration: InputDecoration(
                        labelText: 'رقم الهاتف',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(Icons.phone, color: Color(0xFF2E7D78)),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Country code dropdown (left)
                  SizedBox(
                    width: 120,
                    child: DropdownButtonFormField<Map<String, String>>(
                      value: selectedCountry,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: countries.map((country) {
                        return DropdownMenuItem<Map<String, String>>(
                          value: country,
                          child: Row(
                            children: [
                              Text(country['name']!, style: const TextStyle(fontSize: 11)),
                              const SizedBox(width: 6),
                              Text(country['code']!, style: const TextStyle(fontSize: 11)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCountry = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordPhoneController,
                obscureText: !_showPasswordPhone,
                onSubmitted: (_) => _login(),
                decoration: InputDecoration(
                  labelText: 'كلمة المرور',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.lock, color: Color(0xFF2E7D78)),
                  suffixIcon: IconButton(
                    icon: Icon(
                      !_showPasswordPhone ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () => setState(() => _showPasswordPhone = !_showPasswordPhone),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: _rememberMe,
                onChanged: (val) => setState(() => _rememberMe = val ?? false),
                title: const Text("تذكرني", style: TextStyle(color: Colors.black87)),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 16),
              _isLoading
                  ? const CircularProgressIndicator(color: Color(0xFF4DD0CC))
                  : ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: const Color(0xFF1E4A47),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text(
                        'تسجيل الدخول',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  );
                  if (result == true) {
                    _showError('تم إنشاء الحساب، يمكنك تسجيل الدخول الآن');
                  }
                },
                child: const Text(
                  "ليس لديك حساب؟ إنشاء حساب جديد",
                  style: TextStyle(color: Color(0xFF1E4A47)),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}