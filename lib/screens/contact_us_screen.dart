import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  /// فتح البريد الإلكتروني
  void _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@sahbo.com',
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  /// فتح واتساب مع الرقم
  void _launchWhatsApp() async {
    final String phoneNumber = '+905510300730';
    final Uri whatsappUri = Uri.parse('https://wa.me/${phoneNumber.replaceAll('+', '')}');
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } else {
      // يمكنك عرض رسالة في حال لم يكن واتساب متاحًا
      debugPrint("لا يمكن فتح واتساب");
    }
  }

  /// فتح الموقع في المتصفح
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
          backgroundColor: Colors.deepPurple,
          title: const Text('اتصل بنا'),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'هل لديك أي استفسار أو اقتراح؟ تواصل معنا عبر:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),

              Card(
                elevation: 2,
                child: ListTile(
                  leading: const Icon(Icons.email, color: Colors.deepPurple),
                  title: const Text('support@sahbo.com'),
                  onTap: _launchEmail,
                ),
              ),
              const SizedBox(height: 10),

              Card(
                elevation: 2,
                child: ListTile(
                  leading: const Icon(Icons.phone, color: Colors.deepPurple),
                  title: const Text('+90 551 0300 730 اتصال أو عبر تطبيق واتس أب',textDirection: TextDirection.ltr,),
                  onTap: _launchWhatsApp,
                ),
              ),
              const SizedBox(height: 10),

              Card(
                elevation: 2,
                child: ListTile(
                  leading: const Icon(Icons.language, color: Colors.deepPurple),
                  title: const Text('www.sahbo.com'),
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
