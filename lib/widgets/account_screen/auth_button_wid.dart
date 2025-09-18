import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthButtonWid extends StatelessWidget {
  final bool isLoggedIn;
  final VoidCallback onPressed;

  const AuthButtonWid({
    super.key,
    required this.isLoggedIn,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final Color buttonColor = isLoggedIn ? const Color(0xFFFF7043) : const Color(0xFF42A5F5); // Soft Orange or Light Blue
    final Color foregroundColor = Colors.white;
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: foregroundColor,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 2,
          textStyle: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        onPressed: onPressed,
        child: Text(
          isLoggedIn ? 'تسجيل الخروج' : 'تسجيل الدخول',
        ),
      ),
    );
  }
}
