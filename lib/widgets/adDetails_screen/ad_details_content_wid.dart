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
  // Removed horizontalPad and verticalPad as they are no longer used
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 4, 6, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Remove box: just show title, divider, and price
          adTitle,
          Divider(
            color: Colors.grey.withOpacity(0.18),
            thickness: 1,
            height: 4,
            endIndent: 0,
            indent: 0,
          ),
          priceSection,
          const SizedBox(height: 8.5),
          tabSection,
          const SizedBox(height: 8.5),
          actionButtons,
        ],
      ),
    );
  }
}
