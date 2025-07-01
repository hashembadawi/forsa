import 'package:flutter/material.dart';

import 'ad_terms_screen.dart';
import 'contact_us_screen.dart';

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
          backgroundColor: Colors.deepPurple,
          title: Text('حسابي'),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ ترحيب بالمستخدم
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.deepPurple[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: isLoggedIn
                    ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('مرحباً، $userName 👋',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('البريد الإلكتروني: $userEmail',
                        style: TextStyle(fontSize: 16)),
                  ],
                )
                    : Center(
                  child: Text(
                    'يرجى تسجيل الدخول لعرض معلومات حسابك',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),

              SizedBox(height: 30),

              // ✅ عناصر القائمة
              _buildItem(context, Icons.article, 'شروط الإعلان', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => AdTermsScreen()));
              }),
              Divider(),

              _buildItem(context, Icons.call, 'اتصل بنا', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => ContactUsScreen()));
              }),
              Divider(),

              _buildItem(context, Icons.logout, 'تسجيل الخروج', () {
                // TODO: تنفيذ تسجيل الخروج
                Navigator.pop(context);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.deepPurple),
      title: Text(title, style: TextStyle(fontSize: 16)),
      trailing: Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
