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
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isLoggedIn ? Colors.orange : Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onPressed: onPressed,
        child: Text(
          isLoggedIn ? 'تسجيل الخروج' : 'تسجيل الدخول',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
