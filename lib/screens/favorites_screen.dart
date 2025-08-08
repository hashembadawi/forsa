import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syria_market/screens/home_screen.dart';
import 'package:syria_market/screens/ad_details_screen.dart';
import 'package:syria_market/utils/dialog_utils.dart';
import 'package:google_fonts/google_fonts.dart';

/// Screen displaying user's favorite advertisements
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  // ========== Constants ==========
  static const String _baseUrl = 'https://sahbo-app-api.onrender.com/api/favorites/my-favorites';
  static const int _adsPerPage = 10;
  static const double _scrollThreshold = 200.0;
  static const double _imageHeight = 200.0;

  // ========== State Variables ==========
  final List<dynamic> _favoriteAds = [];
  bool _isLoading = false;
  bool _hasMoreAds = true;
  int _currentPage = 1;
  
  // ========== Controllers & Authentication ==========
  late ScrollController _scrollController;
  String? _userId;
  String? _authToken;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ========== Initialization ==========

  /// Initialize screen components and load data
  void _initializeScreen() {
    _scrollController = ScrollController()..addListener(_onScroll);
    _initializeAndFetchFavorites();
  }

  /// Initialize user authentication and fetch favorite advertisements
  Future<void> _initializeAndFetchFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _authToken = prefs.getString('token') ?? '';
      _userId = prefs.getString('userId');

      if (_isValidAuthentication()) {
        await _fetchFavoriteAds();
      }
    } catch (e) {
      DialogUtils.showErrorDialog(
        context: context,
        message: 'خطأ في تحميل البيانات',
      );
    }
  }

  /// Check if user authentication is valid
  bool _isValidAuthentication() {
    return _authToken != null && 
           _authToken!.isNotEmpty && 
           _userId != null && 
           _userId!.isNotEmpty;
  }

  // ========== Data Fetching ==========

  /// Fetch user's favorite advertisements
  Future<void> _fetchFavoriteAds() async {
    if (_isLoading || !_hasMoreAds || !_isValidAuthentication()) return;

    setState(() => _isLoading = true);

    try {
      final response = await _performFavoritesRequest();
      await _handleFavoritesResponse(response);
    } catch (e) {
      _handleFetchError(e);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Perform HTTP request to fetch favorites
  Future<http.Response> _performFavoritesRequest() async {
    final url = Uri.parse('$_baseUrl?page=$_currentPage&limit=$_adsPerPage');
    
    return await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $_authToken',
      },
    );
  }

  /// Handle favorites response and update state
  Future<void> _handleFavoritesResponse(http.Response response) async {
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List<dynamic> favorites = decoded['favorites'] ?? [];
      
      // Extract ads from favorites - each favorite contains an 'ad' object
      final List<dynamic> newAds = favorites.map((fav) => fav['ad']).where((ad) => ad != null).toList();

      setState(() {
        _favoriteAds.addAll(newAds);
        _currentPage++;
        // Check if we have more data based on the limit
        _hasMoreAds = favorites.length >= _adsPerPage;
      });
    } else {
      _handleHttpError(response);
    }
  }

  /// Handle HTTP errors
  void _handleHttpError(http.Response response) {
    setState(() => _hasMoreAds = false);
    debugPrint('HTTP Error: ${response.statusCode} - ${response.body}');
    DialogUtils.showErrorDialog(
      context: context,
      message: 'خطأ في تحميل المفضلة',
    );
  }

  /// Handle fetch errors
  void _handleFetchError(dynamic error) {
    setState(() => _hasMoreAds = false);
    debugPrint('Fetch Exception: $error');
    DialogUtils.showErrorDialog(
      context: context,
      message: 'خطأ في الاتصال بالخادم',
    );
  }

  /// Refresh favorites list
  Future<void> _refreshFavorites() async {
    setState(() {
      _favoriteAds.clear();
      _currentPage = 1;
      _hasMoreAds = true;
    });
    await _fetchFavoriteAds();
  }

  // ========== Scroll Handling ==========

  /// Handle scroll events for pagination
  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - _scrollThreshold) {
      _fetchFavoriteAds();
    }
  }

  // ========== Navigation ==========

  /// Navigate to ad details screen
  void _navigateToAdDetails(Map<String, dynamic> ad) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdDetailsScreen(ad: ad),
      ),
    ).then((_) {
      // Refresh favorites when returning from ad details
      _refreshFavorites();
    });
  }

  /// Navigate back to home screen
  void _navigateToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (Route<dynamic> route) => false,
    );
  }

  // ========== Favorites Management ==========

  /// Show confirmation dialog for removing from favorites
  void _showRemoveFromFavoritesDialog(Map<String, dynamic> ad) {
    DialogUtils.showConfirmationDialog(
      context: context,
      title: 'إزالة من المفضلة',
      message: 'هل تريد حقاً إزالة هذا الإعلان من المفضلة؟',
      confirmText: 'إزالة',
      cancelText: 'إلغاء',
      onConfirm: () => _removeFromFavorites(ad),
    );
  }

  /// Remove ad from favorites
  Future<void> _removeFromFavorites(Map<String, dynamic> ad) async {
    try {
      final response = await _performRemoveFromFavoritesRequest(ad);
      await _handleRemoveFromFavoritesResponse(response, ad);
    } catch (e) {
      debugPrint('Remove from favorites error: $e');
      DialogUtils.showErrorDialog(
        context: context,
        message: 'خطأ في إزالة الإعلان من المفضلة',
      );
    }
  }

  /// Perform HTTP request to remove from favorites
  Future<http.Response> _performRemoveFromFavoritesRequest(Map<String, dynamic> ad) async {
    const url = 'https://sahbo-app-api.onrender.com/api/favorites/delete';
    
    final body = {
      'userId': _userId,
      'adId': ad['_id'],
    };

    return await http.delete(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $_authToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
  }

  /// Handle remove from favorites response
  Future<void> _handleRemoveFromFavoritesResponse(http.Response response, Map<String, dynamic> ad) async {
    if (response.statusCode == 200) {
      // Remove the ad from local list
      setState(() {
        _favoriteAds.removeWhere((favoriteAd) => favoriteAd['_id'] == ad['_id']);
      });
      
      DialogUtils.showSuccessDialog(
        context: context,
        message: 'تم إزالة الإعلان من المفضلة بنجاح',
      );
    } else {
      debugPrint('Remove from favorites HTTP Error: ${response.statusCode} - ${response.body}');
      DialogUtils.showErrorDialog(
        context: context,
        message: 'فشل في إزالة الإعلان من المفضلة',
      );
    }
  }

  // ========== Utility Methods ==========

  /// Format date for display
  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays >= 1) return 'منذ ${difference.inDays} يوم';
      if (difference.inHours >= 1) return 'منذ ${difference.inHours} ساعة';
      if (difference.inMinutes >= 1) return 'منذ ${difference.inMinutes} دقيقة';
      return 'الآن';
    } catch (e) {
      return 'غير محدد';
    }
  }

  /// Check if favorites list is empty
  bool get _isFavoritesListEmpty => _favoriteAds.isEmpty;

  /// Check if currently loading initial data
  bool get _isLoadingInitialData => _isFavoritesListEmpty && _isLoading;

  // ========== Widget Building Methods ==========

  /// Build main app bar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'المفضلة',
        style: GoogleFonts.cairo(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      centerTitle: true,
      backgroundColor: Colors.blue[700],
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: _navigateToHome,
      ),
    );
  }

  /// Build main body content
  Widget _buildBody() {
    if (_isLoadingInitialData) {
      return _buildLoadingIndicator();
    }

    if (_isFavoritesListEmpty) {
      return _buildEmptyState();
    }

    return _buildFavoritesList();
  }

  /// Build loading indicator
  Widget _buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد إعلانات مفضلة بعد',
            style: GoogleFonts.cairo(
              fontSize: 18,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ابدأ بإضافة الإعلانات التي تعجبك إلى المفضلة',
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _navigateToHome,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: Text(
              'تصفح الإعلانات',
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build favorites list with refresh capability
  Widget _buildFavoritesList() {
    return RefreshIndicator(
      color: Colors.blue,
      onRefresh: _refreshFavorites,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _favoriteAds.length + (_hasMoreAds ? 1 : 0),
        itemBuilder: _buildListItem,
      ),
    );
  }

  /// Build individual list item
  Widget _buildListItem(BuildContext context, int index) {
    if (index == _favoriteAds.length) {
      return _buildLoadingItem();
    }

    final ad = _favoriteAds[index];
    return _buildAdCard(ad);
  }

  /// Build loading item for pagination
  Widget _buildLoadingItem() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
      ),
    );
  }

  /// Build advertisement card
  Widget _buildAdCard(Map<String, dynamic> ad) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: _buildCardDecoration(),
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => _navigateToAdDetails(ad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAdImage(ad),
                  _buildAdContent(ad),
                ],
              ),
            ),
            // Remove from favorites icon
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red[600],
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.favorite,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () => _showRemoveFromFavoritesDialog(ad),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build card decoration
  BoxDecoration _buildCardDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      color: Colors.white,
      border: Border.all(color: Colors.blue[300]!, width: 1.5),
      boxShadow: [
        BoxShadow(
          color: Colors.blue[100]!.withOpacity(0.3),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  /// Build ad image section
  Widget _buildAdImage(Map<String, dynamic> ad) {
    final List<dynamic> images = ad['images'] is List ? ad['images'] : [];
    final firstImageBase64 = images.isNotEmpty ? images[0] : null;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      child: SizedBox(
        height: _imageHeight,
        width: double.infinity,
        child: _buildImageWidget(firstImageBase64),
      ),
    );
  }

  /// Build image widget with error handling
  Widget _buildImageWidget(String? imageBase64) {
    if (imageBase64 != null) {
      return Image.memory(
        base64Decode(imageBase64),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
      );
    } else {
      return _buildImagePlaceholder(showNoImageText: true);
    }
  }

  /// Build image placeholder
  Widget _buildImagePlaceholder({bool showNoImageText = false}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue[50]!, Colors.blue[100]!],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image, size: 60, color: Colors.blue[600]),
            const SizedBox(height: 8),
            Text(
              showNoImageText ? 'لا توجد صورة' : 'صورة',
              style: GoogleFonts.cairo(
                color: Colors.black87,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build ad content section
  Widget _buildAdContent(Map<String, dynamic> ad) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAdTitle(ad),
          const SizedBox(height: 12),
          _buildAdPrice(ad),
          const SizedBox(height: 12),
          _buildAdLocation(ad),
          const SizedBox(height: 8),
          _buildAdDate(ad),
        ],
      ),
    );
  }

  /// Build ad title
  Widget _buildAdTitle(Map<String, dynamic> ad) {
    return Text(
      ad['adTitle'] ?? 'بدون عنوان',
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.cairo(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  /// Build ad price
  Widget _buildAdPrice(Map<String, dynamic> ad) {
    final price = ad['price'] ?? '0';
    final currency = ad['currencyName'] ?? ad['currency'] ?? '';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[300]!, width: 1),
      ),
      child: Text(
        '$price $currency',
        style: GoogleFonts.cairo(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.blue[700],
        ),
      ),
    );
  }

  /// Build ad location
  Widget _buildAdLocation(Map<String, dynamic> ad) {
    final cityName = ad['cityName'] ?? '';
    final regionName = ad['regionName'] ?? '';
    final location = '$cityName - $regionName'.replaceAll(RegExp(r'^-\s*|-\s*$'), '');
    
    return Row(
      children: [
        Icon(Icons.location_on, size: 16, color: Colors.blue[600]),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            location.isNotEmpty ? location : 'موقع غير محدد',
            style: GoogleFonts.cairo(
              color: Colors.black87,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  /// Build ad date
  Widget _buildAdDate(Map<String, dynamic> ad) {
    final createDate = ad['createDate'];
    final formattedDate = createDate != null ? _formatDate(createDate) : 'غير محدد';
    
    return Row(
      children: [
        Icon(Icons.access_time, size: 16, color: Colors.blue[600]),
        const SizedBox(width: 4),
        Text(
          formattedDate,
          style: GoogleFonts.cairo(
            color: Colors.black87,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ========== Main Build Method ==========

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(),
        body: _buildBody(),
      ),
    );
  }
}
