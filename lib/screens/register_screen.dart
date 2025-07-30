import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:syria_market/screens/verification_screen.dart';
import 'package:syria_market/utils/dialog_utils.dart';

/// User registration screen with form validation and country selection
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // ========== Constants ==========
  static const String _registerApiUrl = 'https://sahbo-app-api.onrender.com/api/user/register-phone';
  static const int _minPasswordLength = 6;
  
  // ========== Form Controllers ==========
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // ========== State Variables ==========
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  Map<String, String>? _selectedCountry;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  // ========== Country Data ==========
  static const List<Map<String, String>> _countries = [
    {'name': 'سوريا', 'code': '963', 'flag': '🇸🇾'},
    {'name': 'تركيا', 'code': '90', 'flag': '🇹🇷'},
    {'name': 'الأردن', 'code': '962', 'flag': '🇯🇴'},
    {'name': 'السعودية', 'code': '966', 'flag': '🇸🇦'},
    {'name': 'مصر', 'code': '20', 'flag': '🇪🇬'},
    {'name': 'العراق', 'code': '964', 'flag': '🇮🇶'},
    {'name': 'لبنان', 'code': '961', 'flag': '🇱🇧'},
    {'name': 'فلسطين', 'code': '970', 'flag': '🇵🇸'},
    {'name': 'الإمارات', 'code': '971', 'flag': '🇦🇪'},
    {'name': 'قطر', 'code': '974', 'flag': '🇶🇦'},
    {'name': 'الكويت', 'code': '965', 'flag': '🇰🇼'},
    {'name': 'عمان', 'code': '968', 'flag': '🇴🇲'},
    {'name': 'البحرين', 'code': '973', 'flag': '🇧🇭'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedCountry = _countries.first;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ========== Network Connectivity ==========

  /// Check if device has internet connection
  Future<bool> _checkInternetConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      debugPrint('Connectivity check error: $e');
      return false;
    }
  }

  // ========== Profile Image Methods ==========

  /// Pick profile image from gallery
  Future<void> _pickProfileImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      DialogUtils.showErrorDialog(
        context: context,
        message: 'حدث خطأ أثناء اختيار الصورة',
      );
    }
  }

  /// Remove selected profile image
  void _removeProfileImage() {
    setState(() {
      _profileImage = null;
    });
  }

  /// Compress profile image to base64
  Future<String?> _compressProfileImage() async {
    if (_profileImage == null) return null;
    
    try {
      final compressedBytes = await FlutterImageCompress.compressWithFile(
        _profileImage!.path,
        quality: 70,
        format: CompressFormat.jpeg,
      );
      
      if (compressedBytes != null) {
        return base64Encode(compressedBytes);
      }
    } catch (e) {
      debugPrint('Image compression error: $e');
    }
    return null;
  }

  // ========== Registration Logic ==========

  /// Handle user registration process
  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_validatePasswordMatch()) {
      DialogUtils.showErrorDialog(
        context: context,
        message: "كلمتا المرور غير متطابقتين",
      );
      return;
    }

    if (!await _checkInternetConnectivity()) {
      DialogUtils.showNoInternetDialog(
        context: context,
        onRetry: _registerUser,
      );
      return;
    }

    // Show loading dialog
    DialogUtils.showLoadingDialog(
      context: context,
      title: 'جارٍ إنشاء الحساب...',
      message: 'يرجى الانتظار حتى يتم إنشاء حسابك',
    );

    try {
      await _performRegistration();
    } catch (e) {
      DialogUtils.closeDialog(context); // Close loading dialog
      debugPrint('Registration error: $e');
      DialogUtils.showErrorDialog(
        context: context,
        message: 'حدث خطأ في الاتصال بالخادم',
      );
    }
  }

  /// Perform the actual registration API call
  Future<void> _performRegistration() async {
    final String fullPhoneNumber = _buildFullPhoneNumber();
    final String? profileImageBase64 = await _compressProfileImage();
    
    final requestBody = {
      'phoneNumber': fullPhoneNumber,
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'password': _passwordController.text,
    };

    // Add profile image if selected
    if (profileImageBase64 != null) {
      requestBody['profileImage'] = profileImageBase64;
    }
    final response = await http.post(
      Uri.parse(_registerApiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    await _handleRegistrationResponse(response);
  }

  /// Handle the registration API response
  Future<void> _handleRegistrationResponse(http.Response response) async {
    DialogUtils.closeDialog(context); // Close loading dialog

    if (response.statusCode == 201) {
      DialogUtils.showSuccessDialog(
        context: context,
        message: 'تم إنشاء حسابك بنجاح، سيتم إرسال رمز التحقق إلى رقم هاتفك',
        onPressed: () {
          Navigator.of(context).pop(); // Close dialog
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => VerificationScreen(
                phoneNumber: _buildFullPhoneNumber(),
              ),
            ),
          );
        },
      );
    } else {
      final errorMessage = 'يرجى استخدام رقم هاتف غير مسجل مسبقاً';
      DialogUtils.showErrorDialog(
        context: context,
        message: errorMessage,
      );
    }
  }

  /// Build full phone number with country code
  String _buildFullPhoneNumber() {
    final countryCode = _selectedCountry?['code'] ?? '';
    final phoneNumber = _phoneController.text.trim();
    return '$countryCode$phoneNumber';
  }

  /// Validate if password and confirm password match
  bool _validatePasswordMatch() {
    return _passwordController.text == _confirmPasswordController.text;
  }

  // ========== Form Validation ==========

  /// Validate phone number input
  String? _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال رقم الهاتف';
    }
    return null;
  }

  /// Validate first name input
  String? _validateFirstName(String? value) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال الاسم الأول';
    }
    return null;
  }

  /// Validate last name input
  String? _validateLastName(String? value) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال الاسم الأخير';
    }
    return null;
  }

  /// Validate password input
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال كلمة المرور';
    }
    if (value.length < _minPasswordLength) {
      return 'كلمة المرور يجب أن تكون $_minPasswordLength أحرف على الأقل';
    }
    return null;
  }

  /// Validate confirm password input
  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'يرجى إعادة كلمة المرور';
    }
    if (value != _passwordController.text) {
      return 'كلمتا المرور غير متطابقتين';
    }
    return null;
  }

  // ========== Widget Build Methods ==========

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: _buildAppBar(),
        body: _buildBody(),
      ),
    );
  }

  /// Build the app bar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('إنشاء حساب جديد'),
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

  /// Build the main body content
  Widget _buildBody() {
    return Container(
      decoration: const BoxDecoration(color: Colors.white),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: _buildFormContainer(),
      ),
    );
  }

  /// Build the form container with styling
  Widget _buildFormContainer() {
    return Form(
      key: _formKey,
      child: Container(
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
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildProfileImageSection(),
            const SizedBox(height: 20),
            _buildCountryDropdown(),
            const SizedBox(height: 16),
            _buildPhoneNumberField(),
            const SizedBox(height: 16),
            _buildNameFields(),
            const SizedBox(height: 16),
            _buildPasswordField(),
            const SizedBox(height: 16),
            _buildConfirmPasswordField(),
            const SizedBox(height: 24),
            _buildRegisterButton(),
          ],
        ),
      ),
    );
  }

  /// Build country selection dropdown
  Widget _buildCountryDropdown() {
    return DropdownButtonFormField<Map<String, String>>(
      value: _selectedCountry,
      decoration: _buildInputDecoration(
        labelText: 'البلد',
        prefixIcon: Icons.flag,
      ),
      items: _countries.map((country) {
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
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCountry = value;
        });
      },
    );
  }

  /// Build phone number input field
  Widget _buildPhoneNumberField() {
    return TextFormField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      validator: _validatePhoneNumber,
      style: const TextStyle(color: Colors.black87),
      decoration: _buildInputDecoration(
        labelText: 'رقم الهاتف',
        prefixIcon: Icons.phone,
        helperText: 'رمز البلد: ${_selectedCountry?['code'] ?? ''}',
      ),
    );
  }

  /// Build first name and last name fields
  Widget _buildNameFields() {
    return Row(
      children: [
        Expanded(
          child: _buildTextField(
            label: 'الاسم الأول',
            controller: _firstNameController,
            validator: _validateFirstName,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildTextField(
            label: 'الاسم الأخير',
            controller: _lastNameController,
            validator: _validateLastName,
          ),
        ),
      ],
    );
  }

  /// Build password input field
  Widget _buildPasswordField() {
    return _buildTextField(
      label: 'كلمة المرور',
      controller: _passwordController,
      icon: Icons.lock,
      obscureText: !_showPassword,
      suffixIcon: IconButton(
        icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off),
        onPressed: () => setState(() => _showPassword = !_showPassword),
      ),
      validator: _validatePassword,
    );
  }

  /// Build confirm password input field
  Widget _buildConfirmPasswordField() {
    return _buildTextField(
      label: 'إعادة كلمة المرور',
      controller: _confirmPasswordController,
      icon: Icons.lock,
      obscureText: !_showConfirmPassword,
      suffixIcon: IconButton(
        icon: Icon(_showConfirmPassword ? Icons.visibility : Icons.visibility_off),
        onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
      ),
      validator: _validateConfirmPassword,
    );
  }

  /// Build register button
  Widget _buildRegisterButton() {
    return ElevatedButton(
      onPressed: _registerUser,
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
        'إنشاء حساب',
        style: TextStyle(fontSize: 18, color: Colors.white),
      ),
    );
  }

  // ========== Helper Widget Methods ==========

  /// Build profile image selection section
  Widget _buildProfileImageSection() {
    return Column(
      children: [
        const Text(
          'صورة الملف الشخصي',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _pickProfileImage,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.blue[300]!,
                width: 2,
              ),
              color: Colors.grey[100],
            ),
            child: _profileImage != null
                ? Stack(
                    children: [
                      ClipOval(
                        child: Image.file(
                          _profileImage!,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _removeProfileImage,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt,
                        size: 40,
                        color: Colors.blue[600],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'إضافة صورة',
                        style: TextStyle(
                          color: Colors.blue[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'اختيارية',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  /// Build a reusable text field with consistent styling
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
      style: const TextStyle(color: Colors.black87),
      decoration: _buildInputDecoration(
        labelText: label,
        prefixIcon: icon,
        suffixIcon: suffixIcon,
      ),
    );
  }

  /// Build consistent input decoration for form fields
  InputDecoration _buildInputDecoration({
    required String labelText,
    IconData? prefixIcon,
    Widget? suffixIcon,
    String? helperText,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(color: Colors.black87),
      filled: true,
      fillColor: Colors.white,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.blue[600]) : null,
      suffixIcon: suffixIcon,
      helperText: helperText,
      helperStyle: TextStyle(
        color: Colors.blue[600],
        fontWeight: FontWeight.bold,
      ),
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
    );
  }
}
