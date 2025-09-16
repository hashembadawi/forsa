import 'package:flutter/material.dart';

class ImageIndicatorWid extends StatelessWidget {
  final int imageCount;

  const ImageIndicatorWid({
    Key? key,
    required this.imageCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        imageCount,
        (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ),
    );
  }
}
