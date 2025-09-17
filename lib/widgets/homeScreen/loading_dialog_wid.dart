import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoadingDialogWid extends StatelessWidget {
  final String message;
  final bool showProgress;

  const LoadingDialogWid({
    Key? key,
    this.message = 'جاري التحميل...',
    this.showProgress = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const Color accentColor = Color(0xFFFF7043); // Soft Orange
    const Color surfaceColor = Color(0xFFF5F5F5); // Light Gray
    const Color textColor = Color(0xFF212121); // Dark Black
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showProgress) const CircularProgressIndicator(color: accentColor),
            if (showProgress) const SizedBox(height: 18),
            Text(
              message,
              style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
