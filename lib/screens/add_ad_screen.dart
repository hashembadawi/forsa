import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AddAdScreen extends StatefulWidget {
  const AddAdScreen({super.key});

  @override
  State<AddAdScreen> createState() => _AddAdScreenState();
}

class _AddAdScreenState extends State<AddAdScreen> {
  List<File?> _images = List.filled(6, null);
  List<String?> _base64Images = List.filled(6, null);
  final picker = ImagePicker();

  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  String selectedCategory = '1'; // مثلاً: 1 = أثاث
  String selectedSubCategory = '101'; // مثلاً: 101 = غرفة نوم
  String selectedCity = 'ادلب';
  String selectedRegion = 'معرة النعمان';
  String selectedCurrency = 'ل.س';

  final Map<String, List<String>> locations = {
    'ادلب': ['معرة النعمان', 'جسر الشغور', 'سراقب', 'اريحا'],
    'دمشق': ['المزة', 'البرامكة', 'باب توما', 'المالكي'],
    // أضف المزيد...
  };

  Future<void> _pickImage(int index) async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);

      // تحويل الصورة إلى Base64
      List<int> imageBytes = await imageFile.readAsBytes();
      String base64String = base64Encode(imageBytes);

      setState(() {
        _images[index] = imageFile;
        _base64Images[index] = base64String;
      });
    }
  }

  Future<void> _submitAd() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      // تحضير البيانات للإرسال
      Map<String, dynamic> requestData = {
        'price': _priceController.text,
        'currency': selectedCurrency,
        'category': selectedCategory,
        'subCategory': selectedSubCategory,
        'city': selectedCity,
        'region': selectedRegion,
        'createDate': DateTime.now().toIso8601String(),
        'description': _descController.text,
        'images': _base64Images.where((img) => img != null).toList(),
      };

      final response = await http.post(
        Uri.parse('http://192.168.1.120:10000/api/product/add'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 201) {
        final json = jsonDecode(response.body);

        // عرض رسالة النجاح مع تنبيه المراجعة
        _showSuccessDialog();

        // مسح البيانات بعد النجح
        _clearForm();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل في الإضافة: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في الاتصال: $e')),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 30),
              SizedBox(width: 10),
              Text('تم إرسال الإعلان'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'شكراً لك!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'تم إرسال إعلانك بنجاح. سيتم مراجعة الإعلان من قبل فريق الإدارة ونشره في حال تحقق جميع الشروط.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 15),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ستتلقى إشعاراً عند نشر الإعلان',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // إغلاق الحوار
                Navigator.of(context).pop(); // العودة للشاشة السابقة
              },
              child: Text(
                'حسناً',
                style: TextStyle(
                  color: Colors.deepPurple,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _clearForm() {
    setState(() {
      _images = List.filled(6, null);
      _base64Images = List.filled(6, null);
      _priceController.clear();
      _descController.clear();
    });
  }

  void _removeImage(int index) {
    setState(() {
      _images[index] = null;
      _base64Images[index] = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('نشر إعلان جديد')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('اختر حتى 6 صور:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(6, (index) {
                return Stack(
                  children: [
                    GestureDetector(
                      onTap: () => _pickImage(index),
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: _images[index] != null
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(_images[index]!, fit: BoxFit.cover),
                        )
                            : Icon(Icons.add_a_photo, color: Colors.grey[600]),
                      ),
                    ),
                    if (_images[index] != null)
                      Positioned(
                        top: -5,
                        right: -5,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            padding: EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.close, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                  ],
                );
              }),
            ),
            SizedBox(height: 20),

            // اختيار المدينة
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                value: selectedCity,
                isExpanded: true,
                underline: SizedBox(),
                items: locations.keys
                    .map((city) => DropdownMenuItem(value: city, child: Text(city)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCity = value!;
                    selectedRegion = locations[selectedCity]!.first;
                  });
                },
              ),
            ),
            SizedBox(height: 10),

            // اختيار المنطقة
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                value: selectedRegion,
                isExpanded: true,
                underline: SizedBox(),
                items: locations[selectedCity]!
                    .map((region) => DropdownMenuItem(value: region, child: Text(region)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedRegion = value!;
                  });
                },
              ),
            ),
            SizedBox(height: 10),

            // حقل السعر
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'السعر',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),

            // اختيار العملة
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                value: selectedCurrency,
                isExpanded: true,
                underline: SizedBox(),
                items: ['ل.س', 'دولار']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCurrency = value!;
                  });
                },
              ),
            ),
            SizedBox(height: 10),

            // حقل الوصف
            TextField(
              controller: _descController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'الوصف',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            SizedBox(height: 20),

            // زر النشر
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submitAd,
                child: Text('نشر الإعلان', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}