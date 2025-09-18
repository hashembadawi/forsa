import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'search_results_screen.dart';
import 'package:google_fonts/google_fonts.dart';

/// Screen for displaying search suggestions with real-time search
class SuggestionsListScreen extends StatefulWidget {
  final String? initialSearchText;

  const SuggestionsListScreen({
    super.key,
    this.initialSearchText,
  });

  @override
  State<SuggestionsListScreen> createState() => _SuggestionsListScreenState();
}

class _SuggestionsListScreenState extends State<SuggestionsListScreen> {
  // Material 3 color palette from home_screen.dart
  static const Color primaryColor = Color(0xFF42A5F5); // Light Blue
  static const Color backgroundColor = Color(0xFFFAFAFA); // White
  static const Color textColor = Color(0xFF212121); // Dark Black
  static const Color outlineColor = Color(0xFFE0E3E7); // Soft Gray
  // ========== Controllers & State ==========
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // ========== Search Suggestions State ==========
  List<String> _searchSuggestions = [];
  bool _isLoadingSuggestions = false;
  Timer? _searchDebounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialSearchText ?? '';
    
    // Auto-focus the search field when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
      
      // If there's initial text, fetch suggestions
      if (widget.initialSearchText != null && widget.initialSearchText!.isNotEmpty) {
        _fetchSearchSuggestions(widget.initialSearchText!);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  // ========== Search Methods ==========

  /// Fetch search suggestions based on user input
  Future<void> _fetchSearchSuggestions(String query) async {
    if (query.isEmpty) {
      if (!mounted) return;
      setState(() {
        _searchSuggestions.clear();
        _isLoadingSuggestions = false;
      });
      return;
    }

    if (!mounted) return;
    setState(() => _isLoadingSuggestions = true);

    try {
      // Use the same search endpoint but limit results for suggestions
      final params = {
        'title': query,
        'page': '1',
        'limit': '10', // Get more suggestions for dedicated screen
      };
      
      final uri = Uri.https('sahbo-app-api.onrender.com', '/api/ads/search-by-title', params);
      final response = await http.get(uri);

      if (!mounted) return;
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> ads = decoded['ads'] ?? [];
        
        // Extract unique ad titles for suggestions
        final Set<String> uniqueTitles = <String>{};
        for (var ad in ads) {
          final title = ad['adTitle']?.toString().trim();
          if (title != null && title.isNotEmpty) {
            uniqueTitles.add(title);
          }
        }
        if (!mounted) return;
        setState(() {
          _searchSuggestions = uniqueTitles.take(10).toList();
          _isLoadingSuggestions = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _searchSuggestions.clear();
          _isLoadingSuggestions = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching search suggestions: $e');
      if (!mounted) return;
      setState(() {
        _searchSuggestions.clear();
        _isLoadingSuggestions = false;
      });
    }
  }

  /// Handle search input change with debounce
  void _onSearchChanged(String value) {
    _searchDebounceTimer?.cancel();

    // Only fetch suggestions if user typed at least 1 character
    if (value.trim().isEmpty) {
      if (!mounted) return;
      setState(() {
        _searchSuggestions.clear();
        _isLoadingSuggestions = false;
      });
      return;
    }

    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _fetchSearchSuggestions(value.trim());
    });
  }

  /// Handle suggestion selection
  void _onSuggestionSelected(String suggestion) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SearchResultsScreen(searchText: suggestion),
      ),
    );
  }

  /// Handle search submission
  void _onSearchSubmitted(String value) {
    if (value.trim().isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SearchResultsScreen(searchText: value.trim()),
        ),
      );
    }
  }

  // ========== UI Building Methods ==========

  /// Build the search field
  Widget _buildSearchField() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        style: GoogleFonts.cairo(color: textColor, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: 'ابحث عن منتج أو خدمة...',
          hintStyle: GoogleFonts.cairo(color: Colors.grey[600]),
          prefixIcon: Icon(Icons.search, color: primaryColor),
          suffixIcon: _buildSearchSuffixIcon(),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: outlineColor, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: outlineColor, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: primaryColor, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        onChanged: _onSearchChanged,
        onSubmitted: _onSearchSubmitted,
      ),
    );
  }

  /// Build suffix icon for search field
  Widget _buildSearchSuffixIcon() {
    if (_isLoadingSuggestions) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    } else if (_searchController.text.isNotEmpty) {
      return IconButton(
        icon: Icon(Icons.clear, color: Colors.grey[600]),
        onPressed: () {
          _searchController.clear();
          setState(() {
            _searchSuggestions.clear();
          });
        },
      );
    }
    return const SizedBox.shrink();
  }

  /// Build suggestions list
  Widget _buildSuggestionsList() {
    if (_searchSuggestions.isEmpty && !_isLoadingSuggestions) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'ابدأ بالكتابة للبحث',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'اكتب ما تبحث عنه وسنقترح عليك نتائج مناسبة',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        itemCount: _searchSuggestions.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final suggestion = _searchSuggestions[index];
          return Column(
            children: [
              Material(
                color: Colors.white,
                elevation: 2,
                borderRadius: BorderRadius.circular(15),
                child: InkWell(
                  borderRadius: BorderRadius.circular(15),
                  onTap: () => _onSuggestionSelected(suggestion),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search,
                          size: 20,
                          color: primaryColor,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            suggestion,
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              color: textColor,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                        Icon(
                          Icons.north_west,
                          size: 18,
                          color: outlineColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (index < _searchSuggestions.length - 1)
                Divider(
                  height: 1,
                  color: outlineColor,
                  indent: 52,
                ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: primaryColor,
          elevation: 4,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
          title: Text(
            'البحث',
            style: GoogleFonts.cairo(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Column(
          children: [
            // Search field
            _buildSearchField(),
            // Suggestions list or empty state
            _buildSuggestionsList(),
          ],
        ),
      ),
    );
  }
}
