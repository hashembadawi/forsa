import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';

/// Contact Us screen that provides multiple ways to contact support
class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  // Contact information constants
  static const String _supportEmail = 'support@syria-market.com';
  static const String _phoneNumber = '905510300730';
  static const String _websiteUrl = 'https://syria-market-web.onrender.com';

  /// Launch email client
  Future<void> _launchEmail() async {
    const String subject = "استفسار حول تطبيق سوق سوريا";
    const String body = "السلام عليكم،\n\nأريد الاستفسار عن تطبيق سوق سوريا.\n\nشكراً لكم.";
    final String encodedSubject = Uri.encodeComponent(subject);
    final String encodedBody = Uri.encodeComponent(body);
    
    final Uri emailUri = Uri.parse("mailto:$_supportEmail?subject=$encodedSubject&body=$encodedBody");
    final Uri emailUriSimple = Uri(scheme: 'mailto', path: _supportEmail);

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(emailUriSimple, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      try {
        await launchUrl(emailUriSimple, mode: LaunchMode.platformDefault);
      } catch (e2) {
        debugPrint('Error launching email: $e2');
      }
    }
  }

  /// Launch WhatsApp
  Future<void> _launchWhatsApp() async {
    final String cleanPhoneNumber = _phoneNumber;
    const String message = "السلام عليكم، أريد التواصل معكم بخصوص تطبيق سوق سوريا.";
    final String encodedMessage = Uri.encodeComponent(message);

    final Uri uriDirect = Uri.parse("whatsapp://send?phone=$cleanPhoneNumber&text=$encodedMessage");
    final Uri uriWeb = Uri.parse("https://wa.me/$cleanPhoneNumber?text=$encodedMessage");

    try {
      if (await canLaunchUrl(uriDirect)) {
        await launchUrl(uriDirect, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uriWeb, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      try {
        await launchUrl(uriWeb, mode: LaunchMode.platformDefault);
      } catch (e2) {
        debugPrint('Error launching WhatsApp: $e2');
      }
    }
  }

  /// Launch website
  Future<void> _launchWebsite() async {
    final Uri webUri = Uri.parse(_websiteUrl);
    final Uri webUriFallback = Uri.parse("https://www.google.com/search?q=syria+market");

    try {
      if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(webUri, mode: LaunchMode.inAppBrowserView);
      }
    } catch (e) {
      try {
        await launchUrl(webUri, mode: LaunchMode.platformDefault);
      } catch (e2) {
        try {
          // Fallback to Google search if the website is not accessible
          await launchUrl(webUriFallback, mode: LaunchMode.externalApplication);
        } catch (e3) {
          debugPrint('Error launching website: $e3');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: _buildAppBar(context),
        body: _buildBody(),
      ),
    );
  }

  /// Build the app bar
  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(
        'اتصل بنا',
        style: GoogleFonts.cairo(fontWeight: FontWeight.bold , fontSize: 22, color: Colors.white),
      ),
      centerTitle: true,
      backgroundColor: Colors.blue[700],
      foregroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  /// Build the main body content
  Widget _buildBody() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: Colors.white,
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildContactContainer(),
          ],
        ),
      ),
    );
  }

  /// Build the main contact container
  Widget _buildContactContainer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Section
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.blue[600],
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.support_agent,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                'هل لديك أي استفسار أو اقتراح؟ تواصل معنا عبر:',
                style: GoogleFonts.cairo(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        // Contact Content
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
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
                ..._buildContactMethods(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Build all contact methods
  List<Widget> _buildContactMethods() {
    return [
      _buildContactCard(
        icon: Icons.email,
        title: _supportEmail,
        subtitle: 'البريد الإلكتروني',
        onTap: _launchEmail,
      ),
      const SizedBox(height: 12),
      _buildContactCard(
        icon: Icons.chat,
        title: 'عبر تطبيق واتس أب',
        subtitle: _phoneNumber,
        onTap: _launchWhatsApp,
      ),
      const SizedBox(height: 12),
      _buildContactCard(
        icon: Icons.language,
        title: 'www.syria-market-web.com',
        subtitle: 'الموقع الإلكتروني',
        onTap: _launchWebsite,
      ),
    ];
  }

  /// Build a single contact card
  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50]!.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue[100]!,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.blue[600],
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.blue[400],
            ),
          ],
        ),
      ),
    );
  }
}