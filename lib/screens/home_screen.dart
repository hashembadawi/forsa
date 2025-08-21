import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syria_market/screens/search_advance_screen.dart';
import '../utils/dialog_utils.dart';
import '../utils/ad_card_widget.dart';
import 'account_screen.dart';
import 'add_ad_screen.dart';
import 'favorites_screen.dart';
import 'login_screen.dart';
import 'my_ads_screen.dart';
import 'suggestions_list_screen.dart';

// Data models for better type safety
class AdModel {
  final String? id;
  final String? adTitle;
  final String? description;
  final String? price;
  final String? currencyName;
  final String? categoryName;
  final String? subCategoryName;
  final String? cityName;
  final String? regionName;
  final String? userName;
  final String? userPhone;
  final String? userId;
  final String? categoryId;
  final String? subCategoryId;
  final String? createDate;
  final List<String>? images;
  final Map<String, dynamic>? location;
  final bool? isSpecial;
  final bool? forSale;
  final bool? deliveryService;

  AdModel({
    this.id,
    this.adTitle,
    this.description,
    this.price,
    this.currencyName,
    this.categoryName,
    this.subCategoryName,
    this.cityName,
    this.regionName,
    this.userName,
    this.userPhone,
    this.userId,
    this.categoryId,
    this.subCategoryId,
    this.createDate,
    this.images,
    this.location,
    this.isSpecial,
    this.forSale,
    this.deliveryService,
  });

  factory AdModel.fromJson(Map<String, dynamic> json) {
    return AdModel(
      id: json['_id'],
      adTitle: json['adTitle'],
      description: json['description'],
      price: json['price']?.toString(),
      currencyName: json['currencyName'],
      categoryName: json['categoryName'],
      subCategoryName: json['subCategoryName'],
      cityName: json['cityName'],
      regionName: json['regionName'],
      userName: json['userName'],
      userPhone: json['userPhone'],
      userId: json['userId'],
      categoryId: json['categoryId']?.toString(),
      subCategoryId: json['subCategoryId']?.toString(),
      createDate: json['createDate'],
      images: json['images'] is List ? List<String>.from(json['images']) : null,
      location: json['location'] is Map<String, dynamic> ? json['location'] : null,
      isSpecial: json['isSpecial'] ?? false, // Default to false if not present
      forSale: json['forSale'] ?? false, // Default to false if not present
      deliveryService: json['deliveryService'] ?? false, // Default to false if not present
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'adTitle': adTitle,
      'description': description,
      'price': price,
      'currencyName': currencyName,
      'categoryName': categoryName,
      'subCategoryName': subCategoryName,
      'cityName': cityName,
      'regionName': regionName,
      'userName': userName,
      'userPhone': userPhone,
      'userId': userId,
      'categoryId': categoryId,
      'subCategoryId': subCategoryId,
      'createDate': createDate,
      'images': images,
      'location': location,
      'isSpecial': isSpecial,
      'forSale': forSale,
      'deliveryService': deliveryService,
    };
  }
}

class LocationModel {
  final int? id;
  final String? name;
  final int? provinceId;

  LocationModel({this.id, this.name, this.provinceId});

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id'],
      name: json['name'],
      provinceId: json['ProvinceId'],
    );
  }
}

/// Home screen that displays advertisements with filtering and search capabilities
class HomeScreen extends StatefulWidget {
  final bool refreshOnStart;
  
  const HomeScreen({super.key, this.refreshOnStart = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  /// Build advanced search field
  Widget _buildAdvancedSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SearchAdvanceScreen()),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.blue[300]!, width: 1.5),
          ),
          child: Row(
            children: [
              Icon(Icons.tune, color: Colors.blue[600]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'بحث متقدم',
                  style: GoogleFonts.cairo(
                    color: Colors.black87,
                    fontSize: 16,
                    
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
  final List<AdModel> _allAds = [];
  bool _isLoadingAds = false;
  bool _isRefreshing = false;
  int _currentPageAds = 1;
  bool _hasMoreAds = true;

  // ========== Controllers & State ==========
  final TextEditingController _searchController = TextEditingController();
  late ScrollController _adsScrollController;
  String? _username;
  String? _userProfileImage;
  
  // ========== Favorites State ==========
  final Set<String> _favoriteAdIds = {};
  bool _isLoadingFavorites = false;
  String? _authToken;
  String? _userId;
  
  // ========== Connectivity State ==========
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  bool _isConnected = true;
  bool _isCheckingConnectivity = true;

  // ========== Image Cache ==========

  @override
  bool get wantKeepAlive => true;

  // Optimized image decoding with caching

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
      if (mounted) {
        setState(() {
          _isConnected = connectivityResult != ConnectivityResult.none;
          _isCheckingConnectivity = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnected = false;
          _isCheckingConnectivity = false;
        });
      }
    }
  }

  /// Subscribe to connectivity changes
  void _subscribeToConnectivityChanges() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (ConnectivityResult result) {
        if (mounted) {
          setState(() {
            _isConnected = result != ConnectivityResult.none;
          });
        }
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
        if (mounted) {
          setState(() {
            _provinces = List<Map<String, dynamic>>.from(data['Province'] ?? []);
            _majorAreas = List<Map<String, dynamic>>.from(data['majorAreas'] ?? []);
          });
        }
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
      if (mounted) {
        setState(() {
          _username = null;
          _userProfileImage = null;
          _authToken = null;
          _userId = null;
          _favoriteAdIds.clear();
        });
      }
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
        if (mounted) {
          setState(() {
            _username = prefs.getString('userName') ?? 'مستخدم';
            // Try different possible keys for profile image
            _userProfileImage = prefs.getString('profileImage') ?? 
                               prefs.getString('userProfileImage');
            _authToken = token;
            _userId = prefs.getString('userId');
          });
        }
        
        // Fetch favorites after validation
        await _fetchUserFavorites();
      } else {
        await prefs.clear();
        if (mounted) {
          setState(() {
            _username = null;
            _userProfileImage = null;
            _authToken = null;
            _userId = null;
            _favoriteAdIds.clear();
          });
        }
      }
    } catch (e) {
      if (!rememberMe) {
        await prefs.clear();
      }
      if (mounted) {
        setState(() {
          _username = null;
          _userProfileImage = null;
          _authToken = null;
          _userId = null;
          _favoriteAdIds.clear();
        });
      }
    }
  }

  /// Clear user data if not remembered
  void _clearUserDataIfNeeded(SharedPreferences prefs, bool rememberMe) {
    if (!rememberMe) {
      prefs.clear();
    }
    if (mounted) {
      setState(() {
        _username = null;
        _userProfileImage = null;
        _authToken = null;
        _userId = null;
        _favoriteAdIds.clear();
      });
    }
  }

  /// Refresh user data from SharedPreferences
  Future<void> _refreshUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token != null && token.isNotEmpty) {
        if (mounted) {
          setState(() {
            _username = prefs.getString('userName') ?? 'مستخدم';
            // Try different possible keys for profile image
            _userProfileImage = prefs.getString('profileImage') ?? 
                               prefs.getString('userProfileImage');
            _authToken = token;
            _userId = prefs.getString('userId');
          });
        }
        
        // Fetch favorites after updating auth data
        await _fetchUserFavorites();
      } else {
        if (mounted) {
          setState(() {
            _username = null;
            _userProfileImage = null;
            _authToken = null;
            _userId = null;
            _favoriteAdIds.clear();
          });
        }
      }
    } catch (e) {
      debugPrint('Error refreshing user data: $e');
    }
  }

  /// Fetch user's favorite advertisements
  Future<void> _fetchUserFavorites() async {
    if (_authToken == null || _userId == null) return;

    if (mounted) {
      setState(() => _isLoadingFavorites = true);
    }

    try {
      final url = Uri.parse('$_baseUrl/api/favorites/my-favorites?page=1&limit=1000');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $_authToken',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> favorites = decoded['favorites'] ?? [];
        
        // Extract ad IDs from favorites
        final favoriteIds = favorites
            .map((fav) => fav['ad']?['_id'] as String?)
            .where((id) => id != null)
            .cast<String>()
            .toSet();

        if (mounted) {
          setState(() {
            _favoriteAdIds.clear();
            _favoriteAdIds.addAll(favoriteIds);
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching favorites: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingFavorites = false);
      }
    }
  }

  /// Check if an ad is in favorites
  bool _isAdInFavorites(String adId) {
    return _favoriteAdIds.contains(adId);
  }

  /// Fetch all advertisements
  Future<void> _fetchAllAds() async {
    if (_isLoadingAds || !_hasMoreAds) return;

    if (mounted) {
      setState(() => _isLoadingAds = true);
    }

    try {
      final url = Uri.parse('$_baseUrl/api/ads?page=$_currentPageAds&limit=$_limitAds');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> fetchedAds = decoded['ads'] ?? [];

        if (mounted) {
          setState(() {
            _allAds.addAll(fetchedAds.map((ad) => AdModel.fromJson(ad)));
            _currentPageAds++;
            _isLoadingAds = false;
            _hasMoreAds = fetchedAds.length >= _limitAds;
          });
        }
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

    if (mounted) {
      setState(() => _isLoadingAds = true);
    }

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

        if (mounted) {
          setState(() {
            if (reset) _allAds.clear();
            _allAds.addAll(fetchedAds.map((ad) => AdModel.fromJson(ad)));
            _currentPageAds++;
            _isLoadingAds = false;
            _hasMoreAds = fetchedAds.length >= _limitAds;
          });
        }
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

    if (mounted) {
      setState(() => _isLoadingAds = true);
    }

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

        if (mounted) {
          setState(() {
            if (reset) _allAds.clear();
            _allAds.addAll(fetchedAds.map((ad) => AdModel.fromJson(ad)));
            _currentPageAds++;
            _isLoadingAds = false;
            _hasMoreAds = fetchedAds.length >= _limitAds;
          });
        }
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
    if (mounted) {
      setState(() {
        _isLoadingAds = false;
        _hasMoreAds = false;
      });
    }
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
    if (mounted) {
      setState(() {
        _resetFilters();
        _resetAdsData();
      });
    }
    
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
    DialogUtils.showConfirmationDialog(
      context: context,
      title: 'تسجيل الدخول مطلوب',
      message: 'يجب تسجيل الدخول للوصول إلى هذه الصفحة.',
      confirmText: 'تسجيل دخول',
      cancelText: 'إلغاء',
      onConfirm: () async {
        await prefs.setString('redirect_to', routeKey);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      },
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
      case 'favorites':
        targetPage = const FavoritesScreen();
        break;
    }

    if (targetPage != null) {
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => targetPage!),
      ).then((_) {
        // Refresh favorites when returning from favorites screen
        if (routeKey == 'favorites' && _authToken != null && _userId != null) {
          _fetchUserFavorites();
        }
      });
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
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(16),
            child: Container(
              width: double.maxFinite,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Blue Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Text(
                      'بحث حسب الموقع',
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // White Body
                  Container(
                    width: double.maxFinite,
                    padding: const EdgeInsets.all(20),
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
                            DropdownMenuItem<Map<String, dynamic>>(
                              value: null,
                              child: Text(
                                'كل المحافظات',
                                style: GoogleFonts.cairo(
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
                                style: GoogleFonts.cairo(
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
                            DropdownMenuItem<Map<String, dynamic>>(
                              value: null,
                              child: Text(
                                'كل المناطق',
                                style: GoogleFonts.cairo(
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
                                style: GoogleFonts.cairo(
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
                        const SizedBox(height: 20),
                        // Action buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.grey[600],
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                ),
                                child: Text(
                                  'إلغاء',
                                  style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  if (mounted) {
                                    setState(() {
                                      _selectedCity = tempSelectedProvince?['name'] ?? _defaultCity;
                                      _selectedDistrict = tempSelectedArea?['name'] ?? _defaultDistrict;
                                      _selectedCityId = tempSelectedProvince?['id'];
                                      _selectedRegionId = tempSelectedArea?['id'];
                                      _resetAdsData();
                                    });
                                  }
                                  
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
                                  elevation: 0,
                                ),
                                child: Text(
                                  'تطبيق',
                                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Build dropdown decoration
  InputDecoration _buildDropdownDecoration(String labelText, double borderRadius) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: GoogleFonts.cairo(color: Colors.blue[600]),
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
    return GoogleFonts.cairo(
      color: Colors.blue,
      fontSize: 15,
      fontWeight: FontWeight.w500,
    );
  }

  // ========== Widget Building Methods ==========

  // Use AdCardWidget directly in your list/grid views:
  // AdCardWidget(
  //   ad: ad,
  //   favoriteIconBuilder: (adId) => _buildFavoriteHeartIcon(adId),
  // )
  // Favorite heart icon builder for AdCardWidget
  Widget _favoriteHeartIconBuilder(String adId) {
    final bool isLoggedIn = _authToken != null && _userId != null;
    final bool isFavorite = isLoggedIn ? _isAdInFavorites(adId) : false;
    return defaultFavoriteHeartIcon(
      adId,
      isFavorite: isFavorite,
      isLoggedIn: isLoggedIn,
      isLoading: isLoggedIn && _isLoadingFavorites,
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
                  Text(
                    'بحث بالموقع',
                    style: GoogleFonts.cairo(
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
                style: GoogleFonts.cairo(fontSize: 15, color: Colors.grey[700]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build search field with autocomplete suggestions
  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SuggestionsListScreen(
                initialSearchText: _searchController.text,
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.blue[300]!, width: 1.5),
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: Colors.blue[600]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _searchController.text.isNotEmpty 
                      ? _searchController.text
                      : 'ابحث عن منتج أو خدمة...',
                  style: GoogleFonts.cairo(
                    color: _searchController.text.isNotEmpty 
                        ? Colors.black87 
                        : Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build navigation drawer
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.grey[50],
      elevation: 0,
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
                    Icons.favorite_rounded, 
                    'المفضلة', 
                    Colors.red[600]!,
                    () {
                      _handleProtectedNavigation(context, 'favorites');
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
                  style: GoogleFonts.cairo(
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
              style: GoogleFonts.cairo(
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
                    style: GoogleFonts.cairo(
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
              Text(
                'لا يوجد اتصال بالإنترنت',
                style: GoogleFonts.cairo(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى',
                style: GoogleFonts.cairo(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _checkInitialConnectivity,
                child: Text('إعادة المحاولة', style: GoogleFonts.cairo(fontSize: 16)),
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

  // ========== Refresh Handler ==========

  /// Handle pull-to-refresh
  Future<void> _handleRefresh() async {
    // Set refreshing state
    if (mounted) {
      setState(() {
        _isRefreshing = true;
        _resetFilters();
        _resetAdsData();
      });
    }
    
    try {
      // Fetch fresh data
      await Future.wait([
        _fetchOptions(),
        _refreshUserData(),
      ]);
      
      await _fetchAllAds();
    } finally {
      // Clear refreshing state
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  // ========== Main Build Method ==========

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
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
      child: GestureDetector(
        onTap: () {
          // Unfocus any text fields
          FocusScope.of(context).unfocus();
        },
        child: Scaffold(
          drawer: _buildDrawer(context),
          body: Container(
          decoration: const BoxDecoration(color: Colors.white),
          child: RefreshIndicator(
            onRefresh: _handleRefresh,
            color: Colors.blue[600],
            backgroundColor: Colors.white,
            strokeWidth: 2.5,
            child: CustomScrollView(
              controller: _adsScrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
              SliverAppBar(
                floating: true,
                pinned: true,
                snap: false,
                elevation: 0,
                backgroundColor: Colors.blue[700],
                title: Text(
                  'سوق سوريا',
                  style: GoogleFonts.cairo(
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
              const SliverToBoxAdapter(child: ImageSlider()),
              SliverToBoxAdapter(child: _buildLocationButton()),
              SliverToBoxAdapter(child: _buildAdvancedSearchField()),
              SliverToBoxAdapter(child: _buildSearchField()),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Text(
                      'جميع الإعلانات',
                      style: GoogleFonts.cairo(
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
                    if (_isRefreshing)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'جاري تحديث الإعلانات...',
                                style: GoogleFonts.cairo(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (_allAds.isEmpty && _isLoadingAds)
                      const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                      )
                    else if (_allAds.isEmpty && !_isLoadingAds)
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
                                style: GoogleFonts.cairo(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'لم يتم العثور على أي إعلانات',
                                style: GoogleFonts.cairo(
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
              if (_allAds.isNotEmpty || _isRefreshing)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 6), // Slight padding from screen edge
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                      childAspectRatio: 0.82,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == _allAds.length && _hasMoreAds) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(5),
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                              ),
                            ),
                          );
                        }
                        return AdCardWidget(
                          ad: _allAds[index],
                          favoriteIconBuilder: _favoriteHeartIconBuilder,
                        );
                      },
                      childCount: _allAds.length + (_hasMoreAds ? 1 : 0),
                    ),
                  ),
                ),
              if (!_hasMoreAds && _allAds.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Center(
                      child: Text(
                        'لا يوجد المزيد من الإعلانات',
                        style: GoogleFonts.cairo(
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
            ),
          ),
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
