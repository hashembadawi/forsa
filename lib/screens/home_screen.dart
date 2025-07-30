import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'account_screen.dart';
import 'ad_details_screen.dart';
import 'add_ad_screen.dart';
import 'login_screen.dart';
import 'my_ads_screen.dart';
import 'search_results_screen.dart';

/// Home screen that displays advertisements with filtering and search capabilities
class HomeScreen extends StatefulWidget {
  final bool refreshOnStart;
  
  const HomeScreen({super.key, this.refreshOnStart = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ========== Constants ==========
  static const String _baseUrl = 'https://sahbo-app-api.onrender.com';
  static const int _limitAds = 10;
  static const String _defaultCity = 'كل المحافظات';
  static const String _defaultDistrict = 'كل المناطق';

  // ========== Location State ==========
  String _selectedCity = _defaultCity;
  String _selectedDistrict = _defaultDistrict;
  int? _selectedCityId;
  int? _selectedRegionId;
  List<Map<String, dynamic>> _provinces = [];
  List<Map<String, dynamic>> _majorAreas = [];

  // ========== Category State ==========
  int? _selectedCategoryId;
  int? _selectedSubCategoryId;

  // ========== Ads State ==========
  final List<dynamic> _allAds = [];
  bool _isLoadingAds = false;
  int _currentPageAds = 1;
  bool _hasMoreAds = true;

  // ========== Controllers & State ==========
  final TextEditingController _searchController = TextEditingController();
  late ScrollController _adsScrollController;
  String? _username;
  String? _userProfileImage;
  
  // ========== Connectivity State ==========
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  bool _isConnected = true;
  bool _isCheckingConnectivity = true;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  @override
  void dispose() {
    _adsScrollController.dispose();
    _connectivitySubscription.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // ========== Initialization Methods ==========

  /// Initialize screen components
  void _initializeScreen() {
    _adsScrollController = ScrollController()..addListener(_onAdsScroll);
    _checkInitialConnectivity();
    _subscribeToConnectivityChanges();
    _checkLoginStatus();
    _fetchOptions();
    _fetchAllAds();
  }

  /// Check initial internet connectivity
  Future<void> _checkInitialConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      setState(() {
        _isConnected = connectivityResult != ConnectivityResult.none;
        _isCheckingConnectivity = false;
      });
    } catch (e) {
      setState(() {
        _isConnected = false;
        _isCheckingConnectivity = false;
      });
    }
  }

  /// Subscribe to connectivity changes
  void _subscribeToConnectivityChanges() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (ConnectivityResult result) {
        setState(() {
          _isConnected = result != ConnectivityResult.none;
        });
      },
    );
  }

  // ========== Data Fetching Methods ==========

  /// Fetch options (provinces, areas, categories)
  Future<void> _fetchOptions() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/api/options'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _provinces = List<Map<String, dynamic>>.from(data['Province'] ?? []);
          _majorAreas = List<Map<String, dynamic>>.from(data['majorAreas'] ?? []);
        });
      }
    } catch (e) {
      debugPrint('Error fetching options: $e');
    }
  }

  /// Check user login status
  Future<void> _checkLoginStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final rememberMe = prefs.getBool('rememberMe') ?? false;

      if (token != null) {
        await _validateToken(token, prefs, rememberMe);
      } else {
        _clearUserDataIfNeeded(prefs, rememberMe);
      }
    } catch (e) {
      debugPrint('Error checking login status: $e');
      setState(() {
        _username = null;
        _userProfileImage = null;
      });
    }
  }

  /// Validate user token
  Future<void> _validateToken(String token, SharedPreferences prefs, bool rememberMe) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/user/validate-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _username = prefs.getString('userName') ?? 'مستخدم';
          // Try different possible keys for profile image
          _userProfileImage = prefs.getString('profileImage') ?? 
                             prefs.getString('userProfileImage');
        });
      } else {
        await prefs.clear();
        setState(() {
          _username = null;
          _userProfileImage = null;
        });
      }
    } catch (e) {
      if (!rememberMe) {
        await prefs.clear();
      }
      setState(() {
        _username = null;
        _userProfileImage = null;
      });
    }
  }

  /// Clear user data if not remembered
  void _clearUserDataIfNeeded(SharedPreferences prefs, bool rememberMe) {
    if (!rememberMe) {
      prefs.clear();
    }
    setState(() {
      _username = null;
      _userProfileImage = null;
    });
  }

  /// Refresh user data from SharedPreferences
  Future<void> _refreshUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token != null && token.isNotEmpty) {
        setState(() {
          _username = prefs.getString('userName') ?? 'مستخدم';
          // Try different possible keys for profile image
          _userProfileImage = prefs.getString('profileImage') ?? 
                             prefs.getString('userProfileImage');
        });
      } else {
        setState(() {
          _username = null;
          _userProfileImage = null;
        });
      }
    } catch (e) {
      debugPrint('Error refreshing user data: $e');
    }
  }

  /// Fetch all advertisements
  Future<void> _fetchAllAds() async {
    if (_isLoadingAds || !_hasMoreAds) return;

    setState(() => _isLoadingAds = true);

    try {
      final url = Uri.parse('$_baseUrl/api/ads?page=$_currentPageAds&limit=$_limitAds');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> fetchedAds = decoded['ads'] ?? [];

        setState(() {
          _allAds.addAll(fetchedAds);
          _currentPageAds++;
          _isLoadingAds = false;
          _hasMoreAds = fetchedAds.length >= _limitAds;
        });
      } else {
        _handleFetchError();
      }
    } catch (e) {
      debugPrint('Exception fetching ads: $e');
      _handleFetchError();
    }
  }

  /// Fetch filtered advertisements by location
  Future<void> _fetchFilteredAds({bool reset = false}) async {
    if (_isLoadingAds || !_hasMoreAds) return;

    setState(() => _isLoadingAds = true);

    try {
      final params = <String, String>{
        'page': '$_currentPageAds',
        'limit': '$_limitAds',
      };
      
      if (_selectedCityId != null) params['cityId'] = _selectedCityId.toString();
      if (_selectedRegionId != null) params['regionId'] = _selectedRegionId.toString();

      final uri = Uri.https('sahbo-app-api.onrender.com', '/api/ads/search', params);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> fetchedAds = decoded['ads'] ?? [];

        setState(() {
          if (reset) _allAds.clear();
          _allAds.addAll(fetchedAds);
          _currentPageAds++;
          _isLoadingAds = false;
          _hasMoreAds = fetchedAds.length >= _limitAds;
        });
      } else {
        _handleFetchError();
      }
    } catch (e) {
      debugPrint('Exception fetching filtered ads: $e');
      _handleFetchError();
    }
  }

  /// Fetch filtered advertisements by category
  Future<void> _fetchCategoryFilteredAds({bool reset = false}) async {
    if (_isLoadingAds || !_hasMoreAds) return;

    setState(() => _isLoadingAds = true);

    try {
      final params = <String, String>{
        'page': '$_currentPageAds',
        'limit': '$_limitAds',
      };
      
      if (_selectedCategoryId != null) params['categoryId'] = _selectedCategoryId.toString();
      if (_selectedSubCategoryId != null) params['subCategoryId'] = _selectedSubCategoryId.toString();

      final uri = Uri.https('sahbo-app-api.onrender.com', '/api/ads/search-by-category', params);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> fetchedAds = decoded['ads'] ?? [];

        setState(() {
          if (reset) _allAds.clear();
          _allAds.addAll(fetchedAds);
          _currentPageAds++;
          _isLoadingAds = false;
          _hasMoreAds = fetchedAds.length >= _limitAds;
        });
      } else {
        _handleFetchError();
      }
    } catch (e) {
      debugPrint('Exception fetching category filtered ads: $e');
      _handleFetchError();
    }
  }

  /// Handle fetch error
  void _handleFetchError() {
    setState(() {
      _isLoadingAds = false;
      _hasMoreAds = false;
    });
  }

  // ========== Event Handlers ==========

  /// Handle scroll for pagination
  void _onAdsScroll() {
    if (_adsScrollController.position.pixels >= 
        _adsScrollController.position.maxScrollExtent - 200) {
      if (_selectedCategoryId != null || _selectedSubCategoryId != null) {
        _fetchCategoryFilteredAds();
      } else if (_selectedCityId != null || _selectedRegionId != null) {
        _fetchFilteredAds();
      } else {
        _fetchAllAds();
      }
    }
  }

  /// Reload home screen
  void _reloadHomeScreen() {
    setState(() {
      _resetFilters();
      _resetAdsData();
    });
    
    _fetchOptions();
    _fetchAllAds();
  }

  /// Reset filter state
  void _resetFilters() {
    _selectedCity = _defaultCity;
    _selectedDistrict = _defaultDistrict;
    _selectedCityId = null;
    _selectedRegionId = null;
    _selectedCategoryId = null;
    _selectedSubCategoryId = null;
    _searchController.clear();
  }

  /// Reset ads data
  void _resetAdsData() {
    _allAds.clear();
    _currentPageAds = 1;
    _hasMoreAds = true;
    _isLoadingAds = false;
  }

  // ========== UI Helper Methods ==========

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

  /// Handle protected navigation (requires login)
  void _handleProtectedNavigation(BuildContext context, String routeKey) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      _showLoginRequiredDialog(context, routeKey, prefs);
    } else {
      _navigateToProtectedPage(context, routeKey);
    }
  }

  /// Show login required dialog
  void _showLoginRequiredDialog(BuildContext context, String routeKey, SharedPreferences prefs) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل الدخول مطلوب'),
        content: const Text('يجب تسجيل الدخول للوصول إلى هذه الصفحة.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              await prefs.setString('redirect_to', routeKey);
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            child: const Text('تسجيل دخول'),
          ),
        ],
      ),
    );
  }

  /// Navigate to protected page
  void _navigateToProtectedPage(BuildContext context, String routeKey) {
    Widget? targetPage;
    
    switch (routeKey) {
      case 'myAds':
        targetPage = const MyAdsScreen();
        break;
      case 'addAd':
        targetPage = const MultiStepAddAdScreen();
        break;
    }

    if (targetPage != null) {
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => targetPage!),
      );
    }
  }

  // ========== Dialog Methods ==========

  /// Show location filter dialog
  Future<void> _showLocationFilterDialog() async {
    // Initialize with current values
    Map<String, dynamic>? tempSelectedProvince = _selectedCityId != null 
        ? _provinces.where((p) => p['id'] == _selectedCityId).isNotEmpty
          ? _provinces.firstWhere((p) => p['id'] == _selectedCityId)
          : null
        : null;
    
    Map<String, dynamic>? tempSelectedArea = _selectedRegionId != null 
        ? _majorAreas.where((a) => a['id'] == _selectedRegionId).isNotEmpty
          ? _majorAreas.firstWhere((a) => a['id'] == _selectedRegionId)
          : null
        : null;
    
    List<Map<String, dynamic>> filteredAreas = [];
    
    // Initialize filtered areas if province is selected
    if (tempSelectedProvince != null) {
      filteredAreas.addAll(
        _majorAreas.where((area) => area['ProvinceId'] == tempSelectedProvince!['id']).toList(),
      );
    }

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Colors.blue[600]!, width: 2),
            ),
            backgroundColor: Colors.white,
            title: const Text(
              'تصفية حسب الموقع',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Province Dropdown
                  DropdownButtonFormField<Map<String, dynamic>>(
                    value: tempSelectedProvince,
                    isExpanded: true,
                    decoration: _buildDropdownDecoration('اختر المحافظة', 15),
                    dropdownColor: Colors.white,
                    style: _buildDropdownTextStyle(),
                    items: [
                      const DropdownMenuItem<Map<String, dynamic>>(
                        value: null,
                        child: Text(
                          'كل المحافظات',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      ..._provinces.map((province) => DropdownMenuItem(
                        value: province,
                        child: Text(
                          province['name'],
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )),
                    ],
                    onChanged: (value) {
                      setStateDialog(() {
                        tempSelectedProvince = value;
                        tempSelectedArea = null; // Reset area selection when province changes
                        filteredAreas.clear();
                        if (value != null) {
                          filteredAreas.addAll(
                            _majorAreas.where((area) => area['ProvinceId'] == value['id']).toList(),
                          );
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  // Area Dropdown
                  DropdownButtonFormField<Map<String, dynamic>>(
                    value: tempSelectedArea,
                    isExpanded: true,
                    decoration: _buildDropdownDecoration('اختر المدينة/المنطقة', 25),
                    dropdownColor: Colors.white,
                    style: _buildDropdownTextStyle(),
                    items: [
                      const DropdownMenuItem<Map<String, dynamic>>(
                        value: null,
                        child: Text(
                          'كل المناطق',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      ...filteredAreas.map((area) => DropdownMenuItem(
                        value: area,
                        child: Text(
                          area['name'],
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )),
                    ],
                    onChanged: (value) {
                      setStateDialog(() {
                        tempSelectedArea = value;
                      });
                    },
                  ),
                ],
              ),
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
                  setState(() {
                    _selectedCity = tempSelectedProvince?['name'] ?? _defaultCity;
                    _selectedDistrict = tempSelectedArea?['name'] ?? _defaultDistrict;
                    _selectedCityId = tempSelectedProvince?['id'];
                    _selectedRegionId = tempSelectedArea?['id'];
                    _resetAdsData();
                  });
                  
                  Navigator.pop(context);
                  
                  if (_selectedCityId != null || _selectedRegionId != null) {
                    _fetchFilteredAds(reset: true);
                  } else {
                    _fetchAllAds();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'تطبيق',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Build dropdown decoration
  InputDecoration _buildDropdownDecoration(String labelText, double borderRadius) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(color: Colors.blue[600]),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide(color: Colors.blue[400]!, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide(color: Colors.blue[400]!, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  /// Build dropdown text style
  TextStyle _buildDropdownTextStyle() {
    return const TextStyle(
      color: Colors.blue,
      fontSize: 15,
      fontWeight: FontWeight.w500,
    );
  }

  // ========== Widget Building Methods ==========

  /// Build advertisement card
  Widget _buildAdCard(dynamic ad) {
    final List<dynamic> images = ad['images'] is List ? ad['images'] : [];
    final firstImageBase64 = images.isNotEmpty ? images[0] : null;

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Color(0xFFF8FBFF),
            Color(0xFFF0F8FF),
          ],
        ),
        border: Border.all(color: Colors.blue[300]!, width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          splashColor: Colors.blue[300]!.withOpacity(0.2),
          highlightColor: Colors.blue[100]!.withOpacity(0.1),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AdDetailsScreen(ad: ad)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                  child: SizedBox(
                    width: double.infinity,
                    child: _buildAdImage(firstImageBase64),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 80),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: _buildAdDetails(ad),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build ad image
  Widget _buildAdImage(String? firstImageBase64) {
    if (firstImageBase64 != null) {
      return Image.memory(
        base64Decode(firstImageBase64),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildNoImagePlaceholder(),
      );
    } else {
      return _buildNoImagePlaceholder();
    }
  }

  /// Build no image placeholder
  Widget _buildNoImagePlaceholder() {
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
            Icon(Icons.image, size: 40, color: Colors.blue[400]),
            const SizedBox(height: 4),
            Text(
              'لا توجد صورة',
              style: TextStyle(
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

  /// Build ad details section
  Widget _buildAdDetails(dynamic ad) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Text(
          '${ad['adTitle'] ?? ''}',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[300]!, width: 1),
          ),
          child: Text(
            '${ad['price'] ?? '0'} ${ad['currencyName'] ?? ''}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        Text(
          ad['description'] ?? '',
          style: const TextStyle(
            fontSize: 10,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_on, size: 12, color: Colors.blue[600]),
            const SizedBox(width: 2),
            Expanded(
              child: Text(
                '${ad['cityName'] ?? ''} - ${_formatDate(ad['createDate'] ?? '')}',
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build location filter button
  Widget _buildLocationButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: _showLocationFilterDialog,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.blue[300]!, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.location_on, size: 22, color: Colors.blue[600]),
                  const SizedBox(width: 8),
                  const Text(
                    'بحث بالموقع',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E4A47),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _selectedCity == _defaultCity
                    ? _defaultCity
                    : '$_selectedCity - $_selectedDistrict',
                style: TextStyle(fontSize: 15, color: Colors.grey[700]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build search field
  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'ابحث عن منتج أو خدمة...',
          hintStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: Icon(Icons.search, color: Colors.blue[600]),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.blue[300]!, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.blue[300]!, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        onSubmitted: (value) {
          if (value.trim().isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SearchResultsScreen(searchText: value.trim()),
              ),
            );
          }
        },
      ),
    );
  }

  /// Build navigation drawer
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.grey[50],
      elevation: 16,
      child: Column(
        children: [
          _buildDrawerHeader(),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.grey[50]!,
                    Colors.white,
                  ],
                ),
              ),
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 0),
                children: [
                  _buildDrawerItem(
                    Icons.home_rounded, 
                    'الرئيسية', 
                    Colors.blue[600]!,
                    () {
                      Navigator.pop(context);
                      _reloadHomeScreen();
                    },
                  ),
                  _buildDrawerItem(
                    Icons.list_alt_rounded, 
                    'إعلاناتي', 
                    Colors.green[600]!,
                    () {
                      _handleProtectedNavigation(context, 'myAds');
                    },
                  ),
                  _buildDrawerItem(
                    Icons.add_circle_outline_rounded, 
                    'إضافة إعلان', 
                    Colors.orange[600]!,
                    () {
                      _handleProtectedNavigation(context, 'addAd');
                    },
                  ),
                  _buildDrawerItem(
                    Icons.person_rounded, 
                    'حسابي', 
                    Colors.purple[600]!,
                    () async {
                      await _handleAccountNavigation(context);
                    },
                  ),
                ],
              ),
            ),
          ),
          // Footer section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(
                top: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.copyright, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '2025 سوق سوريا',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build drawer header
  Widget _buildDrawerHeader() {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue[700]!,
            Colors.blue[500]!,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Profile image
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white,
              child: _userProfileImage != null && _userProfileImage!.isNotEmpty
                  ? ClipOval(
                      child: Image.memory(
                        base64Decode(_userProfileImage!),
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.person_rounded, size: 40, color: Colors.blue[700]);
                        },
                      ),
                    )
                  : Icon(Icons.person_rounded, size: 40, color: Colors.blue[700]),
            ),
            const SizedBox(height: 16),
            // Welcome text without border
            Text(
              _username != null ? 'مرحباً، $_username 👋' : 'مرحبا بك 👋',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// Build drawer item
  Widget _buildDrawerItem(IconData icon, String title, Color iconColor, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 1),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.grey[50]!,
          ],
        ),
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 0.5),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          splashColor: iconColor.withOpacity(0.1),
          highlightColor: iconColor.withOpacity(0.05),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: iconColor.withOpacity(0.2), width: 1),
                  ),
                  child: Icon(
                    icon, 
                    color: iconColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.grey[400],
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Handle account navigation
  Future<void> _handleAccountNavigation(BuildContext context) async {
    Navigator.pop(context);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      await prefs.setString('redirect_to', 'account');
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      ).then((_) {
        // Refresh user data when returning from login
        _refreshUserData();
      });
    } else {
      final username = prefs.getString('userName') ?? '';
      final email = prefs.getString('userEmail') ?? '';
      final phone = prefs.getString('userPhone') ?? '';
      final userId = prefs.getString('userId') ?? '';
      final userAccountNumber = prefs.getString('userAccountNumber') ?? '';

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AccountScreen(
            isLoggedIn: true,
            userName: username,
            userEmail: email,
            phoneNumber: phone,
            userId: userId,
            userProfileImage: _userProfileImage,
            userAccountNumber: userAccountNumber,
          ),
        ),
      ).then((_) {
        // Refresh user data when returning from account screen
        _refreshUserData();
      });
    }
  }

  /// Build no internet screen
  Widget _buildNoInternetScreen() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off, size: 100, color: Colors.grey),
              const SizedBox(height: 20),
              const Text(
                'لا يوجد اتصال بالإنترنت',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _checkInitialConnectivity,
                child: const Text('إعادة المحاولة', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build loading screen
  Widget _buildLoadingScreen() {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }

  // ========== Main Build Method ==========

  @override
  Widget build(BuildContext context) {
    // Show loading screen while checking connectivity
    if (_isCheckingConnectivity) {
      return _buildLoadingScreen();
    }

    // Show no internet connection screen
    if (!_isConnected) {
      return _buildNoInternetScreen();
    }

    // Normal home screen when connected
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        drawer: _buildDrawer(context),
        body: Container(
          decoration: const BoxDecoration(color: Colors.white),
          child: CustomScrollView(
            controller: _adsScrollController,
            slivers: [
              SliverAppBar(
                floating: true,
                pinned: true,
                snap: false,
                elevation: 0,
                backgroundColor: Colors.blue[700],
                title: const Text(
                  'سوق سوريا',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                centerTitle: true,
                leading: Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.menu, size: 28, color: Colors.white),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                ),
              ),
              SliverToBoxAdapter(child: _buildLocationButton()),
              SliverToBoxAdapter(child: _buildSearchField()),
              const SliverToBoxAdapter(child: ImageSlider()),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Text(
                      'جميع الإعلانات',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E4A47),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 3,
                      width: 80,
                      decoration: BoxDecoration(
                        color: Colors.blue[600],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_allAds.isEmpty && _isLoadingAds)
                      const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                      ),
                    if (_allAds.isEmpty && !_isLoadingAds)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'لا يوجد نتائج',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'لم يتم العثور على أي إعلانات',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ]),
                ),
              ),
              if (_allAds.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.65,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == _allAds.length && _hasMoreAds) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                            ),
                          ),
                        );
                      }
                      return _buildAdCard(_allAds[index]);
                    },
                    childCount: _allAds.length + (_hasMoreAds ? 1 : 0),
                  ),
                ),
              ),
              if (!_hasMoreAds && _allAds.isNotEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Center(
                      child: Text(
                        'لا يوجد المزيد من الإعلانات',
                        style: TextStyle(color: Colors.grey),
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

/// Image slider widget for displaying promotional images
class ImageSlider extends StatefulWidget {
  const ImageSlider({super.key});

  @override
  State<ImageSlider> createState() => _ImageSliderState();
}

class _ImageSliderState extends State<ImageSlider> {
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

  /// Start automatic slide transition
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
    return SizedBox(
      height: 220,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: _imagePaths.length,
              onPageChanged: (index) => setState(() => _currentImageIndex = index),
              itemBuilder: (context, index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue[300]!, width: 1.5),
                  image: DecorationImage(
                    image: AssetImage(_imagePaths[index]),
                    fit: BoxFit.cover,
                  ),
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
                          ? Colors.blue[600]
                          : Colors.white.withOpacity(0.7),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
