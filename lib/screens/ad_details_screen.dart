import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import 'image_preview_screen.dart';

class AdDetailsScreen extends StatefulWidget {
  final dynamic ad;

  const AdDetailsScreen({super.key, required this.ad});

  @override
  State<AdDetailsScreen> createState() => _AdDetailsScreenState();
}

class _AdDetailsScreenState extends State<AdDetailsScreen> {
  // Constants
  static const double _imageHeight = 200.0;
  static const int _limitSimilarAds = 6;
  
  // Tab state
  int _selectedTabIndex = 0;
  
  // Similar ads state
  List<dynamic> _similarAds = [];
  bool _isLoadingSimilarAds = false;
  bool _hasErrorSimilarAds = false;

  @override
  void initState() {
    super.initState();
    _fetchSimilarAds();
  }

  @override
  Widget build(BuildContext context) {
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
      title: const Text(
        'تفاصيل الإعلان',
        style: TextStyle(
          fontSize: 24,
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
        boxShadow: [
          BoxShadow(
            color: Colors.blue[100]!.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            _buildImageSection(),
            _buildDetailsSection(),
          ],
        ),
      ),
    );
  }

  // Image Section Builders
  Widget _buildImageSection() {
    final List<dynamic> images = widget.ad['images'] ?? [];
    
    if (images.isEmpty) {
      return _buildNoImagePlaceholder();
    }

    return SizedBox(
      height: _imageHeight,
      child: PageView.builder(
        itemCount: images.length,
        itemBuilder: (context, index) => _buildImageItem(images, index),
      ),
    );
  }

  Widget _buildImageItem(List<dynamic> images, int index) {
    final imgBase64 = images[index];
    
    return GestureDetector(
      onTap: () => _navigateToImagePreview(images, index),
      child: Image.memory(
        base64Decode(imgBase64),
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) => _buildImageErrorWidget(),
      ),
    );
  }

  Widget _buildNoImagePlaceholder() {
    return Container(
      height: _imageHeight,
      color: Colors.grey[200],
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported, size: 60, color: Colors.grey),
            SizedBox(height: 8),
            Text('لا توجد صور متاحة', style: TextStyle(color: Colors.grey)),
          ],
        ),
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

  // Details Section Builder
  Widget _buildDetailsSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAdTitle(),
                const SizedBox(height: 12),
                _buildPriceSection(),
              ],
            ),
          ),
          _buildTabSection(),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: _buildActionButtons(),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildAdTitle() {
    return Text(
      '${widget.ad['adTitle'] ?? 'غير متوفر'}',
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildPriceSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue[100]!.withOpacity(0.3),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.blue[300]!.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: Text(
        'السعر: ${widget.ad['price'] ?? 'غير محدد'} ${widget.ad['currencyName'] ?? ''}',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  // Tab Section Builder
  Widget _buildTabSection() {
    return Column(
      children: [
        _buildTabHeader(),
        _buildTabContent(),
      ],
    );
  }

  Widget _buildTabHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              title: 'معلومات الإعلان',
              index: 0,
              isSelected: _selectedTabIndex == 0,
            ),
          ),
          Expanded(
            child: _buildTabButton(
              title: 'الوصف',
              index: 1,
              isSelected: _selectedTabIndex == 1,
            ),
          ),
          Expanded(
            child: _buildTabButton(
              title: 'الموقع',
              index: 2,
              isSelected: _selectedTabIndex == 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required int index,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[600] : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: _selectedTabIndex == 0 
          ? _buildAdInfoTab() 
          : _selectedTabIndex == 1
              ? _buildDescriptionTab()
              : _buildLocationTab(),
    );
  }

  Widget _buildAdInfoTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBasicInfo(),
        const Divider(height: 32, thickness: 1, color: Colors.grey),
        _buildAdvertiserInfo(),
        const Divider(height: 32, thickness: 1, color: Colors.grey),
        _buildCategoryInfo(),
      ],
    );
  }

  Widget _buildBasicInfo() {
    return Column(
      children: [
        _buildInfoRow(
          Icons.location_on,
          'الموقع',
          '${widget.ad['cityName'] ?? 'غير محدد'} - ${widget.ad['regionName'] ?? 'غير محدد'}',
        ),
        const SizedBox(height: 12),
        _buildInfoRow(
          Icons.calendar_today,
          'تاريخ الإعلان',
          _formatDate(widget.ad['createDate']),
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
          const Text(
            'معلومات المعلن',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.person,
            'الاسم',
            '${widget.ad['userName'] ?? 'غير متوفر'}',
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.phone,
            'الهاتف',
            '${widget.ad['userPhone'] ?? 'غير متوفر'}',
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryInfo() {
    return _buildInfoRow(
      Icons.category,
      'التصنيف',
      '${widget.ad['categoryName'] ?? 'غير محدد'} - ${widget.ad['subCategoryName'] ?? 'غير متوفر'}',
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
        style: const TextStyle(fontSize: 14, color: Colors.black87),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          // Special handling for phone numbers
          if (icon == Icons.phone)
            WidgetSpan(child: _buildPhoneText(value))
          else
            TextSpan(
              text: value,
              style: const TextStyle(fontWeight: FontWeight.w500),
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
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildDescriptionTab() {
    final String description = widget.ad['description'] ?? '';
    
    if (description.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.description_outlined, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'لا يوجد وصف متاح لهذا الإعلان',
                style: TextStyle(
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
      decoration: BoxDecoration(
        color: Colors.blue[50]!.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue[200]!.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Text(
        description,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black87,
          height: 1.5,
        ),
        textAlign: TextAlign.justify,
      ),
    );
  }

  Widget _buildLocationTab() {
    final location = widget.ad['location'];
    
    // Check if location exists and has the correct structure
    if (location == null || 
        location['coordinates'] == null || 
        location['coordinates'] is! List ||
        (location['coordinates'] as List).length < 2) {
      return _buildNoLocationAvailable();
    }

    final coordinates = location['coordinates'] as List;
    final longitude = coordinates[0]?.toDouble() ?? 0.0;
    final latitude = coordinates[1]?.toDouble() ?? 0.0;

    // Check if coordinates are [0, 0] which means no location selected
    if (longitude == 0.0 && latitude == 0.0) {
      return _buildNoLocationAvailable();
    }

    return _buildLocationMap(latitude, longitude);
  }

  Widget _buildNoLocationAvailable() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: const Center(
        child: Column(
          children: [
            Icon(Icons.location_off_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              'لا يوجد موقع محدد لهذا الإعلان',
              style: TextStyle(
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
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[300]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
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
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: GestureDetector(
                onTap: () => _openGoogleMapsDirections(latitude, longitude),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.directions, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'الحصول على الاتجاهات في خرائط جوجل',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
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
    final String phone = widget.ad['userPhone'] ?? '';
    
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
      child: const Center(
        child: Text(
          'معلومات الاتصال غير متوفرة',
          style: TextStyle(
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
      label: const Text(
        'دردشة واتساب',
        style: TextStyle(
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
      label: const Text(
        'اتصل الآن',
        style: TextStyle(
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

  // Utility Methods
  String _formatDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return 'غير معروف';
    
    try {
      final date = DateTime.parse(isoDate);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'غير معروف';
    }
  }

  String _cleanPhoneNumber(String phone) {
    return phone.replaceAll(RegExp(r'[^\d]'), '');
  }

  String _formatPhoneNumber(String phone) {
    return phone.startsWith('+') ? phone : '+$phone';
  }

  // Navigation Methods
  void _navigateToImagePreview(List<dynamic> images, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ImagePreviewScreen(
          images: images,
          initialIndex: index,
        ),
      ),
    );
  }

  // Action Methods
  Future<void> _openWhatsApp(String phone) async {
    final formattedPhone = _cleanPhoneNumber(phone);
    const message = "السلام عليكم، أنا مهتم بالإعلان الخاص بك.";
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('فشل في فتح واتساب')),
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
              child: const Text(
                'اختر طريقة الاتصال',
                style: TextStyle(
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
      title: Text(title),
      subtitle: Text(subtitle),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل في الاتصال المباشر')),
        );
      }
    }
  }

  Future<void> _copyPhoneNumber(String phone) async {
    await Clipboard.setData(ClipboardData(text: phone));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم نسخ رقم الهاتف: $phone')),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل في إرسال الرسالة')),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل في فتح خرائط جوجل'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ========== Similar Ads Methods ==========

  /// Fetch similar ads based on category and subcategory
  Future<void> _fetchSimilarAds() async {
    final categoryId = widget.ad['categoryId'];
    final subCategoryId = widget.ad['subCategoryId'];
    final currentAdId = widget.ad['id'];
    
    if (categoryId == null) return;

    setState(() {
      _isLoadingSimilarAds = true;
      _hasErrorSimilarAds = false;
    });

    try {
      final params = <String, String>{
        'page': '1',
        'limit': '$_limitSimilarAds',
        'categoryId': categoryId.toString(),
      };
      
      if (subCategoryId != null) {
        params['subCategoryId'] = subCategoryId.toString();
      }
      print('Fetching similar ads with params: $params');
      final uri = Uri.https('sahbo-app-api.onrender.com', '/api/ads/search-by-category', params);
      final response = await http.get(uri);

      print(response.body);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> fetchedAds = decoded['ads'] ?? [];
        
        // Filter out the current ad from similar ads
        final filteredAds = fetchedAds.where((ad) => ad['id'] != currentAdId).toList();
        
        setState(() {
          _similarAds = filteredAds.take(_limitSimilarAds).toList();
          _isLoadingSimilarAds = false;
        });
      } else {
        setState(() {
          _hasErrorSimilarAds = true;
          _isLoadingSimilarAds = false;
        });
      }
    } catch (e) {
      debugPrint('Exception fetching similar ads: $e');
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
        boxShadow: [
          BoxShadow(
            color: Colors.blue[100]!.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue[600],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: const Text(
                'إعلانات مشابهة',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            // Similar Ads Content
            Container(
              padding: const EdgeInsets.all(16),
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
      height: 150,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'جاري تحميل الإعلانات المشابهة...',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build error widget for similar ads
  Widget _buildSimilarAdsError() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.orange,
          ),
          const SizedBox(height: 16),
          const Text(
            'فشل في تحميل الإعلانات المشابهة',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _fetchSimilarAds,
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
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
      padding: const EdgeInsets.all(20),
      child: const Column(
        children: [
          Icon(
            Icons.search_off,
            size: 48,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'لا توجد إعلانات مشابهة في الوقت الحالي',
            style: TextStyle(
              fontSize: 16,
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
    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _similarAds.length,
          itemBuilder: (context, index) => _buildSimilarAdCard(_similarAds[index]),
        ),
      ],
    );
  }

  /// Build similar ad card (same style as home screen)
  Widget _buildSimilarAdCard(dynamic ad) {
    final List<dynamic> images = ad['images'] is List ? ad['images'] : [];
    final firstImageBase64 = images.isNotEmpty ? images[0] : null;

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Color(0xFFF8FBFF),
            Color(0xFFF0F8FF),
          ],
        ),
        border: Border.all(color: Colors.blue[300]!, width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          splashColor: Colors.blue[300]!.withOpacity(0.2),
          highlightColor: Colors.blue[100]!.withOpacity(0.1),
          onTap: () => _navigateToAdDetails(ad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                  child: SizedBox(
                    width: double.infinity,
                    child: _buildSimilarAdImage(firstImageBase64),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 80),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: _buildSimilarAdDetails(ad),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build similar ad image (same style as home screen)
  Widget _buildSimilarAdImage(String? firstImageBase64) {
    if (firstImageBase64 != null) {
      return Image.memory(
        base64Decode(firstImageBase64),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => _buildSimilarAdImagePlaceholder(),
      );
    } else {
      return _buildSimilarAdImagePlaceholder();
    }
  }

  /// Build similar ad image placeholder (same style as home screen)
  Widget _buildSimilarAdImagePlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF0F8FF), Color(0xFFE6F3FF)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image, size: 40, color: Colors.blue[400]),
            const SizedBox(height: 4),
            Text(
              'لا توجد صورة',
              style: TextStyle(
                color: Colors.blue[700],
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build similar ad details (same style as home screen)
  Widget _buildSimilarAdDetails(dynamic ad) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Text(
          '${ad['adTitle'] ?? ''}',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[300]!, width: 1),
          ),
          child: Text(
            '${ad['price'] ?? '0'} ${ad['currencyName'] ?? ''}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        Text(
          ad['description'] ?? '',
          style: const TextStyle(
            fontSize: 10,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_on, size: 12, color: Colors.blue[600]),
            const SizedBox(width: 2),
            Expanded(
              child: Text(
                '${ad['cityName'] ?? ''} - ${_formatDate(ad['createDate'] ?? '')}',
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Navigate to ad details
  void _navigateToAdDetails(dynamic ad) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdDetailsScreen(ad: ad),
      ),
    );
  }
}
