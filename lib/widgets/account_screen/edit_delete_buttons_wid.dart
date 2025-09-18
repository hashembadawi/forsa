import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EditDeleteButtonsWid extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const EditDeleteButtonsWid({
    super.key,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF42A5F5), // Light Blue
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
                textStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              onPressed: onEdit,
              icon: const Icon(Icons.edit),
              label: const Text('تعديل الملف الشخصي'),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE53935), // Red
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
                textStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
              label: const Text('حذف الحساب'),
            ),
          ),
        ),
      ],
    );
  }
}
