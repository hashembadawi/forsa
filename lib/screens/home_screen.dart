import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'add_ad_screen.dart';
import 'favorites_screen.dart';
import 'login_screen.dart';
import 'my_ads_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? selectedCity;
  List<String> cities = ['إدلب', 'حلب', 'الشام'];
  List<String> categories = ['الكترونيات', 'أثاث', 'سيارات', 'عقارات', 'ملابس', 'خدمات'];

  List<String> imagePaths = [
    'assets/image1.jpg',
    'assets/image2.jpg',
    'assets/image3.jpg',
  ];

  int _currentImageIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(seconds: 3), (Timer timer) {
      setState(() {
        _currentImageIndex = (_currentImageIndex + 1) % imagePaths.length;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _requireLogin(Function onSuccess, {String? redirectTo}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token != null) {
      onSuccess();
    } else {
      if (redirectTo != null) {
        await prefs.setString('redirect_to', redirectTo); // نحفظ الصفحة المراد الوصول إليها
      }
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text("يتطلب تسجيل الدخول"),
          content: Text("يرجى تسجيل الدخول للوصول إلى هذه الميزة."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => LoginScreen()),
                );
              },
              child: Text("تسجيل الدخول"),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text("إلغاء"),
            ),
          ],
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: Text('صاحب Com'),
          centerTitle: true,
          backgroundColor: Colors.deepPurpleAccent,
          elevation: 4,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ عرض الصور المتغيرة
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 6),
                    ],
                  ),
                  child: AnimatedSwitcher(
                    duration: Duration(milliseconds: 700),
                    transitionBuilder: (child, animation) {
                      final offset = Tween<Offset>(
                        begin: Offset(1.0, 0.0),
                        end: Offset.zero,
                      ).animate(animation);
                      return SlideTransition(position: offset, child: child);
                    },
                    child: ClipRRect(
                      key: ValueKey(imagePaths[_currentImageIndex]),
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        imagePaths[_currentImageIndex],
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),

                // مربع البحث
                TextField(
                  decoration: InputDecoration(
                    hintText: 'ابحث عن منتج أو خدمة...',
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: Icon(Icons.search, color: Colors.deepPurple),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                SizedBox(height: 20),

                // اختيار الموقع
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, color: Colors.deepPurple),
                    SizedBox(width: 8),
                    Text('الموقع:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    SizedBox(width: 12),
                    DropdownButton<String>(
                      value: selectedCity,
                      hint: Text('اختر المحافظة'),
                      icon: Icon(Icons.arrow_drop_down),
                      dropdownColor: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      onChanged: (newValue) {
                        setState(() {
                          selectedCity = newValue;
                        });
                      },
                      items: cities.map((city) {
                        return DropdownMenuItem(
                          value: city,
                          child: Text(city),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                SizedBox(height: 24),

                // التصنيفات
                Text('التصنيفات',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: categories.map((category) {
                      return Container(
                        margin: EdgeInsets.symmetric(horizontal: 6),
                        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.deepPurpleAccent, width: 1),
                          boxShadow: [
                            BoxShadow(color: Colors.black12, blurRadius: 4),
                          ],
                        ),
                        child: Text(
                          category,
                          style: TextStyle(fontSize: 16, color: Colors.deepPurple[700]),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ✅ زر الإضافة
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _requireLogin(() {
              Navigator.push(context, MaterialPageRoute(builder: (_) => AddAdScreen()));
            }, redirectTo: 'addAd');
          },
          child: Icon(Icons.add, size: 30),
          backgroundColor: Colors.deepPurple,
          shape: CircleBorder(),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

        // ✅ الشريط السفلي
        bottomNavigationBar: BottomAppBar(
          shape: CircularNotchedRectangle(),
          notchMargin: 8,
          color: Colors.white,
          elevation: 10,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // الجهة اليمنى
                Row(
                  children: [
                    _buildBottomBarItem(Icons.home, 'الرئيسية', () => print("الرئيسية")),
                    _buildBottomBarItem(Icons.favorite_border, 'المفضلة', () {
                      _requireLogin(() {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => FavoritesScreen()));
                      }, redirectTo: 'favorites');
                    }),
                  ],
                ),
                // الجهة اليسرى
                Row(
                  children: [
                    _buildBottomBarItem(Icons.campaign_outlined, 'إعلاناتي', () {
                      _requireLogin(() {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => MyAdsScreen()));
                      }, redirectTo: 'myAds');
                    }),
                    _buildBottomBarItem(Icons.person_outline, 'حسابي', () => print("حسابي")),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBarItem(IconData icon, String label, VoidCallback onTap) {
    return TextButton(
      onPressed: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.deepPurpleAccent),
          Text(label, style: TextStyle(color: Colors.deepPurpleAccent, fontSize: 12)),
        ],
      ),
    );
  }
}
