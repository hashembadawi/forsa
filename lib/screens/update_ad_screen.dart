
  import 'dart:convert';
  import 'package:flutter/material.dart';
  import 'package:http/http.dart' as http;
  import 'package:shared_preferences/shared_preferences.dart';
  import 'package:connectivity_plus/connectivity_plus.dart';
  import 'package:syria_market/utils/dialog_utils.dart';
  import 'package:google_fonts/google_fonts.dart';



/// Screen for editing existing advertisements
class EditAdScreen extends StatefulWidget {
  final String adId;
  final String initialTitle;
  final String initialPrice;
  final String initialCurrency;
  final String initialDescription;
  final bool initialForSale;
  final bool initialDeliveryService;

  const EditAdScreen({
    super.key,
    required this.adId,
    required this.initialTitle,
    required this.initialPrice,
    required this.initialCurrency,
    required this.initialDescription,
    this.initialForSale = false,
    this.initialDeliveryService = false,
  });

  @override
  State<EditAdScreen> createState() => _EditAdScreenState();
}

class _EditAdScreenState extends State<EditAdScreen> {
  // ========== Constants ==========
  static const String _baseApiUrl = 'https://sahbo-app-api.onrender.com';
  static const String _optionsEndpoint = '/api/options';
  static const String _updateAdEndpoint = '/api/ads/userAds/update';

  // ========== Form Controllers ==========
  late TextEditingController _titleController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;

  // ========== State Variables ==========
  bool _isLoadingCurrencies = true;
    late bool _forSale;
    late bool _deliveryService;
  
  // ========== Currency Data ==========
  List<Map<String, dynamic>> _currencies = [];
  Map<String, dynamic>? _selectedCurrency;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _fetchCurrencies();
    _forSale = widget.initialForSale;
    _deliveryService = widget.initialDeliveryService;
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  // ========== Initialization Methods ==========

  /// Initialize form controllers with initial values
  void _initializeControllers() {
    _titleController = TextEditingController(text: widget.initialTitle);
    _priceController = TextEditingController(text: widget.initialPrice);
    _descriptionController = TextEditingController(text: widget.initialDescription);
  }

  /// Dispose form controllers to prevent memory leaks
  void _disposeControllers() {
    _titleController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
  }

  // ========== API Methods ==========

  /// Fetch available currencies from the server
  Future<void> _fetchCurrencies() async {
    if (!mounted) return;

    setState(() => _isLoadingCurrencies = true);

    try {
      final response = await _performCurrenciesRequest();
      await _handleCurrenciesResponse(response);
    } catch (e) {
      debugPrint('Error fetching currencies: $e');
      _handleCurrenciesError();
    }
  }

  /// Perform HTTP request to fetch currencies
  Future<http.Response> _performCurrenciesRequest() async {
    final uri = Uri.parse('$_baseApiUrl$_optionsEndpoint');
    return await http.get(uri);
  }

  /// Handle currencies API response
  Future<void> _handleCurrenciesResponse(http.Response response) async {
    if (!mounted) return;

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final currenciesList = List<Map<String, dynamic>>.from(data['currencies'] ?? []);

      setState(() {
        _currencies = currenciesList;
        _selectedCurrency = _findInitialCurrency(currenciesList);
        _isLoadingCurrencies = false;
      });
    } else {
      _handleCurrenciesError();
    }
  }

  /// Find the initial currency based on widget parameter
  Map<String, dynamic> _findInitialCurrency(List<Map<String, dynamic>> currencies) {
    // First try to find by exact name match
    for (final currency in currencies) {
      if (currency['name'] == widget.initialCurrency) {
        debugPrint('Found currency by name: ${currency['name']}');
        return currency;
      }
    }
    
    // If not found by exact name, try case-insensitive search
    for (final currency in currencies) {
      if (currency['name']?.toString().toLowerCase() == widget.initialCurrency.toLowerCase()) {
        debugPrint('Found currency by case-insensitive name: ${currency['name']}');
        return currency;
      }
    }
    
    // If still not found, return first currency or create fallback
    if (currencies.isNotEmpty) {
      debugPrint('Currency not found, using first available: ${currencies.first['name']}');
      return currencies.first;
    } else {
      debugPrint('No currencies available, creating fallback for: ${widget.initialCurrency}');
      return {'name': widget.initialCurrency, 'id': null};
    }
  }

  /// Handle currencies fetch error
  void _handleCurrenciesError() {
    if (!mounted) return;

    setState(() {
      _isLoadingCurrencies = false;
      _selectedCurrency = {'name': widget.initialCurrency, 'id': null};
    });
  }

  // ========== Network Connectivity ==========

  /// Check if device has internet connection
  Future<bool> _checkInternetConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      debugPrint('Connectivity check error: $e');
      return false;
    }
  }

  // ========== Update Ad Logic ==========

  /// Update advertisement with form data
  Future<void> _updateAd() async {
    if (!_validateForm()) return;

    if (!await _checkInternetConnectivity()) {
      DialogUtils.showNoInternetDialog(
        context: context,
        onRetry: () => _updateAd(),
      );
      return;
    }

    // Show loading dialog
    DialogUtils.showLoadingDialog(
      context: context,
      title: 'جارٍ تحديث الإعلان...',
      message: 'يرجى الانتظار',
    );

    try {
      await _performUpdateRequest();
    } catch (e) {
      // Close loading dialog
      DialogUtils.closeDialog(context);
      debugPrint('Update ad error: $e');
      DialogUtils.showErrorDialog(
        context: context,
        message: 'حدث خطأ في الاتصال بالخادم',
      );
    }
  }

  /// Validate form fields
  bool _validateForm() {
    final fields = [
      _titleController.text.trim(),
      _priceController.text.trim(),
      _descriptionController.text.trim(),
    ];

    if (fields.any((field) => field.isEmpty)) {
      DialogUtils.showErrorDialog(
        context: context,
        message: 'يرجى ملء جميع الحقول المطلوبة',
      );
      return false;
    }

    return true;
  }

  /// Perform the update request
  Future<void> _performUpdateRequest() async {
    final token = await _getAuthToken();
    final requestBody = _buildUpdateRequestBody();

    final response = await http.put(
      Uri.parse('$_baseApiUrl$_updateAdEndpoint/${widget.adId}'),
      headers: _buildRequestHeaders(token),
      body: jsonEncode(requestBody),
    );

    await _handleUpdateResponse(response);
  }

  /// Get authentication token from shared preferences
  Future<String> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  /// Build update request body
  Map<String, dynamic> _buildUpdateRequestBody() {
    return {
      'adTitle': _titleController.text.trim(),
      'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
      'currencyId': _selectedCurrency?['id'],
      'currencyName': _selectedCurrency?['name'],
      'description': _descriptionController.text.trim(),
      'forSale': _forSale,
      'deliveryService': _deliveryService,
    };
  }

  /// Build request headers
  Map<String, String> _buildRequestHeaders(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Handle update response
  Future<void> _handleUpdateResponse(http.Response response) async {
    // Close loading dialog first
    DialogUtils.closeDialog(context);
    
    if (response.statusCode == 200) {
      DialogUtils.showSuccessDialog(
        context: context,
        message: 'تم تعديل الإعلان بنجاح',
        onPressed: () {
          Navigator.of(context).pop(); // Close success dialog
          Navigator.of(context).pop(true); // Return to previous screen with success result
        },
      );
    } else {
      final errorMessage = _extractErrorMessage(response);
      DialogUtils.showErrorDialog(
        context: context,
        message: errorMessage,
      );
    }
  }

  /// Extract error message from response
  String _extractErrorMessage(http.Response response) {
    try {
      final responseData = jsonDecode(response.body);
      return responseData['message'] ?? 'فشل في تحديث الإعلان';
    } catch (e) {
      return 'فشل في تحديث الإعلان: رمز الخطأ ${response.statusCode}';
    }
  }

  // ========== Widget Build Methods ==========

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(),
        body: _buildBody(),
      ),
    );
  }

  /// Build the app bar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'تعديل الإعلان',
        style: GoogleFonts.cairo(
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      backgroundColor: Colors.blue[700],
      foregroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  /// Build the main body content
  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildTitleField(),
          const SizedBox(height: 16),
          _buildPriceField(),
          const SizedBox(height: 16),
          _buildCurrencyField(),
           const SizedBox(height: 16),
           _buildForSaleField(),
           const SizedBox(height: 16),
           _buildDeliveryServiceField(),
          const SizedBox(height: 16),
          _buildDescriptionField(),
          const SizedBox(height: 24),
          _buildUpdateButton(),
        ],
      ),
    );
  }

  /// Build title input field
  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      style: GoogleFonts.cairo(color: Colors.black87),
      decoration: _buildInputDecoration('عنوان الإعلان'),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'يرجى إدخال عنوان الإعلان';
        }
        return null;
      },
    );
  }

  /// Build price input field
  Widget _buildPriceField() {
    return TextFormField(
      controller: _priceController,
      keyboardType: TextInputType.number,
      style: GoogleFonts.cairo(color: Colors.black87),
      decoration: _buildInputDecoration('السعر'),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'يرجى إدخال السعر';
        }
        return null;
      },
    );
  }

  /// Build currency selection field
  Widget _buildCurrencyField() {
    if (_isLoadingCurrencies) {
      return _buildCurrencyLoadingWidget();
    }

    // Ensure the selected currency is in the dropdown list
    final allCurrencies = List<Map<String, dynamic>>.from(_currencies);
    
    // Check if the selected currency exists in the list
    final bool currencyExists = allCurrencies.any(
      (currency) => currency['name'] == _selectedCurrency?['name']
    );
    
    // If the selected currency doesn't exist in the list, add it
    if (!currencyExists && _selectedCurrency != null) {
      allCurrencies.insert(0, _selectedCurrency!);
    }

    return DropdownButtonFormField<Map<String, dynamic>>(
      value: _selectedCurrency,
      decoration: _buildInputDecoration('العملة'),
      items: allCurrencies.map((currency) {
        return DropdownMenuItem(
          value: currency,
          child: Text(
            currency['name'] ?? '',
            style: GoogleFonts.cairo(color: Colors.black87),
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() => _selectedCurrency = value);
      },
      hint: Text(
        'اختر العملة',
        style: GoogleFonts.cairo(color: Colors.grey[600]),
      ),
    );
  }

  /// Build currency loading widget
  Widget _buildCurrencyLoadingWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            'العملة: ${widget.initialCurrency}',
            style: GoogleFonts.cairo(color: Colors.black87),
          ),
          const Spacer(),
          SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              color: Colors.blue,
              strokeWidth: 2,
            ),
          ),
        ],
      ),
    );
  }

  /// Build description input field
  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      maxLines: 5,
      style: GoogleFonts.cairo(color: Colors.black87),
      decoration: _buildInputDecoration('الوصف', alignLabelWithHint: true),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'يرجى إدخال الوصف';
        }
        return null;
      },
    );
  }

    /// Build forSale field (للبيع/للإيجار)
    Widget _buildForSaleField() {
      return DropdownButtonFormField<bool>(
        value: _forSale,
        decoration: _buildInputDecoration('نوع الإعلان'),
        items: [
          DropdownMenuItem(
            value: true,
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Text('للبيع', style: GoogleFonts.cairo(color: Colors.black87)),
            ),
          ),
          DropdownMenuItem(
            value: false,
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Text('للإيجار', style: GoogleFonts.cairo(color: Colors.black87)),
            ),
          ),
        ],
        onChanged: (value) {
          setState(() => _forSale = value ?? true);
        },
        hint: Directionality(
          textDirection: TextDirection.rtl,
          child: Text(
            'اختر نوع الإعلان',
            style: GoogleFonts.cairo(color: Colors.grey[600]),
          ),
        ),
      );
    }

    /// Build deliveryService field (يوجد/لايوجد)
    Widget _buildDeliveryServiceField() {
      return DropdownButtonFormField<bool>(
        value: _deliveryService,
        decoration: _buildInputDecoration('خدمة التوصيل'),
        items: [
          DropdownMenuItem(
            value: true,
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Text('يوجد', style: GoogleFonts.cairo(color: Colors.black87)),
            ),
          ),
          DropdownMenuItem(
            value: false,
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Text('لايوجد', style: GoogleFonts.cairo(color: Colors.black87)),
            ),
          ),
        ],
        onChanged: (value) {
          setState(() => _deliveryService = value ?? false);
        },
        hint: Directionality(
          textDirection: TextDirection.rtl,
          child: Text(
            'اختر حالة التوصيل',
            style: GoogleFonts.cairo(color: Colors.grey[600]),
          ),
        ),
      );
    }

  /// Build update button
  Widget _buildUpdateButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _updateAd,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[700],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: Text(
          'حفظ التغييرات',
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ========== Helper Methods ==========

  /// Build consistent input decoration for form fields
  InputDecoration _buildInputDecoration(
    String labelText, {
    bool alignLabelWithHint = false,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: GoogleFonts.cairo(color: Colors.black87),
      alignLabelWithHint: alignLabelWithHint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.blue[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.blue[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
      ),
    );
  }
}