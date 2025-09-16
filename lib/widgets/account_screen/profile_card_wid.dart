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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.blue[300]!,
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: isLoggedIn
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IntrinsicHeight(
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.blue[400]!,
                                width: 2,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: MediaQuery.of(context).size.width * 0.12,
                              backgroundColor: Colors.grey[100],
                              backgroundImage: avatarImage,
                              child: avatarImage == null
                                  ? Icon(
                                      Icons.person,
                                      color: Colors.blue,
                                      size: MediaQuery.of(context).size.width * 0.1,
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            width: 2,
                            height: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.blue[300]!.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '$firstName $lastName',
                                  style: GoogleFonts.cairo(
                                    fontSize: MediaQuery.of(context).size.width * 0.045,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  phoneNumber,
                                  style: GoogleFonts.cairo(
                                    fontSize: MediaQuery.of(context).size.width * 0.035,
                                    color: Colors.black.withOpacity(0.7),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (accountNumber != null && accountNumber!.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    accountNumber!,
                                    style: GoogleFonts.cairo(
                                      fontSize: MediaQuery.of(context).size.width * 0.032,
                                      color: Colors.black.withOpacity(0.6),
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
                        border: Border.all(
                          color: Colors.blue[400]!,
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.grey[100],
                        child: const Icon(Icons.person, size: 35, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'مرحباً بك!',
                              style: GoogleFonts.cairo(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'سجل الدخول للوصول لجميع الميزات',
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              color: Colors.grey[600],
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
