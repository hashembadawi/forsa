import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class LocationButtonWid extends StatelessWidget {
  final String selectedCity;
  final String defaultCity;
  final String selectedDistrict;
  final String defaultDistrict;
  final VoidCallback onTap;

  const LocationButtonWid({
    super.key,
    required this.selectedCity,
    required this.defaultCity,
    required this.selectedDistrict,
    required this.defaultDistrict,
    required this.onTap,
  });

  static Future<void> showLocationFilterDialog({
    required BuildContext context,
    required String defaultCity,
    required String defaultDistrict,
    required List<Map<String, dynamic>> provinces,
    required List<Map<String, dynamic>> majorAreas,
    required int? selectedCityId,
    required int? selectedRegionId,
    required Function({String? cityName, String? districtName, int? cityId, int? regionId}) onApply,
  }) async {
    Map<String, dynamic>? tempSelectedProvince = selectedCityId != null
        ? provinces.where((p) => p['id'] == selectedCityId).isNotEmpty
            ? provinces.firstWhere((p) => p['id'] == selectedCityId)
            : null
        : null;

    Map<String, dynamic>? tempSelectedArea = selectedRegionId != null
        ? majorAreas.where((a) => a['id'] == selectedRegionId).isNotEmpty
            ? majorAreas.firstWhere((a) => a['id'] == selectedRegionId)
            : null
        : null;

    List<Map<String, dynamic>> filteredAreas = [];
    if (tempSelectedProvince != null && tempSelectedProvince['id'] != null) {
      final provinceId = tempSelectedProvince['id'];
      if (provinceId != null) {
        filteredAreas.addAll(
          majorAreas.where((area) => area['ProvinceId'] == provinceId).toList(),
        );
      }
    }

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(16),
            child: Container(
              width: double.maxFinite,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Color(0xFF42A5F5), // Match home_screen.dart header color
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Text(
                      'بحث حسب الموقع',
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Container(
                    width: double.maxFinite,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Directionality(
                          textDirection: TextDirection.rtl,
                          child: DropdownButtonFormField<Map<String, dynamic>>(
                            value: tempSelectedProvince,
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down, textDirection: TextDirection.ltr),
                            decoration: InputDecoration(
                              labelText: 'اختر المحافظة',
                              labelStyle: GoogleFonts.cairo(color: Color(0xFF42A5F5)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(color: Colors.black.withOpacity(0.4), width: 1.5),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(color: Colors.black.withOpacity(0.4), width: 1.5),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(color: Color(0xFF42A5F5), width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                            dropdownColor: Colors.white,
                            style: GoogleFonts.cairo(
                              color: Color(0xFF212121),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                            items: [
                              DropdownMenuItem<Map<String, dynamic>>(
                                value: null,
                                child: Directionality(
                                  textDirection: TextDirection.rtl,
                                  child: Text(
                                    defaultCity,
                                    style: GoogleFonts.cairo(
                                      color: Color(0xFF212121),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              ...provinces.map((province) => DropdownMenuItem(
                                value: province,
                                child: Directionality(
                                  textDirection: TextDirection.rtl,
                                  child: Text(
                                    province['name'],
                                    style: GoogleFonts.cairo(
                                      color: Color(0xFF212121),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              )),
                            ],
                            onChanged: (value) {
                              setStateDialog(() {
                                tempSelectedProvince = value;
                                tempSelectedArea = null;
                                filteredAreas.clear();
                                if (value != null && value['id'] != null) {
                                  filteredAreas.addAll(
                                    majorAreas.where((area) => area['ProvinceId'] == value['id']).toList(),
                                  );
                                }
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        Directionality(
                          textDirection: TextDirection.rtl,
                          child: DropdownButtonFormField<Map<String, dynamic>>(
                            value: tempSelectedArea,
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down, textDirection: TextDirection.ltr),
                            decoration: InputDecoration(
                              labelText: 'اختر المدينة/المنطقة',
                              labelStyle: GoogleFonts.cairo(color: Color(0xFF42A5F5)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(color: Colors.black.withOpacity(0.4), width: 1.5),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(color: Colors.black.withOpacity(0.4), width: 1.5),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(color: Color(0xFF42A5F5), width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                            dropdownColor: Colors.white,
                            style: GoogleFonts.cairo(
                              color: Color(0xFF212121),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                            items: [
                              DropdownMenuItem<Map<String, dynamic>>(
                                value: null,
                                child: Directionality(
                                  textDirection: TextDirection.rtl,
                                  child: Text(
                                    defaultDistrict,
                                    style: GoogleFonts.cairo(
                                      color: Color(0xFF212121),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              ...filteredAreas.map((area) => DropdownMenuItem(
                                value: area,
                                child: Directionality(
                                  textDirection: TextDirection.rtl,
                                  child: Text(
                                    area['name'],
                                    style: GoogleFonts.cairo(
                                      color: Color(0xFF212121),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              )),
                            ],
                            onChanged: (value) {
                              setStateDialog(() {
                                tempSelectedArea = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.grey[600],
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                ),
                                child: Text(
                                  'إلغاء',
                                  style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  onApply(
                                    cityName: tempSelectedProvince?['name'],
                                    districtName: tempSelectedArea?['name'],
                                    cityId: tempSelectedProvince?['id'],
                                    regionId: tempSelectedArea?['id'],
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF42A5F5),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  'تطبيق',
                                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static Future<void> fetchFilteredAds({
    required BuildContext context,
    required int currentPageAds,
    required int limitAds,
    required int? selectedCityId,
    required int? selectedRegionId,
    required Function(List<Map<String, dynamic>> ads, bool hasMoreAds) onResult,
    bool reset = false,
  }) async {
    try {
      final params = <String, String>{
        'page': currentPageAds.toString(),
        'limit': limitAds.toString(),
      };
      if (selectedCityId != null) params['cityId'] = selectedCityId.toString();
      if (selectedRegionId != null) params['regionId'] = selectedRegionId.toString();
      final uri = Uri.https('sahbo-app-api.onrender.com', '/api/ads/search', params);
      final response = await http.get(uri);
      debugPrint('Fetching filtered ads from: $uri');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> fetchedAds = decoded['ads'] ?? [];
        onResult(List<Map<String, dynamic>>.from(fetchedAds), fetchedAds.length >= limitAds);
      } else {
        onResult([], false);
      }
    } catch (e) {
      debugPrint('Exception fetching filtered ads: $e');
      onResult([], false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color secondaryColor = Color(0xFF42A5F5); // Light Blue
    const Color surfaceColor = Color(0xFFF5F5F5); // Light Gray
    const Color textColor = Color(0xFF212121); // Dark Black
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Material(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on, size: 22, color: secondaryColor),
                    const SizedBox(width: 8),
                    Text(
                      'بحث بالموقع',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  selectedCity == defaultCity
                      ? defaultCity
                      : '$selectedCity - $selectedDistrict',
                  style: GoogleFonts.cairo(fontSize: 12, color: textColor.withOpacity(0.7)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
