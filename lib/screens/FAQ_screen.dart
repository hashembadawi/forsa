import 'package:flutter/material.dart';

/// Data model for FAQ items
class FAQItem {
  final String question;
  final String answer;

  const FAQItem({
    required this.question,
    required this.answer,
  });
}

/// FAQ Screen displaying frequently asked questions with expandable answers
class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  // FAQ data structure
  static const List<FAQItem> _faqItems = [
    FAQItem(
      question: 'كيف يمكنني نشر إعلان جديد؟',
      answer: 'اضغط على زر "إضافة إعلان" في الصفحة الرئيسية أو من القائمة الجانبية، ثم اتبع الخطوات لملء معلومات الإعلان.',
    ),
    FAQItem(
      question: 'كم تستغرق عملية مراجعة الإعلان؟',
      answer: 'عادةً ما يتم مراجعة الإعلانات خلال 24 ساعة، ولكن قد تختلف المدة حسب عدد الإعلانات المقدمة.',
    ),
    FAQItem(
      question: 'هل يمكنني تعديل إعلان بعد نشره؟',
      answer: 'نعم، يمكنك تعديل الإعلان من صفحة "إعلاناتي" عن طريق الضغط على الإعلان ثم اختيار "تعديل".',
    ),
    FAQItem(
      question: 'ما هي سياسة الإلغاء والاسترجاع؟',
      answer: 'يمكنك حذف إعلانك في أي وقت، ولكن لا يمكن استرجاع المبلغ المدفوع في حالة الإعلانات المميزة.',
    ),
    FAQItem(
      question: 'كيف أتواصل مع البائع؟',
      answer: 'يتم التواصل مع البائع عبر رقم الهاتف الموجود في صفحة الإعلان أو عبر زر "تواصل" إذا كان متاحاً.',
    ),
    FAQItem(
      question: 'ما هي الإعلانات الممنوعة؟',
      answer: 'يمنع أي إعلان مخالف للقوانين أو يحتوي على محتوى غير لائق. راجع "شروط الإعلان" للمزيد من التفاصيل.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: _buildAppBar(context),
        body: _buildBody(),
      ),
    );
  }

  /// Build the app bar
  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text(
        'الأسئلة الشائعة',
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
    );
  }

  /// Build the main body content
  Widget _buildBody() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: Colors.white,
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildFAQContainer(),
          ],
        ),
      ),
    );
  }

  /// Build the main FAQ container
  Widget _buildFAQContainer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Section
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.blue[600],
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.help_outline,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                'إجابات على أكثر الأسئلة التي يطرحها المستخدمون',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        // FAQ Content
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            border: Border.all(
              color: Colors.blue[300]!,
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._buildFAQList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Build the FAQ list
  List<Widget> _buildFAQList() {
    return _faqItems.asMap().entries.map((entry) {
      return _buildFAQItem(entry.value);
    }).toList();
  }

  /// Build a single FAQ item
  Widget _buildFAQItem(FAQItem faqItem) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.blue[50]!.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue[100]!,
          width: 1,
        ),
      ),
      child: Theme(
        data: ThemeData(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 20,
                height: 20,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: Colors.blue[600],
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.question_mark,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  faqItem.question,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          iconColor: Colors.blue[600],
          collapsedIconColor: Colors.blue[600],
          backgroundColor: Colors.transparent,
          collapsedBackgroundColor: Colors.transparent,
          children: [
            _buildAnswerSection(faqItem.answer),
          ],
        ),
      ),
    );
  }

  /// Build the answer section
  Widget _buildAnswerSection(String answer) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[600]!, Colors.blue[700]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              answer,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
