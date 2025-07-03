import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sahbo_app/screens/update_ad_screen.dart';
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

    setState(() {
      isLoading = true;
    });

    try {
      final url = Uri.parse(
        'http://localhost:10000/api/userProducts/$userId?page=$currentPage&limit=$limit',
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
          if (ads.length < limit) {
            hasMore = false;
          }
        });
      } else {
        hasMore = false;
        print('Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      hasMore = false;
      print('Exception: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      fetchMyAds();
    }
  }

  Future<void> _deleteAd(String adId) async {
    final url = Uri.parse('http://localhost:10000/api/userProducts/$adId');

    try {
      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          myAds.removeWhere((ad) => ad['_id'] == adId);
        });
      } else {
        print('فشل في الحذف: ${response.body}');
      }
    } catch (e) {
      print('خطأ أثناء الحذف: $e');
    }
  }

  void _confirmDeleteAd(String adId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد أنك تريد حذف هذا الإعلان؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAd(adId);
            },
            child: Text('حذف', style: TextStyle(color: Colors.red)),
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

    // إذا تم التعديل بنجاح، قم بإعادة تحميل الإعلانات
    if (updated == true) {
      setState(() {
        myAds.clear();
        currentPage = 1;
        hasMore = true;
      });
      fetchMyAds();
    }
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
    return Scaffold(
      appBar: AppBar(
        title: Text('إعلاناتي'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: myAds.isEmpty && isLoading
          ? Center(child: CircularProgressIndicator())
          : myAds.isEmpty
          ? Center(child: Text('لا توجد إعلانات بعد'))
          : ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.all(16),
        itemCount: myAds.length + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == myAds.length) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final ad = myAds[index];

          final List<dynamic> images =
          ad['images'] is List ? ad['images'] : [];
          final firstImageBase64 =
          images.isNotEmpty ? images[0] : null;

          final image = firstImageBase64 != null
              ? Image.memory(
            base64Decode(firstImageBase64),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[200],
                child: Icon(Icons.image, size: 60),
              );
            },
          )
              : Container(
            color: Colors.grey[200],
            child: Icon(Icons.image, size: 60),
          );

          return Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: EdgeInsets.only(bottom: 16),
            elevation: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(
                      top: Radius.circular(12)),
                  child: SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: image,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ad['productTitle'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[800]),
                      ),
                      SizedBox(height: 10),
                      Text(
                        '${ad['price'] ?? '0'} ${ad['currency'] ?? ''}',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 6),
                      Text(
                        ad['description'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[800]),
                      ),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              size: 18, color: Colors.deepPurple),
                          SizedBox(width: 4),
                          Text(
                            '${ad['city'] ?? ''} - ${ad['region'] ?? ''}',
                            style:
                            TextStyle(color: Colors.grey[700]),
                          ),
                        ],
                      ),
                      SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.access_time,
                              size: 18, color: Colors.grey),
                          SizedBox(width: 4),
                          Text(
                            ad['createDate'] != null
                                ? formatDate(ad['createDate'])
                                : 'غير محدد',
                            style:
                            TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () =>
                                _navigateToEditAd(ad), // مؤقتًا
                            icon: Icon(Icons.edit, color: Colors.blue),
                            label: Text('تعديل'),
                          ),
                          TextButton.icon(
                            onPressed: () =>
                                _confirmDeleteAd(ad['_id']),
                            icon:
                            Icon(Icons.delete, color: Colors.red),
                            label: Text('حذف'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
