import 'package:flutter/material.dart';

class AdDetailsContentWid extends StatelessWidget {
  final Widget adTitle;
  final Widget priceSection;
  final Widget tabSection;
  final Widget actionButtons;

  const AdDetailsContentWid({
    super.key,
    required this.adTitle,
    required this.priceSection,
    required this.tabSection,
    required this.actionButtons,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPad = screenWidth * 0.015; // much smaller
    final verticalPad = screenWidth * 0.008; // much smaller
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 4, 6, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.07),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.symmetric(horizontal: horizontalPad, vertical: verticalPad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                adTitle,
                Divider(
                  color: colorScheme.primary.withOpacity(0.18),
                  thickness: 1,
                  height: 4,
                  endIndent: 0,
                  indent: 0,
                ),
                priceSection,
              ],
            ),
          ),
          const SizedBox(height: 6),
          tabSection,
          const SizedBox(height: 8),
          actionButtons,
        ],
      ),
    );
  }
}
