import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'image_indicator_wid.dart';

class ImageSectionWid extends StatelessWidget {
  final List<String> allImages;
  final double imageHeight;
  final PageController? imagePageController;
  final Uint8List? Function(String?) getDecodedImage;
  final void Function(List<String>, int) onImageTap;
  final Widget favoriteButton;

  const ImageSectionWid({
    Key? key,
    required this.allImages,
    required this.imageHeight,
    required this.imagePageController,
    required this.getDecodedImage,
    required this.onImageTap,
    required this.favoriteButton,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (allImages.isEmpty) {
          return SizedBox(
            width: width,
            height: imageHeight,
            child: Stack(
              children: [
                Container(
                  width: width,
                  height: imageHeight,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_not_supported, size: 60, color: colorScheme.outline),
                        SizedBox(height: 8),
                        Text('لا توجد صور متاحة', style: GoogleFonts.cairo(color: colorScheme.outline)),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: favoriteButton,
                ),
              ],
            ),
          );
        }
        return SizedBox(
          width: width,
          height: imageHeight,
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: PageView.builder(
                  controller: imagePageController,
                  itemCount: allImages.length,
                  itemBuilder: (context, index) {
                    final imgBase64 = allImages[index];
                    final decodedImage = getDecodedImage(imgBase64);
                    return GestureDetector(
                      onTap: () => onImageTap(allImages, index),
                      child: decodedImage != null
                          ? Image.memory(
                              decodedImage,
                              fit: BoxFit.cover,
                              width: width,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: width,
                                height: imageHeight,
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceVariant,
                                ),
                                child: Center(
                                  child: Icon(Icons.broken_image, size: 60, color: colorScheme.outline),
                                ),
                              ),
                            )
                          : Container(
                              width: width,
                              height: imageHeight,
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceVariant,
                              ),
                              child: Center(
                                child: Icon(Icons.broken_image, size: 60, color: colorScheme.outline),
                              ),
                            ),
                    );
                  },
                ),
              ),
              if (allImages.length > 1)
                Positioned(
                  bottom: 10,
                  left: 0,
                  right: 0,
                  child: ImageIndicatorWid(imageCount: allImages.length),
                ),
              Positioned(
                top: 10,
                left: 10,
                child: favoriteButton,
              ),
            ],
          ),
        );
      },
    );
  }
}
