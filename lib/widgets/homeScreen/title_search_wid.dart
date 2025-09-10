import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TitleSearchWid extends StatelessWidget {
  final String initialText;
  final VoidCallback? onTap;
  const TitleSearchWid({Key? key, this.initialText = '', this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.blue[300]!, width: 1.5),
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: Colors.blue[600], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  initialText.isNotEmpty
                      ? initialText
                      : 'ابحث عن منتج أو خدمة...',
                  style: GoogleFonts.cairo(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
