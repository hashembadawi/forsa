import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class MultiStepAddAdScreen extends StatefulWidget {
  const MultiStepAddAdScreen({super.key});

  @override
  State<MultiStepAddAdScreen> createState() => _MultiStepAddAdScreenState();
}

class _MultiStepAddAdScreenState extends State<MultiStepAddAdScreen> {
  int currentStep = 0;
  List<File?> selectedImages = [];
  String selectedCategory = '';
  String selectedSubCategory = '';
  String productTitle = '';
  String price = '';
  String currency = 'ل.س';
  String selectedProvince = '';
  String selectedCity = '';
  String description = '';
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'نشر إعلان جديد',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          elevation: 2,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.deepPurple.shade50,
                Colors.deepPurple.shade100.withOpacity(0.3),
              ],
            ),
          ),
          child: Column(
            children: [
              _buildProgressIndicator(),
              Expanded(
                child: _buildCurrentStep(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: List.generate(3, (index) {
              return Expanded(
                child: Container(
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: index <= currentStep ? Colors.deepPurple : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStepIndicator(0, 'إضافة الصور'),
              _buildStepIndicator(1, 'اختيار التصنيف'),
              _buildStepIndicator(2, 'معلومات الإعلان'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int stepIndex, String title) {
    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: stepIndex <= currentStep ? Colors.deepPurple : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${stepIndex + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            color: stepIndex <= currentStep ? Colors.deepPurple : Colors.grey[600],
            fontWeight: stepIndex == currentStep ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentStep() {
    switch (currentStep) {
      case 0:
        return ImagesSelectionStep(
          selectedImages: selectedImages,
          onImagesChanged: (images) => setState(() => selectedImages = images),
          onNext: () => setState(() => currentStep = 1),
        );
      case 1:
        return CategorySelectionStep(
          selectedCategory: selectedCategory,
          selectedSubCategory: selectedSubCategory,
          onCategorySelected: (category, subCategory) => setState(() {
            selectedCategory = category;
            selectedSubCategory = subCategory;
            currentStep = 2;
          }),
          onBack: () => setState(() => currentStep = 0),
        );
      case 2:
        return AdDetailsStep(
          productTitle: productTitle,
          price: price,
          currency: currency,
          selectedProvince: selectedProvince,
          selectedCity: selectedCity,
          description: description,
          onDetailsChanged: (title, p, c, province, city, desc) => setState(() {
            productTitle = title;
            price = p;
            currency = c;
            selectedProvince = province;
            selectedCity = city;
            description = desc;
          }),
          onSubmit: _submitAd,
          onBack: () => setState(() => currentStep = 1),
        );
      default:
        return Container();
    }
  }

  Future<void> _submitAd() async {
    setState(() => _isUploading = true);
    _showUploadingDialog();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      List<String> base64Images = [];
      for (File? image in selectedImages.where((img) => img != null)) {
        final compressedBytes = await FlutterImageCompress.compressWithFile(
          image!.path,
          quality: 60,
          format: CompressFormat.jpeg,
        );
        if (compressedBytes != null) {
          base64Images.add(base64Encode(compressedBytes));
        }
      }

      Map<String, dynamic> requestData = {
        'userId': prefs.getString('userId'),
        'productTitle': productTitle,
        'price': price,
        'currency': currency,
        'category': _getCategoryId(selectedCategory),
        'subCategory': _getSubCategoryId(selectedSubCategory),
        'city': selectedProvince,
        'region': selectedCity,
        'createDate': DateTime.now().toIso8601String(),
        'description': description,
        'images': base64Images,
      };

      final response = await http.post(
        Uri.parse('http://localhost:10000/api/userProducts/add'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
        body: jsonEncode(requestData),
      );

      Navigator.of(context).pop();
      response.statusCode == 201 ? _showSuccessDialog() : _showErrorDialog('فشل في نشر الإعلان');
    } catch (e) {
      Navigator.of(context).pop();
      _showErrorDialog('حدث خطأ أثناء الاتصال بالخادم');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  int _getCategoryId(String category) {
    const categoryMapping = {'أثاث': 1};
    return categoryMapping[category] ?? 1;
  }

  int _getSubCategoryId(String subCategory) {
    const subCategoryMapping = {
      'غرف نوم': 101,
      'أثاث مكتب': 102,
      'غرف ضيوف': 103,
      'طاولات': 104,
      'كراسي': 105,
      'خزائن': 106,
      'أثاث أطفال': 107,
      'أثاث حدائق': 108,
    };
    return subCategoryMapping[subCategory] ?? 101;
  }

  void _showUploadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
            ),
            const SizedBox(height: 20),
            const Text(
              'جارٍ رفع الإعلان...',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'يرجى الانتظار حتى يتم إرسال البيانات',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 10),
            Text('تم بنجاح'),
          ],
        ),
        content: const Text('تم نشر إعلانك بنجاح'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('موافق', style: TextStyle(color: Colors.deepPurple)),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 10),
            Text('خطأ'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('موافق', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

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
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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

  String _currency = 'ل.س';
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

                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'ما الذي تريد نشره؟',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onChanged: (value) => _updateData(),
                  ),
                  SizedBox(height: 15),

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