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
import '../widgets/homeScreen/app_drawer_wid.dart';
import '../widgets/no_internet_wid.dart';


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
  // Fetch all ads first, then fetch most active users
  _fetchAllAds().then((_) => _fetchMostActiveUsers());
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

  // ========== Main Build Method ==========

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    if (!_isConnected) {
      return NoInternetWid(onRetry: _checkInitialConnectivity);
    }

    // Define custom colors
  const Color primaryColor = Color(0xFF42A5F5); // Light Blue (matches الرئيسية in drawer)
  const Color accentColor = Color(0xFFFF7043); // Soft Orange
  const Color backgroundColor = Color(0xFFFAFAFA); // White
  const Color textColor = Color(0xFF212121); // Dark Black
  const Color outlineColor = Color(0xFFE0E3E7); // Soft Gray
  const Color successColor = Color(0xFF66BB6A); // Green

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        drawer: AppDrawer(
          reloadHomeScreen: (ctx) => _reloadHomeScreen(),
          handleProtectedNavigation: (ctx, routeKey) => _handleProtectedNavigation(ctx, routeKey),
          handleAccountNavigation: (ctx) => _handleAccountNavigation(ctx),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _handleProtectedNavigation(context, 'addAd'),
          backgroundColor: accentColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.add_circle_outline_rounded, size: 32, color: Colors.white),
        ),
        body: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
          ),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              if (FocusScope.of(context).hasFocus) {
                FocusScope.of(context).unfocus();
              }
            },
            child: CustomScrollView(
              controller: _adsScrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar(
                  floating: true,
                  pinned: true,
                  snap: false,
                  elevation: 4,
                  backgroundColor: primaryColor,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                  ),
                  title: Text(
                    'الرئيسية',
                    style: GoogleFonts.cairo(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  centerTitle: true,
                  leading: Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu, size: 40), // Increased icon size
                      color: textColor,
                      iconSize: 48, // Increased button size
                      padding: const EdgeInsets.all(8), // More touch area
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
                            color: backgroundColor,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            border: Border.all(
                color: (_authToken != null && _userId != null)
                  ? successColor
                  : accentColor,
                width: 2,
                            ),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Icon(
              Icons.person_rounded,
              size: 26,
              color: (_authToken != null && _userId != null)
                ? successColor
                : accentColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 10)),
                SliverToBoxAdapter(child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: ImageSliderWid(),
                )),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: LocationButtonWid(
                      selectedCity: _selectedCity,
                      defaultCity: _defaultCity,
                      selectedDistrict: _selectedDistrict,
                      defaultDistrict: _defaultDistrict,
                      onTap: _showLocationFilterDialog,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: AdvanceSearchWid(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SearchAdvanceScreen()),
                        );
                      },
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
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
                ),
                if (_isCheckingConnectivity || _isLoadingAds || _isRefreshing)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: const FullScreenLoadingWid(),
                  )
                else ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: MostActiveUserWid(
                        mostActiveUsers: _mostActiveUsers,
                        isLoading: _isLoadingActiveUsers,
                        hasError: _hasErrorActiveUsers,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        Text(
                          'جميع الإعلانات',
                          style: GoogleFonts.cairo(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 4,
                          width: 100,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [primaryColor, accentColor],
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_allAds.isEmpty && !_isLoadingAds)
                          const NoResultsWid(),
                      ]),
                    ),
                  ),
                  if (_allAds.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                          childAspectRatio: 0.82,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index == _allAds.length && _hasMoreAds) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(3),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            final ad = _allAds[index];
                            return Material(
                              elevation: 3,
                              borderRadius: BorderRadius.circular(18),
                              color: backgroundColor,
                              child: AdCardWidget(
                                key: ValueKey(ad.id),
                                ad: ad,
                                favoriteIconBuilder: _favoriteHeartIconBuilder,
                                onTap: () {
                                  final adId = ad.id;
                                  if (adId != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AdDetailsScreen(adId: adId),
                                      ),
                                    );
                                  }
                                },
                              ),
                            );
                          },
                          childCount: _allAds.length + (_hasMoreAds ? 1 : 0),
                        ),
                      ),
                    ),
                  if (!_hasMoreAds && _allAds.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        child: Center(
                          child: Text(
                            'لا يوجد المزيد من الإعلانات',
                            style: GoogleFonts.cairo(
                              color: outlineColor,
                              fontSize: 16,
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
