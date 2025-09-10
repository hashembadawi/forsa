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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
