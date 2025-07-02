import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// الشاشة الرئيسية لإدارة المراحل
class MultiStepAddAdScreen extends StatefulWidget {
  const MultiStepAddAdScreen({super.key});

  @override
  State<MultiStepAddAdScreen> createState() => _MultiStepAddAdScreenState();
}

class _MultiStepAddAdScreenState extends State<MultiStepAddAdScreen> {
  int currentStep = 0;

  // بيانات مشتركة بين المراحل
  List<File?> selectedImages = [];
  String selectedCategory = '';
  String selectedSubCategory = '';
  String productTitle = '';
  String price = '';
  String currency = 'ل.س';
  String selectedProvince = '';
  String selectedCity = '';
  String description = '';

  final List<String> stepTitles = [
    'إضافة الصور',
    'اختيار التصنيف',
    'معلومات الإعلان'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('نشر إعلان جديد'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // شريط التقدم
          _buildProgressIndicator(),

          // محتوى المرحلة الحالية
          Expanded(
            child: _buildCurrentStep(),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: List.generate(3, (index) {
              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: index <= currentStep ? Colors.deepPurple : Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    if (index < 2) SizedBox(width: 8),
                  ],
                ),
              );
            }),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(3, (index) {
              return Column(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: index <= currentStep ? Colors.deepPurple : Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    stepTitles[index],
                    style: TextStyle(
                      fontSize: 12,
                      color: index <= currentStep ? Colors.deepPurple : Colors.grey[600],
                      fontWeight: index == currentStep ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (currentStep) {
      case 0:
        return ImagesSelectionStep(
          selectedImages: selectedImages,
          onImagesChanged: (images) {
            setState(() {
              selectedImages = images;
            });
          },
          onNext: () {
            setState(() {
              currentStep = 1;
            });
          },
        );
      case 1:
        return CategorySelectionStep(
          selectedCategory: selectedCategory,
          selectedSubCategory: selectedSubCategory,
          onCategorySelected: (category, subCategory) {
            setState(() {
              selectedCategory = category;
              selectedSubCategory = subCategory;
              currentStep = 2;
            });
          },
          onBack: () {
            setState(() {
              currentStep = 0;
            });
          },
        );
      case 2:
        return AdDetailsStep(
          productTitle: productTitle,
          price: price,
          currency: currency,
          selectedProvince: selectedProvince,
          selectedCity: selectedCity,
          description: description,
          onDetailsChanged: (title, p, c, province, city, desc) {
            setState(() {
              productTitle = title;
              price = p;
              currency = c;
              selectedProvince = province;
              selectedCity = city;
              description = desc;
            });
          },
          onSubmit: _submitAd,
          onBack: () {
            setState(() {
              currentStep = 1;
            });
          },
        );
      default:
        return Container();
    }
  }

  Future<void> _submitAd() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      // تحويل الصور إلى Base64
      List<String> base64Images = [];
      for (File? image in selectedImages) {
        if (image != null) {
          List<int> imageBytes = await image.readAsBytes();
          String base64String = base64Encode(imageBytes);
          base64Images.add(base64String);
        }
      }

      // تحويل أسماء التصنيفات إلى أرقام
      Map<String, int> categoryMapping = {
        'أثاث': 1,
      };

      Map<String, int> subCategoryMapping = {
        'غرف نوم': 101,
        'أثاث مكتب': 102,
        'غرف ضيوف': 103,
        'طاولات': 104,
        'كراسي': 105,
        'خزائن': 106,
        'أثاث أطفال': 107,
        'أثاث حدائق': 108,
      };

      Map<String, dynamic> requestData = {
        'price': price,
        'currency': currency,
        'category': categoryMapping[selectedCategory] ?? 1,
        'subCategory': subCategoryMapping[selectedSubCategory] ?? 101,
        'city': selectedProvince, // API يستخدم city للمحافظة
        'region': selectedCity, // API يستخدم region للمدينة
        'createDate': DateTime.now().toIso8601String(),
        'description': description,
        'images': base64Images,
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
        _showSuccessDialog();
      } else {
        _showErrorDialog('فشل في نشر الإعلان. حاول مرة أخرى.');
      }
    } catch (e) {
      _showErrorDialog('خطأ في الاتصال. تأكد من اتصالك بالإنترنت.');
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 30),
              SizedBox(width: 10),
              Text('تم نشر الإعلان بنجاح'),
            ],
          ),
          content: Text(
            'شكراً لك! تم نشر إعلانك بنجاح.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: Text('موافق', style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red, size: 30),
              SizedBox(width: 10),
              Text('فشل في نشر الإعلان'),
            ],
          ),
          content: Text(
            message,
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('موافق', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}

// المرحلة الأولى: اختيار الصور
class ImagesSelectionStep extends StatefulWidget {
  final List<File?> selectedImages;
  final Function(List<File?>) onImagesChanged;
  final VoidCallback onNext;

  const ImagesSelectionStep({
    super.key,
    required this.selectedImages,
    required this.onImagesChanged,
    required this.onNext,
  });

  @override
  State<ImagesSelectionStep> createState() => _ImagesSelectionStepState();
}

class _ImagesSelectionStepState extends State<ImagesSelectionStep> {
  final picker = ImagePicker();
  List<File?> _images = [];

  @override
  void initState() {
    super.initState();
    _images = List.from(widget.selectedImages);
    if (_images.isEmpty) {
      _images = List.filled(6, null);
    }
  }

  Future<void> _pickImage(int index) async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _images[index] = File(pickedFile.path);
      });
      widget.onImagesChanged(_images);
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images[index] = null;
    });
    widget.onImagesChanged(_images);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'أضف صور المنتج',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text(
                  'يمكنك إضافة حتى 6 صور للمنتج. الصورة الأولى ستكون الصورة الرئيسية.',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                SizedBox(height: 30),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: 6,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          GestureDetector(
                            onTap: () => _pickImage(index),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: _images[index] != null
                                  ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(_images[index]!, fit: BoxFit.cover),
                              )
                                  : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('إضافة صورة', style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            ),
                          ),
                          if (_images[index] != null)
                            Positioned(
                              top: 5,
                              right: 5,
                              child: GestureDetector(
                                onTap: () => _removeImage(index),
                                child: Container(
                                  padding: EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.close, color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                          if (index == 0 && _images[index] != null)
                            Positioned(
                              bottom: 5,
                              left: 5,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'رئيسية',
                                  style: TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _images.any((image) => image != null) ? widget.onNext : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('متابعة', style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }
}

// المرحلة الثانية: اختيار التصنيف
class CategorySelectionStep extends StatelessWidget {
  final String selectedCategory;
  final String selectedSubCategory;
  final Function(String, String) onCategorySelected;
  final VoidCallback onBack;

  const CategorySelectionStep({
    super.key,
    required this.selectedCategory,
    required this.selectedSubCategory,
    required this.onCategorySelected,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'اختر تصنيف المنتج',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text(
                  'اختر التصنيف المناسب لمنتجك',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                SizedBox(height: 30),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SubCategoryScreen(
                          onSubCategorySelected: (subCategory) {
                            onCategorySelected('أثاث', subCategory);
                          },
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.chair, size: 40, color: Colors.deepPurple),
                        SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'أثاث',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'غرف نوم، مكاتب، كراسي، طاولات وأكثر',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: onBack,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300],
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('رجوع', style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }
}

// شاشة التصنيفات الفرعية
class SubCategoryScreen extends StatelessWidget {
  final Function(String) onSubCategorySelected;

  const SubCategoryScreen({super.key, required this.onSubCategorySelected});

  final List<Map<String, dynamic>> subCategories = const [
    {'name': 'غرف نوم', 'icon': Icons.bed},
    {'name': 'أثاث مكتب', 'icon': Icons.desk},
    {'name': 'غرف ضيوف', 'icon': Icons.weekend},
    {'name': 'طاولات', 'icon': Icons.table_restaurant},
    {'name': 'كراسي', 'icon': Icons.chair},
    {'name': 'خزائن', 'icon': Icons.storage},
    {'name': 'أثاث أطفال', 'icon': Icons.child_care},
    {'name': 'أثاث حدائق', 'icon': Icons.grass},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('اختر التصنيف الفرعي'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
          ),
          itemCount: subCategories.length,
          itemBuilder: (context, index) {
            final subCategory = subCategories[index];
            return GestureDetector(
              onTap: () {
                onSubCategorySelected(subCategory['name']);
                Navigator.pop(context);
              },
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(subCategory['icon'], size: 50, color: Colors.deepPurple),
                    SizedBox(height: 10),
                    Text(
                      subCategory['name'],
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// المرحلة الثالثة: تفاصيل الإعلان
class AdDetailsStep extends StatefulWidget {
  final String productTitle;
  final String price;
  final String currency;
  final String selectedProvince;
  final String selectedCity;
  final String description;
  final Function(String, String, String, String, String, String) onDetailsChanged;
  final VoidCallback onSubmit;
  final VoidCallback onBack;

  const AdDetailsStep({
    super.key,
    required this.productTitle,
    required this.price,
    required this.currency,
    required this.selectedProvince,
    required this.selectedCity,
    required this.description,
    required this.onDetailsChanged,
    required this.onSubmit,
    required this.onBack,
  });

  @override
  State<AdDetailsStep> createState() => _AdDetailsStepState();
}

class _AdDetailsStepState extends State<AdDetailsStep> {
  late TextEditingController _titleController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;

  String _currency = 'سوري';
  String _selectedProvince = '';
  String _selectedCity = '';

  final Map<String, List<String>> locations = {
    'إدلب': ['معرة النعمان', 'جسر الشغور', 'سراقب', 'أريحا'],
    'دمشق': ['المزة', 'البرامكة', 'باب توما', 'المالكي'],
    'حلب': ['الحمدانية', 'الفرقان', 'الشهباء', 'الصالحين'],
    'اللاذقية': ['الرمل الجنوبي', 'الرمل الشمالي', 'المشروع', 'الأزهري'],
  };

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.productTitle);
    _priceController = TextEditingController(text: widget.price);
    _descriptionController = TextEditingController(text: widget.description);
    _currency = widget.currency.isEmpty ? 'ل.س' : widget.currency;
    _selectedProvince = widget.selectedProvince.isEmpty ? 'إدلب' : widget.selectedProvince;
    _selectedCity = widget.selectedCity.isEmpty ? locations[_selectedProvince]!.first : widget.selectedCity;
  }

  void _updateData() {
    widget.onDetailsChanged(
      _titleController.text,
      _priceController.text,
      _currency,
      _selectedProvince,
      _selectedCity,
      _descriptionController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'معلومات الإعلان',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),

                  // عنوان المنتج
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'ما الذي تريد نشره؟',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onChanged: (value) => _updateData(),
                  ),
                  SizedBox(height: 15),

                  // السعر والعملة
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'السعر',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onChanged: (value) => _updateData(),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButton<String>(
                            value: _currency,
                            isExpanded: true,
                            underline: SizedBox(),
                            items: ['ل.س', 'دولار', 'ل.ت']
                                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _currency = value!;
                              });
                              _updateData();
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 15),

                  // المحافظة
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedProvince,
                      isExpanded: true,
                      underline: SizedBox(),
                      hint: Text('اختر المحافظة'),
                      items: locations.keys
                          .map((province) => DropdownMenuItem(value: province, child: Text(province)))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedProvince = value!;
                          _selectedCity = locations[_selectedProvince]!.first;
                        });
                        _updateData();
                      },
                    ),
                  ),
                  SizedBox(height: 15),

                  // المدينة
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedCity,
                      isExpanded: true,
                      underline: SizedBox(),
                      hint: Text('اختر المدينة'),
                      items: locations[_selectedProvince]!
                          .map((city) => DropdownMenuItem(value: city, child: Text(city)))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCity = value!;
                        });
                        _updateData();
                      },
                    ),
                  ),
                  SizedBox(height: 15),

                  // الوصف
                  TextField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'وصف المنتج',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      alignLabelWithHint: true,
                    ),
                    onChanged: (value) => _updateData(),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 20),

          // أزرار التنقل
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.onBack,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: Text('رجوع', style: TextStyle(fontSize: 16)),
                ),
              ),
              SizedBox(width: 15),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _canSubmit() ? widget.onSubmit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: Text('نشر الإعلان', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _canSubmit() {
    return _titleController.text.isNotEmpty &&
        _priceController.text.isNotEmpty &&
        _selectedProvince.isNotEmpty &&
        _selectedCity.isNotEmpty;
  }
}