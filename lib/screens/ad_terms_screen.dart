import 'package:flutter/material.dart';

class AdTermsScreen extends StatelessWidget {
  const AdTermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'شروط الإعلان',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: const Color(0xFF1E4A47),
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF7FE8E4),
                Colors.white,
              ],
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        Color(0xFFF8FDFD),
                      ],
                    ),
                    border: Border.all(
                      color: const Color(0xFF4DD0CC),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      '''
١. يجب أن يكون محتوى الإعلان واضحًا وصحيحًا وخاليًا من الاحتيال.
٢. يُمنع نشر إعلانات تحتوي على ألفاظ نابية أو محتوى مسيء.
٣. يمنع نشر إعلانات عن مواد أو منتجات مخالفة للقانون أو الأخلاق.
٤. يتم حذف أي إعلان يحتوي على محتوى مضلل أو مزيف.
٥. للإدارة الحق في حذف أي إعلان دون إشعار مسبق إذا خالف الشروط.

الرجاء الالتزام بهذه القواعد لضمان بيئة آمنة لجميع المستخدمين.
''',
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.8,
                        color: Color(0xFF1E4A47),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}