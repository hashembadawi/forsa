import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'account_screen.dart';
import 'add_ad_screen.dart';
import 'login_screen.dart';
import 'my_ads_screen.dart';
import 'select_location_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedCity = 'كل المحافظات';
  String selectedDistrict = 'كل المناطق';

  List<IconData> categoryIcons = [
    Icons.pets,
    Icons.groups,
    Icons.checkroom,
    Icons.build,
    Icons.chair,
    Icons.devices,
    Icons.home_work,
    Icons.directions_car,
  ];

  List<String> imagePaths = [
    'assets/image1.jpg',
    'assets/image2.jpg',
    'assets/image3.jpg',
  ];

  int _currentImageIndex = 0;
  late PageController _pageController;
  Timer? _sliderTimer;
  String? _username;

  // لإعلانات العرض
  List<dynamic> allAds = [];
  bool isLoadingAds = false;
  int currentPageAds = 1;
  final int limitAds = 10;
  bool hasMoreAds = true;
  late ScrollController _adsScrollController;

  @override
  void initState() {
    super.initState();
    _loadUsername();
    _pageController = PageController(viewportFraction: 1.0);
    _startAutoSlide();

    _adsScrollController = ScrollController()..addListener(_onAdsScroll);
    fetchAllAds();
  }

  @override
  void dispose() {
    _sliderTimer?.cancel();
    _pageController.dispose();
    _adsScrollController.dispose();
    super.dispose();
  }

  void _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username');
    });
  }

  void _startAutoSlide() {
    _sliderTimer = Timer.periodic(Duration(seconds: 4), (_) {
      if (_pageController.hasClients) {
        int nextPage = (_currentImageIndex + 1) % imagePaths.length;
        _pageController.animateToPage(
          nextPage,
          duration: Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> fetchAllAds() async {
    if (isLoadingAds || !hasMoreAds) return;

    setState(() {
      isLoadingAds = true;
    });

    try {
      final url = Uri.parse(
        'http://localhost:10000/api/products?page=$currentPageAds&limit=$limitAds',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> fetchedAds = decoded['products'] ?? [];

        setState(() {
          allAds.addAll(fetchedAds);
          currentPageAds++;
          isLoadingAds = false;
          if (fetchedAds.length < limitAds) {
            hasMoreAds = false;
          }
        });
      } else {
        setState(() {
          isLoadingAds = false;
          hasMoreAds = false;
        });
        print('Error fetching ads: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoadingAds = false;
        hasMoreAds = false;
      });
      print('Exception fetching ads: $e');
    }
  }

  void _onAdsScroll() {
    if (_adsScrollController.position.pixels >=
        _adsScrollController.position.maxScrollExtent - 200) {
      fetchAllAds();
    }
  }

  String formatDate(String isoDate) {
    final date = DateTime.parse(isoDate);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays >= 1) return 'منذ ${difference.inDays} يوم';
    if (difference.inHours >= 1) return 'منذ ${difference.inHours} ساعة';
    if (difference.inMinutes >= 1) return 'منذ ${difference.inMinutes} دقيقة';
    return 'الآن';
  }

  Widget _buildAdCard(dynamic ad) {
    final List<dynamic> images = ad['images'] is List ? ad['images'] : [];
    final firstImageBase64 = images.isNotEmpty ? images[0] : null;

    final image = firstImageBase64 != null
        ? Image.memory(
      base64Decode(firstImageBase64),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
            color: Colors.grey[200], child: Icon(Icons.image, size: 60));
      },
    )
        : Container(
        color: Colors.grey[200], child: Icon(Icons.image, size: 60));

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      margin: EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            child: SizedBox(
              height: 120,
              width: double.infinity,
              child: image,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${ad['price'] ?? '0'} ${ad['currency'] ?? ''}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  ad['description'] ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: Colors.grey[800]),
                ),
                SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.deepPurple),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${ad['city'] ?? ''} - ${ad['region'] ?? ''}',
                        style: TextStyle(color: Colors.grey[700], fontSize: 12),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(
                      ad['createDate'] != null
                          ? formatDate(ad['createDate'])
                          : 'غير محدد',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleProtectedNavigation(BuildContext context, String routeKey) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      // المستخدم غير مسجل دخول
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('تسجيل الدخول مطلوب'),
          content: Text('يجب تسجيل الدخول للوصول إلى هذه الصفحة.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إلغاء'),
            ),
            TextButton(
              onPressed: () async {
                await prefs.setString('redirect_to', routeKey);
                Navigator.pop(context); // أغلق الحوار
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              child: Text('تسجيل دخول'),
            ),
          ],
        ),
      );
    } else {
      Widget targetPage;
      switch (routeKey) {
        case 'myAds':
          targetPage = MyAdsScreen();
          break;
        case 'addAd':
          targetPage = MultiStepAddAdScreen();
          break;
        default:
          return;
      }
      Navigator.pop(context); // إغلاق الدروار
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => targetPage),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        drawer: _buildDrawer(context),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // AppBar مع زر القائمة
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
                  child: Row(
                    children: [
                      Builder(
                        builder: (context) => IconButton(
                          icon: Icon(Icons.menu, size: 28, color: Colors.deepPurple),
                          onPressed: () => Scaffold.of(context).openDrawer(),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            'صاحب Com',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple),
                          ),
                        ),
                      ),
                      SizedBox(width: 40), // تعويض لأيقونة القائمة حتى يبقى العنوان بالوسط
                    ],
                  ),
                ),

                // سلايدر الصور + الموقع + بحث
                Stack(
                  children: [
                    Container(
                      height: 250,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: imagePaths.length,
                        onPageChanged: (index) {
                          setState(() => _currentImageIndex = index);
                        },
                        itemBuilder: (context, index) {
                          return Container(
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage(imagePaths[index]),
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'مرحباً بك في صاحب Com',
                            style: TextStyle(
                              fontSize: 22,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              shadows: [Shadow(blurRadius: 5, color: Colors.black54)],
                            ),
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.location_on, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                selectedCity == 'كل المحافظات'
                                    ? 'كل المحافظات'
                                    : '$selectedCity - $selectedDistrict',
                                style: TextStyle(color: Colors.white, fontSize: 16),
                              ),
                              Spacer(),
                              IconButton(
                                icon: Icon(Icons.edit_location_alt, color: Colors.white),
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => LocationSelectionScreen()),
                                  );
                                  if (result != null) {
                                    setState(() {
                                      selectedCity = result['province'];
                                      selectedDistrict = result['district'];
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'ابحث عن منتج أو خدمة...',
                                prefixIcon: Icon(Icons.search, color: Colors.deepPurple),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // مؤشرات السلايدر
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: imagePaths.asMap().entries.map((entry) {
                    return Container(
                      width: 10,
                      height: 10,
                      margin: EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentImageIndex == entry.key
                            ? Colors.deepPurple
                            : Colors.deepPurple.withOpacity(0.3),
                      ),
                    );
                  }).toList(),
                ),

                // التصنيفات
                SizedBox(height: 24),

                // عرض الإعلانات في GridView ثنائية الأعمدة
                SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Text('جميع الإعلانات',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple)),
                    ],
                  ),
                ),
                SizedBox(height: 12),


                Container(
                  height: 600, // يمكن تعديل الارتفاع حسب الحاجة
                  child: allAds.isEmpty && isLoadingAds
                      ? Center(child: CircularProgressIndicator())
                      : GridView.builder(
                    controller: _adsScrollController,
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.65,
                    ),
                    itemCount: allAds.length + (hasMoreAds ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == allAds.length) {
                        return Center(child: CircularProgressIndicator());
                      }
                      return _buildAdCard(allAds[index]);
                    },
                  ),
                ),

                SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Drawer _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurpleAccent, Colors.deepPurple],
              ),
            ),
            child: Center(
              child: Text(
                _username != null ? 'مرحباً، $_username 👋' : 'مرحبا بك 👋',
                style: TextStyle(fontSize: 22, color: Colors.white),
              ),
            ),
          ),
          _drawerItem(Icons.home, 'الرئيسية', () {
            Navigator.pop(context);
          }),
          _drawerItem(Icons.list_alt, 'إعلاناتي', () {
            _handleProtectedNavigation(context, 'myAds');
          }),
          _drawerItem(Icons.add_circle_outline, 'إضافة إعلان', () {
            _handleProtectedNavigation(context, 'addAd');
          }),
          _drawerItem(Icons.person, 'حسابي', () async {
            Navigator.pop(context);
            final prefs = await SharedPreferences.getInstance();
            final token = prefs.getString('token');
            final username = prefs.getString('username') ?? '';
            final email = prefs.getString('email') ?? '';

            if (token == null || token.isEmpty) {
              await prefs.setString('redirect_to', 'account');
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AccountScreen(
                    isLoggedIn: true,
                    userName: username,
                    userEmail: email,
                  ),
                ),
              );
            }
          }),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.deepPurple),
      title: Text(title, style: TextStyle(fontSize: 16)),
      onTap: onTap,
    );
  }
}
