import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TitleSearchWid extends StatelessWidget {
  final String initialText;
  final VoidCallback? onTap;
  const TitleSearchWid({Key? key, this.initialText = '', this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const Color secondaryColor = Color(0xFF42A5F5); // Light Blue
    const Color surfaceColor = Color(0xFFF5F5F5); // Light Gray
    const Color textColor = Color(0xFF212121); // Dark Black
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Material(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                Icon(Icons.search, color: secondaryColor, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    initialText.isNotEmpty
                        ? initialText
                        : 'ابحث عن منتج أو خدمة...',
                    style: GoogleFonts.cairo(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
