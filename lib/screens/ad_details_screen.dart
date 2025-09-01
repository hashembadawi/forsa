import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/ad_card_widget.dart';
import 'home_screen.dart' as home;

import 'advertiser_page_screen.dart';
import 'login_screen.dart';
import '../utils/dialog_utils.dart';

// Models for better type safety
class AdModel {
  final String? id;
  final String? adTitle;
  final String? description;
  final String? price;
  final String? currencyName;
  final String? categoryName;
  final String? subCategoryName;
  final String? cityName;
  final String? regionName;
  final String? userName;
  final String? userPhone;
  final String? userId;
  final String? categoryId;
  final String? subCategoryId;
  final String? createDate;
  final List<String>? images;
  final LocationModel? location;
  final bool? forSale;
  final bool? deliveryService;

  AdModel({
    this.id,
    this.adTitle,
    this.description,
    this.price,
    this.currencyName,
    this.categoryName,
    this.subCategoryName,
    this.cityName,
    this.regionName,
    this.userName,
    this.userPhone,
    this.userId,
    this.categoryId,
    this.subCategoryId,
    this.createDate,
    this.images,
    this.location,
    this.forSale,
    this.deliveryService,
  });

  factory AdModel.fromJson(Map<String, dynamic> json) {
    return AdModel(
      id: json['_id'],
      adTitle: json['adTitle'],
      description: json['description'],
      price: json['price']?.toString(),
      currencyName: json['currencyName'],
      categoryName: json['categoryName'],
      subCategoryName: json['subCategoryName'],
      cityName: json['cityName'],
      regionName: json['regionName'],
      userName: json['userName'],
      userPhone: json['userPhone'],
      userId: json['userId'],
      categoryId: json['categoryId']?.toString(),
      subCategoryId: json['subCategoryId']?.toString(),
      createDate: json['createDate'],
      images: json['images'] is List ? List<String>.from(json['images']) : null,
      location: json['location'] != null ? LocationModel.fromJson(json['location']) : null,
      forSale: json['forSale'],
      deliveryService: json['deliveryService'],
    );
  }
}

class LocationModel {
  final List<double>? coordinates;

  LocationModel({this.coordinates});

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      coordinates: json['coordinates'] is List 
        ? List<double>.from(json['coordinates'].map((e) => e?.toDouble() ?? 0.0))
        : null,
    );
  }

  double? get longitude => coordinates != null && coordinates!.length >= 2 ? coordinates![0] : null;
  double? get latitude => coordinates != null && coordinates!.length >= 2 ? coordinates![1] : null;
  bool get isValid => longitude != null && latitude != null && longitude != 0.0 && latitude != 0.0;
}

class AdDetailsScreen extends StatefulWidget {
  final dynamic ad;

  const AdDetailsScreen({super.key, required this.ad});

  @override
  State<AdDetailsScreen> createState() => _AdDetailsScreenState();
}

class _AdDetailsScreenState extends State<AdDetailsScreen> with AutomaticKeepAliveClientMixin {
  void _showBuiltInImageViewer(List<String> images, int initialIndex) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: const EdgeInsets.all(0),
          child: StatefulBuilder(
            builder: (context, setState) {
              int currentIndex = initialIndex;
              return Stack(
                children: [
                  PageView.builder(
                    itemCount: images.length,
                    controller: PageController(initialPage: initialIndex),
                    onPageChanged: (i) => setState(() => currentIndex = i),
                    itemBuilder: (context, i) {
                      final decoded = _getDecodedImage(images[i]);
                      return decoded != null
                          ? InteractiveViewer(
                              child: Center(
                                child: Image.memory(
                                  decoded,
                                  fit: BoxFit.contain,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              ),
                            )
                          : Center(child: _buildImageErrorWidget());
                    },
                  ),
                  Positioned(
                    top: 40,
                    right: 20,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 32),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  if (images.length > 1)
                    Positioned(
                      bottom: 30,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          images.length,
                          (i) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i == currentIndex ? Colors.white : Colors.white24,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }
  int _currentSimilarAdPage = 0;
  /// Navigate to ad details
  void _navigateToAdDetails(AdModel ad) {
    // Convert back to dynamic for navigation (maintaining compatibility)
    final Map<String, dynamic> adData = {
      '_id': ad.id,
      'adTitle': ad.adTitle,
      'description': ad.description,
      'price': ad.price,
      'currencyName': ad.currencyName,
      'categoryName': ad.categoryName,
      'subCategoryName': ad.subCategoryName,
      'cityName': ad.cityName,
      'regionName': ad.regionName,
      'userName': ad.userName,
      'userPhone': ad.userPhone,
      'userId': ad.userId,
      'categoryId': ad.categoryId,
      'subCategoryId': ad.subCategoryId,
      'createDate': ad.createDate,
      'images': ad.images,
      'location': ad.location != null ? {
        'coordinates': ad.location!.coordinates,
      } : null,
    };
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdDetailsScreen(ad: adData),
      ),
    );
  }
  // Constants
  static const double _imageHeight = 200.0;
  static const int _limitSimilarAds = 6;
  static const String _baseUrl = 'https://sahbo-app-api.onrender.com';
  
  // Models
  late final AdModel _adModel;
  
  // State variables
  int _selectedTabIndex = 0;
  List<AdModel> _similarAds = [];
  bool _isLoadingSimilarAds = false;
  bool _hasErrorSimilarAds = false;
  bool _isFavorite = false;
  bool _isLoadingFavorite = false;
  
  // Auth variables
  String? _userId;
  String? _authToken;
  
  // Cache for decoded images
  final Map<String, Uint8List> _imageCache = {};
  
  // Controllers
  PageController? _imagePageController;
  PageController? _similarAdsPageController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _adModel = AdModel.fromJson(widget.ad);
    _imagePageController = PageController();
    _similarAdsPageController = PageController();
    _initializeData();
    _similarAdsPageController?.addListener(() {
      if (_similarAdsPageController == null) return;
      final int newPage = _similarAdsPageController!.page?.round() ?? 0;
      if (newPage != _currentSimilarAdPage) {
        setState(() {
          _currentSimilarAdPage = newPage;
        });
      }
    });
  }

  @override
  void dispose() {
    _imagePageController?.dispose();
    _similarAdsPageController?.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    await Future.wait([
      _checkAuthenticationAndFavorites(),
      _fetchSimilarAds(),
    ]);
    if (!mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: _buildAppBar(),
        body: _buildBody(),
      ),
    );
  }

  // App Bar Builder
  AppBar _buildAppBar() {
    return AppBar(
      title: Text(
        'تفاصيل الإعلان',
        style: GoogleFonts.cairo(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      backgroundColor: Colors.blue[700],
      elevation: 4,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      centerTitle: true,
    );
  }

  // Main Body Builder
  Widget _buildBody() {
    return Container(
      color: Colors.grey[50],
      child: ListView(
        children: [
          // First Section: Current Ad Details
          _buildCurrentAdSection(),
          
          // Divider between sections
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            height: 8,
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          
          // Action Buttons Section (Share, Report, Favorite)
          _buildActionButtonsSection(),
          
          const SizedBox(height: 16),
          
          // Second Section: Similar Ads
          _buildSimilarAdsSection(),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Current Ad Section Builder
  Widget _buildCurrentAdSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.blue[300]!,
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Images Section
            _buildImageSection(),
            
            // Ad Content
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ad Title
                  _buildAdTitle(),
                  
                  const SizedBox(height: 16),
                  
                  // Price Section
                  _buildPriceSection(),
                  
                  const SizedBox(height: 20),
                  
                  // Tabs
                  _buildTabSection(),
                  
                  const SizedBox(height: 20),
                  
                  // Action Buttons
                  _buildActionButtons(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Optimized image decoding with caching
  Uint8List? _getDecodedImage(String? base64String) {
    if (base64String == null || base64String.isEmpty) return null;
    
    if (_imageCache.containsKey(base64String)) {
      return _imageCache[base64String];
    }
    
    try {
      final decoded = base64Decode(base64String);
      _imageCache[base64String] = decoded;
      return decoded;
    } catch (e) {
      debugPrint('Error decoding image: $e');
      return null;
    }
  }

  // Optimized widget builders
  Widget _buildAdTitle() {
    return Text(
      _adModel.adTitle ?? 'غير متوفر',
      style: GoogleFonts.cairo(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildPriceSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue[200]!,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'السعر:',
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            '${_adModel.price ?? 'غير محدد'} ${_adModel.currencyName ?? ''}',
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
        ],
      ),
    );
  }

  // Tab Section Builder
  Widget _buildTabSection() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[400]!, width: 1.5),
        borderRadius: BorderRadius.circular(18),
        color: Colors.white,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            // Tab Headers
            Container(
              child: Row(
                children: [
                  _buildTabButton('معلومات الإعلان', 0),
                  _buildTabButton('الوصف', 1),
                  _buildTabButton('الموقع', 2),
                ],
              ),
            ),
            // Tab Content
            Container(
              padding: const EdgeInsets.all(16),
              child: _buildTabContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    final isSelected = _selectedTabIndex == index;
    final isFirst = index == 0;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue[600] : Colors.transparent,
            border: !isFirst ? Border(
              right: BorderSide(color: Colors.blue[300]!, width: 1),
            ) : null,
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              color: isSelected ? Colors.white : Colors.blue[700],
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildAdInfoTab();
      case 1:
        return _buildDescriptionTab();
      case 2:
        return _buildLocationTab();
      default:
        return _buildAdInfoTab();
    }
  }

  // Image Section Builders with optimization
  Widget _buildImageSection() {
    final images = _adModel.images ?? [];
    
    if (images.isEmpty) {
      return _buildNoImagePlaceholder();
    }

    return SizedBox(
      height: _imageHeight,
      child: Stack(
        children: [
          // Optimized Image PageView
          PageView.builder(
            controller: _imagePageController,
            itemCount: images.length,
            itemBuilder: (context, index) => _buildImageItem(images, index),
          ),
          // Image indicator if multiple images
          if (images.length > 1)
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: _buildImageIndicator(images.length),
            ),
          // Favorite Heart Icon
          Positioned(
            top: 10,
            left: 10,
            child: _buildFavoriteButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildImageItem(List<String> images, int index) {
    final imgBase64 = images[index];
    final decodedImage = _getDecodedImage(imgBase64);
    return GestureDetector(
      onTap: () => _showBuiltInImageViewer(images, index),
      child: decodedImage != null
          ? Image.memory(
              decodedImage,
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (context, error, stackTrace) => _buildImageErrorWidget(),
            )
          : _buildImageErrorWidget(),
    );
  }

  Widget _buildImageIndicator(int imageCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        imageCount,
        (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ),
    );
  }

  Widget _buildNoImagePlaceholder() {
    return SizedBox(
      height: _imageHeight,
      child: Stack(
        children: [
          // Placeholder content
          Container(
            height: _imageHeight,
            color: Colors.grey[200],
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_not_supported, size: 60, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('لا توجد صور متاحة', style: GoogleFonts.cairo(color: Colors.grey)),
                ],
              ),
            ),
          ),
          // Favorite Heart Icon
          Positioned(
            top: 10,
            left: 10,
            child: _buildFavoriteButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildImageErrorWidget() {
    return Container(
      height: _imageHeight,
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.broken_image, size: 60, color: Colors.grey),
      ),
    );
  }

  Widget _buildAdInfoTab() {
    bool hideTypeAndDelivery = _adModel.categoryId == '3' || _adModel.categoryId == 3;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBasicInfo(),
        const Divider(height: 32, thickness: 1, color: Colors.grey),
        _buildAdvertiserInfo(),
        const Divider(height: 32, thickness: 1, color: Colors.grey),
        _buildCategoryInfo(),
        if (!hideTypeAndDelivery) ...[
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.sell,
            'نوع الإعلان',
            _adModel.forSale == true ? 'للبيع' : 'للإيجار',
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.delivery_dining,
            'خدمة التوصيل',
            (_adModel.deliveryService == true) ? 'يوجد' : 'لا يوجد',
          ),
        ],
      ],
    );
  }

  Widget _buildBasicInfo() {
    return Column(
      children: [
        _buildInfoRow(
          Icons.location_on,
          'الموقع',
          '${_adModel.cityName ?? 'غير محدد'} - ${_adModel.regionName ?? 'غير محدد'}',
        ),
        const SizedBox(height: 12),
        _buildInfoRow(
          Icons.calendar_today,
          'تاريخ الإعلان',
          _formatDate(_adModel.createDate),
        ),
      ],
    );
  }

  Widget _buildAdvertiserInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50]!.withOpacity(0.5),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.blue[200]!.withOpacity(0.7),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'معلومات المعلن',
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.person,
            'الاسم',
            _adModel.userName ?? 'غير متوفر',
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.phone,
            'الهاتف',
            _adModel.userPhone ?? 'غير متوفر',
          ),
          const SizedBox(height: 12),
          // Advertiser Page Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.store, color: Colors.white),
              label: Text(
                'صفحة المعلن',
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              onPressed: () => _navigateToAdvertiserPage(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryInfo() {
    return _buildInfoRow(
      Icons.category,
      'التصنيف',
      '${_adModel.categoryName ?? 'غير محدد'} - ${_adModel.subCategoryName ?? 'غير متوفر'}',
    );
  }

  // Info Row Builder
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.blue[600]),
        const SizedBox(width: 8),
        Expanded(child: _buildInfoText(icon, label, value)),
      ],
    );
  }

  Widget _buildInfoText(IconData icon, String label, String value) {
    return RichText(
      text: TextSpan(
        style: GoogleFonts.cairo(fontSize: 14, color: Colors.black87),
        children: [
          TextSpan(
            text: '$label: ',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          // Special handling for phone numbers
          if (icon == Icons.phone)
            WidgetSpan(child: _buildPhoneText(value))
          else
            TextSpan(
              text: value,
              style: GoogleFonts.cairo(fontWeight: FontWeight.w500),
            ),
        ],
      ),
    );
  }

  Widget _buildPhoneText(String value) {
    final formattedPhone = value.startsWith('+') ? value : '+$value';
    
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Text(
        formattedPhone,
        style: GoogleFonts.cairo(
          fontWeight: FontWeight.w500,
          fontSize: 14,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildDescriptionTab() {
    final description = _adModel.description ?? '';
    
    if (description.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.description_outlined, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'لا يوجد وصف متاح لهذا الإعلان',
                style: GoogleFonts.cairo(
                  color: Colors.grey,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Text(
        description,
        style: GoogleFonts.cairo(
          fontSize: 14,
          color: Colors.black87,
          height: 1.5,
        ),
        textAlign: TextAlign.justify,
      ),
    );
  }

  Widget _buildLocationTab() {
    final location = _adModel.location;
    
    if (location == null || !location.isValid) {
      return _buildNoLocationAvailable();
    }

    return _buildLocationMap(location.latitude!, location.longitude!);
  }

  Widget _buildNoLocationAvailable() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.location_off_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              'لا يوجد موقع محدد لهذا الإعلان',
              style: GoogleFonts.cairo(
                color: Colors.grey,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationMap(double latitude, double longitude) {
    final LatLng adLocation = LatLng(latitude, longitude);
    
    return Container(
      height: 300,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          children: [
            // Map Section
            Expanded(
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: adLocation,
                  zoom: 15.0,
                ),
                markers: {
                  Marker(
                    markerId: const MarkerId('ad_location'),
                    position: adLocation,
                    infoWindow: const InfoWindow(
                      title: 'موقع الإعلان',
                      snippet: 'اضغط على الزر أدناه للحصول على الاتجاهات',
                    ),
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                  ),
                },
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                onTap: (_) => _openGoogleMapsDirections(latitude, longitude),
              ),
            ),
            // Directions Button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[600],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: GestureDetector(
                onTap: () => _openGoogleMapsDirections(latitude, longitude),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.directions, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'الحصول على الاتجاهات في خرائط جوجل',
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final phone = _adModel.userPhone ?? '';
    
    if (phone.isEmpty) {
      return _buildNoContactInfo();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(child: _buildWhatsAppButton(phone)),
        const SizedBox(width: 16),
        Expanded(child: _buildCallButton(phone)),
      ],
    );
  }

  Widget _buildNoContactInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Center(
        child: Text(
          'معلومات الاتصال غير متوفرة',
          style: GoogleFonts.cairo(
            color: Colors.orange,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildWhatsAppButton(String phone) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.chat, color: Colors.white),
      label: Text(
        'دردشة واتساب',
        style: GoogleFonts.cairo(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: _buildWhatsAppButtonStyle(),
      onPressed: () => _openWhatsApp(phone),
    );
  }

  Widget _buildCallButton(String phone) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.call, color: Colors.white),
      label: Text(
        'اتصل الآن',
        style: GoogleFonts.cairo(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: _buildCallButtonStyle(),
      onPressed: () => _showCallOptions(phone),
    );
  }

  // Style Builders
  ButtonStyle _buildWhatsAppButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF25D366),
      padding: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 0,
    );
  }

  ButtonStyle _buildCallButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.blue[600],
      padding: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 0,
    );
  }

  // ========== New Action Buttons Section ==========

  /// Build action buttons section (Share, Report, Favorite)
  Widget _buildActionButtonsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.blue[300]!,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue[100]!.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            icon: Icons.share,
            label: 'مشاركة',
            color: Colors.blue[600]!,
            onTap: _shareAd,
          ),
          _buildActionButton(
            icon: Icons.report_outlined,
            label: 'ابلاغ',
            color: Colors.red[600]!,
            onTap: _reportAd,
          ),
          _buildActionButton(
            icon: _isFavorite ? Icons.favorite : Icons.favorite_border,
            label: 'تفضيل',
            color: _isFavorite ? Colors.red[600]! : Colors.grey[600]!,
            onTap: _toggleFavorite,
            isLoading: _isLoadingFavorite,
          ),
        ],
      ),
    );
  }

  /// Build individual action button
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isLoading ? null : onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLoading)
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  )
                else
                  Icon(
                    icon,
                    color: color,
                    size: 28,
                  ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: GoogleFonts.cairo(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ========== Action Button Methods ==========

  /// Share ad functionality
  Future<void> _shareAd() async {
    try {
      final String adId = _adModel.id ?? '';
      final String shareText = '''
${_adModel.adTitle ?? 'إعلان مميز'}

شاهد هذا الاعلان على موقع سوق سوريا
https://syria-market-web.onrender.com/$adId
      '''.trim();

      // Show share dialog with app options
      await _showShareDialog(shareText);
    } catch (e) {
      if (mounted) {
        _showErrorMessage('حدث خطأ أثناء المشاركة');
      }
    }
  }

  /// Show share dialog with social media apps
  Future<void> _showShareDialog(String shareText) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Blue Header (matching other dialogs)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Text(
                'مشاركة الإعلان',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            // White Body with Share Options
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  
                  // WhatsApp Share
                  _buildShareOption(
                    Icons.message,
                    'مشاركة عبر واتساب',
                    Colors.green,
                    () => _shareViaWhatsApp(shareText),
                  ),
                  
                  const Divider(height: 1, color: Colors.grey),
                  
                  // Facebook Share
                  _buildShareOption(
                    Icons.facebook,
                    'مشاركة عبر فيسبوك',
                    Colors.blue,
                    () => _shareViaFacebook(shareText),
                  ),
                  
                  const Divider(height: 1, color: Colors.grey),
                  
                  // Telegram Share
                  _buildShareOption(
                    Icons.send,
                    'مشاركة عبر تيليجرام',
                    Colors.blue[400]!,
                    () => _shareViaTelegram(shareText),
                  ),
                  
                  const Divider(height: 1, color: Colors.grey),
                  
                  // Copy Link
                  _buildShareOption(
                    Icons.copy,
                    'نسخ الرابط',
                    Colors.orange,
                    () => _copyShareText(shareText),
                  ),
                  
                  const Divider(height: 1, color: Colors.grey),
                  
                  // More Apps
                  _buildShareOption(
                    Icons.share,
                    'مشاركة عبر تطبيقات أخرى',
                    Colors.grey[600]!,
                    () => _shareViaOtherApps(shareText),
                  ),
                  
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build share option item
  Widget _buildShareOption(IconData icon, String title, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: GoogleFonts.cairo()),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  /// Share via WhatsApp
  Future<void> _shareViaWhatsApp(String shareText) async {
    try {
      final encodedMessage = Uri.encodeComponent(shareText);
      final uriDirect = Uri.parse("whatsapp://send?text=$encodedMessage");
      final uriWeb = Uri.parse("https://wa.me/?text=$encodedMessage");

      if (await canLaunchUrl(uriDirect)) {
        await launchUrl(uriDirect, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uriWeb, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('فشل في فتح واتساب');
      }
    }
  }

  /// Share via Facebook
  Future<void> _shareViaFacebook(String shareText) async {
    try {
      final String adId = _adModel.id ?? '';
      final String adUrl = 'https://syria-market.onrender.com/$adId';
      final encodedMessage = Uri.encodeComponent(shareText);
      // Facebook app URL scheme
      final uriDirect = Uri.parse("fb://facewebmodal/f?href=$adUrl");
      // Facebook web URL
      final uriWeb = Uri.parse("https://www.facebook.com/sharer/sharer.php?u=$adUrl&quote=$encodedMessage");

      if (await canLaunchUrl(uriDirect)) {
        await launchUrl(uriDirect, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uriWeb, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('فشل في فتح فيسبوك');
      }
    }
  }

  /// Share via Telegram
  Future<void> _shareViaTelegram(String shareText) async {
    try {
      final String adId = _adModel.id ?? '';
      final String adUrl = 'https://syria-market.onrender.com/$adId';
      final encodedMessage = Uri.encodeComponent(shareText);
      // Telegram app URL scheme
      final uriDirect = Uri.parse("tg://msg?text=$encodedMessage");
      // Telegram web URL
      final uriWeb = Uri.parse("https://t.me/share/url?url=$adUrl&text=$encodedMessage");

      if (await canLaunchUrl(uriDirect)) {
        await launchUrl(uriDirect, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uriWeb, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('فشل في فتح تيليجرام');
      }
    }
  }

  /// Copy share text to clipboard
  Future<void> _copyShareText(String shareText) async {
    try {
      await Clipboard.setData(ClipboardData(text: shareText));
      if (mounted) {
        DialogUtils.showSuccessDialog(
          context: context,
          message: 'تم نسخ رابط الإعلان',
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('فشل في نسخ الرابط');
      }
    }
  }

  /// Share via other apps (system share)
  Future<void> _shareViaOtherApps(String shareText) async {
    try {
      // For now, we'll copy to clipboard as fallback
      // In a real app, you would use the share_plus package here
      await Clipboard.setData(ClipboardData(text: shareText));
      if (mounted) {
        DialogUtils.showSuccessDialog(
          context: context,
          message: 'تم نسخ النص للمشاركة. يمكنك لصقه في أي تطبيق تريده.',
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('حدث خطأ أثناء المشاركة');
      }
    }
  }

  /// Report ad functionality
  Future<void> _reportAd() async {
    // Check if user is logged in first
    if (_authToken == null || _userId == null) {
      _showLoginRequiredForReportDialog();
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Red Header (matching call dialog style)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Text(
                'الإبلاغ عن الإعلان',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            // White Body with Options
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  const SizedBox(height: 10),
            
                  // Report reasons
                  _buildReportOption('محتوى غير مناسب', Icons.warning),
                  _buildReportOption('إعلان مخادع أو احتيالي', Icons.error_outline),
                  _buildReportOption('منتج مقلد أو مزيف', Icons.copyright),
                  _buildReportOption('معلومات اتصال خاطئة', Icons.phone_disabled),
                  _buildReportOption('إعلان مكرر', Icons.repeat),
                  _buildReportOption('أخرى', Icons.more_horiz),
            
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build report option
  Widget _buildReportOption(String reason, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.red[600]),
      title: Text(reason, style: GoogleFonts.cairo()),
      onTap: () async {
        Navigator.pop(context);
        await _submitReport(reason);
      },
    );
  }

  /// Submit report to server
  Future<void> _submitReport(String reason) async {
    try {
      // Show loading dialog using DialogUtils
      if (mounted) {
        DialogUtils.showLoadingDialog(
          context: context,
          title: 'جاري إرسال البلاغ',
          message: 'يرجى الانتظار، سيتم مراجعة البلاغ من قبل فريقنا',
        );
      }
      
      // Prepare report data
      final reportData = {
        'adId': _adModel.id,
        'userId': _userId,
        'reason': reason,
        'reportedAt': DateTime.now().toIso8601String(),
      };
      
      // Send report to server
      final response = await http.post(
        Uri.parse('$_baseUrl/api/reports/submit'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(reportData),
      );
      
      if (mounted) {
        DialogUtils.closeDialog(context); // Close loading dialog
        
        if (response.statusCode == 200 || response.statusCode == 201) {
          DialogUtils.showSuccessDialog(
            context: context,
            message: 'تم إرسال البلاغ بنجاح. سيتم مراجعته من قبل فريقنا.',
          );
        } else {
          _showErrorMessage('حدث خطأ أثناء إرسال البلاغ. يرجى المحاولة مرة أخرى.');
        }
      }
    } catch (e) {
      if (mounted) {
        DialogUtils.closeDialog(context); // Close loading dialog
        _showErrorMessage('حدث خطأ أثناء إرسال البلاغ. يرجى المحاولة مرة أخرى.');
      }
    }
  }

  // Utility Methods
  String _formatDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return 'غير محدد';
    
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

  String _cleanPhoneNumber(String phone) {
    return phone.replaceAll(RegExp(r'[^\d]'), '');
  }

  String _formatPhoneNumber(String phone) {
    return phone.startsWith('+') ? phone : '+$phone';
  }

  // Navigation Methods

  void _navigateToAdvertiserPage() {
    final userId = _adModel.userId;
    if (userId != null && userId.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AdvertiserPageScreen(
            userId: userId,
            initialUserName: _adModel.userName,
            initialUserPhone: _adModel.userPhone,
          ),
        ),
      );
    } else {
      if (mounted) {
        DialogUtils.showErrorDialog(
          context: context,
          message: 'معرف المعلن غير متوفر',
        );
      }
    }
  }

  // Action Methods
  Future<void> _openWhatsApp(String phone) async {
    final formattedPhone = _cleanPhoneNumber(phone);
    final adTitle = _adModel.adTitle ?? '';
    final message = "السلام عليكم، أنا مهتم بالإعلان الخاص بك: $adTitle";
    final encodedMessage = Uri.encodeComponent(message);

    final uriDirect = Uri.parse("whatsapp://send?phone=$formattedPhone&text=$encodedMessage");
    final uriWeb = Uri.parse("https://wa.me/$formattedPhone?text=$encodedMessage");

    try {
      if (await canLaunchUrl(uriDirect)) {
        await launchUrl(uriDirect, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uriWeb, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      try {
        await launchUrl(uriWeb, mode: LaunchMode.platformDefault);
      } catch (e2) {
        if (mounted) {
          DialogUtils.showErrorDialog(
            context: context,
            message: 'فشل في فتح واتساب',
          );
        }
      }
    }
  }

  void _showCallOptions(String phone) {
    final formattedPhone = _formatPhoneNumber(phone);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Blue Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Text(
                'اختر طريقة الاتصال',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            // White Body with Options
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  _buildCallOption(
                    Icons.call,
                    'اتصال مباشر',
                    formattedPhone,
                    Colors.blue,
                    () => _makeDirectCall(formattedPhone),
                  ),
                  const Divider(height: 1, color: Colors.grey),
                  _buildCallOption(
                    Icons.copy,
                    'نسخ رقم الهاتف',
                    'للاتصال يدوياً',
                    Colors.orange,
                    () => _copyPhoneNumber(formattedPhone),
                  ),
                  const Divider(height: 1, color: Colors.grey),
                  _buildCallOption(
                    Icons.sms,
                    'إرسال رسالة نصية',
                    'SMS',
                    Colors.green,
                    () => _sendSMS(formattedPhone),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallOption(
    IconData icon,
    String title,
    String subtitle,
    Color color,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: GoogleFonts.cairo()),
      subtitle: Text(subtitle, style: GoogleFonts.cairo()),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  Future<void> _makeDirectCall(String phone) async {
    final uri = Uri.parse("tel:$phone");
    
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        DialogUtils.showErrorDialog(
          context: context,
          message: 'فشل في الاتصال المباشر',
        );
      }
    }
  }

  Future<void> _copyPhoneNumber(String phone) async {
    await Clipboard.setData(ClipboardData(text: phone));
    if (mounted) {
      DialogUtils.showSuccessDialog(
        context: context,
        message: 'تم نسخ رقم الهاتف: $phone',
      );
    }
  }

  Future<void> _sendSMS(String phone) async {
    const message = 'مرحباً، أنا مهتم بالإعلان الخاص بك.';
    final encodedMessage = Uri.encodeComponent(message);
    final uri = Uri.parse("sms:$phone?body=$encodedMessage");
    
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        DialogUtils.showErrorDialog(
          context: context,
          message: 'فشل في إرسال الرسالة',
        );
      }
    }
  }

  Future<void> _openGoogleMapsDirections(double latitude, double longitude) async {
    // Google Maps URL for directions
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude'
    );
    
    // Google Maps app URL
    final googleMapsAppUrl = Uri.parse(
      'google.navigation:q=$latitude,$longitude'
    );

    try {
      // Try to open Google Maps app first
      if (await canLaunchUrl(googleMapsAppUrl)) {
        await launchUrl(googleMapsAppUrl, mode: LaunchMode.externalApplication);
      } else {
        // Fallback to web version
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        DialogUtils.showErrorDialog(
          context: context,
          message: 'فشل في فتح خرائط جوجل',
        );
      }
    }
  }

  // ========== Favorite Feature Methods ==========

  /// Check authentication status and load favorites
  Future<void> _checkAuthenticationAndFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _authToken = prefs.getString('token');
      _userId = prefs.getString('userId');
      // If user is logged in, check if current ad is in favorites
      if (_authToken != null && _authToken!.isNotEmpty && _userId != null && _userId!.isNotEmpty) {
        await _checkIfAdIsFavorite();
        if (!mounted) return;
      } else {
        // For non-logged-in users, set stable states to prevent flashing
        if (!mounted) return;
        setState(() {
          _isFavorite = false;
          _isLoadingFavorite = false;
        });
      }
    } catch (e) {
      // Ensure stable state even on error
      if (!mounted) return;
      setState(() {
        _isFavorite = false;
        _isLoadingFavorite = false;
      });
      debugPrint('Error checking authentication: $e');
    }
  }

  /// Check if current ad is in user's favorites list
  Future<void> _checkIfAdIsFavorite() async {
    if (_authToken == null || _userId == null) return;

    try {
      if (!mounted) return;
      setState(() {
        _isLoadingFavorite = true;
      });

      final response = await http.get(
        Uri.parse('$_baseUrl/api/favorites/my-favorites?page=1&limit=1000'), // Get all favorites
        headers: {
          'Authorization': 'Bearer $_authToken',
        },
      );

      if (!mounted) return;
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> favorites = decoded['favorites'] ?? [];
        // Check if current ad is in favorites list
        final currentAdId = _adModel.id;
        final isCurrentAdFavorite = favorites.any((favorite) {
          final ad = favorite['ad'];
          return ad != null && ad['_id'] == currentAdId;
        });
        setState(() {
          _isFavorite = isCurrentAdFavorite;
          _isLoadingFavorite = false;
        });
      } else {
        setState(() {
          _isLoadingFavorite = false;
        });
        debugPrint('Failed to fetch favorites: ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingFavorite = false;
      });
      debugPrint('Error checking if ad is favorite: $e');
    }
  }

  /// Build favorite heart button
  Widget _buildFavoriteButton() {
    return GestureDetector(
      onTap: _isLoadingFavorite ? null : _toggleFavorite,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: _isLoadingFavorite
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                ),
              )
            : Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? Colors.red : Colors.grey[600],
                size: 24,
              ),
      ),
    );
  }

  /// Toggle favorite status
  Future<void> _toggleFavorite() async {
    // Check if user is logged in
    if (_authToken == null || _userId == null) {
      _showLoginRequiredDialog();
      return;
    }

    setState(() {
      _isLoadingFavorite = true;
    });

    try {
      final adId = _adModel.id;
      if (adId == null) return;
      
      if (_isFavorite) {
        // Remove from favorites directly without confirmation
        await _removeFromFavorites(adId);
      } else {
        // Add to favorites directly
        await _addToFavorites(adId);
      }
    } catch (e) {
      if (_isFavorite) {
        _showErrorMessage('حدث خطأ أثناء إزالة الإعلان من المفضلة');
      } else {
        _showErrorMessage('حدث خطأ أثناء إضافة الإعلان إلى المفضلة');
      }
    } finally {
      setState(() {
        _isLoadingFavorite = false;
      });
    }
  }

  /// Add ad to favorites
  Future<void> _addToFavorites(String adId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/favorites/add'),
      headers: {
        'Authorization': 'Bearer $_authToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'userId': _userId,
        'adId': adId,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      setState(() {
        _isFavorite = true;
      });
    } else {
      throw Exception('Failed to add to favorites');
    }
  }

  /// Remove ad from favorites
  Future<void> _removeFromFavorites(String adId) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/api/favorites/delete'),
      headers: {
        'Authorization': 'Bearer $_authToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'userId': _userId,
        'adId': adId,
      }),
    );

    if (response.statusCode == 200) {
      setState(() {
        _isFavorite = false;
      });
    } else {
      throw Exception('Failed to remove from favorites');
    }
  }

  /// Show login required dialog
  void _showLoginRequiredDialog() {
    DialogUtils.showConfirmationDialog(
      context: context,
      title: 'تسجيل الدخول مطلوب',
      message: 'يجب تسجيل الدخول أولاً لإضافة الإعلانات إلى المفضلة',
      confirmText: 'تسجيل الدخول',
      cancelText: 'إلغاء',
      onConfirm: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );
      },
    );
  }

  /// Show login required dialog for reporting
  void _showLoginRequiredForReportDialog() {
    DialogUtils.showConfirmationDialog(
      context: context,
      title: 'تسجيل الدخول مطلوب',
      message: 'يجب تسجيل الدخول أولاً للإبلاغ عن الإعلانات',
      confirmText: 'تسجيل الدخول',
      cancelText: 'إلغاء',
      onConfirm: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );
      },
    );
  }

  /// Show error message
  void _showErrorMessage(String message) {
    if (mounted) {
      DialogUtils.showErrorDialog(
        context: context,
        message: message,
      );
    }
  }

  // ========== Similar Ads Methods ==========

  /// Fetch similar ads based on category and subcategory
  Future<void> _fetchSimilarAds() async {
    final categoryId = _adModel.categoryId;
    final subCategoryId = _adModel.subCategoryId;
    final currentAdId = _adModel.id;
    if (categoryId == null) return;

    if (!mounted) return;
    setState(() {
      _isLoadingSimilarAds = true;
      _hasErrorSimilarAds = false;
    });

    try {
      final params = <String, String>{
        'page': '1',
        'limit': '$_limitSimilarAds',
        'categoryId': categoryId,
      };
      if (subCategoryId != null) {
        params['subCategoryId'] = subCategoryId;
      }
      final uri = Uri.https('sahbo-app-api.onrender.com', '/api/ads/search-by-category', params);
      final response = await http.get(uri);

      if (!mounted) return;
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> fetchedAds = decoded['ads'] ?? [];
        // Filter out the current ad from similar ads
        final filteredAds = fetchedAds.where((ad) => ad['_id'] != currentAdId).toList();
        setState(() {
          _similarAds = filteredAds.map((ad) => AdModel.fromJson(ad)).take(_limitSimilarAds).toList();
          _isLoadingSimilarAds = false;
          _hasErrorSimilarAds = false;
        });
      } else {
        setState(() {
          _hasErrorSimilarAds = true;
          _isLoadingSimilarAds = false;
        });
      }
    } catch (e) {
      debugPrint('Exception fetching similar ads: $e');
      if (!mounted) return;
      setState(() {
        _hasErrorSimilarAds = true;
        _isLoadingSimilarAds = false;
      });
    }
  }

  /// Build similar ads section
  Widget _buildSimilarAdsSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.blue[300]!,
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue[600],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
              ),
              child: Text(
                'إعلانات مشابهة',
                style: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            // Similar Ads Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: _buildSimilarAdsContent(),
            ),
          ],
        ),
      ),
    );
  }

  /// Build similar ads content based on loading state
  Widget _buildSimilarAdsContent() {
    if (_isLoadingSimilarAds) {
      return _buildSimilarAdsLoading();
    }
    if (_hasErrorSimilarAds) {
      return _buildSimilarAdsError();
    }
    if (_similarAds.isEmpty) {
      return _buildNoSimilarAds();
    }
    return _buildSimilarAdsList();
  }

  /// Build loading widget for similar ads
  Widget _buildSimilarAdsLoading() {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            SizedBox(height: 12),
            Text(
              'جاري تحميل الإعلانات المشابهة...',
              style: GoogleFonts.cairo(
                color: Colors.grey,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Build error widget for similar ads
  Widget _buildSimilarAdsError() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            size: 40,
            color: Colors.orange,
          ),
          const SizedBox(height: 12),
          Text(
            'فشل في تحميل الإعلانات المشابهة',
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _fetchSimilarAds,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build no similar ads widget
  Widget _buildNoSimilarAds() {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off,
            size: 40,
            color: Colors.grey,
          ),
          SizedBox(height: 12),
          Text(
            'لا توجد إعلانات مشابهة في الوقت الحالي',
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build similar ads list
  Widget _buildSimilarAdsList() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double cardWidth = constraints.maxWidth * 0.92;
        final double cardHeight = 290.0;
        if (_similarAds.length <= 1) {
          // Show single card (no sliding)
          return Center(
            child: SizedBox(
              width: cardWidth,
              height: cardHeight,
              child: _similarAds.isNotEmpty
                  ? AdCardWidget(
                      ad: home.AdModel(
                        id: _similarAds[0].id,
                        adTitle: _similarAds[0].adTitle,
                        description: _similarAds[0].description,
                        price: _similarAds[0].price,
                        currencyName: _similarAds[0].currencyName,
                        categoryName: _similarAds[0].categoryName,
                        subCategoryName: _similarAds[0].subCategoryName,
                        cityName: _similarAds[0].cityName,
                        regionName: _similarAds[0].regionName,
                        userName: _similarAds[0].userName,
                        userPhone: _similarAds[0].userPhone,
                        userId: _similarAds[0].userId,
                        categoryId: _similarAds[0].categoryId,
                        subCategoryId: _similarAds[0].subCategoryId,
                        createDate: _similarAds[0].createDate,
                        images: _similarAds[0].images,
                        location: _similarAds[0].location != null ? {'coordinates': _similarAds[0].location!.coordinates} : null,
                        forSale: _similarAds[0].forSale,
                        deliveryService: _similarAds[0].deliveryService,
                      ),
                      onTap: () => _navigateToAdDetails(_similarAds[0]),
                    )
                  : const SizedBox.shrink(),
            ),
          );
        } else {
          // Show PageView for sliding with dots below
          return SizedBox(
            height: cardHeight + 32,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: cardHeight,
                  child: PageView.builder(
                    controller: _similarAdsPageController,
                    itemCount: _similarAds.length,
                    itemBuilder: (context, index) {
                      final ad = _similarAds[index];
                      final homeAd = home.AdModel(
                        id: ad.id,
                        adTitle: ad.adTitle,
                        description: ad.description,
                        price: ad.price,
                        currencyName: ad.currencyName,
                        categoryName: ad.categoryName,
                        subCategoryName: ad.subCategoryName,
                        cityName: ad.cityName,
                        regionName: ad.regionName,
                        userName: ad.userName,
                        userPhone: ad.userPhone,
                        userId: ad.userId,
                        categoryId: ad.categoryId,
                        subCategoryId: ad.subCategoryId,
                        createDate: ad.createDate,
                        images: ad.images,
                        location: ad.location != null ? {'coordinates': ad.location!.coordinates} : null,
                        forSale: ad.forSale,
                        deliveryService: ad.deliveryService,
                      );
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: AdCardWidget(
                          ad: homeAd,
                          onTap: () => _navigateToAdDetails(ad),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_similarAds.length, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentSimilarAdPage == index ? 16 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentSimilarAdPage == index ? Colors.blue : Colors.grey[400],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ],
            ),
          );
        }
      },
    );
  }
  /// Build similar ad card (optimized with model)
  // _buildSimilarAdCard is no longer needed and has been removed.
}