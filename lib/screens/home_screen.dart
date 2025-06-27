import 'dart:async';
import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Sahib Com App'),
          centerTitle: true,
          backgroundColor: Colors.blueAccent,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ AnimatedSwitcher لعرض الصور المتغيرة
              Container(
                height: 180,
                width: double.infinity,
                child: AnimatedSwitcher(
                  duration: Duration(milliseconds: 700),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    final offsetAnimation = Tween<Offset>(
                      begin: const Offset(1.0, 0.0),
                      end: Offset.zero,
                    ).animate(animation);
                    return SlideTransition(
                      position: offsetAnimation,
                      child: child,
                    );
                  },
                  child: ClipRRect(
                    key: ValueKey<String>(imagePaths[_currentImageIndex]),
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      imagePaths[_currentImageIndex],
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // مربع البحث
              TextField(
                decoration: InputDecoration(
                  hintText: 'ابحث هنا...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              SizedBox(height: 16),

              // اختيار الموقع
              Row(
                children: [
                  Text('الموقع: ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                  SizedBox(width: 10),
                  DropdownButton<String>(
                    hint: Text('اختر المحافظة'),
                    value: selectedCity,
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
              SizedBox(height: 20),

              // التصنيفات
              Text('التصنيفات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: categories.map((category) {
                    return Container(
                      margin: EdgeInsets.symmetric(horizontal: 8),
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.grey[200],
                      ),
                      child: Text(category, style: TextStyle(fontSize: 16)),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        // ✅ زر الإضافة
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            print("إضافة إعلان جديد");
          },
          child: Icon(Icons.add, size: 50),
          backgroundColor: Colors.blueAccent,
          shape: CircleBorder(),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

        // ✅ الشريط السفلي
        bottomNavigationBar: BottomAppBar(
          shape: CircularNotchedRectangle(),
          notchMargin: 8,
          color: Colors.white,
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // الجهة اليمنى
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => HomeScreen()),
                              (Route<dynamic> route) => false, // حذف كل ما قبل الصفحة الجديدة
                        );
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.home, color: Colors.blueAccent),
                          Text("الرئيسية", style: TextStyle(color: Colors.blueAccent, fontSize: 12)),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => print("المفضلة"),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.favorite_border, color: Colors.blueAccent),
                          Text("المفضلة", style: TextStyle(color: Colors.blueAccent, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),

                // الجهة اليسرى
                Row(
                  children: [
                    TextButton(
                      onPressed: () => print("إعلاناتي"),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.campaign_outlined, color: Colors.blueAccent),
                          Text("إعلاناتي", style: TextStyle(color: Colors.blueAccent, fontSize: 12)),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => print("حسابي"),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person_outline, color: Colors.blueAccent),
                          Text("حسابي", style: TextStyle(color: Colors.blueAccent, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
