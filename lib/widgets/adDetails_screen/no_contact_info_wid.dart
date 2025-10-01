import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NoContactInfoWid extends StatelessWidget {
  const NoContactInfoWid({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Center(
        child: Text(
          'معلومات الاتصال غير متوفرة',
          style: GoogleFonts.cairo(
            color: Colors.orange,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
