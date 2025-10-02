import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DescriptionTabWid extends StatelessWidget {
  final String description;

  const DescriptionTabWid({super.key, required this.description});

  @override
  Widget build(BuildContext context) {
    if (description.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.description_outlined, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'لا يوجد وصف متاح لهذا الإعلان',
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Text(
        description,
        style: GoogleFonts.cairo(
          fontSize: 14,
          color: Colors.black87,
          height: 1.5,
        ),
        textAlign: TextAlign.justify,
      ),
    );
  }
}
