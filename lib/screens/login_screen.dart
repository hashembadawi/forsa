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
    String apiUrl = 'http://192.168.1.120:10000/api/auth/login';

    final body = method == 'phone'
        ? {
      'phoneNumber': phoneController.text.trim(),
      'password': passwordPhoneController.text,
    }
        : {
      'email': emailController.text.trim(),
      'password': passwordEmailController.text,
    };

    setState(() {
      _isLoading = true;
    });

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    setState(() {
      _isLoading = false;
    });

    final res = jsonDecode(response.body);

    if (response.statusCode == 200 && res['token'] != null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', res['token']);
      if (res['username'] != null) {
        await prefs.setString('username', res['username']);
      }
      if (res['email'] != null) {
        await prefs.setString('email', res['email']);
      }

      String? redirect = prefs.getString('redirect_to');
      prefs.remove('redirect_to');

      Widget nextScreen;
      switch (redirect) {
        case 'myAds':
          nextScreen = MyAdsScreen();
          break;
        case 'addAd':
          nextScreen = MultiStepAddAdScreen();
          break;
        default:
          nextScreen = HomeScreen();
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => nextScreen),
            (route) => false,
      );
    } else {
      String message = res['message'] ?? 'حدث خطأ أثناء تسجيل الدخول';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
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
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: Icon(label1.contains("الهاتف") ? Icons.phone : Icons.email,
                  color: Colors.deepPurple),
            ),
            keyboardType: label1.contains("الهاتف")
                ? TextInputType.phone
                : TextInputType.emailAddress,
          ),
          SizedBox(height: 16),
          TextField(
            controller: controller2,
            obscureText: obscureText,
            decoration: InputDecoration(
              labelText: label2,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: Icon(Icons.lock, color: Colors.deepPurple),
              suffixIcon: IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: toggleObscure,
              ),
            ),
          ),
          SizedBox(height: 24),
          _isLoading
              ? CircularProgressIndicator()
              : ElevatedButton(
            onPressed: onLogin,
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 50),
              backgroundColor: Colors.deepPurple,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('تسجيل الدخول', style: TextStyle(fontSize: 18, color: Colors.white)),
          ),
          SizedBox(height: 10),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => RegisterScreen()),
              );
            },
            child: Text(
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
            backgroundColor: Colors.deepPurpleAccent,
            title: Text('تسجيل الدخول'),
            leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            bottom: TabBar(
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: [
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
