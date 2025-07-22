import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sahbo_app/screens/update_ad_screen.dart';
import 'package:sahbo_app/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyAdsScreen extends StatefulWidget {
  const MyAdsScreen({super.key});

  @override
  State<MyAdsScreen> createState() => _MyAdsScreenState();
}

class _MyAdsScreenState extends State<MyAdsScreen> {
  List<dynamic> myAds = [];
  bool isLoading = false;
  bool hasMore = true;
  int currentPage = 1;
  final int limit = 5;
  late ScrollController _scrollController;
  String? userId;
  String? token;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    _initAndFetchAds();
  }

  Future<void> _initAndFetchAds() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token') ?? '';
    userId = prefs.getString('userId');

    if (token == null || token!.isEmpty) return;
    await fetchMyAds();
  }

  Future<void> fetchMyAds() async {
    if (isLoading || !hasMore || userId == null) return;

    setState(() => isLoading = true);

    try {
      final url = Uri.parse(
        'https://sahbo-app-api.onrender.com/api/userProducts/$userId?page=$currentPage&limit=$limit',
      );

      final response = await http.get(url, headers: {
        'authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> ads = decoded['products'] ?? [];

        setState(() {
          myAds.addAll(ads);
          currentPage++;
          if (ads.length < limit) hasMore = false;
        });
      } else {
        hasMore = false;
        debugPrint('Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      hasMore = false;
      debugPrint('Exception: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      fetchMyAds();
    }
  }

  Future<void> _deleteAd(String adId) async {
    final url = Uri.parse('https://sahbo-app-api.onrender.com/api/userProducts/$adId');

    try {
      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() => myAds.removeWhere((ad) => ad['_id'] == adId));
      } else {
        _showError('فشل في حذف الإعلان');
      }
    } catch (e) {
      _showError('حدث خطأ أثناء الحذف');
    }
  }

  void _confirmDeleteAd(String adId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Color(0xFF4DD0CC), width: 1.5),
        ),
        backgroundColor: Colors.white,
        title: Text(
          'تأكيد الحذف',
          style: TextStyle(
            color: Color(0xFF1E4A47),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Text(
          'هل أنت متأكد أنك تريد حذف هذا الإعلان؟',
          style: TextStyle(
            color: Color(0xFF2E7D78),
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              'إلغاء',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAd(adId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFE74C3C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: Text(
              'حذف',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToEditAd(Map<String, dynamic> ad) async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditAdScreen(
          adId: ad['_id'],
          initialTitle: ad['productTitle'] ?? '',
          initialPrice: ad['price']?.toString() ?? '',
          initialCurrency: ad['currency'] ?? 'ل.س',
          initialDescription: ad['description'] ?? '',
        ),
      ),
    );

    if (updated == true) {
      setState(() {
        myAds.clear();
        currentPage = 1;
        hasMore = true;
      });
      fetchMyAds();
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  String formatDate(String isoDate) {
    final date = DateTime.parse(isoDate);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays >= 1) return 'منذ ${difference.inDays} يوم';
    if (difference.inHours >= 1) return 'منذ ${difference.inHours} ساعة';
    if (difference.inMinutes >= 1) return 'منذ ${difference.inMinutes} دقيقة';
    return 'الآن';
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(
            'إعلاناتي',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          backgroundColor: const Color(0xFF1E4A47),
          elevation: 4,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              // Navigate back to home screen instead of just popping
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => HomeScreen()),
                (Route<dynamic> route) => false,
              );
            },
          ),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (myAds.isEmpty && isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4DD0CC)),
        ),
      );
    }

    if (myAds.isEmpty) {
      return Center(
        child: Text(
          'لا توجد إعلانات بعد',
          style: TextStyle(
            fontSize: 18,
            color: Color(0xFF2E7D78),
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: Color(0xFF4DD0CC),
      onRefresh: () async {
        setState(() {
          myAds.clear();
          currentPage = 1;
          hasMore = true;
        });
        await fetchMyAds();
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: myAds.length + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == myAds.length) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4DD0CC)),
                ),
              ),
            );
          }

          final ad = myAds[index];
          return _buildAdCard(ad);
        },
      ),
    );
  }

  Widget _buildAdCard(Map<String, dynamic> ad) {
    final List<dynamic> images = ad['images'] is List ? ad['images'] : [];
    final firstImageBase64 = images.isNotEmpty ? images[0] : null;

    final image = firstImageBase64 != null
        ? Image.memory(
            base64Decode(firstImageBase64),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFF0FAFA),
                      Color(0xFFE8F5F5),
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image,
                        size: 60,
                        color: Color(0xFF4DD0CC),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'صورة',
                        style: TextStyle(
                          color: Color(0xFF2E7D78),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          )
        : Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF0FAFA),
                  Color(0xFFE8F5F5),
                ],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.image,
                    size: 60,
                    color: Color(0xFF4DD0CC),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'لا توجد صورة',
                    style: TextStyle(
                      color: Color(0xFF2E7D78),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Color(0xFFF8FDFD),
            Color(0xFFF0FAFA),
          ],
        ),
        border: Border.all(
          color: Color(0xFF4DD0CC),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: SizedBox(
              height: 200,
              width: double.infinity,
              child: image,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ad['productTitle'] ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E4A47),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Color(0xFFFF7A59).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Color(0xFFFF7A59).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${ad['price'] ?? '0'} ${ad['currencyName'] ?? ad['currency'] ?? ''}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF7A59),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  ad['description'] ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF2E7D78),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Color(0xFF2E7D78)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${ad['cityName'] ?? ''} - ${ad['regionName'] ?? ''}',
                        style: TextStyle(
                          color: Color(0xFF1E4A47),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Color(0xFF2E7D78)),
                    const SizedBox(width: 4),
                    Text(
                      ad['createDate'] != null
                          ? formatDate(ad['createDate'])
                          : 'غير محدد',
                      style: TextStyle(
                        color: Color(0xFF1E4A47),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF4DD0CC), Color(0xFF7FE8E4)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _navigateToEditAd(ad),
                      icon: Icon(Icons.edit, size: 18, color: Colors.white),
                      label: Text(
                        'تعديل',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF2E7D78),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => _confirmDeleteAd(ad['_id']),
                      icon: Icon(Icons.delete, size: 18, color: Colors.white),
                      label: Text(
                        'حذف',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFE74C3C),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}