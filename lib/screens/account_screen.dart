import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'FAQ_screen.dart';
import 'ad_terms_screen.dart';
import 'contact_us_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class AccountScreen extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String phoneNumber;
  final bool isLoggedIn;

  const AccountScreen({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.phoneNumber,
    required this.isLoggedIn,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('حسابي'),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.blue[700],
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.home),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                      (route) => false,
                );
              },
            ),
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // بطاقة معلومات المستخدم
                  _buildUserCard(context),
                  const SizedBox(height: 24),

                  // قسم المعلومات
                  const SizedBox(height: 16),
                  _buildSectionTitle('المعلومات'),
                  _buildInfoList(context),

                  // زر تسجيل الدخول/الخروج
                  const SizedBox(height: 32),
                  _buildAuthButton(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue,
            Color(0xFF87CEEB),
          ],
        ),
        border: Border.all(
          color: Colors.blue,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: isLoggedIn
            ? Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white.withOpacity(0.8),
              child: Icon(
                Icons.person,
                size: 30,
                color: Colors.blue[700],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userEmail,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  if (phoneNumber.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        phoneNumber,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        )
            : Column(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white.withOpacity(0.8),
              child: const Icon(
                Icons.person_outline,
                size: 30,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'مرحباً بك!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'سجل الدخول للوصول إلى جميع الميزات',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildInfoList(BuildContext context) {
    return Container(
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
      child: Column(
        children: [
          _buildListItem(
            context,
            icon: Icons.article,
            title: 'شروط الإعلان',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdTermsScreen()),
              );
            },
          ),
          Divider(height: 1, indent: 16, endIndent: 16, color: Colors.blue[200]),
          _buildListItem(
            context,
            icon: Icons.help_center,
            title: 'الأسئلة الشائعة',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FAQScreen()),
              );
            },
          ),
          Divider(height: 1, indent: 16, endIndent: 16, color: Colors.blue[200]),
          _buildListItem(
            context,
            icon: Icons.call,
            title: 'اتصل بنا',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ContactUsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required VoidCallback onTap,
      }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue[700]),
      title: Text(title, style: const TextStyle(color: Colors.black87)),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.black87,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Widget _buildAuthButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isLoggedIn ? const Color(0xFFFF7A59) : Colors.blue[700],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        onPressed: () async {
          if (isLoggedIn) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('token');
            await prefs.remove('username');
            await prefs.remove('email');

            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (route) => false,
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          }
        },
        child: Text(
          isLoggedIn ? 'تسجيل الخروج' : 'تسجيل الدخول',
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}