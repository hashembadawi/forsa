import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NoLocationAvailableWid extends StatelessWidget {
  const NoLocationAvailableWid({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.location_off_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              'لا يوجد موقع محدد لهذا الإعلان',
              style: GoogleFonts.cairo(
                color: Colors.grey,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
