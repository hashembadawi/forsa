import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/ad_terms_screen.dart';
import '../screens/FAQ_screen.dart';
import '../screens/contact_us_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
  const Color mainColor = Color(0xFF009688);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('حول التطبيق', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 25, color: Color(0xFF212121))),
          backgroundColor: mainColor,
          foregroundColor: Color(0xFF212121),
          elevation: 4,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
        ),
        backgroundColor: Colors.white,
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _AboutButton(
                icon: Icons.rule,
                label: 'شروط الاعلان',
                color: mainColor,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdTermsScreen()),
                ),
              ),
              const SizedBox(height: 10),
              _AboutButton(
                icon: Icons.help_outline,
                label: 'الاسئلة الشائعة',
                color: mainColor,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FAQScreen()),
                ),
              ),
              const SizedBox(height: 10),
              _AboutButton(
                icon: Icons.phone_in_talk,
                label: 'اتصل بنا',
                color: mainColor,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ContactUsScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AboutButton extends StatelessWidget {
  static const Color surfaceColor = Color(0xFFF5F5F5);
  static const Color accentColor = Color.fromARGB(255, 0, 0, 0); // Like location search
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AboutButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const Color headerColor = Color(0xFF009688);
    return Material(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: headerColor.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(10),
                child: Icon(icon, color: headerColor, size: 28),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.cairo(
                    color: accentColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: accentColor, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
