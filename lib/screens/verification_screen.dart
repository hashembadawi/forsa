import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'login_screen.dart';
import 'package:syria_market/utils/dialog_utils.dart';

class VerificationScreen extends StatefulWidget {
  final String phoneNumber;
  const VerificationScreen({super.key, required this.phoneNumber});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  /// Validate verification form
  bool _validateForm() {
    if (_codeController.text.trim().isEmpty) {
      DialogUtils.showErrorDialog(
        context: context,
        message: 'يرجى إدخال رمز التحقق',
      );
      return false;
    }
    return true;
  }

  Future<void> verifyCode() async {
    if (!_validateForm()) return;

    // Show loading dialog
    DialogUtils.showLoadingDialog(
      context: context,
      title: 'جارٍ التحقق...',
      message: 'يرجى الانتظار',
    );

    try {
      print ('Verifying code for phone: ${widget.phoneNumber}');
      final response = await http.post(
        Uri.parse('https://sahbo-app-api.onrender.com/api/user/verify-phone'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phoneNumber': widget.phoneNumber,
          'verificationCode': _codeController.text.trim(),
        }),
      );
      
      final res = jsonDecode(response.body);

      // Close loading dialog
      DialogUtils.closeDialog(context);

      if (response.statusCode == 200) {
        DialogUtils.showSuccessDialog(
          context: context,
          message: 'تم التحقق بنجاح! يمكنك الآن تسجيل الدخول',
          onPressed: () {
            Navigator.of(context).pop(); // Close dialog
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          },
        );
      } else {
        DialogUtils.showErrorDialog(
          context: context,
          message: res['message'] ?? 'رمز التحقق غير صحيح',
        );
      }
    } catch (e) {
      // Close loading dialog
      DialogUtils.closeDialog(context);
      DialogUtils.showErrorDialog(
        context: context,
        message: 'حدث خطأ في الاتصال بالخادم',
      );
    }
  }

  // ========== Widget Building Methods ==========

  /// Build main app bar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('تأكيد رقم الهاتف'),
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
            _buildVerificationForm(),
            const SizedBox(height: 24),
            _buildInfoSection(),
          ],
        ),
      ),
    );
  }

  /// Build verification form container
  Widget _buildVerificationForm() {
    return Container(
      decoration: _buildFormDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildPhoneNumberDisplay(),
            const SizedBox(height: 16),
            _buildInstructionText(),
            const SizedBox(height: 20),
            _buildCodeField(),
            const SizedBox(height: 20),
            _buildVerifyButton(),
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

  /// Build phone number display
  Widget _buildPhoneNumberDisplay() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.phone, color: Colors.blue[600], size: 20),
          const SizedBox(width: 8),
          Text(
            'رقم الهاتف: ${widget.phoneNumber}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
        ],
      ),
    );
  }

  /// Build instruction text
  Widget _buildInstructionText() {
    return Text(
      'أدخل رمز التحقق المرسل إلى واتساب',
      style: TextStyle(
        fontSize: 16,
        color: Colors.grey[700],
        fontWeight: FontWeight.w500,
      ),
      textAlign: TextAlign.center,
    );
  }

  /// Build verification code field
  Widget _buildCodeField() {
    return TextField(
      controller: _codeController,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      onSubmitted: (_) => verifyCode(),
      decoration: _buildInputDecoration(
        labelText: 'رمز التحقق',
        prefixIcon: Icons.verified_user,
        helperText: 'أدخل الرمز المكون من 6 أرقام',
      ),
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: 2,
      ),
    );
  }

  /// Build input field decoration
  InputDecoration _buildInputDecoration({
    required String labelText,
    required IconData prefixIcon,
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
      helperText: helperText,
      helperStyle: TextStyle(
        color: Colors.blue[600],
        fontWeight: FontWeight.bold,
      ),
    );
  }

  /// Build verify button
  Widget _buildVerifyButton() {
    return ElevatedButton(
      onPressed: verifyCode,
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
        'تأكيد رمز التحقق',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  /// Build info section
  Widget _buildInfoSection() {
    return Container(
      decoration: _buildInfoDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildInfoIcon(),
            const SizedBox(height: 12),
            _buildInfoTitle(),
            const SizedBox(height: 8),
            _buildInfoSubtitle(),
          ],
        ),
      ),
    );
  }

  /// Build info section decoration
  BoxDecoration _buildInfoDecoration() {
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

  /// Build info icon
  Widget _buildInfoIcon() {
    return Icon(
      Icons.info_outline,
      size: 32,
      color: Colors.blue[600],
    );
  }

  /// Build info title
  Widget _buildInfoTitle() {
    return const Text(
      'معلومة مهمة',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  /// Build info subtitle
  Widget _buildInfoSubtitle() {
    return Text(
      'بعد التحقق بنجاح سيتم توجيهك لتسجيل الدخول',
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey[600],
      ),
      textAlign: TextAlign.center,
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