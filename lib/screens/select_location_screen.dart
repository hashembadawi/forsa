import 'package:flutter/material.dart';

class LocationSelectionScreen extends StatefulWidget {
  @override
  _LocationSelectionScreenState createState() => _LocationSelectionScreenState();
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
          title: Text('اختيار الموقع'),
          backgroundColor: Colors.deepPurpleAccent,
        ),
        body: selectedProvince == null
            ? ListView(
          children: locations.keys.map((province) {
            return ListTile(
              title: Text(province),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () {
                if (province == 'كل المحافظات') {
                  Navigator.pop(context, {
                    'province': 'كل المحافظات',
                    'district': 'كل المناطق',
                  });
                } else {
                  setState(() {
                    selectedProvince = province;
                  });
                }
              },
            );
          }).toList(),
        )
            : ListView(
          children: locations[selectedProvince!]!.map((district) {
            return ListTile(
              title: Text(district),
              onTap: () {
                Navigator.pop(context, {
                  'province': selectedProvince,
                  'district': district,
                });
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
