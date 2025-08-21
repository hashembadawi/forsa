import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'login_screen.dart';
import 'package:syria_market/utils/dialog_utils.dart';
import 'package:google_fonts/google_fonts.dart';

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
    String code = _codeController.text.trim();
    if (code.isEmpty) {
      DialogUtils.showErrorDialog(
        context: context,
        message: 'يرجى إدخال رمز التحقق',
      );
      return false;
    }
    if (code.length != 4) {
      DialogUtils.showErrorDialog(
        context: context,
        message: 'يرجى إدخال رمز التحقق المكون من 4 أرقام',
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
      title: Text(
        'تأكيد رقم الهاتف',
        style: GoogleFonts.cairo(fontWeight: FontWeight.bold , fontSize: 22, color: Colors.white),
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: Colors.white,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          children: [
            _buildVerificationContainer(),
          ],
        ),
      ),
    );
  }

  /// Build the main verification container
  Widget _buildVerificationContainer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Section
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.blue[600],
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.verified_user,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                'أدخل رمز التحقق المرسل إلى واتساب',
                style: GoogleFonts.cairo(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        // Verification Content
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPhoneNumberDisplay(),
                const SizedBox(height: 20),
                _buildCodeField(),
                const SizedBox(height: 20),
                _buildVerifyButton(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Build phone number display
  Widget _buildPhoneNumberDisplay() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          'رقم الهاتف: ${widget.phoneNumber}',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  /// Build verification code field
  Widget _buildCodeField() {
    return Container(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'رمز التحقق',
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 4,
              onSubmitted: (_) => verifyCode(),
              decoration: InputDecoration(
                hintText: 'أدخل رمز التحقق (4 أرقام)',
                hintStyle: GoogleFonts.cairo(
                  color: Colors.grey[500],
                  fontSize: 14,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.blue[200]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.blue[200]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                counterText: '', // Hide the character counter
              ),
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build verify button
  Widget _buildVerifyButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[600]!, Colors.blue[700]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blue[300]!.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: verifyCode,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.verified_user,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'تأكيد رمز التحقق',
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
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