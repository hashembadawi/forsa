import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:forsa/screens/home_screen.dart' as home;
import 'package:forsa/utils/ad_card_widget.dart';
import 'package:forsa/screens/ad_details_screen.dart';
import 'package:forsa/utils/dialog_utils.dart';
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
      MaterialPageRoute(builder: (context) => const home.HomeScreen()),
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
          fontSize: 22,
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
    return AdCardWidget(
      ad: home.AdModel.fromJson(ad),
      onTap: () => _navigateToAdDetails(ad),
      favoriteIconBuilder: (adId) => GestureDetector(
        onTap: () => _showRemoveFromFavoritesDialog(ad),
        child: Icon(
          Icons.favorite,
          color: Colors.red,
          size: 24,
        ),
      ),
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
