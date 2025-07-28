import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Contact Us screen that provides multiple ways to contact support
class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  // Contact information constants
  static const String _supportEmail = 'support@sahbo.com';
  static const String _phoneNumber = '+905510300730';
  static const String _websiteUrl = 'https://www.sahbo.com';

  /// Launch email client
  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        debugPrint('Cannot launch email client');
      }
    } catch (e) {
      debugPrint('Error launching email: $e');
    }
  }

  /// Launch WhatsApp
  Future<void> _launchWhatsApp() async {
    final String cleanPhoneNumber = _phoneNumber.replaceAll('+', '');
    final Uri whatsappUri = Uri.parse('https://wa.me/$cleanPhoneNumber');

    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('Cannot launch WhatsApp');
      }
    } catch (e) {
      debugPrint('Error launching WhatsApp: $e');
    }
  }

  /// Launch website
  Future<void> _launchWebsite() async {
    final Uri webUri = Uri.parse(_websiteUrl);

    try {
      if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('Cannot launch website');
      }
    } catch (e) {
      debugPrint('Error launching website: $e');
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
    );
  }

  /// Build the main body content
  Widget _buildBody() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderText(),
          const SizedBox(height: 24),
          _buildContactMethods(),
        ],
      ),
    );
  }

  /// Build the header text
  Widget _buildHeaderText() {
    return const Text(
      'هل لديك أي استفسار أو اقتراح؟ تواصل معنا عبر:',
      style: TextStyle(
        fontSize: 16,
        height: 1.5,
        color: Colors.black87,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  /// Build all contact methods
  Widget _buildContactMethods() {
    return Column(
      children: [
        _buildContactCard(
          icon: Icons.email,
          title: _supportEmail,
          onTap: _launchEmail,
        ),
        const SizedBox(height: 12),
        _buildContactCard(
          icon: Icons.phone,
          title: 'عبر تطبيق واتس أب',
          onTap: _launchWhatsApp,
        ),
        const SizedBox(height: 12),
        _buildContactCard(
          icon: Icons.language,
          title: 'www.sahbo.com',
          onTap: _launchWebsite,
        ),
      ],
    );
  }

  /// Build a single contact card
  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: _buildCardDecoration(),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue[600]),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.blue[400],
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 4,
        ),
        onTap: onTap,
      ),
    );
  }

  /// Build card decoration
  BoxDecoration _buildCardDecoration() {
    return BoxDecoration(
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
    );
  }
}