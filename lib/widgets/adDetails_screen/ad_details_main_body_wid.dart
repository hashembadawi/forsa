import 'package:flutter/material.dart';

class AdDetailsMainBodyWid extends StatelessWidget {
  final Widget currentAdSection;
  final Widget actionButtonsSection;
  final Widget similarAdsSection;

  const AdDetailsMainBodyWid({
    super.key,
    required this.currentAdSection,
    required this.actionButtonsSection,
    required this.similarAdsSection,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[50],
      child: ListView(
        children: [
          currentAdSection,
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            height: 8,
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          actionButtonsSection,
          const SizedBox(height: 16),
          similarAdsSection,
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
