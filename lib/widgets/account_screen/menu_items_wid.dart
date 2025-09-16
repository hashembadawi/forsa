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
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.article, color: Colors.blue),
            title: Text('شروط الإعلان', style: GoogleFonts.cairo()),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: onAdTerms,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.help, color: Colors.blue),
            title: Text('الأسئلة الشائعة', style: GoogleFonts.cairo()),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: onFAQ,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.call, color: Colors.blue),
            title: Text('اتصل بنا', style: GoogleFonts.cairo()),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: onContactUs,
          ),
        ],
      ),
    );
  }
}
