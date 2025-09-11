import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AppDrawer extends StatelessWidget {
  final Function(BuildContext) reloadHomeScreen;
  final Function(BuildContext, String) handleProtectedNavigation;
  final Future<void> Function(BuildContext) handleAccountNavigation;

  const AppDrawer({
    Key? key,
    required this.reloadHomeScreen,
    required this.handleProtectedNavigation,
    required this.handleAccountNavigation,
  }) : super(key: key);

  Widget _buildDrawerHeader() {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(height: 240, color: Colors.blue);
        }
        final prefs = snapshot.data!;
        final firstName = prefs.getString('userFirstName') ?? '';
        final lastName = prefs.getString('userLastName') ?? '';
        final profileImage = prefs.getString('userProfileImage');
        ImageProvider? avatar;
        if (profileImage != null && profileImage.isNotEmpty) {
          try {
            avatar = MemoryImage(base64Decode(profileImage));
          } catch (e) {
            avatar = null;
          }
        }
        return Container(
          width: double.infinity,
          height: 260,
          decoration: const BoxDecoration(
            color: Colors.blue,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 60, // bigger profile image
                backgroundColor: Colors.white,
                backgroundImage: avatar,
                child: avatar == null ? const Icon(Icons.person, size: 60, color: Colors.blue) : null,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.waving_hand, color: Colors.white, size: 22),
                  const SizedBox(width: 6),
                  Text(
                    'مرحبا $firstName $lastName',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, Color iconColor, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 1),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.grey[50]!,
          ],
        ),
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 0.5),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          splashColor: iconColor.withOpacity(0.1),
          highlightColor: iconColor.withOpacity(0.05),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: iconColor.withOpacity(0.2), width: 1),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.cairo(
                      color: Colors.grey[800],
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.grey[400],
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.grey[50],
      elevation: 0,
      child: Column(
        children: [
          _buildDrawerHeader(),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.grey[50]!,
                    Colors.white,
                  ],
                ),
              ),
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 0),
                children: [
                  _buildDrawerItem(
                    Icons.home_rounded,
                    'الرئيسية',
                    Colors.blue[600]!,
                    () {
                      Navigator.pop(context);
                      reloadHomeScreen(context);
                    },
                  ),
                  _buildDrawerItem(
                    Icons.list_alt_rounded,
                    'إعلاناتي',
                    Colors.green[600]!,
                    () {
                      handleProtectedNavigation(context, 'myAds');
                    },
                  ),
                  _buildDrawerItem(
                    Icons.add_circle_outline_rounded,
                    'إضافة إعلان',
                    Colors.orange[600]!,
                    () {
                      handleProtectedNavigation(context, 'addAd');
                    },
                  ),
                  _buildDrawerItem(
                    Icons.favorite_rounded,
                    'المفضلة',
                    Colors.red[600]!,
                    () {
                      handleProtectedNavigation(context, 'favorites');
                    },
                  ),
                  _buildDrawerItem(
                    Icons.person_rounded,
                    'حسابي',
                    Colors.purple[600]!,
                    () async {
                      await handleAccountNavigation(context);
                    },
                  ),
                ],
              ),
            ),
          ),
          // Footer section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(
                top: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.copyright, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'فرصة 2025',
                  style: GoogleFonts.cairo(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
