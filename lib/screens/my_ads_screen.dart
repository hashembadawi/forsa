import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:forsa/screens/update_ad_screen.dart';
import 'package:forsa/screens/add_ad_screen.dart';
import 'package:forsa/utils/dialog_utils.dart';
import 'package:forsa/utils/ad_card_widget.dart';
import 'package:forsa/screens/home_screen.dart' as home;
import 'package:google_fonts/google_fonts.dart';

/// Screen displaying user's personal advertisements with edit and delete functionality
class MyAdsScreen extends StatefulWidget {
  const MyAdsScreen({super.key});

  @override
  State<MyAdsScreen> createState() => _MyAdsScreenState();
}

class _MyAdsScreenState extends State<MyAdsScreen> {
  // ========== Constants ==========
  static const String _baseUrl = 'https://sahbo-app-api.onrender.com/api/ads/userAds';
  static const int _adsPerPage = 5;
  static const double _scrollThreshold = 200.0;

  // ========== State Variables ==========
  final List<dynamic> _myAds = [];
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
    _initializeAndFetchAds();
  }

  /// Initialize user authentication and fetch advertisements
  Future<void> _initializeAndFetchAds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _authToken = prefs.getString('token') ?? '';
      _userId = prefs.getString('userId');

      if (_isValidAuthentication()) {
        await _fetchMyAds();
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

  /// Fetch user's advertisements with pagination
  Future<void> _fetchMyAds() async {
    if (_isLoading || !_hasMoreAds || !_isValidAuthentication()) return;

    setState(() => _isLoading = true);

    try {
      final response = await _performAdsRequest();
      await _handleAdsResponse(response);
    } catch (e) {
      _handleFetchError(e);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Perform HTTP request to fetch ads
  Future<http.Response> _performAdsRequest() async {
    final url = Uri.parse('$_baseUrl/$_userId?page=$_currentPage&limit=$_adsPerPage');
    
    return await http.get(
      url,
      headers: {'Authorization': 'Bearer $_authToken'},
    );
  }

  /// Handle ads response and update state
  Future<void> _handleAdsResponse(http.Response response) async {
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List<dynamic> newAds = decoded['ads'] ?? [];

      setState(() {
        _myAds.addAll(newAds);
        _currentPage++;
        _hasMoreAds = newAds.length >= _adsPerPage;
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
      message: 'خطأ في تحميل الإعلانات',
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

  /// Refresh ads list
  Future<void> _refreshAds() async {
    setState(() {
      _myAds.clear();
      _currentPage = 1;
      _hasMoreAds = true;
    });
    await _fetchMyAds();
  }

  // ========== Scroll Handling ==========

  /// Handle scroll events for pagination
  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - _scrollThreshold) {
      _fetchMyAds();
    }
  }

  // ========== Ad Management ==========

  /// Delete an advertisement
  Future<void> _deleteAd(String adId) async {
    // Show loading dialog
    DialogUtils.showLoadingDialog(
      context: context,
      title: 'جارٍ حذف الإعلان...',
      message: 'يرجى الانتظار',
    );

    try {
      final response = await _performDeleteRequest(adId);
      
      // Close loading dialog
      DialogUtils.closeDialog(context);
      
      if (response.statusCode == 200) {
        _removeAdFromList(adId);
        DialogUtils.showSuccessDialog(
          context: context,
          message: 'تم حذف الإعلان بنجاح',
        );
      } else {
        DialogUtils.showErrorDialog(
          context: context,
          message: 'فشل في حذف الإعلان',
        );
      }
    } catch (e) {
      // Close loading dialog
      DialogUtils.closeDialog(context);
      debugPrint('Delete Exception: $e');
      DialogUtils.showErrorDialog(
        context: context,
        message: 'حدث خطأ أثناء الحذف',
      );
    }
  }

  /// Perform delete HTTP request
  Future<http.Response> _performDeleteRequest(String adId) async {
    final url = Uri.parse('$_baseUrl/$adId');
    
    return await http.delete(
      url,
      headers: {'Authorization': 'Bearer $_authToken'},
    );
  }

  /// Remove ad from local list
  void _removeAdFromList(String adId) {
    setState(() {
      _myAds.removeWhere((ad) => ad['_id'] == adId);
    });
  }

  /// Show delete confirmation dialog
  void _showDeleteConfirmation(String adId, String adTitle) {
    DialogUtils.showConfirmationDialog(
      context: context,
      title: 'تأكيد الحذف',
      message: 'هل أنت متأكد أنك تريد حذف هذا الإعلان؟\n"$adTitle"',
      confirmText: 'حذف',
      cancelText: 'إلغاء',
      confirmColor: const Color(0xFFE74C3C),
      onConfirm: () => _deleteAd(adId),
    );
  }

  // ========== Navigation ==========

  /// Navigate to edit ad screen
  Future<void> _navigateToEditAd(Map<String, dynamic> ad) async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditAdScreen(
          adId: ad['_id'],
          initialTitle: ad['adTitle'] ?? '',
          initialPrice: ad['price']?.toString() ?? '',
          initialCurrency: ad['currencyName'] ?? 'ل.س',
          initialDescription: ad['description'] ?? '',
          initialForSale: ad['forSale'] ?? false,
          initialDeliveryService: ad['deliveryService'] ?? false,
        ),
      ),
    );

    if (updated == true) {
      await _refreshAds();
    }
  }

  /// Navigate back to home screen and reload it
  void _navigateToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => home.HomeScreen(refreshOnStart: true),
      ),
      (route) => false,
    );
  }

  /// Navigate to add ad screen
  void _navigateToAddAd() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MultiStepAddAdScreen()),
    );
  }


  /// Check if ads list is empty
  bool get _isAdsListEmpty => _myAds.isEmpty;

  /// Check if currently loading initial data
  bool get _isLoadingInitialData => _isAdsListEmpty && _isLoading;

  // ========== Widget Building Methods ==========

  /// Build main app bar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'إعلاناتي',
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

    if (_isAdsListEmpty) {
      return _buildEmptyState();
    }

    return _buildAdsList();
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
            Icons.announcement_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد إعلانات بعد',
            style: GoogleFonts.cairo(
              fontSize: 18,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _navigateToAddAd,
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
              'أضف إعلان',
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

  /// Build ads list with refresh capability
  Widget _buildAdsList() {
    return RefreshIndicator(
      color: Colors.blue,
      onRefresh: _refreshAds,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _myAds.length + (_hasMoreAds ? 1 : 0),
        itemBuilder: _buildListItem,
      ),
    );
  }

  /// Build individual list item
  Widget _buildListItem(BuildContext context, int index) {
    if (index == _myAds.length) {
      return _buildLoadingItem();
    }

    final ad = _myAds[index];
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
    final isApproved = ad['isApproved'] ?? false;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.blue[300]!, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.blue[100]!.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdCardWidget(
            ad: home.AdModel.fromJson(ad),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                if (!isApproved)
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.orange, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.pending, size: 16, color: Colors.orange),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'قيد المراجعة',
                              style: GoogleFonts.cairo(
                                color: Colors.orange,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                _buildEditButton(ad),
                const SizedBox(width: 12),
                _buildDeleteButton(ad),
              ],
            ),
          ),
        ],
      ),
    );
  }









  /// Build edit button
  Widget _buildEditButton(Map<String, dynamic> ad) {
    return ElevatedButton.icon(
      onPressed: () => _navigateToEditAd(ad),
      icon: const Icon(Icons.edit, size: 18, color: Colors.white),
      label: Text(
        'تعديل',
        style: GoogleFonts.cairo(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue[700],
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
    );
  }

  /// Build delete button
  Widget _buildDeleteButton(Map<String, dynamic> ad) {
    return ElevatedButton.icon(
      onPressed: () => _showDeleteConfirmation(ad['_id'], ad['adTitle'] ?? 'الإعلان'),
      icon: const Icon(Icons.delete, size: 18, color: Colors.white),
      label: Text(
        'حذف',
        style: GoogleFonts.cairo(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFE74C3C),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
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
