import 'dart:convert';
import 'package:flutter/material.dart';
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
              color: Color(0xFF2E7D78),
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 4,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Color(0xFF1E4A47)),
            onPressed: () => Navigator.pop(context),
          ),
          centerTitle: true,
        ),
        body: Container(
          color: Colors.grey[50],
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
                  color: Color(0xFF2E7D78),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4DD0CC), Color(0xFF7FE8E4)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
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
                    Color(0xFFF8FDFD),
                    Color(0xFFF0FAFA),
                  ],
                ),
                border: Border.all(
                  color: Color(0xFF4DD0CC),
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
                        color: Color(0xFF1E4A47),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Color(0xFFFF7A59).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: Color(0xFFFF7A59).withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        'السعر: ${ad['price']} ${ad['currencyName']}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF7A59),
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
                        color: Color(0xFF4DD0CC).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: Color(0xFF4DD0CC).withOpacity(0.3),
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
                              color: Color(0xFF1E4A47),
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
                              backgroundColor: Color(0xFF2E7D78),
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
          color: Color(0xFF2E7D78),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF1E4A47),
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
                          color: Color(0xFF1E4A47),
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
    // Ensure phone number starts with + if it doesn't already
    String formattedPhone = phone.startsWith('+') ? phone : '+$phone';
    final uri = Uri.parse("https://wa.me/$formattedPhone");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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
