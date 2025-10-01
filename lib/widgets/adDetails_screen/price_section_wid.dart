import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PriceSectionWid extends StatelessWidget {
  final String price;
  final String currencyName;
  const PriceSectionWid({Key? key, required this.price, required this.currencyName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            '$price $currencyName',
            style: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
