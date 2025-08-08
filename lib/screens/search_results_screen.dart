import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:syria_market/screens/ad_details_screen.dart';
import 'package:google_fonts/google_fonts.dart';

/// Screen displaying search results for advertisements
class SearchResultsScreen extends StatefulWidget {
  final String searchText;
  
  const SearchResultsScreen({
    super.key,
    required this.searchText,
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  // ========== Constants ==========
  static const String _baseApiUrl = 'sahbo-app-api.onrender.com';
  static const String _searchEndpoint = '/api/ads/search-by-title';
  static const int _defaultPage = 1;
  static const int _defaultLimit = 20;
  static const double _cardBorderRadius = 18.0;
  static const double _gridSpacing = 12.0;
  static const double _cardAspectRatio = 0.65;
  static const int _tabletCrossAxisCount = 3;
  static const int _mobileCrossAxisCount = 2;
  static const int _tabletBreakpoint = 600;

  // ========== State Variables ==========
  List<dynamic> _searchResults = [];
  bool _isLoading = true;
  String? _errorMessage;

  // ========== Color Scheme ==========
  static const Color _aliceBlue = Color(0xFFF0F8FF);
  static const Color _lightBlue = Color(0xFFE6F3FF);

  @override
  void initState() {
    super.initState();
    _fetchSearchResults();
  }

  // ========== Search API Methods ==========

  /// Fetch search results from the API
  Future<void> _fetchSearchResults() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _performSearchRequest();
      await _handleSearchResponse(response);
    } catch (e) {
      debugPrint('Search error: $e');
      _handleSearchError(e);
    }
  }

  /// Perform the HTTP search request
  Future<http.Response> _performSearchRequest() async {
    final params = _buildSearchParameters();
    final uri = Uri.https(_baseApiUrl, _searchEndpoint, params);
    return await http.get(uri);
  }

  /// Build search parameters for the API request
  Map<String, String> _buildSearchParameters() {
    return {
      'title': widget.searchText,
      'page': _defaultPage.toString(),
      'limit': _defaultLimit.toString(),
    };
  }

  /// Handle the search API response
  Future<void> _handleSearchResponse(http.Response response) async {
    if (!mounted) return;

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final ads = decoded['ads'];
      
      setState(() {
        _searchResults = ads is List ? ads : [];
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = 'فشل في تحميل النتائج. رمز الخطأ: ${response.statusCode}';
        _isLoading = false;
      });
    }
  }

  /// Handle search errors
  void _handleSearchError(dynamic error) {
    if (!mounted) return;

    setState(() {
      _errorMessage = 'حدث خطأ في الاتصال بالخادم';
      _isLoading = false;
    });
  }

  // ========== Ad Card Widget Methods ==========

  /// Build individual advertisement card
  Widget _buildAdCard(dynamic ad) {
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: _buildCardDecoration(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(_cardBorderRadius),
          splashColor: Colors.blue[300]!.withOpacity(0.2),
          highlightColor: Colors.blue[100]!.withOpacity(0.1),
          onTap: () => _navigateToAdDetails(ad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAdImage(ad),
              _buildAdContent(ad),
            ],
          ),
        ),
      ),
    );
  }

  /// Build card decoration with gradient and border
  BoxDecoration _buildCardDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(_cardBorderRadius),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_aliceBlue, _lightBlue],
      ),
      border: Border.all(
        color: Colors.blue[300]!,
        width: 1.5,
      ),
    );
  }

  /// Build advertisement image section
  Widget _buildAdImage(dynamic ad) {
    return Expanded(
      flex: 3,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(_cardBorderRadius),
        ),
        child: SizedBox(
          width: double.infinity,
          child: _buildImageWidget(ad),
        ),
      ),
    );
  }

  /// Build image widget with error handling
  Widget _buildImageWidget(dynamic ad) {
    final images = _extractImages(ad);
    final firstImageBase64 = images.isNotEmpty ? images.first : null;

    if (firstImageBase64 != null) {
      return _buildDecodedImage(firstImageBase64);
    } else {
      return _buildPlaceholderImage(false);
    }
  }

  /// Extract images from ad data
  List<dynamic> _extractImages(dynamic ad) {
    final images = ad['images'];
    return images is List ? images : [];
  }

  /// Build decoded base64 image with error handling
  Widget _buildDecodedImage(String base64String) {
    return Image.memory(
      base64Decode(base64String),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Image decode error: $error');
        return _buildPlaceholderImage(true);
      },
    );
  }

  /// Build placeholder image when no image is available or error occurs
  Widget _buildPlaceholderImage(bool isError) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_aliceBlue, _lightBlue],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image,
              size: 40,
              color: Colors.blue[400],
            ),
            const SizedBox(height: 4),
            Text(
              isError ? 'صورة' : 'لا توجد صورة',
              style: GoogleFonts.cairo(
                color: Colors.blue[700],
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build advertisement content section
  Widget _buildAdContent(dynamic ad) {
    return Expanded(
      flex: 2,
      child: Container(
        constraints: const BoxConstraints(minHeight: 80),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildAdTitle(ad),
              _buildAdPrice(ad),
              _buildAdDescription(ad),
              _buildAdLocation(ad),
            ],
          ),
        ),
      ),
    );
  }

  /// Build advertisement title
  Widget _buildAdTitle(dynamic ad) {
    return Text(
      ad['adTitle']?.toString() ?? '',
      style: GoogleFonts.cairo(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }

  /// Build advertisement price with styling
  Widget _buildAdPrice(dynamic ad) {
    final price = ad['price']?.toString() ?? '0';
    final currency = ad['currencyName']?.toString() ?? '';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue[200]!,
          width: 1,
        ),
      ),
      child: Text(
        '$price $currency',
        style: GoogleFonts.cairo(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.blue[700],
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }

  /// Build advertisement description
  Widget _buildAdDescription(dynamic ad) {
    return Text(
      ad['description']?.toString() ?? '',
      style: GoogleFonts.cairo(
        fontSize: 10,
        color: Colors.black87,
        fontWeight: FontWeight.w500,
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }

  /// Build advertisement location
  Widget _buildAdLocation(dynamic ad) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.location_on,
          size: 12,
          color: Colors.blue[600],
        ),
        const SizedBox(width: 2),
        Expanded(
          child: Text(
            ad['cityName']?.toString() ?? '',
            style: GoogleFonts.cairo(
              color: Colors.black87,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  // ========== Navigation Methods ==========

  /// Navigate to advertisement details screen
  void _navigateToAdDetails(dynamic ad) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdDetailsScreen(ad: ad),
      ),
    );
  }

  // ========== Grid Configuration ==========

  /// Get cross axis count based on screen width
  int _getCrossAxisCount(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth > _tabletBreakpoint 
        ? _tabletCrossAxisCount 
        : _mobileCrossAxisCount;
  }

  // ========== Main UI Build Methods ==========

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: _buildAppBar(),
        body: _buildBody(),
      ),
    );
  }

  /// Build the app bar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.blue[700],
      elevation: 4,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'نتائج البحث',
        style: GoogleFonts.cairo(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      centerTitle: true,
    );
  }

  /// Build the main body content
  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    if (_errorMessage != null) {
      return _buildErrorWidget();
    }

    if (_searchResults.isEmpty) {
      return _buildEmptyResultsWidget();
    }

    return _buildSearchResultsGrid();
  }

  /// Build loading indicator
  Widget _buildLoadingWidget() {
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
      ),
    );
  }

  /// Build error message widget
  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: GoogleFonts.cairo(
              fontSize: 16,
              color: Colors.red[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _fetchSearchResults,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
            ),
            child: Text(
              'إعادة المحاولة',
              style: GoogleFonts.cairo(),
            ),
          ),
        ],
      ),
    );
  }

  /// Build empty results widget
  Widget _buildEmptyResultsWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد نتائج للبحث عن "${widget.searchText}"',
            style: GoogleFonts.cairo(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'جرب البحث بكلمات مختلفة',
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build search results grid
  Widget _buildSearchResultsGrid() {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _getCrossAxisCount(context),
            mainAxisSpacing: _gridSpacing,
            crossAxisSpacing: _gridSpacing,
            childAspectRatio: _cardAspectRatio,
          ),
          itemCount: _searchResults.length,
          itemBuilder: (context, index) {
            return _buildAdCard(_searchResults[index]);
          },
        ),
      ),
    );
  }
}
