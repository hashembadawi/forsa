import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sahbo_app/screens/login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final phoneController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _isLoading = false;

  // Country list
  final List<Map<String, String>> countries = [
    {'name': 'سوريا', 'code': '+963', 'flag': '🇸🇾'},
    {'name': 'تركيا', 'code': '+90', 'flag': '🇹🇷'},
    {'name': 'الأردن', 'code': '+962', 'flag': '🇯🇴'},
    {'name': 'السعودية', 'code': '+966', 'flag': '🇸🇦'},
    {'name': 'مصر', 'code': '+20', 'flag': '🇪🇬'},
    {'name': 'العراق', 'code': '+964', 'flag': '🇮🇶'},
    {'name': 'لبنان', 'code': '+961', 'flag': '🇱🇧'},
    {'name': 'فلسطين', 'code': '+970', 'flag': '🇵🇸'},
    {'name': 'الإمارات', 'code': '+971', 'flag': '🇦🇪'},
    {'name': 'قطر', 'code': '+974', 'flag': '🇶🇦'},
    {'name': 'الكويت', 'code': '+965', 'flag': '🇰🇼'},
    {'name': 'عمان', 'code': '+968', 'flag': '🇴🇲'},
    {'name': 'البحرين', 'code': '+973', 'flag': '🇧🇭'},
  ];
  Map<String, String>? selectedCountry;

  @override
  void initState() {
    super.initState();
    selectedCountry = countries[0];
  }

  Future<void> registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    if (passwordController.text != confirmPasswordController.text) {
      _showError("كلمتا المرور غير متطابقتين");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final fullPhone = '${selectedCountry?['code'] ?? ''}${phoneController.text.trim()}';
      final response = await http.post(
        Uri.parse('https://sahbo-app-api.onrender.com/api/auth/register-phone'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phoneNumber': fullPhone,
          'firstName': firstNameController.text.trim(),
          'lastName': lastNameController.text.trim(),
          'password': passwordController.text,
        }),
      );

      if (response.statusCode == 201) {
        //show success 
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم إضافة المستخدم بنجاح'),
            duration: Duration(seconds: 3), // سيختفي بعد 3 ثواني
            behavior: SnackBarBehavior.floating, // لجعله عائمًا بدلاً من أن يكون ملتصقًا بالأسفل
          ),
        );
        Future.delayed(Duration(seconds: 3), () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => LoginScreen()), // استبدل LoginScreen بشاشة تسجيل الدخول الخاصة بك
          );
        }
      });
        /* Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => VerificationScreen(
              phoneNumber: fullPhone,
            ),
          ),
        );
        Navigator.pop(context); */
      } else {
        final resBody = jsonDecode(response.body);
        _showError(resBody['message'] ?? 'حدث خطأ، حاول مرة أخرى');
      }
    } catch (e) {
      _showError('حدث خطأ في الاتصال بالخادم');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: const Text('إنشاء حساب جديد'),
          centerTitle: true,
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Country picker + phone field
                Row(
  children: [
    // Phone number field (right)
    Expanded(
      child: _buildTextField(
        label: 'رقم الهاتف',
        controller: phoneController,
        keyboardType: TextInputType.phone,
        validator: (value) =>
            value == null || value.isEmpty ? 'يرجى إدخال رقم الهاتف' : null,
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
                Text(country['name']!, style: const TextStyle(fontSize: 10)),
                const SizedBox(width: 6),
                Text(country['code']!, style: const TextStyle(fontSize: 10)),
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
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        label: 'الاسم الأول',
                        controller: firstNameController,
                        validator: (value) =>
                            value == null || value.isEmpty ? 'يرجى إدخال الاسم الأول' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        label: 'الاسم الأخير',
                        controller: lastNameController,
                        validator: (value) =>
                            value == null || value.isEmpty ? 'يرجى إدخال الاسم الأخير' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  label: 'كلمة المرور',
                  controller: passwordController,
                  icon: Icons.lock,
                  obscureText: !_showPassword,
                  suffixIcon: IconButton(
                    icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _showPassword = !_showPassword),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'يرجى إدخال كلمة المرور';
                    if (value.length < 6) return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  label: 'إعادة كلمة المرور',
                  controller: confirmPasswordController,
                  icon: Icons.lock,
                  obscureText: !_showConfirmPassword,
                  suffixIcon: IconButton(
                    icon: Icon(_showConfirmPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'يرجى إعادة كلمة المرور';
                    if (value != passwordController.text) return 'كلمتا المرور غير متطابقتين';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: registerUser,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: Colors.deepPurple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'إنشاء حساب',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        prefixIcon: icon != null ? Icon(icon, color: Colors.deepPurple) : null,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}