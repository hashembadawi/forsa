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
  const Color headerColor = Color(0xFF42A5F5); // Light Blue
  const Color surfaceColor = Color(0xFFF5F5F5); // Light Gray
  // Removed unused textColor
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(height: 240, color: headerColor);
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
          decoration: BoxDecoration(
            color: headerColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 68,
                  backgroundColor: surfaceColor,
                  backgroundImage: avatar,
                  child: avatar == null ? Icon(Icons.person, size: 68, color: Colors.white) : null,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.waving_hand, color: Colors.white, size: 22),
                  const SizedBox(width: 6),
                  Text(
                    'مرحبا $firstName $lastName',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              // Removed subtitle for cleaner look
            ],
          ),
        );
      },
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, Color iconColor, VoidCallback onTap) {
    const Color surfaceColor = Color(0xFFF5F5F5);
    const Color textColor = Color(0xFF212121);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 1),
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(
          bottom: BorderSide(color: surfaceColor, width: 0.5),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          splashColor: iconColor.withOpacity(0.12),
          highlightColor: iconColor.withOpacity(0.06),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.13),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.cairo(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: iconColor.withOpacity(0.5),
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
    const Color backgroundColor = Color(0xFFFAFAFA);
    const Color outlineColor = Color(0xFFE0E3E7);
    return Drawer(
      backgroundColor: backgroundColor,
      elevation: 0,
      child: Column(
        children: [
          _buildDrawerHeader(),
          Expanded(
            child: Container(
              color: backgroundColor,
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 0),
                children: [
                  _buildDrawerItem(
                    Icons.home_rounded,
                    'الرئيسية',
                    Color(0xFF42A5F5), // Light Blue
                    () {
                      Navigator.pop(context);
                      reloadHomeScreen(context);
                    },
                  ),
                  _buildDrawerItem(
                    Icons.list_alt_rounded,
                    'إعلاناتي',
                    Color(0xFF66BB6A), // Green
                    () {
                      handleProtectedNavigation(context, 'myAds');
                    },
                  ),
                  _buildDrawerItem(
                    Icons.add_circle_outline_rounded,
                    'إضافة إعلان',
                    Color(0xFFFF7043), // Soft Orange
                    () {
                      handleProtectedNavigation(context, 'addAd');
                    },
                  ),
                  _buildDrawerItem(
                    Icons.favorite_rounded,
                    'المفضلة',
                    Color(0xFFE53935), // Red
                    () {
                      handleProtectedNavigation(context, 'favorites');
                    },
                  ),
                  _buildDrawerItem(
                    Icons.person_rounded,
                    'حسابي',
                    Color(0xFF7C4DFF), // Material 3 purple
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
              color: backgroundColor,
              border: Border(
                top: BorderSide(color: outlineColor, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.copyright, size: 16, color: outlineColor),
                const SizedBox(width: 4),
                Text(
                  'فرصة 2025',
                  style: GoogleFonts.cairo(
                    color: outlineColor,
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
