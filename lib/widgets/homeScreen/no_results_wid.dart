import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NoResultsWid extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const NoResultsWid({
    Key? key,
    this.title = 'لا يوجد نتائج',
    this.subtitle = 'لم يتم العثور على أي إعلانات',
    this.icon = Icons.search_off,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const Color accentColor = Color(0xFFFF7043); // Soft Orange
    const Color surfaceColor = Color(0xFFF5F5F5); // Light Gray
    const Color textColor = Color(0xFF212121); // Dark Black
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Material(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(20),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 64,
                  color: accentColor.withOpacity(0.7),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: textColor.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
