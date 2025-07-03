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
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          elevation: 2,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.deepPurple.shade50,
                Colors.deepPurple.shade100.withOpacity(0.3),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'هل لديك أي استفسار أو اقتراح؟ تواصل معنا عبر:',
                style: TextStyle(fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 24),

              // بطاقة البريد الإلكتروني
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(Icons.email, color: Colors.deepPurple),
                  title: const Text('support@sahbo.com'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  onTap: _launchEmail,
                ),
              ),
              const SizedBox(height: 12),

              // بطاقة واتساب
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(Icons.phone, color: Colors.deepPurple),
                  title: const Text(
                    '+90 551 0300 730 اتصال أو عبر تطبيق واتس أب',
                    textDirection: TextDirection.ltr,
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  onTap: _launchWhatsApp,
                ),
              ),
              const SizedBox(height: 12),

              // بطاقة الموقع
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(Icons.language, color: Colors.deepPurple),
                  title: const Text('www.sahbo.com'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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