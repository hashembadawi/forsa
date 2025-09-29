import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdvertiserInfoWid extends StatelessWidget {
  final String userName;
  final String userPhone;
  final VoidCallback onAdvertiserPage;
  const AdvertiserInfoWid({
    Key? key,
    required this.userName,
    required this.userPhone,
    required this.onAdvertiserPage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'معلومات المعلن',
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.person, size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'الاسم: $userName',
                  style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w500, color: colorScheme.onSurface),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.phone, size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'الهاتف: $userPhone',
                  style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w500, color: colorScheme.onSurface),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: Icon(Icons.person, color: colorScheme.onPrimary),
              label: Text(
                'صفحة المعلن',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimary,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 0,
              ),
              onPressed: onAdvertiserPage,
            ),
          ),
        ],
      ),
    );
  }
}
