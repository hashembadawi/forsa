import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:sahbo_app/screens/home_screen.dart';
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
  String productTitle = '';
  String price = '';
  String description = '';

  // Option data from server
  List<Map<String, dynamic>> currencies = [];
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> subCategories = [];
  List<Map<String, dynamic>> provinces = [];
  List<Map<String, dynamic>> majorAreas = [];

  // Selected values (IDs and Names)
  Map<String, dynamic>? selectedCurrency;
  Map<String, dynamic>? selectedCategory;
  Map<String, dynamic>? selectedSubCategory;
  Map<String, dynamic>? selectedProvince;
  Map<String, dynamic>? selectedMajorArea;

  bool _isUploading = false;
  bool _isLoadingOptions = true;
  String? _optionsError;

  @override
  void initState() {
    super.initState();
    _fetchOptions();
  }

  Future<void> _fetchOptions() async {
    setState(() {
      _isLoadingOptions = true;
      _optionsError = null;
    });
    try {
      final response = await http.get(Uri.parse('https://sahbo-app-api.onrender.com/api/options'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          currencies = List<Map<String, dynamic>>.from(data['currencies']);
          categories = List<Map<String, dynamic>>.from(data['categories']);
          subCategories = List<Map<String, dynamic>>.from(data['subCategories']);
          provinces = List<Map<String, dynamic>>.from(data['Province']);
          majorAreas = List<Map<String, dynamic>>.from(data['majorAreas']);
          // Set defaults
          selectedCurrency = currencies.isNotEmpty ? currencies[0] : null;
          selectedCategory = categories.isNotEmpty ? categories[0] : null;
          selectedSubCategory = null;
          selectedProvince = provinces.isNotEmpty ? provinces[0] : null;
          _updateMajorAreaDefault();
          _isLoadingOptions = false;
        });
      } else {
        setState(() {
          _optionsError = 'فشل تحميل الخيارات من الخادم';
          _isLoadingOptions = false;
        });
      }
    } catch (e) {
      setState(() {
        _optionsError = 'حدث خطأ أثناء الاتصال بالخادم';
        _isLoadingOptions = false;
      });
    }
  }

  void _updateMajorAreaDefault() {
    if (selectedProvince != null) {
      final filtered = majorAreas.where((area) => area['ProvinceId'] == selectedProvince!['id']).toList();
      selectedMajorArea = filtered.isNotEmpty ? filtered[0] : null;
    } else {
      selectedMajorArea = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingOptions) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('نشر إعلان جديد'),
          backgroundColor: const Color(0xFF1E4A47),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFF4DD0CC))),
      );
    }
    if (_optionsError != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('نشر إعلان جديد'),
          backgroundColor: const Color(0xFF1E4A47),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_optionsError!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _fetchOptions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E4A47),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'نشر إعلان جديد',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: const Color(0xFF1E4A47),
          foregroundColor: Colors.white,
          elevation: 2,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF7FE8E4),
                Colors.white,
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
                    color: index <= currentStep ? const Color(0xFF1E4A47) : Colors.grey[300],
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
            color: stepIndex <= currentStep ? const Color(0xFF1E4A47) : Colors.grey[300],
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
            color: stepIndex <= currentStep ? const Color(0xFF1E4A47) : Colors.grey[600],
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
          categories: categories,
          subCategories: subCategories,
          selectedCategory: selectedCategory,
          selectedSubCategory: selectedSubCategory,
          onCategorySelected: (cat, subCat) {
            setState(() {
              selectedCategory = cat;
              selectedSubCategory = subCat;
              currentStep = 2;
            });
          },
          onBack: () => setState(() => currentStep = 0),
        );
      case 2:
        return AdDetailsStep(
          productTitle: productTitle,
          price: price,
          description: description,
          currencies: currencies,
          selectedCurrency: selectedCurrency,
          provinces: provinces,
          selectedProvince: selectedProvince,
          majorAreas: majorAreas,
          selectedMajorArea: selectedMajorArea,
          onDetailsChanged: (title, p, desc, currency, province, area) {
            setState(() {
              productTitle = title;
              price = p;
              description = desc;
              selectedCurrency = currency;
              selectedProvince = province;
              selectedMajorArea = area;
            });
          },
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
      final userId = prefs.getString('userId') ?? '';
      final userPhone = prefs.getString('userPhone') ?? '';
      final username = prefs.getString('userName') ?? '';

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
        'userId': userId,
        'userPhone': userPhone,
        'userName': username,
        'productTitle': productTitle,
        'price': price,
        'currencyId': selectedCurrency?['id'],
        'currencyName': selectedCurrency?['name'],
        'categoryId': selectedCategory?['id'],
        'categoryName': selectedCategory?['name'],
        'subCategoryId': selectedSubCategory?['id'],
        'subCategoryName': selectedSubCategory?['name'],
        'cityId': selectedProvince?['id'],
        'cityName': selectedProvince?['name'],
        'regionId': selectedMajorArea?['id'],
        'regionName': selectedMajorArea?['name'],
        'description': description,
        'images': base64Images,
      };

      final response = await http.post(
        Uri.parse('https://sahbo-app-api.onrender.com/api/userProducts/add'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
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
              color: Color(0xFF1E4A47),
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
            Navigator.of(context).pop(); // Close dialog
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => const HomeScreen(refreshOnStart: true),
              ),
              (route) => false,
            );
          },
          child: const Text('موافق', style: TextStyle(color: Color(0xFF1E4A47))),
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
            child: const Text('موافق', style: TextStyle(color: Color(0xFFFF7A59))),
          ),
        ],
      ),
    );
  }
}

// --- ImagesSelectionStep remains unchanged ---

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
                backgroundColor: const Color(0xFF1E4A47),
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

// --- CategorySelectionStep updated to use server data ---
class CategorySelectionStep extends StatefulWidget {
  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> subCategories;
  final Map<String, dynamic>? selectedCategory;
  final Map<String, dynamic>? selectedSubCategory;
  final Function(Map<String, dynamic>, Map<String, dynamic>) onCategorySelected;
  final VoidCallback onBack;

  const CategorySelectionStep({
    super.key,
    required this.categories,
    required this.subCategories,
    required this.selectedCategory,
    required this.selectedSubCategory,
    required this.onCategorySelected,
    required this.onBack,
  });

  @override
  State<CategorySelectionStep> createState() => _CategorySelectionStepState();
}

class _CategorySelectionStepState extends State<CategorySelectionStep> {
  Map<String, dynamic>? _selectedCategory;
  Map<String, dynamic>? _selectedSubCategory;
  List<Map<String, dynamic>> _filteredSubCategories = [];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.selectedCategory ?? (widget.categories.isNotEmpty ? widget.categories[0] : null);
    _filterSubCategories();
    _selectedSubCategory = widget.selectedSubCategory;
  }

  void _filterSubCategories() {
    if (_selectedCategory != null) {
      _filteredSubCategories = widget.subCategories
          .where((s) => s['categoryId'] == _selectedCategory!['id'])
          .toList();
    } else {
      _filteredSubCategories = [];
    }
    if (!_filteredSubCategories.contains(_selectedSubCategory)) {
      _selectedSubCategory = null;
    }
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
                  'اختر تصنيف المنتج',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text(
                  'اختر التصنيف المناسب لمنتجك',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                SizedBox(height: 30),
                DropdownButtonFormField<Map<String, dynamic>>(
                  value: _selectedCategory,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'التصنيف الرئيسي',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: widget.categories
                      .map((cat) => DropdownMenuItem(
                    value: cat,
                    child: Text(cat['name']),
                  ))
                      .toList(),
                  onChanged: (cat) {
                    setState(() {
                      _selectedCategory = cat;
                      _selectedSubCategory = null;
                      _filterSubCategories();
                    });
                  },
                ),
                SizedBox(height: 20),
                DropdownButtonFormField<Map<String, dynamic>>(
                  value: _selectedSubCategory,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'التصنيف الفرعي',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: _filteredSubCategories
                      .map((subCat) => DropdownMenuItem(
                    value: subCat,
                    child: Text(subCat['name']),
                  ))
                      .toList(),
                  onChanged: (subCat) {
                    setState(() {
                      _selectedSubCategory = subCat;
                    });
                  },
                ),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.onBack,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('رجوع', style: TextStyle(fontSize: 18)),
                ),
              ),
              SizedBox(width: 15),
              Expanded(
                child: ElevatedButton(
                  onPressed: (_selectedCategory != null && _selectedSubCategory != null)
                      ? () => widget.onCategorySelected(_selectedCategory!, _selectedSubCategory!)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E4A47),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('متابعة', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- AdDetailsStep updated to use server data ---

class AdDetailsStep extends StatefulWidget {
  final String productTitle;
  final String price;
  final String description;
  final List<Map<String, dynamic>> currencies;
  final Map<String, dynamic>? selectedCurrency;
  final List<Map<String, dynamic>> provinces;
  final Map<String, dynamic>? selectedProvince;
  final List<Map<String, dynamic>> majorAreas;
  final Map<String, dynamic>? selectedMajorArea;
  final Function(
      String,
      String,
      String,
      Map<String, dynamic>?,
      Map<String, dynamic>?,
      Map<String, dynamic>?,
      ) onDetailsChanged;
  final VoidCallback onSubmit;
  final VoidCallback onBack;

  const AdDetailsStep({
    super.key,
    required this.productTitle,
    required this.price,
    required this.description,
    required this.currencies,
    required this.selectedCurrency,
    required this.provinces,
    required this.selectedProvince,
    required this.majorAreas,
    required this.selectedMajorArea,
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

  Map<String, dynamic>? _selectedCurrency;
  Map<String, dynamic>? _selectedProvince;
  Map<String, dynamic>? _selectedMajorArea;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.productTitle);
    _priceController = TextEditingController(text: widget.price);
    _descriptionController = TextEditingController(text: widget.description);
    _selectedCurrency = widget.selectedCurrency ?? (widget.currencies.isNotEmpty ? widget.currencies[0] : null);
    _selectedProvince = widget.selectedProvince ?? (widget.provinces.isNotEmpty ? widget.provinces[0] : null);
    _updateMajorAreaDefault();
  }

  void _updateMajorAreaDefault() {
    if (_selectedProvince != null) {
      final filtered = widget.majorAreas.where((area) => area['ProvinceId'] == _selectedProvince!['id']).toList();
      _selectedMajorArea = filtered.isNotEmpty ? filtered[0] : null;
    } else {
      _selectedMajorArea = null;
    }
  }

  void _updateData() {
    widget.onDetailsChanged(
      _titleController.text,
      _priceController.text,
      _descriptionController.text,
      _selectedCurrency,
      _selectedProvince,
      _selectedMajorArea,
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
                          child: DropdownButton<Map<String, dynamic>>(
                            value: _selectedCurrency,
                            isExpanded: true,
                            underline: SizedBox(),
                            items: widget.currencies
                                .map((c) => DropdownMenuItem(value: c, child: Text(c['name'])))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCurrency = value;
                              });
                              _updateData();
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 15),

                  DropdownButtonFormField<Map<String, dynamic>>(
                    value: _selectedProvince,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'اختر المحافظة',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: widget.provinces
                        .map((province) => DropdownMenuItem(
                      value: province,
                      child: Text(province['name']),
                    ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedProvince = value;
                        // Update major area
                        final filtered = widget.majorAreas.where((area) => area['ProvinceId'] == _selectedProvince!['id']).toList();
                        _selectedMajorArea = filtered.isNotEmpty ? filtered[0] : null;
                      });
                      _updateData();
                    },
                  ),
                  SizedBox(height: 15),

                  DropdownButtonFormField<Map<String, dynamic>>(
                    value: _selectedMajorArea,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'اختر المدينة/المنطقة',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: widget.majorAreas
                        .where((area) => _selectedProvince != null && area['ProvinceId'] == _selectedProvince!['id'])
                        .map((area) => DropdownMenuItem(
                      value: area,
                      child: Text(area['name']),
                    ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedMajorArea = value;
                      });
                      _updateData();
                    },
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
                    backgroundColor: const Color(0xFF1E4A47),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: const Text('نشر الإعلان', style: TextStyle(fontSize: 16)),
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
        _selectedCurrency != null &&
        _selectedProvince != null &&
        _selectedMajorArea != null;
  }
}