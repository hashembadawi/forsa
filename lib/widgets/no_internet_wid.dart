import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Material 3 color palette (same as home_screen.dart)
const Color kSecondaryColor = Color(0xFF42A5F5); // Light Blue
const Color kTextColor = Color(0xFF212121); // Dark Black
const Color kAccentColor = Color(0xFFFF7043); // Soft Orange
const Color kBackgroundColor = Color(0xFFFAFAFA); // White

class NoInternetWid extends StatelessWidget {
  final VoidCallback onRetry;
  const NoInternetWid({Key? key, required this.onRetry}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off, size: 100, color: kSecondaryColor),
              const SizedBox(height: 20),
              Text(
                'لا يوجد اتصال بالإنترنت',
                style: GoogleFonts.cairo(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: kTextColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى',
                style: GoogleFonts.cairo(fontSize: 16, color: kTextColor.withOpacity(0.7)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kSecondaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                    textStyle: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold),
                  ).copyWith(
                    overlayColor: MaterialStateProperty.all(kAccentColor.withOpacity(0.12)),
                  ),
                  child: Text('إعادة المحاولة'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
