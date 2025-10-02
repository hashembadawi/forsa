import 'package:flutter/material.dart';

class BasicInfoWid extends StatelessWidget {
  final Widget locationRow;
  final Widget dateRow;

  const BasicInfoWid({
    super.key,
    required this.locationRow,
    required this.dateRow,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          locationRow,
          const SizedBox(height: 3),
          dateRow,
        ],
      ),
    );
  }
}
