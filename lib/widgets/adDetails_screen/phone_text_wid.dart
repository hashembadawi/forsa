import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PhoneTextWid extends StatelessWidget {
  final String value;
  const PhoneTextWid({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    final formattedPhone = value.startsWith('+') ? value : '+$value';
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Text(
        formattedPhone,
        style: GoogleFonts.cairo(
          fontWeight: FontWeight.w500,
          fontSize: 14,
          color: Colors.black87,
        ),
      ),
    );
  }
}
