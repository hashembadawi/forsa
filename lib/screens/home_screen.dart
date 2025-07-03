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

  final List<Map<String, dynamic>> categories = [
    {'icon': Icons.pets, 'name': 'حيوانات'},
    {'icon': Icons.groups, 'name': 'خدمات'},
    {'icon': Icons.checkroom, 'name': 'أزياء'},
    {'icon': Icons.build, 'name': 'أدوات'},
    {'icon': Icons.chair, 'name': 'أثاث'},
    {'icon': Icons.devices, 'name': 'إلكترونيات'},
    {'icon': Icons.home_work, 'name': 'عقارات'},
    {'icon': Icons.directions_car, 'name': 'مركبات'},
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
    _sliderTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_pageController.hasClients) {
        int nextPage = (_currentImageIndex + 1) % imagePaths.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
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
        debugPrint('Error fetching ads: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoadingAds = false;
        hasMoreAds = false;
      });
      debugPrint('Exception fetching ads: $e');
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
            color: Colors.grey[200],
            child: const Icon(Icons.image, size: 60));
      },
    )
        : Container(
        color: Colors.grey[200],
        child: const Icon(Icons.image, size: 60));

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      margin: const EdgeInsets.all(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // يمكن إضافة تفاصيل الإعلان هنا
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16)),
              child: SizedBox(
                height: 120,
                width: double.infinity,
                child: image,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${ad['price'] ?? '0'} ${ad['currency'] ?? ''}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ad['description'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[800],
                        height: 1.4),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on,
                          size: 14, color: Colors.deepPurple),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${ad['city'] ?? ''} - ${ad['region'] ?? ''}',
                          style: TextStyle(
                              color: Colors.grey[700], fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        ad['createDate'] != null
                            ? formatDate(ad['createDate'])
                            : 'غير محدد',
                        style: TextStyle(
                            color: Colors.grey[600], fontSize: 12),
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
  }

  void _handleProtectedNavigation(
      BuildContext context, String routeKey) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      // المستخدم غير مسجل دخول
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
                Navigator.pop(context); // أغلق الحوار
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const LoginScreen()),
                );
              },
              child: const Text('تسجيل دخول'),
            ),
          ],
        ),
      );
    } else {
      Widget targetPage;
      switch (routeKey) {
        case 'myAds':
          targetPage = const MyAdsScreen();
          break;
        case 'addAd':
          targetPage = const MultiStepAddAdScreen();
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
        body: CustomScrollView(
          slivers: [
            // AppBar مع زر القائمة
            SliverAppBar(
              floating: true,
              pinned: true,
              snap: false,
              elevation: 1,
              backgroundColor: Colors.white,
              title: Text(
                'صاحب Com',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple[800],
                ),
              ),
              centerTitle: true,
              leading: Builder(
                builder: (context) => IconButton(
                  icon: Icon(Icons.menu,
                      size: 28, color: Colors.deepPurple[800]),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
            ),

            // محتوى الصفحة
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // سلايدر الصور
                  _buildImageSlider(),

                  // حقل البحث
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 2,
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'ابحث عن منتج أو خدمة...',
                          prefixIcon: Icon(Icons.search,
                              color: Colors.deepPurple),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                  ),

                  // التصنيفات
                  _buildCategoriesSection(),

                  // جميع الإعلانات
                  _buildAllAdsSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSlider() {
    return SizedBox(
      height: 180,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: imagePaths.length,
            onPageChanged: (index) {
              setState(() => _currentImageIndex = index);
            },
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(
                    image: AssetImage(imagePaths[index]),
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                imagePaths.length,
                    (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: _currentImageIndex == index ? 20 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: _currentImageIndex == index
                        ? Colors.deepPurple
                        : Colors.white.withOpacity(0.7),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on,
                      size: 16, color: Colors.deepPurple),
                  const SizedBox(width: 4),
                  Text(
                    selectedCity == 'كل المحافظات'
                        ? 'كل المحافظات'
                        : '$selectedCity - $selectedDistrict',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => LocationSelectionScreen()),
                      );
                      if (result != null) {
                        setState(() {
                          selectedCity = result['province'];
                          selectedDistrict = result['district'];
                        });
                      }
                    },
                    child: Icon(Icons.edit,
                        size: 16, color: Colors.deepPurple),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'التصنيفات',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          categories[index]['icon'],
                          size: 30,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        categories[index]['name'],
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllAdsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'جميع الإعلانات',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          allAds.isEmpty && isLoadingAds
              ? const Center(child: CircularProgressIndicator())
              : GridView.builder(
            controller: _adsScrollController,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.7,
            ),
            itemCount: allAds.length + (hasMoreAds ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == allAds.length) {
                return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ));
              }
              return _buildAdCard(allAds[index]);
            },
          ),
          if (!hasMoreAds && allAds.isNotEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'لا يوجد المزيد من الإعلانات',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Drawer _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.deepPurple.shade800,
                  Colors.deepPurple.shade600
                ],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 30,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _username != null ? 'مرحباً، $_username 👋' : 'مرحبا بك 👋',
                    style: const TextStyle(
                        fontSize: 18, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
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
                      MaterialPageRoute(
                          builder: (_) => const LoginScreen()),
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
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.deepPurple),
      title: Text(title),
      onTap: onTap,
    );
  }
}