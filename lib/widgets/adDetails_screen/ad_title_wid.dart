import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdTitleWid extends StatelessWidget {
  final String title;
  const AdTitleWid({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text(
        title,
        style: GoogleFonts.cairo(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: colorScheme.primary,
          letterSpacing: 0.2,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
