import 'package:flutter/material.dart';

class AdTermsScreen extends StatelessWidget {
  const AdTermsScreen({super.key});

  // Constants
  static const double _borderRadius = 18.0;
  static const double _padding = 20.0;
  static const EdgeInsets _screenPadding = EdgeInsets.symmetric(horizontal: _padding, vertical: 16);
  static const EdgeInsets _containerPadding = EdgeInsets.all(_padding);

  // Terms data
  static const List<String> _terms = [
    '١. يجب أن يكون محتوى الإعلان واضحًا وصحيحًا وخاليًا من الاحتيال.',
    '٢. يُمنع نشر إعلانات تحتوي على ألفاظ نابية أو محتوى مسيء.',
    '٣. يمنع نشر إعلانات عن مواد أو منتجات مخالفة للقانون أو الأخلاق.',
    '٤. يتم حذف أي إعلان يحتوي على محتوى مضلل أو مزيف.',
    '٥. للإدارة الحق في حذف أي إعلان دون إشعار مسبق إذا خالف الشروط.',
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
    return Container(
      decoration: _buildContainerDecoration(),
      child: Padding(
        padding: _containerPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ..._buildTermsList(),
            const SizedBox(height: 20),
            _buildFooterMessage(),
          ],
        ),
      ),
    );
  }

  // Terms List Builder
  List<Widget> _buildTermsList() {
    final List<Widget> widgets = [];
    
    for (int i = 0; i < _terms.length; i++) {
      widgets.add(_buildTermItem(_terms[i]));
      
      // Add separator between items (but not after the last item)
      if (i < _terms.length - 1) {
        widgets.add(_buildSeparator());
      }
    }
    
    return widgets;
  }

  // Term Item Builder
  Widget _buildTermItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBulletPoint(),
          const SizedBox(width: 12),
          Expanded(child: _buildTermText(text)),
        ],
      ),
    );
  }

  // Bullet Point Builder
  Widget _buildBulletPoint() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: Colors.blue[600],
        shape: BoxShape.circle,
      ),
    );
  }

  // Term Text Builder
  Widget _buildTermText(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        height: 1.6,
        color: Colors.black87,
      ),
    );
  }

  // Separator Builder
  Widget _buildSeparator() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      height: 1,
      color: Colors.blue[200]!.withOpacity(0.5),
    );
  }

  // Footer Message Builder
  Widget _buildFooterMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _buildFooterDecoration(),
      child: Text(
        _footerMessage,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
          height: 1.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // Style Builders
  BoxDecoration _buildContainerDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(_borderRadius),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white,
          Color(0xFFF8FBFF),
          Color(0xFFF0F8FF),
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
    );
  }

  BoxDecoration _buildFooterDecoration() {
    return BoxDecoration(
      color: Colors.blue[50]!.withOpacity(0.5),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: Colors.blue[200]!.withOpacity(0.7),
        width: 1,
      ),
    );
  }
}