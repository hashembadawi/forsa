import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  void _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@sahbo.com',
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  void _launchWhatsApp() async {
    final String phoneNumber = '+905510300730';
    final Uri whatsappUri = Uri.parse('https://wa.me/${phoneNumber.replaceAll('+', '')}');
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint("لا يمكن فتح واتساب");
    }
  }

  void _launchWebsite() async {
    final Uri webUri = Uri.parse('https://www.sahbo.com');
    if (await canLaunchUrl(webUri)) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'اتصل بنا',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: Colors.blue[700],
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'هل لديك أي استفسار أو اقتراح؟ تواصل معنا عبر:',
                style: TextStyle(
                  fontSize: 16, 
                  height: 1.5,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),

              // بطاقة البريد الإلكتروني
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  leading: Icon(Icons.email, color: Colors.blue[600]),
                  title: const Text(
                    'support@sahbo.com',
                    style: TextStyle(color: Colors.black87),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios, 
                    size: 16,
                    color: Colors.blue[400],
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  onTap: _launchEmail,
                ),
              ),

              // بطاقة واتساب
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  leading: Icon(Icons.phone, color: Colors.blue[600]),
                  title: const Text(
                    ' عبر تطبيق واتس أب',
                    textDirection: TextDirection.rtl,
                    style: TextStyle(color: Colors.black87),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios, 
                    size: 16,
                    color: Colors.blue[400],
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  onTap: _launchWhatsApp,
                ),
              ),

              // بطاقة الموقع
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  leading: Icon(Icons.language, color: Colors.blue[600]),
                  title: const Text(
                    'www.sahbo.com',
                    style: TextStyle(color: Colors.black87),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios, 
                    size: 16,
                    color: Colors.blue[400],
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  onTap: _launchWebsite,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}