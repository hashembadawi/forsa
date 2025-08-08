import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:syria_market/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:syria_market/utils/dialog_utils.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart';

/// Multi-step screen for adding new advertisements
class MultiStepAddAdScreen extends StatefulWidget {
  const MultiStepAddAdScreen({super.key});

  @override
  State<MultiStepAddAdScreen> createState() => _MultiStepAddAdScreenState();
}

class _MultiStepAddAdScreenState extends State<MultiStepAddAdScreen> {
  // Constants
  static const String _baseUrl = 'https://sahbo-app-api.onrender.com/api';
  static const int _totalSteps = 3;

  // Current step tracker
  int _currentStep = 0;
  
  // Form data
  final List<File?> _selectedImages = [];
  String _adTitle = '';
  String _price = '';
  String _description = '';
  LatLng? _selectedLocation;
  bool _useCurrentLocation = false;

  // Server data
  List<Map<String, dynamic>> _currencies = [];
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _subCategories = [];
  List<Map<String, dynamic>> _provinces = [];
  List<Map<String, dynamic>> _majorAreas = [];

  // Selected values
  Map<String, dynamic>? _selectedCurrency;
  Map<String, dynamic>? _selectedCategory;
  Map<String, dynamic>? _selectedSubCategory;
  Map<String, dynamic>? _selectedProvince;
  Map<String, dynamic>? _selectedMajorArea;

  // State flags
  bool _isLoadingOptions = true;
  String? _optionsError;

  @override
  void initState() {
    super.initState();
    _fetchOptions();
  }

  /// Initialize data by fetching options from server
  Future<void> _fetchOptions() async {
    setState(() {
      _isLoadingOptions = true;
      _optionsError = null;
    });

    try {
      final response = await http.get(Uri.parse('$_baseUrl/options'));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        setState(() {
          _currencies = List<Map<String, dynamic>>.from(data['currencies'] ?? []);
          _categories = List<Map<String, dynamic>>.from(data['categories'] ?? []);
          _subCategories = List<Map<String, dynamic>>.from(data['subCategories'] ?? []);
          _provinces = List<Map<String, dynamic>>.from(data['Province'] ?? []);
          _majorAreas = List<Map<String, dynamic>>.from(data['majorAreas'] ?? []);
          
          _setDefaultSelections();
          _isLoadingOptions = false;
        });
      } else {
        _handleFetchError('فشل تحميل الخيارات من الخادم');
      }
    } catch (e) {
      _handleFetchError('حدث خطأ أثناء الاتصال بالخادم');
    }
  }

  /// Set default values for dropdowns
  void _setDefaultSelections() {
    _selectedCurrency = _currencies.isNotEmpty ? _currencies[0] : null;
    _selectedCategory = _categories.isNotEmpty ? _categories[0] : null;
    _selectedSubCategory = null;
    _selectedProvince = _provinces.isNotEmpty ? _provinces[0] : null;
    _updateMajorAreaDefault();
  }

  /// Handle fetch errors
  void _handleFetchError(String errorMessage) {
    setState(() {
      _optionsError = errorMessage;
      _isLoadingOptions = false;
    });
  }

  /// Update major area when province changes
  void _updateMajorAreaDefault() {
    if (_selectedProvince != null) {
      final filteredAreas = _majorAreas
          .where((area) => area['ProvinceId'] == _selectedProvince!['id'])
          .toList();
      _selectedMajorArea = filteredAreas.isNotEmpty ? filteredAreas[0] : null;
    } else {
      _selectedMajorArea = null;
    }
  }

  /// Check internet connectivity
  Future<bool> _checkInternetConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingOptions) return _buildLoadingScreen();
    if (_optionsError != null) return _buildErrorScreen();
    return _buildMainScreen();
  }

  /// Loading screen widget
  Widget _buildLoadingScreen() {
    return Scaffold(
      appBar: _buildAppBar(),
      body: const Center(
        child: CircularProgressIndicator(color: Colors.blue),
      ),
    );
  }

  /// Error screen widget
  Widget _buildErrorScreen() {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[300],
              ),
              const SizedBox(height: 16),
              Text(
                _optionsError!,
                style: GoogleFonts.cairo(
                  color: Colors.red,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _fetchOptions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text('إعادة المحاولة', style: GoogleFonts.cairo()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Main screen widget
  Widget _buildMainScreen() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: _buildAppBar(),
        body: Container(
          color: Colors.white,
          child: Column(
            children: [
              _buildProgressIndicator(),
              Expanded(child: _buildCurrentStep()),
            ],
          ),
        ),
      ),
    );
  }

  /// App bar widget
  AppBar _buildAppBar() {
    return AppBar(
      title: Text(
        'نشر إعلان جديد',
        style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
      backgroundColor: Colors.blue[700],
      foregroundColor: Colors.white,
      elevation: 2,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => const HomeScreen(refreshOnStart: true),
            ),
            (route) => false,
          );
        },
      ),
    );
  }

  /// Progress indicator widget
  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: List.generate(_totalSteps, (index) {
              return Expanded(
                child: Container(
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: index <= _currentStep ? Colors.blue[600] : Colors.grey[300],
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

  /// Step indicator widget
  Widget _buildStepIndicator(int stepIndex, String title) {
    final isActive = stepIndex <= _currentStep;
    final isCurrentStep = stepIndex == _currentStep;
    
    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: isActive ? Colors.blue[600] : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${stepIndex + 1}',
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: GoogleFonts.cairo(
            color: isActive ? Colors.blue[600] : Colors.grey[600],
            fontWeight: isCurrentStep ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Current step widget
  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return ImagesSelectionStep(
          selectedImages: _selectedImages,
          onImagesChanged: (images) => setState(() {
            _selectedImages.clear();
            _selectedImages.addAll(images);
          }),
          onNext: () => setState(() => _currentStep = 1),
        );
      case 1:
        return CategorySelectionStep(
          categories: _categories,
          subCategories: _subCategories,
          selectedCategory: _selectedCategory,
          selectedSubCategory: _selectedSubCategory,
          onCategorySelected: (cat, subCat) {
            setState(() {
              _selectedCategory = cat;
              _selectedSubCategory = subCat;
              _currentStep = 2;
            });
          },
          onBack: () => setState(() => _currentStep = 0),
        );
      case 2:
        return AdDetailsStep(
          adTitle: _adTitle,
          price: _price,
          description: _description,
          currencies: _currencies,
          selectedCurrency: _selectedCurrency,
          provinces: _provinces,
          selectedProvince: _selectedProvince,
          majorAreas: _majorAreas,
          selectedMajorArea: _selectedMajorArea,
          selectedLocation: _selectedLocation,
          useCurrentLocation: _useCurrentLocation,
          onDetailsChanged: (title, price, desc, currency, province, area, location, useCurrentLoc) {
            setState(() {
              _adTitle = title;
              _price = price;
              _description = desc;
              _selectedCurrency = currency;
              _selectedProvince = province;
              _selectedMajorArea = area;
              _selectedLocation = location;
              _useCurrentLocation = useCurrentLoc;
            });
          },
          onSubmit: _submitAd,
          onBack: () => setState(() => _currentStep = 1),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  /// Submit ad method
  Future<void> _submitAd() async {
    final isConnected = await _checkInternetConnectivity();
    if (!isConnected) {
      _showNoInternetDialog();
      return;
    }

    _showUploadingDialog();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final userId = prefs.getString('userId') ?? '';
      final userPhone = prefs.getString('userPhone') ?? '';
      final username = prefs.getString('userName') ?? '';

      final base64Images = await _processImages();
      final requestData = _buildRequestData(
        userId: userId,
        userPhone: userPhone,
        username: username,
        base64Images: base64Images,
      );

      final response = await http.post(
        Uri.parse('$_baseUrl/ads/userAds/add'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestData),
      );

      Navigator.of(context).pop(); // Close loading dialog
      
      if (response.statusCode == 201) {
        _showSuccessDialog();
      } else {
        _showErrorDialog('فشل في نشر الإعلان');
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      _showErrorDialog('حدث خطأ أثناء الاتصال بالخادم');
    }
  }

  /// Process images for upload
  Future<List<String>> _processImages() async {
    final base64Images = <String>[];
    
    for (final image in _selectedImages.where((img) => img != null)) {
      final compressedBytes = await FlutterImageCompress.compressWithFile(
        image!.path,
        minWidth: 250,    // Maximum width of 250px
        minHeight: 250,   // Maximum height of 250px
        quality: 30,       // Very low quality (1-100, lower = smaller file)
        format: CompressFormat.jpeg,
        rotate: 0,
      );
      
      if (compressedBytes != null) {
        base64Images.add(base64Encode(compressedBytes));
      }
    }
    
    return base64Images;
  }

  /// Build request data
  Map<String, dynamic> _buildRequestData({
    required String userId,
    required String userPhone,
    required String username,
    required List<String> base64Images,
  }) {
    final Map<String, dynamic> requestData = {
      'userId': userId,
      'userPhone': userPhone,
      'userName': username,
      'adTitle': _adTitle,
      'price': _price,
      'currencyId': _selectedCurrency?['id'],
      'currencyName': _selectedCurrency?['name'],
      'categoryId': _selectedCategory?['id'],
      'categoryName': _selectedCategory?['name'],
      'subCategoryId': _selectedSubCategory?['id'],
      'subCategoryName': _selectedSubCategory?['name'],
      'cityId': _selectedProvince?['id'],
      'cityName': _selectedProvince?['name'],
      'regionId': _selectedMajorArea?['id'],
      'regionName': _selectedMajorArea?['name'],
      'description': _description,
      'images': base64Images,
    };

    // Add location data if available
    if (_selectedLocation != null) {
      requestData['location'] = {
        'type': 'Point',
        'coordinates': [_selectedLocation!.longitude, _selectedLocation!.latitude],
      };
    }

    return requestData;
  }

  // Dialog methods
  void _showUploadingDialog() {
    DialogUtils.showLoadingDialog(
      context: context,
      title: 'جارٍ رفع الإعلان...',
      message: 'يرجى الانتظار حتى يتم إرسال البيانات',
    );
  }

  void _showSuccessDialog() {
    DialogUtils.showSuccessDialog(
      context: context,
      title: 'تم بنجاح',
      message: 'تم اضافة اعلانك بنجاح يرجى متابعة حالته في صفحة إعلاناتي',
      buttonText: 'موافق',
      onPressed: () {
        Navigator.of(context).pop(); // Close dialog
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const HomeScreen(refreshOnStart: true),
          ),
          (route) => false,
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    DialogUtils.showErrorDialog(
      context: context,
      title: 'خطأ',
      message: message,
      buttonText: 'موافق',
    );
  }

  void _showNoInternetDialog() {
    DialogUtils.showNoInternetDialog(
      context: context,
      onRetry: () {
        Navigator.of(context).pop();
        _submitAd(); // Retry the submission
      },
    );
  }
}

/// Images Selection Step Widget
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
  final ImagePicker _picker = ImagePicker();
  late List<File?> _images;

  @override
  void initState() {
    super.initState();
    _images = List.from(widget.selectedImages);
    if (_images.isEmpty) {
      _images = List.filled(6, null);
    }
  }

  Future<void> _pickImage(int index) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
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
                  style: GoogleFonts.cairo(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'يمكنك إضافة حتى 6 صور للمنتج. الصورة الأولى ستكون الصورة الرئيسية.',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 30),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: 6,
                    itemBuilder: (context, index) => _buildImageSlot(index),
                  ),
                ),
              ],
            ),
          ),
          _buildContinueButton(),
        ],
      ),
    );
  }

  Widget _buildImageSlot(int index) {
    return Stack(
      children: [
        GestureDetector(
          onTap: () => _pickImage(index),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[300]!),
            ),
            child: _images[index] != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _images[index]!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate,
                          size: 30,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'إضافة صورة',
                          style: GoogleFonts.cairo(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
        if (_images[index] != null) ...[
          // Remove button
          Positioned(
            top: 5,
            right: 5,
            child: GestureDetector(
              onTap: () => _removeImage(index),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          // Main image indicator
          if (index == 0)
            Positioned(
              bottom: 5,
              left: 5,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'رئيسية',
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _images.any((image) => image != null) ? widget.onNext : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          'متابعة',
          style: GoogleFonts.cairo(fontSize: 18),
        ),
      ),
    );
  }
}

/// Category Selection Step Widget
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
    _selectedCategory = widget.selectedCategory ?? 
        (widget.categories.isNotEmpty ? widget.categories[0] : null);
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
                  style: GoogleFonts.cairo(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'اختر التصنيف المناسب لمنتجك',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 30),
                _buildCategoryDropdown(),
                const SizedBox(height: 20),
                _buildSubCategoryDropdown(),
              ],
            ),
          ),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<Map<String, dynamic>>(
      value: _selectedCategory,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'التصنيف الرئيسي',
        labelStyle: GoogleFonts.cairo(),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      items: widget.categories
          .map((cat) => DropdownMenuItem(
                value: cat,
                child: Text(cat['name'] ?? '', style: GoogleFonts.cairo()),
              ))
          .toList(),
      onChanged: (cat) {
        setState(() {
          _selectedCategory = cat;
          _filterSubCategories();
        });
      },
    );
  }

  Widget _buildSubCategoryDropdown() {
    return DropdownButtonFormField<Map<String, dynamic>>(
      value: _selectedSubCategory,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'التصنيف الفرعي',
        labelStyle: GoogleFonts.cairo(),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      items: _filteredSubCategories
          .map((subCat) => DropdownMenuItem(
                value: subCat,
                child: Text(subCat['name'] ?? '', style: GoogleFonts.cairo()),
              ))
          .toList(),
      onChanged: (subCat) {
        setState(() {
          _selectedSubCategory = subCat;
        });
      },
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: widget.onBack,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[300],
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'رجوع',
              style: GoogleFonts.cairo(fontSize: 18),
            ),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: ElevatedButton(
            onPressed: (_selectedCategory != null && _selectedSubCategory != null)
                ? () => widget.onCategorySelected(_selectedCategory!, _selectedSubCategory!)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'متابعة',
              style: GoogleFonts.cairo(fontSize: 18),
            ),
          ),
        ),
      ],
    );
  }
}

/// Ad Details Step Widget
class AdDetailsStep extends StatefulWidget {
  final String adTitle;
  final String price;
  final String description;
  final List<Map<String, dynamic>> currencies;
  final Map<String, dynamic>? selectedCurrency;
  final List<Map<String, dynamic>> provinces;
  final Map<String, dynamic>? selectedProvince;
  final List<Map<String, dynamic>> majorAreas;
  final Map<String, dynamic>? selectedMajorArea;
  final LatLng? selectedLocation;
  final bool useCurrentLocation;
  final Function(
    String,
    String,
    String,
    Map<String, dynamic>?,
    Map<String, dynamic>?,
    Map<String, dynamic>?,
    LatLng?,
    bool,
  ) onDetailsChanged;
  final VoidCallback onSubmit;
  final VoidCallback onBack;

  const AdDetailsStep({
    super.key,
    required this.adTitle,
    required this.price,
    required this.description,
    required this.currencies,
    required this.selectedCurrency,
    required this.provinces,
    required this.selectedProvince,
    required this.majorAreas,
    required this.selectedMajorArea,
    this.selectedLocation,
    this.useCurrentLocation = false,
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
  LatLng? _selectedLocation;
  bool _useCurrentLocation = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.adTitle);
    _priceController = TextEditingController(text: widget.price);
    _descriptionController = TextEditingController(text: widget.description);
    
    _selectedCurrency = widget.selectedCurrency ?? 
        (widget.currencies.isNotEmpty ? widget.currencies[0] : null);
    _selectedProvince = widget.selectedProvince ?? 
        (widget.provinces.isNotEmpty ? widget.provinces[0] : null);
    _selectedLocation = widget.selectedLocation;
    _useCurrentLocation = widget.useCurrentLocation;
    
    _updateMajorAreaDefault();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _updateMajorAreaDefault() {
    if (_selectedProvince != null) {
      final filtered = widget.majorAreas
          .where((area) => area['ProvinceId'] == _selectedProvince!['id'])
          .toList();
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
      _selectedLocation,
      _useCurrentLocation,
    );
  }

  bool _canSubmit() {
    return _titleController.text.isNotEmpty &&
        _priceController.text.isNotEmpty &&
        _selectedCurrency != null &&
        _selectedProvince != null &&
        _selectedMajorArea != null;
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check and request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showLocationPermissionDialog();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showLocationPermissionDialog();
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
        _useCurrentLocation = true;
      });
      _updateData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تحديد موقعك الحالي', style: GoogleFonts.cairo()),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ في تحديد الموقع', style: GoogleFonts.cairo()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('إذن الموقع مطلوب', style: GoogleFonts.cairo()),
        content: Text('يرجى منح التطبيق إذن الوصول للموقع لاستخدام هذه الميزة', style: GoogleFonts.cairo()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: Text('الإعدادات', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
  }

  void _selectLocationOnMap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapLocationPicker(
          initialLocation: _selectedLocation ?? const LatLng(33.5138, 36.2765), // Default to Damascus
          onLocationSelected: (location) {
            setState(() {
              _selectedLocation = location;
              _useCurrentLocation = false;
            });
            _updateData();
          },
        ),
      ),
    );
  }

  void _clearLocation() {
    setState(() {
      _selectedLocation = null;
      _useCurrentLocation = false;
    });
    _updateData();
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
                    style: GoogleFonts.cairo(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildTitleField(),
                  const SizedBox(height: 15),
                  _buildPriceRow(),
                  const SizedBox(height: 15),
                  _buildProvinceDropdown(),
                  const SizedBox(height: 15),
                  _buildMajorAreaDropdown(),
                  const SizedBox(height: 15),
                  _buildLocationSection(),
                  const SizedBox(height: 15),
                  _buildDescriptionField(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildTitleField() {
    return TextField(
      controller: _titleController,
      decoration: InputDecoration(
        labelText: 'عنوان الإعلان',
        labelStyle: GoogleFonts.cairo(),
        hintText: 'أدخل عنوان جذاب للمنتج',
        hintStyle: GoogleFonts.cairo(),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      onChanged: (_) => _updateData(),
    );
  }

  Widget _buildPriceRow() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: TextField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'السعر',
              labelStyle: GoogleFonts.cairo(),
              hintText: '0',
              hintStyle: GoogleFonts.cairo(),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: (_) => _updateData(),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: DropdownButtonFormField<Map<String, dynamic>>(
            value: _selectedCurrency,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'العملة',
              labelStyle: GoogleFonts.cairo(),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            items: widget.currencies
                .map((currency) => DropdownMenuItem(
                      value: currency,
                      child: Text(currency['name'] ?? '', style: GoogleFonts.cairo()),
                    ))
                .toList(),
            onChanged: (currency) {
              setState(() {
                _selectedCurrency = currency;
              });
              _updateData();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProvinceDropdown() {
    return DropdownButtonFormField<Map<String, dynamic>>(
      value: _selectedProvince,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'المحافظة',
        labelStyle: GoogleFonts.cairo(),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      items: widget.provinces
          .map((province) => DropdownMenuItem(
                value: province,
                child: Text(province['name'] ?? '', style: GoogleFonts.cairo()),
              ))
          .toList(),
      onChanged: (province) {
        setState(() {
          _selectedProvince = province;
          _updateMajorAreaDefault();
        });
        _updateData();
      },
    );
  }

  Widget _buildMajorAreaDropdown() {
    final filteredAreas = widget.majorAreas
        .where((area) => 
            _selectedProvince != null && 
            area['ProvinceId'] == _selectedProvince!['id'])
        .toList();

    return DropdownButtonFormField<Map<String, dynamic>>(
      value: _selectedMajorArea,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'المنطقة',
        labelStyle: GoogleFonts.cairo(),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      items: filteredAreas
          .map((area) => DropdownMenuItem(
                value: area,
                child: Text(area['name'] ?? '', style: GoogleFonts.cairo()),
              ))
          .toList(),
      onChanged: (area) {
        setState(() {
          _selectedMajorArea = area;
        });
        _updateData();
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextField(
      controller: _descriptionController,
      maxLines: 4,
      decoration: InputDecoration(
        labelText: 'وصف المنتج',
        labelStyle: GoogleFonts.cairo(),
        hintText: 'أدخل وصفاً تفصيلياً للمنتج...',
        hintStyle: GoogleFonts.cairo(),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        alignLabelWithHint: true,
      ),
      onChanged: (_) => _updateData(),
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الموقع (اختياري)',
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        if (_selectedLocation != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.green),
              borderRadius: BorderRadius.circular(10),
              color: Colors.green.shade50,
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _useCurrentLocation 
                        ? 'تم تحديد موقعك الحالي'
                        : 'تم تحديد الموقع على الخريطة',
                    style: GoogleFonts.cairo(color: Colors.green),
                  ),
                ),
                IconButton(
                  onPressed: _clearLocation,
                  icon: const Icon(Icons.clear, color: Colors.red),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _getCurrentLocation,
                icon: const Icon(Icons.my_location),
                label: Text('موقعي الحالي', style: GoogleFonts.cairo()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _selectLocationOnMap,
                icon: const Icon(Icons.map),
                label: Text('اختر من الخريطة', style: GoogleFonts.cairo()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: widget.onBack,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[300],
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'رجوع',
              style: GoogleFonts.cairo(fontSize: 16),
            ),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _canSubmit() ? widget.onSubmit : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'نشر الإعلان',
              style: GoogleFonts.cairo(fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}

/// Map Location Picker Widget
class MapLocationPicker extends StatefulWidget {
  final LatLng initialLocation;
  final Function(LatLng) onLocationSelected;

  const MapLocationPicker({
    super.key,
    required this.initialLocation,
    required this.onLocationSelected,
  });

  @override
  State<MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  LatLng? _selectedLocation;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
    _updateMarker();
  }

  void _updateMarker() {
    if (_selectedLocation != null) {
      setState(() {
        _markers = {
          Marker(
            markerId: const MarkerId('selected_location'),
            position: _selectedLocation!,
            infoWindow: const InfoWindow(title: 'الموقع المحدد'),
          ),
        };
      });
    }
  }

  void _onMapTapped(LatLng location) {
    setState(() {
      _selectedLocation = location;
    });
    _updateMarker();
  }

  void _confirmLocation() {
    if (_selectedLocation != null) {
      widget.onLocationSelected(_selectedLocation!);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('اختر الموقع', style: GoogleFonts.cairo()),
          backgroundColor: Colors.blue[700],
          foregroundColor: Colors.white,
          actions: [
            TextButton(
              onPressed: _confirmLocation,
              child: Text(
                'تأكيد',
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue[50],
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'اضغط على الخريطة لتحديد موقع الإعلان',
                      style: GoogleFonts.cairo(color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: widget.initialLocation,
                  zoom: 14.0,
                ),
                onTap: _onMapTapped,
                markers: _markers,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                mapType: MapType.normal,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _selectedLocation != null ? _confirmLocation : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'تأكيد الموقع',
                    style: GoogleFonts.cairo(fontSize: 18),
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
