import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sahbo_app/screens/verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _isLoading = false;

  Future<void> registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    if (passwordController.text != confirmPasswordController.text) {
      _showError("كلمتا المرور غير متطابقتين");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('https://sahbo-app-api.onrender.com:10000/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': emailController.text.trim(),
          'firstName': firstNameController.text.trim(),
          'lastName': lastNameController.text.trim(),
          'phoneNumber': phoneController.text.trim(),
          'password': passwordController.text,
        }),
      );

      if (response.statusCode == 201) {
        // توجيه شاشة التحقق بعد التسجيل
        final emailOrPhone = emailController.text.trim().isNotEmpty
            ? emailController.text.trim()
            : phoneController.text.trim();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                VerificationScreen(emailOrPhone: emailOrPhone),
          ),
        );
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

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
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
                _buildTextField(
                  label: 'البريد الإلكتروني',
                  controller: emailController,
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'يرجى إدخال البريد الإلكتروني';
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return 'البريد الإلكتروني غير صالح';
                    return null;
                  },
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
                  label: 'رقم الهاتف',
                  controller: phoneController,
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  validator: (value) =>
                  value == null || value.isEmpty ? 'يرجى إدخال رقم الهاتف' : null,
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