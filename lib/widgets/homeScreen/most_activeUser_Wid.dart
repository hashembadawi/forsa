import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../screens/advertiser_page_screen.dart';
import '../../screens/most_active_users_screen.dart';

class MostActiveUserWid extends StatelessWidget {
  final List<Map<String, dynamic>> mostActiveUsers;
  final bool isLoading;
  final bool hasError;

  const MostActiveUserWid({
    Key? key,
    required this.mostActiveUsers,
    this.isLoading = false,
    this.hasError = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }
    if (hasError) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(child: Text('تعذر تحميل المستخدمين الأكثر حركة', style: GoogleFonts.cairo(fontSize: 14, color: Colors.red))),
      );
    }
    if (mostActiveUsers.isEmpty) {
      return SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'المستخدمين الأكثر حركة',
                style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MostActiveUsersScreen(),
                    ),
                  );
                },
                child: Text(
                  'عرض الكل >',
                  style: GoogleFonts.cairo(fontSize: 12, color: Colors.blue[700], fontWeight: FontWeight.w600),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                  minimumSize: Size(0, 24),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: mostActiveUsers.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final user = mostActiveUsers[index];
              final String? base64Image = user['profileImage'];
              final String userName = ((user['firstName'] ?? '') + ' ' + (user['lastName'] ?? '')).trim();
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdvertiserPageScreen(
                        userId: user['userId'] ?? '',
                        initialUserName: userName,
                        initialUserPhone: user['phoneNumber'] ?? '',
                      ),
                    ),
                  );
                },
                child: SizedBox(
                  width: 80,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.blue[300]!, width: 2),
                          color: Colors.white,
                        ),
                        child: base64Image != null && base64Image.isNotEmpty
                            ? ClipOval(
                                child: Image.memory(
                                  base64Decode(base64Image),
                                  fit: BoxFit.cover,
                                  width: 64,
                                  height: 64,
                                  errorBuilder: (context, error, stackTrace) => Icon(Icons.person, size: 32, color: Colors.blue[400]),
                                ),
                              )
                            : Icon(Icons.person, size: 32, color: Colors.blue[400]),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 70,
                        child: Text(
                          userName,
                          style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
