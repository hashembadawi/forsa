import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A screen for previewing images with navigation and zoom capabilities
class ImagePreviewScreen extends StatefulWidget {
  /// List of base64 encoded images to display
  final List<dynamic> images;
  
  /// Initial index to start viewing from
  final int initialIndex;

  const ImagePreviewScreen({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  @override
  State<ImagePreviewScreen> createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends State<ImagePreviewScreen> {
  // ========== Constants ==========
  static const Duration _animationDuration = Duration(milliseconds: 300);
  static const Curve _animationCurve = Curves.easeInOut;
  static const double _minScale = 0.5;
  static const double _maxScale = 4.0;
  
  // ========== Controllers & State ==========
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ========== Initialization ==========

  /// Initialize page controller with initial index
  void _initializeController() {
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  // ========== Navigation Methods ==========

  /// Navigate to previous image
  void _navigateToPrevious() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: _animationDuration,
        curve: _animationCurve,
      );
    }
  }

  /// Navigate to next image
  void _navigateToNext() {
    if (_currentIndex < widget.images.length - 1) {
      _pageController.nextPage(
        duration: _animationDuration,
        curve: _animationCurve,
      );
    }
  }

  /// Update current index when page changes
  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
  }

  // ========== Helper Methods ==========

  /// Check if previous navigation is available
  bool get _canNavigatePrevious => _currentIndex > 0;

  /// Check if next navigation is available
  bool get _canNavigateNext => _currentIndex < widget.images.length - 1;

  /// Check if multiple images exist
  bool get _hasMultipleImages => widget.images.length > 1;

  // ========== Widget Building Methods ==========

  /// Build the main app bar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.blue[700],
      foregroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Text(
        'معاينة الصور',
        style: GoogleFonts.cairo(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
      ),
      centerTitle: true,
      actions: [
        _buildBackButton(),
      ],
    );
  }

  /// Build back button with styling
  Widget _buildBackButton() {
    return IconButton(
      icon: const Icon(Icons.arrow_forward, color: Colors.white),
      onPressed: () => Navigator.pop(context),
    );
  }

  /// Build main body container with gradient background
  Widget _buildBody() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Expanded(child: _buildImageViewer()),
          if (_hasMultipleImages) ...[
            _buildNavigationSection(),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  /// Build main image viewer container
  Widget _buildImageViewer() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: _buildImageViewerDecoration(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: _buildPageView(),
      ),
    );
  }

  /// Build image viewer decoration
  BoxDecoration _buildImageViewerDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.blue[300]!, width: 2),
      boxShadow: [
        BoxShadow(
          color: Colors.blue[200]!.withOpacity(0.3),
          blurRadius: 15,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  /// Build page view for images
  Widget _buildPageView() {
    return PageView.builder(
      controller: _pageController,
      itemCount: widget.images.length,
      onPageChanged: _onPageChanged,
      itemBuilder: _buildImagePage,
    );
  }

  /// Build individual image page
  Widget _buildImagePage(BuildContext context, int index) {
    return Container(
      color: Colors.white,
      child: InteractiveViewer(
        panEnabled: true,
        minScale: _minScale,
        maxScale: _maxScale,
        child: Center(
          child: _buildImage(index),
        ),
      ),
    );
  }

  /// Build image widget with error handling
  Widget _buildImage(int index) {
    return Image.memory(
      base64Decode(widget.images[index]),
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => _buildErrorPlaceholder(),
    );
  }

  /// Build error placeholder for failed image loads
  Widget _buildErrorPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF0F8FF), Color(0xFFE6F3FF)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, size: 64, color: Colors.blue[400]),
            const SizedBox(height: 16),
            Text(
              'تعذر تحميل الصورة',
              style: GoogleFonts.cairo(
                color: Colors.blue[700],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build navigation section container
  Widget _buildNavigationSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: _buildNavigationDecoration(),
      child: _buildNavigationRow(),
    );
  }

  /// Build navigation section decoration
  BoxDecoration _buildNavigationDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.blue[300]!, width: 1.5),
      boxShadow: [
        BoxShadow(
          color: Colors.blue[100]!.withOpacity(0.3),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// Build navigation row with buttons and indicators
  Widget _buildNavigationRow() {
    return Column(
      children: [
        // Dot indicators row
        _buildDotIndicators(),
        const SizedBox(height: 16),
        // Navigation buttons row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Flexible(
              child: _buildNavigationButton(
                text: 'السابقة',
                icon: Icons.arrow_back_ios,
                isEnabled: _canNavigatePrevious,
                onTap: _navigateToPrevious,
                isLeftButton: true,
              ),
            ),
            const SizedBox(width: 16),
            Flexible(
              child: _buildNavigationButton(
                text: 'التالية',
                icon: Icons.arrow_forward_ios,
                isEnabled: _canNavigateNext,
                onTap: _navigateToNext,
                isLeftButton: false,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build navigation button (previous/next)
  Widget _buildNavigationButton({
    required String text,
    required IconData icon,
    required bool isEnabled,
    required VoidCallback onTap,
    required bool isLeftButton,
  }) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        constraints: const BoxConstraints(
          minWidth: 80,
          maxWidth: 120,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: _buildButtonDecoration(isEnabled),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: isLeftButton
              ? [
                  Icon(icon, color: _getButtonColor(isEnabled), size: 14),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      text,
                      style: _getButtonTextStyle(isEnabled),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]
              : [
                  Flexible(
                    child: Text(
                      text,
                      style: _getButtonTextStyle(isEnabled),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(icon, color: _getButtonColor(isEnabled), size: 14),
                ],
        ),
      ),
    );
  }

  /// Build button decoration based on enabled state
  BoxDecoration _buildButtonDecoration(bool isEnabled) {
    return BoxDecoration(
      color: isEnabled ? Colors.blue[600] : Colors.grey[300],
      borderRadius: BorderRadius.circular(12),
      boxShadow: isEnabled
          ? [
              BoxShadow(
                color: Colors.blue[300]!.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ]
          : null,
    );
  }

  /// Get button color based on enabled state
  Color _getButtonColor(bool isEnabled) {
    return isEnabled ? Colors.white : Colors.grey[600]!;
  }

  /// Get button text style based on enabled state
  TextStyle _getButtonTextStyle(bool isEnabled) {
    return GoogleFonts.cairo(
      color: _getButtonColor(isEnabled),
      fontSize: 12,
      fontWeight: FontWeight.bold,
    );
  }

  /// Build dot indicators for image navigation
  Widget _buildDotIndicators() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 12,
      child: widget.images.length <= 10
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.images.length,
                (index) => _buildDotIndicator(index),
              ),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(
                  widget.images.length,
                  (index) => _buildDotIndicator(index),
                ),
              ),
            ),
    );
  }

  /// Build individual dot indicator
  Widget _buildDotIndicator(int index) {
    final isActive = _currentIndex == index;
    
    return AnimatedContainer(
      duration: _animationDuration,
      width: isActive ? 32 : 12,
      height: 12,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: isActive ? Colors.blue[600] : Colors.blue[200],
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: Colors.blue[300]!.withOpacity(0.4),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: isActive ? _buildActiveDotContent() : null,
    );
  }

  /// Build content for active dot indicator
  Widget _buildActiveDotContent() {
    return const Center(
      child: SizedBox(
        width: 6,
        height: 6,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  // ========== Main Build Method ==========

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }
}
