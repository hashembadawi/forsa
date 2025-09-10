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
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showProgress) const CircularProgressIndicator(),
            if (showProgress) const SizedBox(height: 16),
            Text(
              message,
              style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
