// AdModel class moved from home_screen.dart
class AdModel {
  final String? id;
  final String? adTitle;
  final String? description;
  final String? price;
  final String? currencyName;
  final String? categoryName;
  final String? subCategoryName;
  final String? cityName;
  final String? regionName;
  final String? userName;
  final String? userPhone;
  final String? userId;
  final String? categoryId;
  final String? subCategoryId;
  final String? createDate;
  final List<String>? images;
  final String? thumbnail;
  final Map<String, dynamic>? location;
  final bool? isSpecial;
  final bool? forSale;
  final bool? deliveryService;

  AdModel({
    this.id,
    this.adTitle,
    this.description,
    this.price,
    this.currencyName,
    this.categoryName,
    this.subCategoryName,
    this.cityName,
    this.regionName,
    this.userName,
    this.userPhone,
    this.userId,
    this.categoryId,
    this.subCategoryId,
    this.createDate,
    this.images,
    this.thumbnail,
    this.location,
    this.isSpecial,
    this.forSale,
    this.deliveryService,
  });

  factory AdModel.fromJson(Map<String, dynamic> json) {
    return AdModel(
      id: json['_id'],
      adTitle: json['adTitle'],
      description: json['description'],
      price: json['price']?.toString(),
      currencyName: json['currencyName'],
      categoryName: json['categoryName'],
      subCategoryName: json['subCategoryName'],
      cityName: json['cityName'],
      regionName: json['regionName'],
      userName: json['userName'],
      userPhone: json['userPhone'],
      userId: json['userId'],
      categoryId: json['categoryId']?.toString(),
      subCategoryId: json['subCategoryId']?.toString(),
      createDate: json['createDate'],
      images: json['images'] is List ? List<String>.from(json['images']) : null,
      thumbnail: json['thumbnail'],
      location: json['location'] is Map<String, dynamic> ? json['location'] : null,
      isSpecial: json['isSpecial'] ?? false,
      forSale: json['forSale'] ?? false,
      deliveryService: json['deliveryService'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'adTitle': adTitle,
      'description': description,
      'price': price,
      'currencyName': currencyName,
      'categoryName': categoryName,
      'subCategoryName': subCategoryName,
      'cityName': cityName,
      'regionName': regionName,
      'userName': userName,
      'userPhone': userPhone,
      'userId': userId,
      'categoryId': categoryId,
      'subCategoryId': subCategoryId,
      'createDate': createDate,
      'images': images,
      'thumbnail': thumbnail,
      'location': location,
      'isSpecial': isSpecial,
      'forSale': forSale,
      'deliveryService': deliveryService,
    };
  }
}
