import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sahbo_app/screens/ad_details_screen.dart';

class SearchResultsScreen extends StatefulWidget {
  final String searchText;
  const SearchResultsScreen({super.key, required this.searchText});

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  List<dynamic> searchResults = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchSearchResults();
  }

  Future<void> fetchSearchResults() async {
    setState(() {
      isLoading = true;
    });
    try {
      final params = <String, String>{
        'title': widget.searchText,
        'page': '1',
        'limit': '20',
      };
      final uri = Uri.https('sahbo-app-api.onrender.com', '/api/products/search-by-title', params);
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        setState(() {
          searchResults = decoded['products'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildAdCard(dynamic ad) {
    final List<dynamic> images = ad['images'] is List ? ad['images'] : [];
    final firstImageBase64 = images.isNotEmpty ? images[0] : null;

    final image = firstImageBase64 != null
        ? Image.memory(
            base64Decode(firstImageBase64),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFF0FAFA),
                      Color(0xFFE8F5F5),
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image,
                        size: 40,
                        color: Color(0xFF4DD0CC),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'صورة',
                        style: TextStyle(
                          color: Color(0xFF2E7D78),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          )
        : Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF0FAFA),
                  Color(0xFFE8F5F5),
                ],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.image,
                    size: 40,
                    color: Color(0xFF4DD0CC),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'لا توجد صورة',
                    style: TextStyle(
                      color: Color(0xFF2E7D78),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Color(0xFFF8FDFD),
            Color(0xFFF0FAFA),
          ],
        ),
        border: Border.all(
          color: Color(0xFF4DD0CC),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          splashColor: Color(0xFF4DD0CC).withOpacity(0.2),
          highlightColor: Color(0xFF7FE8E4).withOpacity(0.1),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AdDetailsScreen(ad: ad),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                  child: SizedBox(
                    width: double.infinity,
                    child: image,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 80),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text(
                          '${ad['productTitle'] ?? ''}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E4A47),
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Color(0xFFFF7A59).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Color(0xFFFF7A59).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '${ad['price'] ?? '0'} ${ad['currencyName'] ?? ''}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFF7A59),
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        Text(
                          ad['description'] ?? '',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF2E7D78),
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 12,
                              color: Color(0xFF2E7D78),
                            ),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                '${ad['cityName'] ?? ''}',
                                style: TextStyle(
                                  color: Color(0xFF1E4A47),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 4,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1E4A47)),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'نتائج البحث',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D78),
            ),
          ),
          centerTitle: true,
        ),
        body: isLoading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4DD0CC)),
                ),
              )
            : searchResults.isEmpty
                ? const Center(child: Text('لا توجد نتائج'))
                : Container(
                    color: Colors.grey[50],
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.65,
                        ),
                        itemCount: searchResults.length,
                        itemBuilder: (context, index) {
                          return _buildAdCard(searchResults[index]);
                        },
                      ),
                    ),
                  ),
      ),
    );
  }
}