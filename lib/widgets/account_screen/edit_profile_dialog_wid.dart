import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EditProfileDialogWid extends StatelessWidget {
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final GlobalKey<FormState> formKey;
  final ImageProvider? avatarImage;
  final VoidCallback onPickImage;
  final VoidCallback onRemoveImage;
  final VoidCallback onSave;

  const EditProfileDialogWid({
    super.key,
    required this.firstNameController,
    required this.lastNameController,
    required this.formKey,
    required this.avatarImage,
    required this.onPickImage,
    required this.onRemoveImage,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.maxFinite,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'تعديل الملف الشخصي',
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: formKey,
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: onPickImage,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.blue, width: 2),
                            color: Colors.grey[100],
                          ),
                          child: ClipOval(
                            child: avatarImage != null
                                ? Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image(image: avatarImage!, fit: BoxFit.cover),
                                      Positioned(
                                        top: 5,
                                        right: 5,
                                        child: GestureDetector(
                                          onTap: onRemoveImage,
                                          child: Container(
                                            width: 20,
                                            height: 20,
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.add_a_photo, size: 30, color: Colors.blue),
                                      const SizedBox(height: 4),
                                      Text(
                                        'اضغط لاختيار صورة',
                                        style: GoogleFonts.cairo(fontSize: 10, color: Colors.blue),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: firstNameController,
                        decoration: InputDecoration(
                          labelText: 'الاسم الأول',
                          labelStyle: GoogleFonts.cairo(),
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        validator: (v) => v?.isEmpty == true ? 'مطلوب' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: lastNameController,
                        decoration: InputDecoration(
                          labelText: 'الاسم الأخير',
                          labelStyle: GoogleFonts.cairo(),
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        validator: (v) => v?.isEmpty == true ? 'مطلوب' : null,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF42A5F5), // Light Blue
                        textStyle: GoogleFonts.cairo(),
                      ),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: onSave,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF42A5F5), // Light Blue
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        textStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                      ),
                      child: const Text('حفظ'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
