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
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0.5,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Column(
          children: [
            locationRow,
            const SizedBox(height: 12),
            dateRow,
          ],
        ),
      ),
    );
  }
}
