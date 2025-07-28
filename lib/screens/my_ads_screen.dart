import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syria_market/screens/update_ad_screen.dart';
import 'package:syria_market/screens/home_screen.dart';

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
  static const double _imageHeight = 200.0;

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
      _showError('خطأ في تحميل البيانات');
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
    _showError('خطأ في تحميل الإعلانات');
  }

  /// Handle fetch errors
  void _handleFetchError(dynamic error) {
    setState(() => _hasMoreAds = false);
    debugPrint('Fetch Exception: $error');
    _showError('خطأ في الاتصال بالخادم');
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
    try {
      final response = await _performDeleteRequest(adId);
      
      if (response.statusCode == 200) {
        _removeAdFromList(adId);
        _showSuccessMessage('تم حذف الإعلان بنجاح');
      } else {
        _showError('فشل في حذف الإعلان');
      }
    } catch (e) {
      debugPrint('Delete Exception: $e');
      _showError('حدث خطأ أثناء الحذف');
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.blue[300]!, width: 1.5),
        ),
        backgroundColor: Colors.white,
        title: Text(
          'تأكيد الحذف',
          style: TextStyle(
            color: Colors.blue[700],
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'هل أنت متأكد أنك تريد حذف هذا الإعلان؟',
              style: TextStyle(color: Colors.black87, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              '"$adTitle"',
              style: TextStyle(
                color: Colors.blue[700],
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'إلغاء',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAd(adId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE74C3C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: const Text(
              'حذف',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
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
        ),
      ),
    );

    if (updated == true) {
      await _refreshAds();
    }
  }

  /// Navigate back to home screen
  void _navigateToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (Route<dynamic> route) => false,
    );
  }

  // ========== UI Feedback ==========

  /// Show error message
  void _showError(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /// Show success message
  void _showSuccessMessage(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
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

  /// Check if ads list is empty
  bool get _isAdsListEmpty => _myAds.isEmpty;

  /// Check if currently loading initial data
  bool get _isLoadingInitialData => _isAdsListEmpty && _isLoading;

  // ========== Widget Building Methods ==========

  /// Build main app bar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'إعلاناتي',
        style: TextStyle(
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
          const Text(
            'لا توجد إعلانات بعد',
            style: TextStyle(
              fontSize: 18,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ابدأ بإضافة إعلانك الأول',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: _buildCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAdImage(ad),
          _buildAdContent(ad),
        ],
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
              style: TextStyle(
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
          _buildAdDescription(ad),
          const SizedBox(height: 12),
          _buildAdLocation(ad),
          const SizedBox(height: 8),
          _buildAdDate(ad),
          _buildDivider(),
          _buildActionButtons(ad),
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
      style: const TextStyle(
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
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.blue[700],
        ),
      ),
    );
  }

  /// Build ad description
  Widget _buildAdDescription(Map<String, dynamic> ad) {
    return Text(
      ad['description'] ?? 'بدون وصف',
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 14,
        color: Colors.black87,
        fontWeight: FontWeight.w500,
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
            style: const TextStyle(
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
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Build content divider
  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[300]!, Colors.blue[400]!],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
    );
  }

  /// Build action buttons
  Widget _buildActionButtons(Map<String, dynamic> ad) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _buildEditButton(ad),
        const SizedBox(width: 12),
        _buildDeleteButton(ad),
      ],
    );
  }

  /// Build edit button
  Widget _buildEditButton(Map<String, dynamic> ad) {
    return ElevatedButton.icon(
      onPressed: () => _navigateToEditAd(ad),
      icon: const Icon(Icons.edit, size: 18, color: Colors.white),
      label: const Text(
        'تعديل',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
      label: const Text(
        'حذف',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
