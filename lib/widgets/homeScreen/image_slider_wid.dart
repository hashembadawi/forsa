import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';

class ImageSliderWid extends StatefulWidget {
  final List<String> imageContents;
  const ImageSliderWid({super.key, required this.imageContents});

  @override
  State<ImageSliderWid> createState() => _ImageSliderWidState();
}

class _ImageSliderWidState extends State<ImageSliderWid> {
  int _currentImageIndex = 0;
  late PageController _pageController;
  Timer? _sliderTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
    _startAutoSlide();
  }

  @override
  void dispose() {
    _sliderTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoSlide() {
    _sliderTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_pageController.hasClients && widget.imageContents.isNotEmpty) {
        final nextPage = (_currentImageIndex + 1) % widget.imageContents.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color secondaryColor = Color(0xFF42A5F5); // Light Blue
    const Color surfaceColor = Color(0xFFF5F5F5); // Light Gray
    const Color textColor = Color(0xFF212121); // Dark Black
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Material(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        child: Container(
          height: 140,
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: widget.imageContents.length,
                onPageChanged: (index) => setState(() => _currentImageIndex = index),
                itemBuilder: (context, index) => ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: widget.imageContents[index].isNotEmpty
                      ? Image.memory(
                          base64Decode(widget.imageContents[index]),
                          fit: BoxFit.fill,
                          gaplessPlayback: true,
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: const Center(child: Icon(Icons.broken_image)),
                        ),
                ),
              ),
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.imageContents.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: _currentImageIndex == index ? 20 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: _currentImageIndex == index
                            ? secondaryColor
                            : textColor.withOpacity(0.2),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}