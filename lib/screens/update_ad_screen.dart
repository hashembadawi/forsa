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
  bool _isUpdating = false;
  
  // Currency data from server
  List<Map<String, dynamic>> currencies = [];
  Map<String, dynamic>? selectedCurrency;
  bool _isLoadingCurrencies = true;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _priceController = TextEditingController(text: widget.initialPrice);
    _descriptionController = TextEditingController(text: widget.initialDescription);
    _fetchCurrencies();
  }

  Future<void> _fetchCurrencies() async {
    setState(() => _isLoadingCurrencies = true);
    try {
      final response = await http.get(Uri.parse('https://sahbo-app-api.onrender.com/api/options'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          currencies = List<Map<String, dynamic>>.from(data['currencies']);
          // Find the selected currency based on the initial currency
          selectedCurrency = currencies.firstWhere(
            (currency) => currency['name'] == widget.initialCurrency,
            orElse: () => currencies.isNotEmpty ? currencies[0] : {'name': widget.initialCurrency, 'id': null},
          );
          _isLoadingCurrencies = false;
        });
      } else {
        setState(() => _isLoadingCurrencies = false);
      }
    } catch (e) {
      setState(() => _isLoadingCurrencies = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _updateAd() async {
    if (_titleController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _descriptionController.text.isEmpty) {
      _showErrorDialog('يرجى ملء جميع الحقول المطلوبة');
      return;
    }

    setState(() => _isUpdating = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.put(
        Uri.parse('https://sahbo-app-api.onrender.com/api/userProducts/update/${widget.adId}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'productTitle': _titleController.text,
          'price': _priceController.text,
          'currencyId': selectedCurrency?['id'],
          'currencyName': selectedCurrency?['name'],
          'description': _descriptionController.text,
        }),
      );

      if (response.statusCode == 200) {
        _showSuccessDialog();
      } else {
        _showErrorDialog('فشل في تحديث الإعلان: ${response.body}');
      }
    } catch (e) {
      _showErrorDialog('حدث خطأ في الاتصال بالخادم');
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 10),
            Text('تم التحديث'),
          ],
        ),
        content: const Text('تم تعديل الإعلان بنجاح.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(true);
            },
            child: const Text('موافق', style: TextStyle(color: Color(0xFF1E4A47))),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 10),
            Text('خطأ'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إغلاق', style: TextStyle(color: Color(0xFFFF7A59))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تعديل الإعلان'),
          centerTitle: true,
          backgroundColor: const Color(0xFF1E4A47),
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'عنوان الإعلان',
                  labelStyle: const TextStyle(color: Color(0xFF1E4A47)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF1E4A47)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF1E4A47)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF1E4A47), width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال عنوان الإعلان';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'السعر',
                  labelStyle: const TextStyle(color: Color(0xFF1E4A47)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF1E4A47)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF1E4A47)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF1E4A47), width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال السعر';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _isLoadingCurrencies
                  ? Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF1E4A47)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Text('العملة', style: TextStyle(color: Color(0xFF1E4A47))),
                          Spacer(),
                          SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Color(0xFF1E4A47),
                              strokeWidth: 2,
                            ),
                          ),
                        ],
                      ),
                    )
                  : DropdownButtonFormField<Map<String, dynamic>>(
                      value: selectedCurrency,
                      decoration: InputDecoration(
                        labelText: 'العملة',
                        labelStyle: const TextStyle(color: Color(0xFF1E4A47)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF1E4A47)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF1E4A47)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF1E4A47), width: 2),
                        ),
                      ),
                      items: currencies
                          .map((currency) => DropdownMenuItem(
                        value: currency,
                        child: Text(currency['name'], style: const TextStyle(color: Color(0xFF1E4A47))),
                      ))
                          .toList(),
                      onChanged: (val) => setState(() => selectedCurrency = val),
                    ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'الوصف',
                  labelStyle: const TextStyle(color: Color(0xFF1E4A47)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF1E4A47)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF1E4A47)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF1E4A47), width: 2),
                  ),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال الوصف';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isUpdating ? null : _updateAd,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E4A47),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isUpdating
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('حفظ التعديلات', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}