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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('صاحب Com'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                Text('الموقع: ',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
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

            // التصنيفات القابلة للتمرير
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
    );
  }
}