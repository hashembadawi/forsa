import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
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

  Future<bool> _checkInternetConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<void> _login() async {
    String apiUrl = 'https://sahbo-app-api.onrender.com/api/auth/login';

    if (phoneController.text.isEmpty || passwordPhoneController.text.isEmpty) {
      _showError('يرجى إدخال رقم الهاتف وكلمة المرور');
      return;
    }

    // Check internet connectivity first
    setState(() => _isLoading = true);
    
    final isConnected = await _checkInternetConnectivity();
    if (!isConnected) {
      setState(() => _isLoading = false);
      _showNoInternetDialog();
      return;
    }

    final body = {
      'phoneNumber': '${selectedCountry?['code'] ?? ''}${phoneController.text.trim()}',
      'password': passwordPhoneController.text,
    };

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

  void _showNoInternetDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: Colors.blue[300]!, width: 1.5),
        ),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.orange),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'لا يوجد اتصال بالإنترنت',
                style: TextStyle(color: Colors.black87),
                overflow: TextOverflow.visible,
              ),
            ),
          ],
        ),
        content: const Text(
          'يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى',
          style: TextStyle(color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إغلاق', style: TextStyle(color: Colors.orange)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _login(); // Retry the login
            },
            child: const Text('إعادة المحاولة', style: TextStyle(color: Colors.blue)),
          ),
        ],
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
          backgroundColor: Colors.blue[700],
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
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
              const SizedBox(height: 32),
              
              // Login form container
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: Colors.white,
                  border: Border.all(
                    color: Colors.blue[300]!,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue[200]!.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
              // Country code dropdown (top)
              DropdownButtonFormField<Map<String, String>>(
                value: selectedCountry,
                decoration: InputDecoration(
                  labelText: 'البلد',
                  labelStyle: TextStyle(color: Colors.black87),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
                  ),
                  prefixIcon: Icon(Icons.flag, color: Colors.blue[600]),
                ),
                items: countries.map((country) {
                  return DropdownMenuItem<Map<String, String>>(
                    value: country,
                    child: Row(
                      children: [
                        Text(country['name']!, style: const TextStyle(fontSize: 14, color: Colors.black87)),
                        const SizedBox(width: 8),
                        Text(country['code']!, style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.bold)),
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
              const SizedBox(height: 16),
              // Phone number field (bottom) - now full width
              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: 'رقم الهاتف',
                  labelStyle: TextStyle(color: Colors.black87),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
                  ),
                  prefixIcon: Icon(Icons.phone, color: Colors.blue[600]),
                  helperText: 'رمز البلد: ${selectedCountry?['code'] ?? ''}',
                  helperStyle: TextStyle(color: Colors.blue[600], fontWeight: FontWeight.bold),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordPhoneController,
                obscureText: !_showPasswordPhone,
                onSubmitted: (_) => _login(),
                decoration: InputDecoration(
                  labelText: 'كلمة المرور',
                  labelStyle: TextStyle(color: Colors.black87),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
                  ),
                  prefixIcon: Icon(Icons.lock, color: Colors.blue[600]),
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
                activeColor: Colors.blue[600],
              ),
              const SizedBox(height: 16),
              _isLoading
                  ? CircularProgressIndicator(color: Colors.blue[600])
                  : ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                      child: const Text(
                        'تسجيل الدخول',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Register section - more attractive
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue[50]!,
                      Colors.white,
                    ],
                  ),
                  border: Border.all(
                    color: Colors.blue[200]!,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue[100]!.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.person_add,
                        size: 32,
                        color: Colors.blue[600],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'مستخدم جديد؟',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'انضم إلينا واستمتع بجميع الميزات',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const RegisterScreen()),
                            );
                            if (result == true) {
                              _showError('تم إنشاء الحساب، يمكنك تسجيل الدخول الآن');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.blue[700],
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.blue[300]!, width: 2),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.app_registration,
                                size: 20,
                                color: Colors.blue[700],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'إنشاء حساب جديد',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
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