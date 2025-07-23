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
          backgroundColor: Colors.blue[700],
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
            color: Colors.white,
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
                        Color(0xFFF8FBFF), // Very light blue
                        Color(0xFFF0F8FF), // Alice blue
                      ],
                    ),
                    border: Border.all(
                      color: Colors.blue[300]!,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTermItem('١. يجب أن يكون محتوى الإعلان واضحًا وصحيحًا وخاليًا من الاحتيال.'),
                        _buildSeparator(),
                        _buildTermItem('٢. يُمنع نشر إعلانات تحتوي على ألفاظ نابية أو محتوى مسيء.'),
                        _buildSeparator(),
                        _buildTermItem('٣. يمنع نشر إعلانات عن مواد أو منتجات مخالفة للقانون أو الأخلاق.'),
                        _buildSeparator(),
                        _buildTermItem('٤. يتم حذف أي إعلان يحتوي على محتوى مضلل أو مزيف.'),
                        _buildSeparator(),
                        _buildTermItem('٥. للإدارة الحق في حذف أي إعلان دون إشعار مسبق إذا خالف الشروط.'),
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue[50]!.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.blue[200]!.withOpacity(0.7),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'الرجاء الالتزام بهذه القواعد لضمان بيئة آمنة لجميع المستخدمين.',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
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

  Widget _buildTermItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.blue[600],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                height: 1.6,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeparator() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      height: 1,
      color: Colors.blue[200]!.withOpacity(0.5),
    );
  }
}