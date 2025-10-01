import 'package:flutter/material.dart';

class AdInfoTabWid extends StatelessWidget {
  final bool hideTypeAndDelivery;
  final Widget basicInfo;
  final Widget advertiserInfo;
  final Widget categoryInfo;
  final Widget typeInfoRow;
  final Widget deliveryInfoRow;

  const AdInfoTabWid({
    super.key,
    required this.hideTypeAndDelivery,
    required this.basicInfo,
    required this.advertiserInfo,
    required this.categoryInfo,
    required this.typeInfoRow,
    required this.deliveryInfoRow,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 1.5,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: colorScheme.surfaceVariant.withOpacity(0.7),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            basicInfo,
            const Divider(height: 32, thickness: 1, color: Colors.grey),
            advertiserInfo,
            const Divider(height: 32, thickness: 1, color: Colors.grey),
            categoryInfo,
            if (!hideTypeAndDelivery) ...[
              const SizedBox(height: 8),
              typeInfoRow,
              const SizedBox(height: 8),
              deliveryInfoRow,
            ],
          ],
        ),
      ),
    );
  }
}
