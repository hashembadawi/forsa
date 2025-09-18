import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MenuItemsWid extends StatelessWidget {
  final VoidCallback onAdTerms;
  final VoidCallback onFAQ;
  final VoidCallback onContactUs;

  const MenuItemsWid({
    super.key,
    required this.onAdTerms,
    required this.onFAQ,
    required this.onContactUs,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFF5F5F5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.article, color: Color(0xFF7C4DFF)),
              title: Text('شروط الإعلان', style: GoogleFonts.cairo(fontWeight: FontWeight.w600, fontSize: 16, color: Color(0xFF212121))),
              trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Color(0xFF7C4DFF)),
              onTap: onAdTerms,
            ),
            Divider(height: 1, color: Color(0xFF7C4DFF).withOpacity(0.4)),
            ListTile(
              leading: const Icon(Icons.help, color: Color(0xFF7C4DFF)),
              title: Text('الأسئلة الشائعة', style: GoogleFonts.cairo(fontWeight: FontWeight.w600, fontSize: 16, color: Color(0xFF212121))),
              trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Color(0xFF7C4DFF)),
              onTap: onFAQ,
            ),
            Divider(height: 1, color: Color(0xFF7C4DFF).withOpacity(0.4)),
            ListTile(
              leading: const Icon(Icons.call, color: Color(0xFF7C4DFF)),
              title: Text('اتصل بنا', style: GoogleFonts.cairo(fontWeight: FontWeight.w600, fontSize: 16, color: Color(0xFF212121))),
              trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Color(0xFF7C4DFF)),
              onTap: onContactUs,
            ),
          ],
        ),
      ),
    );
  }
}
