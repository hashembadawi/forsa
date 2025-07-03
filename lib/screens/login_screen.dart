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
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordPhoneController = TextEditingController();
  final passwordEmailController = TextEditingController();

  bool _isLoading = false;
  bool _showPasswordPhone = false;
  bool _showPasswordEmail = false;

  Future<void> _login({required String method}) async {
    String apiUrl = 'http://localhost:10000/api/auth/login';

    final body = method == 'phone'
        ? {
      'phoneNumber': phoneController.text.trim(),
      'password': passwordPhoneController.text,
    }
        : {
      'email': emailController.text.trim(),
      'password': passwordEmailController.text,
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
        if (res['username'] != null) await prefs.setString('username', res['username']);
        if (res['email'] != null) await prefs.setString('email', res['email']);
        if (res['userId'] != null) await prefs.setString('userId', res['userId']);

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
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildLoginTab({
    required String label1,
    required String label2,
    required TextEditingController controller1,
    required TextEditingController controller2,
    required bool obscureText,
    required VoidCallback toggleObscure,
    required VoidCallback onLogin,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: controller1,
            decoration: InputDecoration(
              labelText: label1,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              prefixIcon: Icon(
                label1.contains("الهاتف") ? Icons.phone : Icons.email,
                color: Colors.deepPurple,
              ),
            ),
            keyboardType: label1.contains("الهاتف")
                ? TextInputType.phone
                : TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller2,
            obscureText: obscureText,
            decoration: InputDecoration(
              labelText: label2,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.lock, color: Colors.deepPurple),
              suffixIcon: IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: toggleObscure,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _isLoading
              ? const CircularProgressIndicator()
              : ElevatedButton(
            onPressed: onLogin,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: Colors.deepPurple,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text(
              'تسجيل الدخول',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RegisterScreen()),
              );
            },
            child: const Text(
              "ليس لديك حساب؟ إنشاء حساب جديد",
              style: TextStyle(color: Colors.deepPurple),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: AppBar(
            title: const Text('تسجيل الدخول'),
            centerTitle: true,
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            bottom: TabBar(
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(icon: Icon(Icons.phone_android), text: 'برقم الهاتف'),
                Tab(icon: Icon(Icons.email_outlined), text: 'بالبريد الإلكتروني'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              _buildLoginTab(
                label1: 'رقم الهاتف',
                label2: 'كلمة المرور',
                controller1: phoneController,
                controller2: passwordPhoneController,
                obscureText: !_showPasswordPhone,
                toggleObscure: () => setState(() => _showPasswordPhone = !_showPasswordPhone),
                onLogin: () => _login(method: 'phone'),
              ),
              _buildLoginTab(
                label1: 'البريد الإلكتروني',
                label2: 'كلمة المرور',
                controller1: emailController,
                controller2: passwordEmailController,
                obscureText: !_showPasswordEmail,
                toggleObscure: () => setState(() => _showPasswordEmail = !_showPasswordEmail),
                onLogin: () => _login(method: 'email'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}