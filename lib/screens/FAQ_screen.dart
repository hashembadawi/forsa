import 'package:flutter/material.dart';

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'الأسئلة الشائعة',
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
          padding: const EdgeInsets.all(16),
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
          child: ListView(
            children: [
              _buildFAQItem(
                question: 'كيف يمكنني نشر إعلان جديد؟',
                answer: 'اضغط على زر "إضافة إعلان" في الصفحة الرئيسية أو من القائمة الجانبية، ثم اتبع الخطوات لملء معلومات الإعلان.',
              ),
              _buildFAQItem(
                question: 'كم تستغرق عملية مراجعة الإعلان؟',
                answer: 'عادةً ما يتم مراجعة الإعلانات خلال 24 ساعة، ولكن قد تختلف المدة حسب عدد الإعلانات المقدمة.',
              ),
              _buildFAQItem(
                question: 'هل يمكنني تعديل إعلان بعد نشره؟',
                answer: 'نعم، يمكنك تعديل الإعلان من صفحة "إعلاناتي" عن طريق الضغط على الإعلان ثم اختيار "تعديل".',
              ),
              _buildFAQItem(
                question: 'ما هي سياسة الإلغاء والاسترجاع؟',
                answer: 'يمكنك حذف إعلانك في أي وقت، ولكن لا يمكن استرجاع المبلغ المدفوع في حالة الإعلانات المميزة.',
              ),
              _buildFAQItem(
                question: 'كيف أتواصل مع البائع؟',
                answer: 'يتم التواصل مع البائع عبر رقم الهاتف الموجود في صفحة الإعلان أو عبر زر "تواصل" إذا كان متاحاً.',
              ),
              _buildFAQItem(
                question: 'ما هي الإعلانات الممنوعة؟',
                answer: 'يمنع أي إعلان مخالف للقوانين أو يحتوي على محتوى غير لائق. راجع "شروط الإعلان" للمزيد من التفاصيل.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQItem({required String question, required String answer}) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              answer,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}