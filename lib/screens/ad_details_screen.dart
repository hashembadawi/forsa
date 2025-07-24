import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'image_preview_screen.dart';
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
          title: Text(
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
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          centerTitle: true,
        ),
        body: Container(
          color: Colors.white,
          child: ListView(
            children: [
            // الصور
            SizedBox(
              height: 200,
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
              child: Text(
                'عدد الصور: ${images.length}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              height: 2,
              decoration: BoxDecoration(
                color: Colors.blue[600],
                borderRadius: BorderRadius.circular(1),
              ),
            ),

            // باقي التفاصيل
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    Color(0xFFF8FBFF), // Very light blue
                    Color(0xFFF0F8FF), // Alice blue
                  ],
                ),
                border: Border.all(
                  color: Colors.blue[300]!,
                  width: 1.5,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${ad['productTitle']}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
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
                        'السعر: ${ad['price']} ${ad['currencyName']}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(Icons.location_on, 'الموقع', '${ad['cityName']} - ${ad['regionName']}'),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.calendar_today, 'تاريخ الإعلان', _formatDate(ad['createDate'])),
                    const SizedBox(height: 16),
                    Container(
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
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(Icons.person, 'الاسم', '${ad['userName']}'),
                          const SizedBox(height: 8),
                          _buildInfoRow(Icons.phone, 'الهاتف', '${ad['userPhone']}'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(Icons.category, 'التصنيف', '${ad['categoryName']} - ${ad['subCategoryName'] ?? 'غير متوفر'}'),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.chat, color: Colors.white),
                            label: const Text(
                              'دردشة واتساب',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF25D366),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 3,
                            ),
                            onPressed: () => _openWhatsApp(ad['userPhone']),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.call, color: Colors.white),
                            label: const Text(
                              'اتصل الآن',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[600],
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 3,
                            ),
                            onPressed: () => _makePhoneCall(ad['userPhone']),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: Colors.blue[600],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Special handling for phone numbers to ensure + appears on the left
                if (icon == Icons.phone)
                  WidgetSpan(
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        value.startsWith('+') ? value : '+$value',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  )
                else
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
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

  void _openWhatsApp(String phone) async {
    // إزالة كل الرموز غير الأرقام
    String formattedPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    final message = Uri.encodeComponent("مرحبًا، أنا مهتم بالإعلان الخاص بك.");
    
    // إنشاء الروابط المختلفة
    final uriDirect = Uri.parse("whatsapp://send?phone=$formattedPhone&text=$message");
    final uriWeb = Uri.parse("https://wa.me/$formattedPhone?text=$message");

    try {
      // محاولة فتح التطبيق مباشرة أولاً
      if (await canLaunchUrl(uriDirect)) {
        await launchUrl(uriDirect, mode: LaunchMode.externalApplication);
        print('تم فتح واتساب من التطبيق');
      } else {
        // إذا فشل، نحاول فتح الرابط في المتصفح
        await launchUrl(uriWeb, mode: LaunchMode.externalApplication);
        print('تم فتح واتساب في المتصفح');
      }
    } catch (e) {
      // في حالة فشل كل الطرق، نحاول طريقة بديلة
      try {
        await launchUrl(uriWeb, mode: LaunchMode.platformDefault);
        print('تم فتح واتساب بالطريقة الافتراضية');
      } catch (e2) {
        print('تعذر فتح واتساب: $e2');
        // يمكن إضافة snackbar هنا لإعلام المستخدم
      }
    }
  }

  // طريقة بديلة تُظهر خيارات للمستخدم
  void _showWhatsAppOptions(BuildContext context, String phone) {
    String formattedPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    final message = Uri.encodeComponent("مرحبًا، أنا مهتم بالإعلان الخاص بك.");
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'اختر طريقة فتح واتساب',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.phone_android, color: Colors.green),
              title: Text('فتح تطبيق واتساب'),
              onTap: () async {
                Navigator.pop(context);
                final uri = Uri.parse("whatsapp://send?phone=$formattedPhone&text=$message");
                try {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } catch (e) {
                  print('فشل في فتح التطبيق: $e');
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.web, color: Colors.blue),
              title: Text('فتح واتساب ويب'),
              onTap: () async {
                Navigator.pop(context);
                final uri = Uri.parse("https://wa.me/$formattedPhone?text=$message");
                try {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } catch (e) {
                  print('فشل في فتح المتصفح: $e');
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.copy, color: Colors.orange),
              title: Text('نسخ رقم الهاتف'),
              onTap: () {
                Navigator.pop(context);
                Clipboard.setData(ClipboardData(text: '+$formattedPhone'));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('تم نسخ الرقم: +$formattedPhone')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }


  void _makePhoneCall(String phone) async {
    // Ensure phone number starts with + if it doesn't already
    String formattedPhone = phone.startsWith('+') ? phone : '+$phone';
    final uri = Uri.parse("tel:$formattedPhone");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
