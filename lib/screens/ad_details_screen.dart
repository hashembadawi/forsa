import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forsa/widgets/adDetails_screen/favorite_button_wid.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/adDetails_screen/image_section_wid.dart';
import '../widgets/adDetails_screen/ad_title_wid.dart';
import '../widgets/adDetails_screen/ad_details_content_wid.dart';
import '../widgets/adDetails_screen/ad_info_tab_wid.dart';
import '../widgets/adDetails_screen/basic_info_wid.dart';
import '../widgets/adDetails_screen/info_row_wid.dart';
import '../widgets/adDetails_screen/phone_text_wid.dart';
import '../widgets/adDetails_screen/description_tab_wid.dart';
import '../widgets/adDetails_screen/location_map_wid.dart';
import '../widgets/adDetails_screen/no_location_available_wid.dart';
import '../widgets/adDetails_screen/no_contact_info_wid.dart';
import '../widgets/adDetails_screen/ad_details_action_buttons_row_wid.dart';
import '../widgets/adDetails_screen/price_section_wid.dart';
import '../widgets/adDetails_screen/tab_section_wid.dart';
import '../widgets/adDetails_screen/advertiser_info_wid.dart';
import '../widgets/adDetails_screen/action_buttons_wid.dart';
import '../widgets/adDetails_screen/similar_ads_section_wid.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/ad_card_widget.dart';
import 'advertiser_page_screen.dart';
import 'login_screen.dart';
import '../utils/dialog_utils.dart';

// AdModel is now imported from models/ad_model.dart
import '../models/ad_model.dart';

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
  final String adId;

  const AdDetailsScreen({super.key, required this.adId});

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
    if (ad.id != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AdDetailsScreen(adId: ad.id!),
        ),
      );
    }
  }
  // Constants
  static const double _imageHeight = 200.0;
  static const int _limitSimilarAds = 6;
  static const String _baseUrl = 'https://sahbo-app-api.onrender.com';
  
  // Models
  AdModel? _adModel;
  bool _isLoadingAd = true;
  bool _hasErrorAd = false;
  
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
    _imagePageController = PageController();
    _similarAdsPageController = PageController();
    _fetchAdDetails();
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

  Future<void> _fetchAdDetails() async {
    if (!mounted) return;
    setState(() {
      _isLoadingAd = true;
      _hasErrorAd = false;
    });
    try {
      final url = Uri.parse('https://sahbo-app-api.onrender.com/api/ads/getAdById/${widget.adId}');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (!mounted) return;
        setState(() {
          _adModel = AdModel.fromJson(data);
          _isLoadingAd = false;
        });
        // Now fetch similar ads and favorites
        _initializeData();
      } else {
        if (!mounted) return;
        setState(() {
          _hasErrorAd = true;
          _isLoadingAd = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasErrorAd = true;
        _isLoadingAd = false;
      });
    }
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
    // Material 3 color scheme
    const Color primaryColor = Color(0xFF42A5F5); // Light Blue
    const Color backgroundColor = Color(0xFFFAFAFA); // White
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Theme(
        data: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),
          scaffoldBackgroundColor: backgroundColor,
          appBarTheme: const AppBarTheme(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            elevation: 4,
            centerTitle: true,
            titleTextStyle: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: Colors.white,
            ),
          ),
        ),
        child: Scaffold(
          appBar: _buildAppBar(),
          body: _isLoadingAd
              ? Center(child: CircularProgressIndicator())
              : _hasErrorAd
                  ? Center(child: Text('حدث خطأ أثناء تحميل الإعلان'))
                  : _buildBody(),
        ),
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
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.primary,
      elevation: 4,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      centerTitle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
    );
  }

  // Main Body Builder
  Widget _buildBody() {
    if (_adModel == null) return SizedBox.shrink();
    // Remove colored divider and extra padding from AdDetailsMainBodyWid
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildCurrentAdSection(),
              _buildActionButtonsSection(),
              _buildSimilarAdsSection(),
            ],
          ),
        ),
      ],
    );
  }

  // Current Ad Section Builder
  Widget _buildCurrentAdSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImageSection(),
          AdDetailsContentWid(
            adTitle: _buildAdTitle(),
            priceSection: _buildPriceSection(),
            tabSection: _buildTabSection(),
            actionButtons: _buildActionButtons(),
          ),
        ],
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
    return AdTitleWid(title: _adModel?.adTitle ?? 'غير متوفر');
  }

  Widget _buildPriceSection() {
    return PriceSectionWid(
      price: _adModel?.price?.toString() ?? 'غير محدد',
      currencyName: _adModel?.currencyName ?? '',
    );
  }

  // Tab Section Builder
  Widget _buildTabSection() {
    return TabSectionWid(
      selectedTabIndex: _selectedTabIndex,
      onTabSelected: (index) => setState(() => _selectedTabIndex = index),
      tabContent: _buildTabContent(),
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
    final images = _adModel?.images ?? [];
    final thumbnail = _adModel?.thumbnail;
    List<String> allImages = [];
    if (thumbnail != null && thumbnail.isNotEmpty) {
      allImages.add(thumbnail);
    }
    allImages.addAll(images);
    return ImageSectionWid(
      allImages: allImages,
      imageHeight: _imageHeight,
      imagePageController: _imagePageController,
      getDecodedImage: _getDecodedImage,
      onImageTap: _showBuiltInImageViewer,
      favoriteButton: _buildFavoriteButton(),
    );
  }


  // Image indicator now uses ImageIndicatorWid widget

  
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
    bool hideTypeAndDelivery = _adModel?.categoryId == '3' || _adModel?.categoryId == 3;
    return AdInfoTabWid(
      hideTypeAndDelivery: hideTypeAndDelivery,
      basicInfo: _buildBasicInfo(),
      advertiserInfo: _buildAdvertiserInfo(),
      categoryInfo: _buildCategoryInfo(),
      typeInfoRow: InfoRowWid(
        icon: Icons.sell,
        label: 'نوع الإعلان',
        value: _adModel?.forSale == true ? 'للبيع' : 'للإيجار',
      ),
      deliveryInfoRow: InfoRowWid(
        icon: Icons.delivery_dining,
        label: 'خدمة التوصيل',
        value: (_adModel?.deliveryService == true) ? 'يوجد' : 'لا يوجد',
      ),
    );
  }

  Widget _buildBasicInfo() {
    return BasicInfoWid(
      locationRow: InfoRowWid(
        icon: Icons.location_on,
        label: 'الموقع',
        value: '${_adModel?.cityName ?? 'غير محدد'} - ${_adModel?.regionName ?? 'غير محدد'}',
      ),
      dateRow: InfoRowWid(
        icon: Icons.calendar_today,
        label: 'تاريخ الإعلان',
        value: _formatDate(_adModel?.createDate),
      ),
    );
  }

  Widget _buildAdvertiserInfo() {
    return AdvertiserInfoWid(
      userName: _adModel?.userName ?? 'غير متوفر',
      userPhone: _adModel?.userPhone ?? 'غير متوفر',
      onAdvertiserPage: _navigateToAdvertiserPage,
    );
  }

  Widget _buildCategoryInfo() {
    return _buildInfoRow(
      Icons.category,
      'التصنيف',
      '${_adModel?.categoryName ?? 'غير محدد'} - ${_adModel?.subCategoryName ?? 'غير متوفر'}',
    );
  }

  // Info Row Builder
  Widget _buildInfoRow(IconData icon, String label, String value) {
    // For phone, use PhoneTextWid
    if (icon == Icons.phone) {
      return InfoRowWid(
        icon: icon,
        label: label,
        value: value,
        phoneText: PhoneTextWid(value: value),
      );
    }
    return InfoRowWid(
      icon: icon,
      label: label,
      value: value,
    );
  }
  // _buildInfoText and _buildPhoneText are now handled by InfoRowWid and PhoneTextWid

  Widget _buildDescriptionTab() {
    final description = _adModel?.description ?? '';
    return DescriptionTabWid(description: description);
  }

  Widget _buildLocationTab() {
    final location = _adModel?.location;
    final locationModel = location != null ? LocationModel.fromJson(location) : null;
    if (locationModel == null || !locationModel.isValid) {
      return const NoLocationAvailableWid();
    }
    return LocationMapWid(
      latitude: locationModel.latitude!,
      longitude: locationModel.longitude!,
      onDirectionsTap: () => _openGoogleMapsDirections(locationModel.latitude!, locationModel.longitude!),
    );
  }

  Widget _buildActionButtons() {
    final phone = _adModel?.userPhone ?? '';
    if (phone.isEmpty) {
      return const NoContactInfoWid();
    }
    return AdDetailsActionButtonsRowWid(
      whatsappButton: _buildWhatsAppButton(phone),
      callButton: _buildCallButton(phone),
    );
  }

  Widget _buildWhatsAppButton(String phone) {
    return FilledButton.icon(
      icon: Icon(Icons.chat, color: Theme.of(context).colorScheme.onPrimary),
      label: Text(
        'دردشة واتساب',
        style: GoogleFonts.cairo(
          color: Theme.of(context).colorScheme.onPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF25D366),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        elevation: 0,
      ),
      onPressed: () => _openWhatsApp(phone),
    );
  }

  Widget _buildCallButton(String phone) {
    return FilledButton.icon(
      icon: Icon(Icons.call, color: Theme.of(context).colorScheme.onPrimary),
      label: Text(
        'اتصل الآن',
        style: GoogleFonts.cairo(
          color: Theme.of(context).colorScheme.onPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: FilledButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        elevation: 0,
      ),
      onPressed: () => _showCallOptions(phone),
    );
  }

  /// Build action buttons section (Share, Report, Favorite)
  Widget _buildActionButtonsSection() {
    return ActionButtonsWid(
      isFavorite: _isFavorite,
      isLoadingFavorite: _isLoadingFavorite,
      onShare: _shareAd,
      onReport: _reportAd,
      onToggleFavorite: _toggleFavorite,
    );
  }

  /// Share ad functionality
  Future<void> _shareAd() async {
    try {
          final String adId = _adModel?.id ?? '';
          final String shareText = '''
        ${_adModel?.adTitle ?? 'إعلان مميز'}

        شاهد هذا الاعلان على موقع فرصة
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
  final String adId = _adModel?.id ?? '';
      final String adUrl = 'https://syria-market.onrender.com/$adId';
      final String encodedMessage = Uri.encodeComponent(shareText);
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
  final String adId = _adModel?.id ?? '';
      final String adUrl = 'https://syria-market.onrender.com/$adId';
      final String encodedMessage = Uri.encodeComponent(shareText);
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
        'adId': _adModel?.id,
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
    final userId = _adModel?.userId;
    if (userId != null && userId.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AdvertiserPageScreen(
            userId: userId,
            initialUserName: _adModel?.userName,
            initialUserPhone: _adModel?.userPhone,
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
  final adTitle = _adModel?.adTitle ?? '';
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
  final currentAdId = _adModel?.id;
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
    return FavoriteButtonWid(
      isFavorite: _isFavorite,
      isLoading: _isLoadingFavorite,
      onTap: _toggleFavorite,
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
      final adId = _adModel?.id;
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
  final categoryId = _adModel?.categoryId;
  final subCategoryId = _adModel?.subCategoryId;
  final currentAdId = _adModel?.id;
    if (categoryId == null) return;

    if (!mounted) return;
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
        if (!mounted) return;
        setState(() {
          _similarAds = filteredAds.map((ad) => AdModel.fromJson(ad)).take(_limitSimilarAds).toList();
          _isLoadingSimilarAds = false;
          _hasErrorSimilarAds = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _hasErrorSimilarAds = true;
          _isLoadingSimilarAds = false;
        });
      }
    } catch (e) {
      debugPrint('Exception fetching similar ads: $e');
      if (!mounted) return;
      if (!mounted) return;
      setState(() {
        _hasErrorSimilarAds = true;
        _isLoadingSimilarAds = false;
      });
    }
  }

  /// Build similar ads section
  Widget _buildSimilarAdsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: SimilarAdsSectionWid(
        isLoading: _isLoadingSimilarAds,
        hasError: _hasErrorSimilarAds,
        similarAds: _similarAds,
        onRetry: _fetchSimilarAds,
        adCardBuilder: (ad) => AdCardWidget(
          ad: ad,
          onTap: () => _navigateToAdDetails(ad),
        ),
        currentPage: _currentSimilarAdPage,
        pageController: _similarAdsPageController,
        limitSimilarAds: _limitSimilarAds,
      ),
    );
  }
}