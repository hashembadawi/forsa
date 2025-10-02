import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InfoRowWid extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? phoneText;

  const InfoRowWid({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.phoneText,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.blue[600]),
        const SizedBox(width: 8),
        Expanded(
          child: phoneText != null
              ? phoneText!
              : RichText(
                  text: TextSpan(
                    style: GoogleFonts.cairo(fontSize: 14, color: Colors.black87),
                    children: [
                      TextSpan(
                        text: '$label: ',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: value,
                        style: GoogleFonts.cairo(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
