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
  final bool isLoggedIn;

  const AccountScreen({
    super.key,
    required this.userName,
    required this.userEmail,
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
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.deepPurple,
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
        body: SingleChildScrollView(
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
    );
  }

  Widget _buildUserCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: isLoggedIn
            ? Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.deepPurple[100],
              child: Icon(
                Icons.person,
                size: 30,
                color: Colors.deepPurple[800],
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
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userEmail,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        )
            : Column(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.deepPurple[100],
              child: const Icon(
                Icons.person_outline,
                size: 30,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'مرحباً بك!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'سجل الدخول للوصول إلى جميع الميزات',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
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
          color: Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildInfoList(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
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
          const Divider(height: 1, indent: 16, endIndent: 16),
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
          const Divider(height: 1, indent: 16, endIndent: 16),
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
      leading: Icon(icon, color: Colors.deepPurple),
      title: Text(title),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey[400],
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
          backgroundColor: isLoggedIn ? Colors.red[50] : Colors.deepPurple,
          foregroundColor: isLoggedIn ? Colors.red : Colors.white,
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