import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'image_preview_screen.dart'; // تأكد من أنك أضفت هذا الملف

class AdDetailsScreen extends StatelessWidget {
  final dynamic ad;

  const AdDetailsScreen({super.key, required this.ad});

  @override
  Widget build(BuildContext context) {
    final List<dynamic> images = ad['images'] ?? [];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تفاصيل الإعلان'),
          backgroundColor: Colors.deepPurple,
        ),
        body: ListView(
          children: [
            // الصور
            SizedBox(
              height: 250,
              child: PageView.builder(
                itemCount: images.length,
                itemBuilder: (context, index) {
                  final imgBase64 = images[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ImagePreviewScreen(
                            images: images,
                            initialIndex: index,
                          ),
                        ),
                      );
                    },
                    child: Image.memory(
                      base64Decode(imgBase64),
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text('عدد الصور: ${images.length}', style: const TextStyle(fontSize: 12)),
            ),
            const Divider(),

            // باقي التفاصيل
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('السعر: ${ad['price']} ${ad['currency']}', style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  Text('الموقع: ${ad['city']} - ${ad['region']}'),
                  const SizedBox(height: 8),
                  Text('تاريخ الإعلان: ${_formatDate(ad['createDate'])}'),
                  const SizedBox(height: 12),
                  const Text('معلومات المعلن:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('الاسم: ${ad['userName']}'),
                  Text('الهاتف: ${ad['userPhone']}'),
                  const SizedBox(height: 12),
                  Text('التصنيف: ${_categoryName(ad['category'])}'),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.chat),
                        label: const Text('دردشة واتساب'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        onPressed: () => _openWhatsApp(ad['userPhone']),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.call),
                        label: const Text('اتصل الآن'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                        onPressed: () => _makePhoneCall(ad['userPhone']),
                      ),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'غير معروف';
    }
  }

  String _categoryName(int categoryId) {
    final categories = {
      1: 'حيوانات',
      2: 'خدمات',
      3: 'أزياء',
      4: 'أدوات',
      5: 'أثاث',
      6: 'إلكترونيات',
      7: 'عقارات',
      8: 'مركبات',
    };
    return categories[categoryId] ?? 'غير معروف';
  }

  void _openWhatsApp(String phone) async {
    final uri = Uri.parse("https://wa.me/$phone");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _makePhoneCall(String phone) async {
    final uri = Uri.parse("tel:$phone");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
