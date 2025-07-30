import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:syria_market/utils/dialog_utils.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import 'my_ads_screen.dart';
import 'add_ad_screen.dart';

/// Login screen for user authentication
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ========== Constants ==========
  static const String _apiUrl = 'https://sahbo-app-api.onrender.com/api/user/login';
  
  // ========== Country Data ==========
  static const List<Map<String, String>> _countries = [
    {'name': 'سوريا', 'code': '963'},
    {'name': 'تركيا', 'code': '90'},
    {'name': 'الأردن', 'code': '962'},
    {'name': 'السعودية', 'code': '966'},
    {'name': 'مصر', 'code': '20'},
    {'name': 'العراق', 'code': '964'},
    {'name': 'لبنان', 'code': '961'},
    {'name': 'فلسطين', 'code': '970'},
    {'name': 'الإمارات', 'code': '971'},
    {'name': 'قطر', 'code': '974'},
    {'name': 'الكويت', 'code': '965'},
    {'name': 'عمان', 'code': '968'},
    {'name': 'البحرين', 'code': '973'},
  ];

  // ========== Controllers & State ==========
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  Map<String, String>? _selectedCountry;
  bool _showPassword = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _initializeDefaults();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ========== Initialization ==========

  /// Initialize default values
  void _initializeDefaults() {
    _selectedCountry = _countries.first;
  }

  // ========== Validation Methods ==========

  /// Validate login form
  bool _validateForm() {
    if (_phoneController.text.trim().isEmpty) {
      _showError('يرجى إدخال رقم الهاتف');
      return false;
    }
    
    if (_passwordController.text.isEmpty) {
      _showError('يرجى إدخال كلمة المرور');
      return false;
    }
    
    return true;
  }

  /// Get formatted phone number with country code
  String get _formattedPhoneNumber {
    final countryCode = _selectedCountry?['code'] ?? '';
    final phoneNumber = _phoneController.text.trim();
    return '$countryCode$phoneNumber';
  }

  // ========== Network Methods ==========

  /// Check internet connectivity
  Future<bool> _checkInternetConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  /// Perform login request
  Future<void> _login() async {
    if (!_validateForm()) return;

    try {
      // Check connectivity first
      final isConnected = await _checkInternetConnectivity();
      if (!isConnected) {
        DialogUtils.showNoInternetDialog(
          context: context,
          onRetry: _login,
        );
        return;
      }

      // Show loading dialog
      DialogUtils.showLoadingDialog(
        context: context,
        title: 'جارٍ تسجيل الدخول...',
        message: 'يرجى الانتظار حتى يتم التحقق من بياناتك',
      );

      // Perform login request
      final response = await _performLoginRequest();
      await _handleLoginResponse(response);
      
    } catch (e) {
      DialogUtils.closeDialog(context); // Close dialog
      DialogUtils.showErrorDialog(
        context: context,
        message: 'حدث خطأ في الاتصال بالخادم',
      );
    }
  }

  /// Perform actual login HTTP request
  Future<http.Response> _performLoginRequest() async {
    final requestBody = {
      'phoneNumber': _formattedPhoneNumber,
      'password': _passwordController.text,
    };

    return await http.post(
      Uri.parse(_apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );
  }

  /// Handle login response
  Future<void> _handleLoginResponse(http.Response response) async {
    final responseData = jsonDecode(response.body);

    DialogUtils.closeDialog(context); // Close loading dialog

    if (response.statusCode == 200 && responseData['token'] != null) {
      await _saveUserData(responseData);
      await _navigateAfterLogin();
    } else {
      final errorMessage = 'حدث خطأ أثناء تسجيل الدخول';
      DialogUtils.showErrorDialog(
        context: context,
        message: errorMessage,
      );
    }
  }

  /// Save user data to shared preferences
  Future<void> _saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    
    await Future.wait([
      prefs.setString('token', userData['token'] ?? ''),
      prefs.setBool('rememberMe', _rememberMe),
      prefs.setString('userName', userData['userName'] ?? ''),
      prefs.setString('userEmail', userData['userEmail'] ?? ''),
      prefs.setString('userId', userData['userId'] ?? ''),
      prefs.setString('userPhone', userData['userPhone'] ?? ''),
      prefs.setString('userProfileImage', userData['userProfileImage'] ?? ''),
      prefs.setString('userAccountNumber', userData['userAccountNumber'] ?? ''),
    ]);
  }

  // ========== Navigation Methods ==========

  /// Navigate after successful login
  Future<void> _navigateAfterLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final redirect = prefs.getString('redirect_to');
    await prefs.remove('redirect_to');

    final nextScreen = _getTargetScreen(redirect);
    
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => nextScreen),
        (route) => false,
      );
    }
  }

  /// Get target screen based on redirect parameter
  Widget _getTargetScreen(String? redirect) {
    switch (redirect) {
      case 'myAds':
        return const MyAdsScreen();
      case 'addAd':
        return const MultiStepAddAdScreen();
      default:
        return const HomeScreen();
    }
  }

  /// Navigate to register screen
  Future<void> _navigateToRegister() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
    
    if (result == true) {
      _showSuccessMessage('تم إنشاء الحساب، يمكنك تسجيل الدخول الآن');
    }
  }

  // ========== UI Feedback Methods ==========

  /// Show error message
  void _showError(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFFF7A59),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /// Show success message
  void _showSuccessMessage(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ========== Widget Building Methods ==========

  /// Build main app bar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('تسجيل الدخول'),
      centerTitle: true,
      backgroundColor: Colors.blue[700],
      foregroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  /// Build main body content
  Widget _buildBody() {
    return Container(
      decoration: const BoxDecoration(color: Colors.white),
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
            _buildLoginForm(),
            const SizedBox(height: 24),
            _buildRegisterSection(),
          ],
        ),
      ),
    );
  }

  /// Build login form container
  Widget _buildLoginForm() {
    return Container(
      decoration: _buildFormDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildCountryDropdown(),
            const SizedBox(height: 16),
            _buildPhoneField(),
            const SizedBox(height: 16),
            _buildPasswordField(),
            const SizedBox(height: 12),
            _buildRememberMeCheckbox(),
            const SizedBox(height: 16),
            _buildLoginButton(),
          ],
        ),
      ),
    );
  }

  /// Build form decoration
  BoxDecoration _buildFormDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      color: Colors.white,
      border: Border.all(color: Colors.blue[300]!, width: 1.5),
      boxShadow: [
        BoxShadow(
          color: Colors.blue[200]!.withOpacity(0.3),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// Build country dropdown
  Widget _buildCountryDropdown() {
    return DropdownButtonFormField<Map<String, String>>(
      value: _selectedCountry,
      decoration: _buildInputDecoration(
        labelText: 'البلد',
        prefixIcon: Icons.flag,
      ),
      items: _countries.map(_buildCountryDropdownItem).toList(),
      onChanged: (value) => setState(() => _selectedCountry = value),
    );
  }

  /// Build country dropdown item
  DropdownMenuItem<Map<String, String>> _buildCountryDropdownItem(
    Map<String, String> country,
  ) {
    return DropdownMenuItem<Map<String, String>>(
      value: country,
      child: Row(
        children: [
          Text(
            country['name']!,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(width: 8),
          Text(
            country['code']!,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Build phone number field
  Widget _buildPhoneField() {
    return TextField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      decoration: _buildInputDecoration(
        labelText: 'رقم الهاتف',
        prefixIcon: Icons.phone,
        helperText: 'رمز البلد: ${_selectedCountry?['code'] ?? ''}',
      ),
    );
  }

  /// Build password field
  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: !_showPassword,
      onSubmitted: (_) => _login(),
      decoration: _buildInputDecoration(
        labelText: 'كلمة المرور',
        prefixIcon: Icons.lock,
        suffixIcon: IconButton(
          icon: Icon(
            _showPassword ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey,
          ),
          onPressed: () => setState(() => _showPassword = !_showPassword),
        ),
      ),
    );
  }

  /// Build input field decoration
  InputDecoration _buildInputDecoration({
    required String labelText,
    required IconData prefixIcon,
    Widget? suffixIcon,
    String? helperText,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(color: Colors.black87),
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
      prefixIcon: Icon(prefixIcon, color: Colors.blue[600]),
      suffixIcon: suffixIcon,
      helperText: helperText,
      helperStyle: TextStyle(
        color: Colors.blue[600],
        fontWeight: FontWeight.bold,
      ),
    );
  }

  /// Build remember me checkbox
  Widget _buildRememberMeCheckbox() {
    return CheckboxListTile(
      value: _rememberMe,
      onChanged: (value) => setState(() => _rememberMe = value ?? false),
      title: const Text(
        "تذكرني",
        style: TextStyle(color: Colors.black87),
      ),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      activeColor: Colors.blue[600],
    );
  }

  /// Build login button
  Widget _buildLoginButton() {
    return ElevatedButton(
      onPressed: _login,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
      child: const Text(
        'تسجيل الدخول',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  /// Build register section
  Widget _buildRegisterSection() {
    return Container(
      decoration: _buildRegisterDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildRegisterIcon(),
            const SizedBox(height: 12),
            _buildRegisterTitle(),
            const SizedBox(height: 8),
            _buildRegisterSubtitle(),
            const SizedBox(height: 16),
            _buildRegisterButton(),
          ],
        ),
      ),
    );
  }

  /// Build register section decoration
  BoxDecoration _buildRegisterDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.blue[50]!, Colors.white],
      ),
      border: Border.all(color: Colors.blue[200]!, width: 1.5),
      boxShadow: [
        BoxShadow(
          color: Colors.blue[100]!.withOpacity(0.3),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  /// Build register icon
  Widget _buildRegisterIcon() {
    return Icon(
      Icons.person_add,
      size: 32,
      color: Colors.blue[600],
    );
  }

  /// Build register title
  Widget _buildRegisterTitle() {
    return const Text(
      'مستخدم جديد؟',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  /// Build register subtitle
  Widget _buildRegisterSubtitle() {
    return Text(
      'انضم إلينا واستمتع بجميع الميزات',
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey[600],
      ),
      textAlign: TextAlign.center,
    );
  }

  /// Build register button
  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _navigateToRegister,
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
            Icon(Icons.app_registration, size: 20, color: Colors.blue[700]),
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
    );
  }

  // ========== Main Build Method ==========

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: _buildAppBar(),
        body: _buildBody(),
      ),
    );
  }
}
