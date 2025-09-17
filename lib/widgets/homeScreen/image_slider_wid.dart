import 'dart:async';
import 'package:flutter/material.dart';

class ImageSliderWid extends StatefulWidget {
  const ImageSliderWid({super.key});

  @override
  State<ImageSliderWid> createState() => _ImageSliderWidState();
}

class _ImageSliderWidState extends State<ImageSliderWid> {
  static const List<String> _imagePaths = [
    'assets/image1.jpg',
    'assets/image2.jpg',
    'assets/image3.jpg',
    'assets/image4.jpg',
  ];

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
      if (_pageController.hasClients) {
        final nextPage = (_currentImageIndex + 1) % _imagePaths.length;
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
                itemCount: _imagePaths.length,
                onPageChanged: (index) => setState(() => _currentImageIndex = index),
                itemBuilder: (context, index) => ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    _imagePaths[index],
                    fit: BoxFit.cover,
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
                    _imagePaths.length,
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
