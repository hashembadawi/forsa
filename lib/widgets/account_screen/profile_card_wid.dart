import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileCardWid extends StatelessWidget {
  final ImageProvider? avatarImage;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String? accountNumber;
  final bool isLoggedIn;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ProfileCardWid({
    super.key,
    required this.avatarImage,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    this.accountNumber,
    required this.isLoggedIn,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(20),
      color: Colors.white,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          // Only keep the boxShadow for card elevation, remove the extra border
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: isLoggedIn
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IntrinsicHeight(
                      child: Row(
                        children: [
                          // Avatar with Material 3 border
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF212121).withOpacity(0.4),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(3),
                              child: CircleAvatar(
                                radius: MediaQuery.of(context).size.width * 0.12,
                                backgroundColor: Colors.grey[100],
                                backgroundImage: avatarImage,
                                child: avatarImage == null
                                    ? Icon(
                                        Icons.person,
                                        color: const Color(0xFF212121),
                                        size: MediaQuery.of(context).size.width * 0.1,
                                      )
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 18),
                          Container(
                            width: 2,
                            height: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFF212121).withOpacity(0.4),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '$firstName $lastName',
                                  style: GoogleFonts.cairo(
                                    fontSize: MediaQuery.of(context).size.width * 0.048,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF212121),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  phoneNumber,
                                  style: GoogleFonts.cairo(
                                    fontSize: MediaQuery.of(context).size.width * 0.037,
                                    color: const Color(0xFF212121).withOpacity(0.7),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (accountNumber != null && accountNumber!.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    accountNumber!,
                                    style: GoogleFonts.cairo(
                                      fontSize: MediaQuery.of(context).size.width * 0.034,
                                      color: const Color(0xFF212121).withOpacity(0.6),
                                      fontWeight: FontWeight.w400,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF7C4DFF).withOpacity(0.4),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(3),
                        child: CircleAvatar(
                          radius: 35,
                          backgroundColor: Colors.grey[100],
                          child: const Icon(Icons.person, size: 35, color: Color(0xFF7C4DFF)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 22),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7C4DFF).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'مرحباً بك!',
                              style: GoogleFonts.cairo(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF7C4DFF),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'سجل الدخول للوصول لجميع الميزات',
                            style: GoogleFonts.cairo(
                              fontSize: 15,
                              color: const Color(0xFF212121).withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
