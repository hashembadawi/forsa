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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          basicInfo,
          const Divider(height: 10, thickness: 1, color: Colors.grey),
          categoryInfo,
          if (!hideTypeAndDelivery) ...[
            const SizedBox(height: 3),
            typeInfoRow,
            const SizedBox(height: 3),
            deliveryInfoRow,
          ],
          const Divider(height: 10, thickness: 1, color: Colors.grey),
          advertiserInfo,
        ],
      ),
    );
  }
}
