import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MyAdsScreen extends StatefulWidget {
  const MyAdsScreen({super.key});

  @override
  State<MyAdsScreen> createState() => _MyAdsScreenState();
}

class _MyAdsScreenState extends State<MyAdsScreen> {
  List<dynamic> myAds = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchMyAds();
  }

  Future<void> fetchMyAds() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await http.get(
      Uri.parse('http://192.168.1.120:10000/api/product/my-ads'),
      headers: {
        'Authorization': token,
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> ads = jsonDecode(response.body);
      setState(() {
        myAds = ads;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  String formatDate(String isoDate) {
    final date = DateTime.parse(isoDate);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays >= 1) {
      return 'منذ ${difference.inDays} يوم';
    } else if (difference.inHours >= 1) {
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inMinutes >= 1) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else {
      return 'الآن';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('إعلاناتي'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : myAds.isEmpty
          ? Center(child: Text('لا توجد إعلانات بعد'))
          : ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: myAds.length,
        itemBuilder: (context, index) {
          final ad = myAds[index];
          final firstImageBase64 = (ad['images'] as List).isNotEmpty
              ? ad['images'][0]
              : null;
          final image = firstImageBase64 != null
              ? Image.memory(base64Decode(firstImageBase64), fit: BoxFit.cover)
              : Container(color: Colors.grey[200], child: Icon(Icons.image, size: 60));

          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: EdgeInsets.only(bottom: 16),
            elevation: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
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
                        '${ad['price']} ${ad['currency']}',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 6),
                      Text(
                        ad['description'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                      ),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 18, color: Colors.deepPurple),
                          SizedBox(width: 4),
                          Text('${ad['city']} - ${ad['region']}',
                              style: TextStyle(color: Colors.grey[700])),
                        ],
                      ),
                      SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 18, color: Colors.grey),
                          SizedBox(width: 4),
                          Text(
                            formatDate(ad['createDate']),
                            style: TextStyle(color: Colors.grey[600]),
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
