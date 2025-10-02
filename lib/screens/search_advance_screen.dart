import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:forsa/screens/advanced_search_results_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SearchAdvanceScreen extends StatefulWidget {
  const SearchAdvanceScreen({super.key});

  @override
  State<SearchAdvanceScreen> createState() => _SearchAdvanceScreenState();
}

class _SearchAdvanceScreenState extends State<SearchAdvanceScreen> {
  // Form fields
  int? _categoryId;
  int? _subCategoryId;
  int? _currencyId;
  bool? _forSale = true;
  bool? _deliveryService = true;
  double? _priceMin = 0;
  double? _priceMax = 0;
  int _page = 1;
  int _limit = 20;

  // Results
  // Removed unused _results, _isLoading, _error fields

  // Example: You may want to fetch these from your API
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _subCategories = [];
  List<Map<String, dynamic>> _currencies = [];

  @override
  void initState() {
    super.initState();
    _fetchOptions();
  }

  Future<void> _fetchOptions() async {
    // Fetch categories and subcategories from your API
    try {
      final response = await http.get(Uri.parse('https://sahbo-app-api.onrender.com/api/options'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final categories = List<Map<String, dynamic>>.from(data['categories'] ?? []);
        final subCategories = List<Map<String, dynamic>>.from(data['subCategories'] ?? []);
        final currencies = List<Map<String, dynamic>>.from(data['currencies'] ?? []);

        int? defaultCategoryId = categories.isNotEmpty
            ? (categories[0]['id'] is int ? categories[0]['id'] : int.tryParse(categories[0]['id'].toString()))
            : null;
        int? defaultSubCategoryId;
        if (defaultCategoryId != null) {
          final relatedSubs = subCategories.where((s) => s['categoryId'] == defaultCategoryId || (s['categoryId'] is String && int.tryParse(s['categoryId']) == defaultCategoryId)).toList();
          if (relatedSubs.isNotEmpty) {
            defaultSubCategoryId = relatedSubs[0]['id'] is int ? relatedSubs[0]['id'] : int.tryParse(relatedSubs[0]['id'].toString());
          }
        }
        int? defaultCurrencyId = currencies.isNotEmpty
            ? (currencies[0]['id'] is int ? currencies[0]['id'] : int.tryParse(currencies[0]['id'].toString()))
            : null;

        setState(() {
          _categories = categories;
          _subCategories = subCategories;
          _currencies = currencies;
          _categoryId = defaultCategoryId;
          _subCategoryId = defaultSubCategoryId;
          _currencyId = defaultCurrencyId;
        });
      }
    } catch (e) {
      // ignore
    }
  }

  void _search() {
    final params = <String, String>{
      if (_categoryId != null) 'categoryId': _categoryId.toString(),
      if (_subCategoryId != null) 'subCategoryId': _subCategoryId.toString(),
      if (_currencyId != null) 'currencyId': _currencyId.toString(),
      if (_forSale != null) 'forSale': _forSale.toString(),
      if (_deliveryService != null) 'deliveryService': _deliveryService.toString(),
      if (_priceMin != null) 'priceMin': _priceMin.toString(),
      if (_priceMax != null) 'priceMax': _priceMax.toString(),
      'page': _page.toString(),
      'limit': _limit.toString(),
    };
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdvancedSearchResultsScreen(searchParams: params),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool hideFields = _categoryId == 3;
    const Color secondaryColor = Color(0xFF42A5F5); // Light Blue
    const Color surfaceColor = Color(0xFFF5F5F5); // Light Gray
    const Color textColor = Color(0xFF212121); // Dark Black
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('بحث متقدم', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white)),
          backgroundColor: secondaryColor,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
        ),
        backgroundColor: surfaceColor,
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Material(
            color: Colors.white,
            elevation: 2,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  DropdownButtonFormField<int>(
                    value: _categoryId,
                    decoration: InputDecoration(
                      labelText: 'التصنيف الرئيسي',
                      labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w600, color: secondaryColor),
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.black.withOpacity(0.4), width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Color(0xFF42A5F5), width: 2),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.black.withOpacity(0.4), width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    items: _categories.map((cat) => DropdownMenuItem<int>(
                      value: cat['id'] is int ? cat['id'] : int.tryParse(cat['id'].toString()),
                      child: Directionality(
                        textDirection: TextDirection.rtl,
                        child: Text(
                          cat['name'] ?? '',
                          style: GoogleFonts.cairo(color: textColor),
                        ),
                      ),
                    )).toList(),
                    onChanged: (val) {
                      setState(() {
                        _categoryId = val;
                        final relatedSubs = _subCategories.where((s) => s['categoryId'] == val || (s['categoryId'] is String && int.tryParse(s['categoryId']) == val)).toList();
                        if (relatedSubs.isNotEmpty) {
                          _subCategoryId = relatedSubs[0]['id'] is int ? relatedSubs[0]['id'] : int.tryParse(relatedSubs[0]['id'].toString());
                        } else {
                          _subCategoryId = null;
                        }
                      });
                    },
                    style: GoogleFonts.cairo(color: textColor),
                    dropdownColor: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: _subCategoryId,
                    decoration: InputDecoration(
                      labelText: 'التصنيف الفرعي',
                      labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w600, color: secondaryColor),
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.black.withOpacity(0.4), width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Color(0xFF42A5F5), width: 2),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.black.withOpacity(0.4), width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    items: _subCategories
                        .where((s) => _categoryId != null && (s['categoryId'] == _categoryId || (s['categoryId'] is String && int.tryParse(s['categoryId']) == _categoryId)))
                        .map((sub) => DropdownMenuItem<int>(
                              value: sub['id'] is int ? sub['id'] : int.tryParse(sub['id'].toString()),
                              child: Text(
                                sub['name'] ?? '',
                                style: GoogleFonts.cairo(color: textColor),
                              ),
                            ))
                        .toList(),
                    onChanged: (val) => setState(() => _subCategoryId = val),
                    style: GoogleFonts.cairo(color: textColor),
                    dropdownColor: Colors.white,
                    disabledHint: Text('اختر التصنيف الرئيسي أولاً', style: GoogleFonts.cairo(color: Colors.grey)),
                    isExpanded: true,
                    hint: Text('اختر التصنيف الفرعي', style: GoogleFonts.cairo(color: Colors.grey)),
                  ),
                  const SizedBox(height: 12),
                  if (!hideFields) ...[
                    DropdownButtonFormField<int>(
                      value: _currencyId,
                      decoration: InputDecoration(
                        labelText: 'العملة',
                        labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w600, color: secondaryColor),
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: Colors.black.withOpacity(0.4), width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(color: Color(0xFF42A5F5), width: 2),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(color: Colors.black, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      items: _currencies.map((cur) => DropdownMenuItem<int>(
                        value: cur['id'] is int ? cur['id'] : int.tryParse(cur['id'].toString()),
                        child: Text(
                          cur['name'] ?? '',
                          style: GoogleFonts.cairo(color: textColor),
                        ),
                      )).toList(),
                      onChanged: (val) => setState(() => _currencyId = val),
                      style: GoogleFonts.cairo(color: textColor),
                      dropdownColor: Colors.white,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<bool>(
                      value: _forSale,
                      decoration: InputDecoration(
                        labelText: 'نوع الإعلان',
                        labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w600, color: secondaryColor),
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: Colors.black.withOpacity(0.4), width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(color: Color(0xFF42A5F5), width: 2),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: Colors.black.withOpacity(0.4), width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      items: [
                        DropdownMenuItem(value: true, child: Text('للبيع', style: GoogleFonts.cairo(color: textColor))),
                        DropdownMenuItem(value: false, child: Text('للإيجار', style: GoogleFonts.cairo(color: textColor))),
                      ],
                      onChanged: (val) => setState(() => _forSale = val),
                      style: GoogleFonts.cairo(color: textColor),
                      dropdownColor: Colors.white,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<bool>(
                      value: _deliveryService,
                      decoration: InputDecoration(
                        labelText: 'خدمة التوصيل',
                        labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w600, color: secondaryColor),
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: Colors.black.withOpacity(0.4), width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(color: Color(0xFF42A5F5), width: 2),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: Colors.black.withOpacity(0.4), width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      items: [
                        DropdownMenuItem(value: true, child: Text('يوجد', style: GoogleFonts.cairo(color: textColor))),
                        DropdownMenuItem(value: false, child: Text('لايوجد', style: GoogleFonts.cairo(color: textColor))),
                      ],
                      onChanged: (val) => setState(() => _deliveryService = val),
                      style: GoogleFonts.cairo(color: textColor),
                      dropdownColor: Colors.white,
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (!hideFields) ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            decoration: InputDecoration(
                              labelText: 'السعر الأدنى',
                              labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w600, color: secondaryColor),
                              hintText: '0',
                              hintStyle: GoogleFonts.cairo(color: Colors.grey),
                              filled: true,
                              fillColor: Colors.white,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(color: Colors.black.withOpacity(0.4), width: 1.5),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: const BorderSide(color: Color(0xFF42A5F5), width: 2),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(color: Colors.black.withOpacity(0.4), width: 1.5),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (val) => setState(() => _priceMin = double.tryParse(val)),
                            style: GoogleFonts.cairo(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            decoration: InputDecoration(
                              labelText: 'السعر الأعلى',
                              labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w600, color: secondaryColor),
                              hintText: '0',
                              hintStyle: GoogleFonts.cairo(color: Colors.grey),
                              filled: true,
                              fillColor: Colors.white,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(color: Colors.black.withOpacity(0.4), width: 1.5),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: const BorderSide(color: Color(0xFF42A5F5), width: 2),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(color: Colors.black.withOpacity(0.4), width: 1.5),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (val) => setState(() => _priceMax = double.tryParse(val)),
                            style: GoogleFonts.cairo(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _search,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: secondaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 17),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            elevation: 3,
                          ),
                          child: Text('بحث', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey[600],
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text('إلغاء', style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
