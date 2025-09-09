import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:forsa/screens/ad_details_screen.dart';
import '../utils/ad_card_widget.dart';
import 'home_screen.dart' as home;
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
  static const double _gridSpacing = 5.0;
  static const double _cardAspectRatio = 0.79;
  static const int _tabletCrossAxisCount = 3;
  static const int _mobileCrossAxisCount = 2;
  static const int _tabletBreakpoint = 600;

  // ========== State Variables ==========
  List<dynamic> _searchResults = [];
  bool _isLoading = true;
  String? _errorMessage;

  // ========== Color Scheme ==========

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
    // Convert the ad map to AdModel (from home_screen.dart)
    final adModel = home.AdModel.fromJson(ad);
    return AdCardWidget(
      ad: adModel,
      favoriteIconBuilder: (adId) => defaultFavoriteHeartIcon(
        adId,
        isFavorite: false, // TODO: Replace with real logic if available
        isLoggedIn: false, // TODO: Replace with real logic if available
        isLoading: false,
      ),
      onTap: () => _navigateToAdDetails(ad),
    );
  }

  // ========== Navigation Methods ==========

  /// Navigate to advertisement details screen
  void _navigateToAdDetails(dynamic ad) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdDetailsScreen(adId: ad['_id']),
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
          fontSize: 22,
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
