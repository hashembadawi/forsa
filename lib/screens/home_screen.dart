import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'account_screen.dart';
import 'ad_details_screen.dart';
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
  int? selectedCityId;
  int? selectedRegionId;
  List<Map<String, dynamic>> provinces = [];
  List<Map<String, dynamic>> majorAreas = [];
  List<Map<String, dynamic>> categoriesList = [];
  List<Map<String, dynamic>> subCategoriesList = [];
  Map<String, dynamic>? selectedCategory;
  Map<String, dynamic>? selectedSubCategory;
  int? selectedCategoryId;
  int? selectedSubCategoryId;
  
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

  // لإعلانات العرض
  List<dynamic> allAds = [];
  bool isLoadingAds = false;
  int currentPageAds = 1;
  final int limitAds = 10;
  bool hasMoreAds = true;
  late ScrollController _adsScrollController;
  String? _username;

  @override
  void initState() {
    super.initState();
    _adsScrollController = ScrollController()..addListener(_onAdsScroll);
    _checkLoginStatus();
    _fetchOptions();
    fetchAllAds();
  }

  @override
  void dispose() {
    _adsScrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchOptions() async {
    try {
      final response = await http.get(Uri.parse('https://sahbo-app-api.onrender.com/api/options'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          provinces = List<Map<String, dynamic>>.from(data['Province']);
          majorAreas = List<Map<String, dynamic>>.from(data['majorAreas']);
          categoriesList = List<Map<String, dynamic>>.from(data['categories']);
        subCategoriesList = List<Map<String, dynamic>>.from(data['subCategories']);
        });
      }
    } catch (e) {
      // handle error if needed
    }
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final rememberMe = prefs.getBool('rememberMe') ?? false;

    if (token != null) {
      try {
        final response = await http.get(
          Uri.parse('https://sahbo-app-api.onrender.com/api/auth/validate-token'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          // التوكن صالح، تحميل اسم المستخدم
          setState(() {
            _username = prefs.getString('userName') ?? 'مستخدم';
          });
        } else {
          // التوكن غير صالح، مسح البيانات
          await prefs.clear();
          setState(() {
            _username = null;
          });
        }
      } catch (e) {
        // خطأ في الاتصال، مسح البيانات إذا لم يكن rememberMe مفعلًا
        if (!rememberMe) {
          await prefs.clear();
        }
        setState(() {
          _username = null;
        });
      }
    } else {
      // لا يوجد توكن، مسح البيانات إذا لم يكن rememberMe مفعلًا
      if (!rememberMe) {
        await prefs.clear();
      }
      setState(() {
        _username = null;
      });
    }
  }

  Future<void> fetchAllAds() async {
    if (isLoadingAds || !hasMoreAds) return;

    setState(() {
      isLoadingAds = true;
    });

    try {
      final url = Uri.parse(
        'https://sahbo-app-api.onrender.com/api/products?page=$currentPageAds&limit=$limitAds',
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

  Future<void> _showLocationFilterDialog() async {
    Map<String, dynamic>? tempSelectedProvince;
    Map<String, dynamic>? tempSelectedArea;
    List<Map<String, dynamic>> filteredAreas = [];

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('تصفية حسب الموقع'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<Map<String, dynamic>>(
                      value: tempSelectedProvince,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'اختر المحافظة',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem<Map<String, dynamic>>(
                          value: null,
                          child: Text('كل المحافظات'),
                        ),
                        ...provinces.map((province) => DropdownMenuItem(
                              value: province,
                              child: Text(province['name']),
                            )),
                      ],
                      onChanged: (value) {
                        setStateDialog(() {
                          tempSelectedProvince = value;
                          tempSelectedArea = null;
                          filteredAreas = value == null
                              ? []
                              : majorAreas.where((area) => area['ProvinceId'] == value['id']).toList();
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<Map<String, dynamic>>(
                      value: tempSelectedArea,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'اختر المدينة/المنطقة',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem<Map<String, dynamic>>(
                          value: null,
                          child: Text('كل المناطق'),
                        ),
                        ...filteredAreas.map((area) => DropdownMenuItem(
                              value: area,
                              child: Text(area['name']),
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
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedCity = tempSelectedProvince?['name'] ?? 'كل المحافظات';
                      selectedDistrict = tempSelectedArea?['name'] ?? 'كل المناطق';
                      selectedCityId = tempSelectedProvince?['id'];
                      selectedRegionId = tempSelectedArea?['id'];
                      allAds.clear();
                      currentPageAds = 1;
                      hasMoreAds = true;
                    });
                    Navigator.pop(context);
                    if (selectedCityId != null || selectedRegionId != null) {
                      fetchFilteredAds(reset: true);
                    } else {
                      fetchAllAds();
                    }
                  },
                  child: const Text('تطبيق'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> fetchFilteredAds({bool reset = false}) async {
    if (isLoadingAds || !hasMoreAds) return;

    setState(() {
      isLoadingAds = true;
    });

    try {
      final params = <String, String>{
        'page': '$currentPageAds',
        'limit': '$limitAds',
      };
      if (selectedCityId != null) params['cityId'] = selectedCityId.toString();
      if (selectedRegionId != null) params['regionId'] = selectedRegionId.toString();

      final uri = Uri.https('sahbo-app-api.onrender.com', '/api/products/search', params);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> fetchedAds = decoded['products'] ?? [];

        setState(() {
          if (reset) allAds.clear();
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
        debugPrint('Error fetching filtered ads: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoadingAds = false;
        hasMoreAds = false;
      });
      debugPrint('Exception fetching filtered ads: $e');
    }
  }

  Future<void> fetchCategoryFilteredAds({bool reset = false}) async {
  if (isLoadingAds || !hasMoreAds) return;

  setState(() {
    isLoadingAds = true;
  });

  try {
    final params = <String, String>{
      'page': '$currentPageAds',
      'limit': '$limitAds',
    };
    if (selectedCategoryId != null) params['categoryId'] = selectedCategoryId.toString();
    if (selectedSubCategoryId != null) params['subCategoryId'] = selectedSubCategoryId.toString();

    final uri = Uri.https('sahbo-app-api.onrender.com', '/api/products/search-by-category', params);

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List<dynamic> fetchedAds = decoded['products'] ?? [];

      setState(() {
        if (reset) allAds.clear();
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
      debugPrint('Error fetching filtered ads: ${response.statusCode}');
    }
  } catch (e) {
    setState(() {
      isLoadingAds = false;
      hasMoreAds = false;
    });
    debugPrint('Exception fetching filtered ads: $e');
  }
}
  void _onAdsScroll() {
    if (_adsScrollController.position.pixels >=
      _adsScrollController.position.maxScrollExtent - 200) {
      if (selectedCategoryId != null || selectedSubCategoryId != null) {
        fetchCategoryFilteredAds();
      } else if (selectedCityId != null || selectedRegionId != null) {
        fetchFilteredAds();
      } else {
        fetchAllAds();
      }
    }
  }

  String formatDate(String isoDate) {
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
            child: const Icon(Icons.image, size: 40));
      },
    )
        : Container(
        color: Colors.grey[200],
        child: const Icon(Icons.image, size: 40));

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      margin: const EdgeInsets.all(4),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AdDetailsScreen(ad: ad),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: SizedBox(
                  width: double.infinity,
                  child: image,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(
                constraints: const BoxConstraints(minHeight: 80),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(
                        '${ad['productTitle'] ?? ''}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      Text(
                        '${ad['price'] ?? '0'} ${ad['currencyName'] ?? ''}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),

                      Text(
                        ad['description'] ?? '',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey[800],
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 8,
                            color: Colors.deepPurple,
                          ),
                          const SizedBox(width: 1),
                          Expanded(
                            child: Text(
                              '${ad['cityName'] ?? ''} - ${formatDate(ad['createDate'] ?? '')}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 8,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleProtectedNavigation(BuildContext context, String routeKey) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
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
      Navigator.pop(context);
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
          controller: _adsScrollController,
          slivers: [
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
            SliverToBoxAdapter(child: _buildLocationButton()),
            SliverToBoxAdapter(child: _buildCategoryFilterSection()),
            SliverToBoxAdapter(child: ImageSlider()),
            SliverToBoxAdapter(child: _buildSearchField()),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const Text(
                    'جميع الإعلانات',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (allAds.isEmpty && isLoadingAds)
                    const Center(child: CircularProgressIndicator()),
                ]),
              ),
            ),
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
                    if (index == allAds.length && hasMoreAds) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    return _buildAdCard(allAds[index]);
                  },
                  childCount: allAds.length + (hasMoreAds ? 1 : 0),
                ),
              ),
            ),
            if (!hasMoreAds && allAds.isNotEmpty)
              SliverToBoxAdapter(
                child: const Padding(
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
    );
  }

  Widget _buildLocationButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: GestureDetector(
        onTap: () async {
          await _showLocationFilterDialog();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.location_on, size: 20, color: Colors.deepPurple),
                  const SizedBox(width: 8),
                  const Text(
                    'موقع',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                selectedCity == 'كل المحافظات'
                    ? 'كل المحافظات'
                    : '$selectedCity - $selectedDistrict',
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildCategoryFilterSection() {
  List<Map<String, dynamic>> filteredSubCategories = selectedCategory == null
      ? []
      : subCategoriesList.where((s) => s['categoryId'] == selectedCategory!['id']).toList();

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<Map<String, dynamic>>(
            value: selectedCategory,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'التصنيف الرئيسي',
              border: OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem<Map<String, dynamic>>(
                value: null,
                child: Text('كل التصنيفات'),
              ),
              ...categoriesList.map((cat) => DropdownMenuItem(
                    value: cat,
                    child: Text(cat['name']),
                  )),
            ],
            onChanged: (value) {
              setState(() {
                selectedCategory = value;
                selectedCategoryId = value?['id'];
                selectedSubCategory = null;
                selectedSubCategoryId = null;
              });
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButtonFormField<Map<String, dynamic>>(
            value: selectedSubCategory,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'التصنيف الفرعي',
              border: OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem<Map<String, dynamic>>(
                value: null,
                child: Text('كل الفروع'),
              ),
              ...filteredSubCategories.map((subCat) => DropdownMenuItem(
                    value: subCat,
                    child: Text(subCat['name']),
                  )),
            ],
            onChanged: (value) {
              setState(() {
                selectedSubCategory = value;
                selectedSubCategoryId = value?['id'];
              });
            },
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () {
            setState(() {
              allAds.clear();
              currentPageAds = 1;
              hasMoreAds = true;
            });
            fetchCategoryFilteredAds(reset: true);
          },
          child: const Text('بحث'),
        ),
      ],
    ),
  );
}
  
  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            prefixIcon: Icon(Icons.search, color: Colors.deepPurple),
            border: InputBorder.none,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
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
                    style: const TextStyle(fontSize: 18, color: Colors.white),
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
                  final username = prefs.getString('userName') ?? '';
                  final email = prefs.getString('userEmail') ?? '';

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

class ImageSlider extends StatefulWidget {
  const ImageSlider({super.key});

  @override
  State<ImageSlider> createState() => _ImageSliderState();
}

class _ImageSliderState extends State<ImageSlider> {
  final List<String> imagePaths = [
    'assets/image1.jpg',
    'assets/image2.jpg',
    'assets/image3.jpg',
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

  @override
  Widget build(BuildContext context) {
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
        ],
      ),
    );
  }
}