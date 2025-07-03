import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EditAdScreen extends StatefulWidget {
  final String adId;
  final String initialTitle;
  final String initialPrice;
  final String initialCurrency;
  final String initialDescription;

  const EditAdScreen({
    super.key,
    required this.adId,
    required this.initialTitle,
    required this.initialPrice,
    required this.initialCurrency,
    required this.initialDescription,
  });

  @override
  State<EditAdScreen> createState() => _EditAdScreenState();
}

class _EditAdScreenState extends State<EditAdScreen> {
  late TextEditingController _titleController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  String _currency = 'ل.س';
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _priceController = TextEditingController(text: widget.initialPrice);
    _descriptionController = TextEditingController(text: widget.initialDescription);
    _currency = widget.initialCurrency;
  }

  Future<void> _updateAd() async {
    setState(() => _isUpdating = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await http.put(
      Uri.parse('http://localhost:10000/api/userProducts/update/${widget.adId}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'productTitle': _titleController.text,
        'price': _priceController.text,
        'currency': _currency,
        'description': _descriptionController.text,
      }),
    );

    setState(() => _isUpdating = false);

    if (response.statusCode == 200) {
      _showSuccessDialog();
    } else {
      _showErrorDialog('فشل في تحديث الإعلان: ${response.body}');
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('تم التحديث'),
        content: Text('تم تعديل الإعلان بنجاح.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // يغلق الحوار
              Navigator.of(context).pop(true); // يعود للشاشة السابقة ويشير إلى نجاح التعديل
            },
            child: Text('موافق'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('خطأ'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('تعديل الإعلان'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'عنوان الإعلان'),
            ),
            SizedBox(height: 15),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'السعر'),
            ),
            SizedBox(height: 15),
            DropdownButtonFormField<String>(
              value: _currency,
              decoration: InputDecoration(labelText: 'العملة'),
              items: ['ل.س', 'دولار', 'ل.ت']
                  .map((val) => DropdownMenuItem(value: val, child: Text(val)))
                  .toList(),
              onChanged: (val) => setState(() => _currency = val!),
            ),
            SizedBox(height: 15),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(labelText: 'الوصف'),
            ),
            SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isUpdating ? null : _updateAd,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                child: _isUpdating
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('حفظ التعديلات'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
