import 'package:flutter/material.dart';

class AdTermsScreen extends StatelessWidget {
  const AdTermsScreen({super.key});

  // Constants
  static const double _padding = 20.0;
  static const EdgeInsets _screenPadding = EdgeInsets.symmetric(horizontal: _padding, vertical: 16);

  // Terms data
  static const List<String> _terms = [
    'يجب أن يكون محتوى الإعلان واضحًا وصحيحًا وخاليًا من الاحتيال.',
    'يُمنع نشر إعلانات تحتوي على ألفاظ نابية أو محتوى مسيء.',
    'يمنع نشر إعلانات عن مواد أو منتجات مخالفة للقانون أو الأخلاق.',
    'يتم حذف أي إعلان يحتوي على محتوى مضلل أو مزيف.',
    'للإدارة الحق في حذف أي إعلان دون إشعار مسبق إذا خالف الشروط.',
  ];

  static const String _footerMessage = 'الرجاء الالتزام بهذه القواعد لضمان بيئة آمنة لجميع المستخدمين.';

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

  // App Bar Builder
  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
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
    );
  }

  // Main Body Builder
  Widget _buildBody() {
    return Container(
      padding: _screenPadding,
      color: Colors.white,
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildTermsContainer(),
          ],
        ),
      ),
    );
  }

  // Terms Container Builder
  Widget _buildTermsContainer() {
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
                Icons.rule,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                'يرجى قراءة الشروط بعناية قبل نشر إعلانك',
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
        // Terms Content
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
                ..._buildTermsList(),
                const SizedBox(height: 20),
                _buildFooterMessage(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Terms List Builder
  List<Widget> _buildTermsList() {
    return _terms.asMap().entries.map((entry) {
      return _buildTermItem(entry.value);
    }).toList();
  }

  // Term Item Builder
  Widget _buildTermItem(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50]!.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue[100]!,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.blue[600],
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.check,
                color: Colors.white,
                size: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Footer Message Builder
  Widget _buildFooterMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[600]!, Colors.blue[700]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Icon(
            Icons.security,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            _footerMessage,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}