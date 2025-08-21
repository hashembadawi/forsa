import 'home_screen.dart' as home;
import '../utils/ad_card_widget.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

import 'ad_details_screen.dart';

class AdvertiserPageScreen extends StatefulWidget {
  final String userId;
  final String? initialUserName;
  final String? initialUserPhone;

  const AdvertiserPageScreen({
    super.key,
    required this.userId,
    this.initialUserName,
    this.initialUserPhone,
  });

  @override
  State<AdvertiserPageScreen> createState() => _AdvertiserPageScreenState();
}

class _AdvertiserPageScreenState extends State<AdvertiserPageScreen> {
  // Constants
  static const int _limitAds = 10;

  // User info state
  Map<String, dynamic>? _userInfo;
  bool _isLoadingUserInfo = false;
  bool _hasErrorUserInfo = false;

  // Ads state
  List<dynamic> _userAds = [];
  bool _isLoadingAds = false;
  bool _hasErrorAds = false;
  int _currentPage = 1;
  bool _hasMoreAds = true;
  int _totalAds = 0;

  // Controllers
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    _fetchAdvertiserData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ========== Data Fetching Methods ==========

  /// Fetch advertiser data (user info and ads)
  Future<void> _fetchAdvertiserData({bool reset = false}) async {
    if (_isLoadingAds || (!_hasMoreAds && !reset)) return;

    setState(() {
      if (reset) {
        _isLoadingUserInfo = true;
        _hasErrorUserInfo = false;
        _hasErrorAds = false;
        _currentPage = 1;
        _hasMoreAds = true;
        _userAds.clear();
      }
      _isLoadingAds = true;
    });

    try {
      
      final url = Uri.parse('https://sahbo-app-api.onrender.com/api/ads/advertiser/${widget.userId}?page=$_currentPage&limit=$_limitAds');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> fetchedAds = decoded['ads'] ?? [];
        final userInfo = decoded['user'];
        final total = decoded['total'] ?? 0;

        setState(() {
          if (reset || _userInfo == null) {
            _userInfo = userInfo;
            _totalAds = total;
          }
          
          _userAds.addAll(fetchedAds);
          _currentPage++;
          _isLoadingAds = false;
          _isLoadingUserInfo = false;
          _hasErrorAds = false;
          _hasErrorUserInfo = false;
          _hasMoreAds = fetchedAds.length >= _limitAds;
        });
      } else {
        _handleFetchError();
      }
    } catch (e) {
      debugPrint('Exception fetching advertiser data: $e');
      _handleFetchError();
    }
  }

  /// Handle fetch error
  void _handleFetchError() {
    setState(() {
      _isLoadingAds = false;
      _isLoadingUserInfo = false;
      _hasErrorAds = true;
      _hasErrorUserInfo = true;
      _hasMoreAds = false;
    });
  }

  /// Handle scroll for pagination
  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _fetchAdvertiserData();
    }
  }

  /// Retry loading data
  void _retryLoading() {
    _fetchAdvertiserData(reset: true);
  }

  // ========== UI Helper Methods ==========

  /// Build loading screen
  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
          ),
          const SizedBox(height: 16),
          Text(
            'جارٍ تحميل معلومات المعلن...',
            style: GoogleFonts.cairo(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  /// Build error screen
  Widget _buildErrorScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.orange[600],
          ),
          const SizedBox(height: 16),
          Text(
            'حدث خطأ في تحميل معلومات المعلن',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _retryLoading,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'إعادة المحاولة',
              style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  /// Build pagination loading indicator
  Widget _buildPaginationLoading() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
        ),
      ),
    );
  }

  // ========== Widget Building Methods ==========

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

  /// Build app bar
  AppBar _buildAppBar() {
    return AppBar(
      title: Text(
        'صفحة المعلن',
        style: GoogleFonts.cairo(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      backgroundColor: Colors.blue[700],
      elevation: 4,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      centerTitle: true,
    );
  }

  /// Build main body
  Widget _buildBody() {
    if (_isLoadingUserInfo && _userAds.isEmpty) {
      return _buildLoadingScreen();
    }

    if (_hasErrorUserInfo && _userAds.isEmpty) {
      return _buildErrorScreen();
    }

    return Container(
      color: Colors.white,
      child: RefreshIndicator(
        onRefresh: () => _fetchAdvertiserData(reset: true),
        child: ListView(
          controller: _scrollController,
          children: [
            // User Info Section
            _buildUserInfoSection(),
            
            const SizedBox(height: 16),
            
            // Ads Section
            _buildAdsSection(),
            
            // Loading indicator for pagination
            if (_isLoadingAds && _userAds.isNotEmpty)
              _buildPaginationLoading(),
              
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Build user info section
  Widget _buildUserInfoSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.blue[300]!,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.person, size: 24, color: Colors.blue[600]),
                const SizedBox(width: 8),
                Text(
                  'معلومات المعلن',
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Profile picture and basic info
            Row(
              children: [
                // Profile picture
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.blue[300]!, width: 2),
                    color: Colors.grey[200],
                  ),
                  child: _buildProfileImage(),
                ),
                
                const SizedBox(width: 16),
                
                // User info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildUserInfoRow(
                        Icons.person,
                        'الاسم',
                        _userInfo?['name'] ?? widget.initialUserName ?? 'غير متوفر',
                      ),
                      const SizedBox(height: 8),
                      _buildUserInfoRow(
                        Icons.phone,
                        'الهاتف',
                        _userInfo?['phoneNumber'] ?? widget.initialUserPhone ?? 'غير متوفر',
                      ),
                      const SizedBox(height: 8),
                      _buildUserInfoRow(
                        Icons.ad_units,
                        'عدد الإعلانات',
                        '$_totalAds إعلان',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build profile image
  Widget _buildProfileImage() {
    final profilePicture = _userInfo?['profilePicture'];
    
    if (profilePicture != null && profilePicture.isNotEmpty) {
      try {
        return ClipOval(
          child: Image.memory(
            base64Decode(profilePicture),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) => _buildDefaultProfileIcon(),
          ),
        );
      } catch (e) {
        return _buildDefaultProfileIcon();
      }
    } else {
      return _buildDefaultProfileIcon();
    }
  }

  /// Build default profile icon
  Widget _buildDefaultProfileIcon() {
    return Icon(
      Icons.person,
      size: 40,
      color: Colors.blue[400],
    );
  }

  /// Build user info row
  Widget _buildUserInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.blue[600]),
        const SizedBox(width: 6),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.cairo(fontSize: 14, color: Colors.black87),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: value,
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Build ads section
  Widget _buildAdsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.blue[300]!,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[600],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.ad_units, size: 24, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'إعلانات المعلن ($_totalAds)',
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          // Ads content
          _buildAdsContent(),
        ],
      ),
    );
  }

  /// Build ads content based on state
  Widget _buildAdsContent() {
    if (_hasErrorAds && _userAds.isEmpty) {
      return _buildAdsError();
    }
    
    if (_userAds.isEmpty && !_isLoadingAds) {
      return _buildNoAds();
    }
    
    return _buildAdsList();
  }

  /// Build ads error widget
  Widget _buildAdsError() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 60,
            color: Colors.orange[600],
          ),
          const SizedBox(height: 16),
          Text(
            'حدث خطأ في تحميل الإعلانات',
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _retryLoading,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'إعادة المحاولة',
              style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  /// Build no ads widget
  Widget _buildNoAds() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 60,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد إعلانات لهذا المعلن',
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build ads list
  Widget _buildAdsList() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double cardWidth = constraints.maxWidth * 0.92;
          final double cardHeight = 290.0;
          if (_userAds.length <= 1) {
            // Show single card (no sliding)
            return Center(
              child: SizedBox(
                width: cardWidth,
                height: cardHeight,
                child: _userAds.isNotEmpty
                    ? AdCardWidget(
                        ad: home.AdModel.fromJson(_userAds[0]),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => AdDetailsScreen(ad: _userAds[0])),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            );
          } else {
            // Show PageView for sliding with dots below
            return SizedBox(
              height: cardHeight + 32,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: cardHeight,
                    child: PageView.builder(
                      itemCount: _userAds.length,
                      itemBuilder: (context, index) {
                        final ad = _userAds[index];
                        final adModel = home.AdModel.fromJson(ad);
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: AdCardWidget(
                            ad: adModel,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => AdDetailsScreen(ad: ad)),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_userAds.length, (index) {
                      // For now, always show as inactive (no controller)
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
