import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sahbo_app/screens/select_location_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedCity = 'كل المحافظات';
  String selectedDistrict = 'كل المناطق';

  List<String> categories = [
    'حيوانات',
    'المجتمع',
    'ملابس',
    'معدات صناعية',
    'أثاث',
    'الكترونيات',
    'عقارات',
    'مركبات'
  ];

  List<String> imagePaths = [
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
    _pageController = PageController(viewportFraction: 0.9);
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _sliderTimer = Timer.periodic(Duration(seconds: 3), (_) {
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

  @override
  void dispose() {
    _sliderTimer?.cancel();
    _pageController.dispose();
    super.dispose();
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
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ سلايدر الصور العصري
                Container(
                  height: 200,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      PageView.builder(
                        controller: _pageController,
                        itemCount: imagePaths.length,
                        onPageChanged: (index) {
                          setState(() {
                            _currentImageIndex = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          return AnimatedContainer(
                            duration: Duration(milliseconds: 500),
                            margin: EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              image: DecorationImage(
                                image: AssetImage(imagePaths[index]),
                                fit: BoxFit.cover,
                              ),
                              boxShadow: [
                                BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 4)),
                              ],
                            ),
                          );
                        },
                      ),
                      // ✅ المؤشرات
                      Positioned(
                        bottom: 10,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: imagePaths.asMap().entries.map((entry) {
                            return Container(
                              width: 8,
                              height: 8,
                              margin: EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentImageIndex == entry.key
                                    ? Colors.deepPurple
                                    : Colors.white70,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),

                // ✅ الموقع أسفل الصور
                SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, color: Colors.deepPurple),
                    SizedBox(width: 8),
                    Text('الموقع:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    IconButton(
                      icon: Icon(Icons.edit_location_alt_outlined, color: Colors.deepPurple),
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
                Padding(
                  padding: const EdgeInsets.only(top: 4.0, right: 40),
                  child: Text(
                    selectedCity == 'كل المحافظات'
                        ? 'كل المحافظات'
                        : '$selectedCity - $selectedDistrict',
                    style: TextStyle(fontSize: 16, color: Colors.deepPurple),
                  ),
                ),

                // ✅ مربع البحث
                SizedBox(height: 20),
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

                // ✅ التصنيفات
                SizedBox(height: 24),
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
      ),
    );
  }
}
