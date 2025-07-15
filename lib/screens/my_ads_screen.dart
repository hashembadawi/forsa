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
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد أنك تريد حذف هذا الإعلان؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAd(adId);
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('إعلاناتي'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (myAds.isEmpty && isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (myAds.isEmpty) {
      return const Center(
        child: Text(
          'لا توجد إعلانات بعد',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
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
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
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

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: SizedBox(
              height: 200,
              width: double.infinity,
              child: firstImageBase64 != null
                  ? Image.memory(
                base64Decode(firstImageBase64),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.image, size: 60),
                  );
                },
              )
                  : Container(
                color: Colors.grey[200],
                child: const Icon(Icons.image, size: 60),
              ),
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
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${ad['price'] ?? '0'} ${ad['currency'] ?? ''}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  ad['description'] ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 18, color: Colors.deepPurple),
                    const SizedBox(width: 4),
                    Text(
                      '${ad['city'] ?? ''} - ${ad['region'] ?? ''}',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 18, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      ad['createDate'] != null
                          ? formatDate(ad['createDate'])
                          : 'غير محدد',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _navigateToEditAd(ad),
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      label: const Text('تعديل'),
                    ),
                    TextButton.icon(
                      onPressed: () => _confirmDeleteAd(ad['_id']),
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text('حذف'),
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