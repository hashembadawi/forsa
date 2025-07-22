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
          backgroundColor: const Color(0xFF1E4A47),
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
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF7FE8E4),
                Colors.white,
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'هل لديك أي استفسار أو اقتراح؟ تواصل معنا عبر:',
                style: TextStyle(
                  fontSize: 16, 
                  height: 1.5,
                  color: Color(0xFF1E4A47),
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
                      Color(0xFFF8FDFD),
                    ],
                  ),
                  border: Border.all(
                    color: const Color(0xFF4DD0CC),
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
                  leading: const Icon(Icons.email, color: Color(0xFF2E7D78)),
                  title: const Text(
                    'support@sahbo.com',
                    style: TextStyle(color: Color(0xFF1E4A47)),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios, 
                    size: 16,
                    color: Color(0xFF7FE8E4),
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
                      Color(0xFFF8FDFD),
                    ],
                  ),
                  border: Border.all(
                    color: const Color(0xFF4DD0CC),
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
                  leading: const Icon(Icons.phone, color: Color(0xFF2E7D78)),
                  title: const Text(
                    '+90 551 0300 730 اتصال أو عبر تطبيق واتس أب',
                    textDirection: TextDirection.ltr,
                    style: TextStyle(color: Color(0xFF1E4A47)),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios, 
                    size: 16,
                    color: Color(0xFF7FE8E4),
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
                      Color(0xFFF8FDFD),
                    ],
                  ),
                  border: Border.all(
                    color: const Color(0xFF4DD0CC),
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
                  leading: const Icon(Icons.language, color: Color(0xFF2E7D78)),
                  title: const Text(
                    'www.sahbo.com',
                    style: TextStyle(color: Color(0xFF1E4A47)),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios, 
                    size: 16,
                    color: Color(0xFF7FE8E4),
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