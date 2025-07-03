import 'package:flutter/material.dart';

class LocationSelectionScreen extends StatefulWidget {
  const LocationSelectionScreen({super.key});

  @override
  State<LocationSelectionScreen> createState() => _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen> {
  String? selectedProvince;

  final Map<String, List<String>> locations = {
    'كل المحافظات': ['كل المناطق'],
    'ادلب': ['معرة النعمان', 'جسر الشغور', 'سراقب', 'اريحا'],
    'دمشق': ['المزة', 'البرامكة', 'باب توما', 'المالكي'],
    'حلب': ['الجميلية', 'السكري', 'الشعار', 'حلب الجديدة'],
    'حمص': ['الوعر', 'باب عمرو', 'الخالدية', 'القصور'],
    'حماة': ['حي القصور', 'الحميدية', 'حي الحاضر', 'المرابط'],
    'الرقة': ['الدرعية', 'المشلب', 'الرميلة', 'حي الصناعة'],
    'السويداء': ['شهبا', 'صلخد', 'قنوات', 'الكفر'],
    'اللاذقية': ['مشروع الصليبة', 'جبلة', 'القرداحة', 'رأس شمرا'],
    'القنيطرة': ['خان أرنبة', 'البعث', 'جباتا الخشب', 'حضر'],
    'دير الزور': ['القصور', 'الجورة', 'الحويقة', 'العرضي'],
    'الحسكة': ['القامشلي', 'رأس العين', 'عامودا', 'تل تمر'],
    'درعا': ['نوى', 'طفس', 'الصنمين', 'ازرع'],
  };

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('اختيار الموقع'),
          centerTitle: true,
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _buildLocationList(),
      ),
    );
  }

  Widget _buildLocationList() {
    return selectedProvince == null ? _buildProvincesList() : _buildDistrictsList();
  }

  Widget _buildProvincesList() {
    return ListView.builder(
      itemCount: locations.keys.length,
      itemBuilder: (context, index) {
        final province = locations.keys.elementAt(index);
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            title: Text(
              province,
              style: const TextStyle(fontSize: 16),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              if (province == 'كل المحافظات') {
                Navigator.pop(context, {
                  'province': 'كل المحافظات',
                  'district': 'كل المناطق',
                });
              } else {
                setState(() => selectedProvince = province);
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildDistrictsList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => selectedProvince = null),
              ),
              const SizedBox(width: 8),
              Text(
                selectedProvince!,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: locations[selectedProvince]!.length,
            itemBuilder: (context, index) {
              final district = locations[selectedProvince]![index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text(district),
                  onTap: () {
                    Navigator.pop(context, {
                      'province': selectedProvince,
                      'district': district,
                    });
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}