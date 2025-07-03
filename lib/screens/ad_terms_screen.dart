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
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          elevation: 2,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.deepPurple.shade50,
                Colors.deepPurple.shade100.withOpacity(0.3),
              ],
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
                        color: Colors.black87,
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