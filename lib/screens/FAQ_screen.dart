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
          backgroundColor: const Color(0xFF1E4A47),
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Container(
          padding: const EdgeInsets.all(16),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E4A47),
          ),
        ),
        iconColor: const Color(0xFF2E7D78),
        collapsedIconColor: const Color(0xFF2E7D78),
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF7FE8E4).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              answer,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1E4A47),
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}