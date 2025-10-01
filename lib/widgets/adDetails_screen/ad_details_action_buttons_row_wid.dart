import 'package:flutter/material.dart';

class AdDetailsActionButtonsRowWid extends StatelessWidget {
  final Widget whatsappButton;
  final Widget callButton;

  const AdDetailsActionButtonsRowWid({
    super.key,
    required this.whatsappButton,
    required this.callButton,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(child: whatsappButton),
        const SizedBox(width: 16),
        Expanded(child: callButton),
      ],
    );
  }
}
