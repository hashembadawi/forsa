import 'package:flutter/material.dart';

class AdTermsScreen extends StatelessWidget {
  const AdTermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.deepPurple,
          title: Text('شروط الإعلان'),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Text(
              '''
١. يجب أن يكون محتوى الإعلان واضحًا وصحيحًا وخاليًا من الاحتيال.
٢. يُمنع نشر إعلانات تحتوي على ألفاظ نابية أو محتوى مسيء.
٣. يمنع نشر إعلانات عن مواد أو منتجات مخالفة للقانون أو الأخلاق.
٤. يتم حذف أي إعلان يحتوي على محتوى مضلل أو مزيف.
٥. للإدارة الحق في حذف أي إعلان دون إشعار مسبق إذا خالف الشروط.

الرجاء الالتزام بهذه القواعد لضمان بيئة آمنة لجميع المستخدمين.
''',
              style: TextStyle(fontSize: 16, height: 1.6),
            ),
          ),
        ),
      ),
    );
  }
}
