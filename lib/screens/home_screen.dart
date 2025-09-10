import 'package:forsa/widgets/homeScreen/advance_search_wid.dart';
import 'package:forsa/widgets/homeScreen/title_search_wid.dart';
import '../widgets/homeScreen/most_activeUser_Wid.dart';
import '../models/ad_model.dart' as ad_models;
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:forsa/screens/search_advance_screen.dart';
import '../utils/dialog_utils.dart';
import '../utils/ad_card_widget.dart';
import 'account_screen.dart';
import 'add_ad_screen.dart';
import 'favorites_screen.dart';
import 'login_screen.dart';
import 'my_ads_screen.dart';
import 'suggestions_list_screen.dart';
import 'ad_details_screen.dart';
import '../widgets/homeScreen/image_slider_wid.dart';
import '../widgets/homeScreen/location_search_wid.dart';
import '../widgets/homeScreen/loading_dialog_wid.dart';
import '../widgets/homeScreen/no_results_wid.dart';
import '../widgets/homeScreen/full_screen_loading_wid.dart';


/// Home screen that displays advertisements with filtering and search capabilities
class HomeScreen extends StatefulWidget {
  final bool refreshOnStart;
  
  const HomeScreen({super.key, this.refreshOnStart = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  // ========== Most Active Users State ========== 
  List<Map<String, dynamic>> _mostActiveUsers = [];
  bool _isLoadingActiveUsers = false;
  bool _hasErrorActiveUsers = false;

  /// Fetch most active users
  Future<void> _fetchMostActiveUsers() async {
    setState(() {
      _isLoadingActiveUsers = true;
      _hasErrorActiveUsers = false;
    });
    try {
      final url = Uri.parse('https://sahbo-app-api.onrender.com/api/user/most-active?limit=10');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> users = jsonDecode(response.body);
        setState(() {
          _mostActiveUsers = users.cast<Map<String, dynamic>>();
          _isLoadingActiveUsers = false;
        });
      } else {
        setState(() {
          _isLoadingActiveUsers = false;
          _hasErrorActiveUsers = true;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingActiveUsers = false;
        _hasErrorActiveUsers = true;
      });
    }
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
  final List<ad_models.AdModel> _allAds = [];
  bool _isLoadingAds = false;
  bool _isRefreshing = false;
  int _currentPageAds = 1;
  bool _hasMoreAds = true;

  // ========== Controllers & State ==========
  final TextEditingController _searchController = TextEditingController();
  late ScrollController _adsScrollController;
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
  _fetchMostActiveUsers();
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
            _allAds.addAll(fetchedAds.map((ad) => ad_models.AdModel.fromJson(ad)));
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
    await LocationButtonWid.fetchFilteredAds(
      context: context,
      currentPageAds: _currentPageAds,
      limitAds: _limitAds,
      selectedCityId: _selectedCityId,
      selectedRegionId: _selectedRegionId,
      onResult: (ads, hasMoreAds) {
        setState(() {
          if (reset) _allAds.clear();
          _allAds.addAll(ads.map((ad) => ad_models.AdModel.fromJson(ad)));
          _currentPageAds++;
          _isLoadingAds = false;
          _hasMoreAds = hasMoreAds;
        });
      },
      reset: reset,
    );
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
            _allAds.addAll(fetchedAds.map((ad) => ad_models.AdModel.fromJson(ad)));
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
      // Prevent repeated calls if already loading or no more ads
      if (_isLoadingAds || !_hasMoreAds) return;
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

  // ...existing code...

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
                  'فرصة 2025',
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
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(height: 240, color: Colors.blue);
        }
        final prefs = snapshot.data!;
        final firstName = prefs.getString('userFirstName') ?? '';
        final lastName = prefs.getString('userLastName') ?? '';
        final profileImage = prefs.getString('userProfileImage');
        ImageProvider? avatar;
        if (profileImage != null && profileImage.isNotEmpty) {
          try {
            avatar = MemoryImage(base64Decode(profileImage));
          } catch (e) {
            avatar = null;
          }
        }
        return Container(
          width: double.infinity,
          height: 240,
          decoration: BoxDecoration(
            color: Colors.blue,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white,
                backgroundImage: avatar,
                child: avatar == null ? Icon(Icons.person, size: 40, color: Colors.blue) : null,
              ),
              const SizedBox(height: 12),
              Text(
                '$firstName $lastName',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
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
                      fontWeight: FontWeight.bold,
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
      //final username = (prefs.getString('userFirstName') ?? '') + ' ' + (prefs.getString('userLastName') ?? '');
      final userFirstName = prefs.getString('userFirstName') ?? '';
      final userLastName = prefs.getString('userLastName') ?? '';
      final email = prefs.getString('userEmail') ?? '';
      final phone = prefs.getString('userPhone') ?? '';
      final userId = prefs.getString('userId') ?? '';
      final userAccountNumber = prefs.getString('userAccountNumber') ?? '';

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AccountScreen(
            isLoggedIn: true,
            //userName: username,
            userFirstName: userFirstName,
            userLastName: userLastName,
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


  // ========== Refresh Handler ==========


  // ========== Main Build Method ==========

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    // Show no internet connection screen
    if (!_isConnected) {
      return _buildNoInternetScreen();
    }

    // Always show the header (AppBar, Drawer), only replace the main content slivers with loading widget
    return Directionality(
      textDirection: TextDirection.rtl,
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Scaffold(
          drawer: _buildDrawer(context),
          body: Container(
            decoration: const BoxDecoration(color: Colors.white),
            child: CustomScrollView(
              controller: _adsScrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Always show header slivers
                SliverAppBar(
                  floating: true,
                  pinned: true,
                  snap: false,
                  elevation: 0,
                  backgroundColor: Colors.blue[700],
                  title: Text(
                    'الرئيسية',
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
                  actions: [
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () async {
                          if (_authToken != null && _userId != null) {
                            final prefs = await SharedPreferences.getInstance();
                            final userFirstName = prefs.getString('userFirstName') ?? '';
                            final userLastName = prefs.getString('userLastName') ?? '';
                            final email = prefs.getString('userEmail') ?? '';
                            final phone = prefs.getString('userPhone') ?? '';
                            final userId = prefs.getString('userId') ?? '';
                            final userAccountNumber = prefs.getString('userAccountNumber') ?? '';
                            final userProfileImage = prefs.getString('profileImage') ?? _userProfileImage;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AccountScreen(
                                  isLoggedIn: true,
                                  userFirstName: userFirstName,
                                  userLastName: userLastName,
                                  userEmail: email,
                                  phoneNumber: phone,
                                  userId: userId,
                                  userProfileImage: userProfileImage,
                                  userAccountNumber: userAccountNumber,
                                ),
                              ),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                            );
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                            border: Border.all(
                              color: (_authToken != null && _userId != null)
                                  ? Colors.green[600]!
                                  : Colors.blue[300]!,
                              width: 1.5,
                            ),
                          ),
                          padding: const EdgeInsets.all(2),
                          child: Icon(
                            Icons.person_rounded, // User account icon
                            size: 22,
                            color: (_authToken != null && _userId != null)
                                ? Colors.green[600]
                                : Colors.blue[300],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SliverToBoxAdapter(child: ImageSliderWid()),
                SliverToBoxAdapter(
                  child: LocationButtonWid(
                    selectedCity: _selectedCity,
                    defaultCity: _defaultCity,
                    selectedDistrict: _selectedDistrict,
                    defaultDistrict: _defaultDistrict,
                    onTap: _showLocationFilterDialog,
                  ),
                ),
                SliverToBoxAdapter(
                  child: AdvanceSearchWid(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SearchAdvanceScreen()),
                      );
                    },
                  ),
                ),
                SliverToBoxAdapter(
                  child: TitleSearchWid(
                    initialText: _searchController.text,
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
                  ),
                ),
                // Main content area: show loading widget or actual content
                if (_isCheckingConnectivity || _isLoadingAds || _isRefreshing)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: const FullScreenLoadingWid(),
                  )
                else ...[
                  SliverToBoxAdapter(
                    child: MostActiveUserWid(
                      mostActiveUsers: _mostActiveUsers,
                      isLoading: _isLoadingActiveUsers,
                      hasError: _hasErrorActiveUsers,
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        Text(
                          'جميع الإعلانات',
                          style: GoogleFonts.cairo(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
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
                        if (_allAds.isEmpty && !_isLoadingAds)
                          const NoResultsWid(),
                      ]),
                    ),
                  ),
                  if (_allAds.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
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
                              onTap: () {
                                final adId = _allAds[index].id;
                                if (adId != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AdDetailsScreen(adId: adId),
                                    ),
                                  );
                                }
                              },
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLocationFilterDialog() async {
    await LocationButtonWid.showLocationFilterDialog(
      context: context,
      defaultCity: _defaultCity,
      defaultDistrict: _defaultDistrict,
      provinces: _provinces,
      majorAreas: _majorAreas,
      selectedCityId: _selectedCityId,
      selectedRegionId: _selectedRegionId,
      onApply: ({cityName, districtName, cityId, regionId}) async {
        setState(() {
          _selectedCity = cityName ?? _defaultCity;
          _selectedDistrict = districtName ?? _defaultDistrict;
          _selectedCityId = cityId;
          _selectedRegionId = regionId;
          _currentPageAds = 1;
        });
        // Show loading dialog using LoadingDialogWid
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const LoadingDialogWid(
              message: 'جاري البحث حسب الموقع',
              showProgress: true,
            );
          },
        );
        await _fetchFilteredAds(reset: true);
        // Hide loading dialog
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }
      },
    );
  }
}
