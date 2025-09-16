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
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              onPressed: onEdit,
              icon: const Icon(Icons.edit),
              label: Text('تعديل الملف الشخصي', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
              label: Text('حذف الحساب', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ),
        ),
      ],
    );
  }
}
