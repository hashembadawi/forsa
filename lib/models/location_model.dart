// LocationModel class moved from home_screen.dart
class LocationModel {
  final int? id;
  final String? name;
  final int? provinceId;

  LocationModel({this.id, this.name, this.provinceId});

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id'],
      name: json['name'],
      provinceId: json['ProvinceId'],
    );
  }
}
