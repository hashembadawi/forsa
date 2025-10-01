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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          adTitle,
          const SizedBox(height: 16),
          priceSection,
          const SizedBox(height: 20),
          tabSection,
          const SizedBox(height: 20),
          actionButtons,
        ],
      ),
    );
  }
}
