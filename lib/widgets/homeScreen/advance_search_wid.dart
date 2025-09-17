import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdvanceSearchWid extends StatelessWidget {
  final VoidCallback? onTap;
  const AdvanceSearchWid({Key? key, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const Color accentColor = Color(0xFFFF7043); // Soft Orange
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
                Icon(Icons.tune, color: accentColor, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'بحث متقدم',
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
