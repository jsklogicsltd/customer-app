class Product {
  final String id;
  final String productName;
  final String category;
  final String subCategory;
  final double unitPrice;
  final int moq;
  final String mainPhotoUrl;
  final String vendorId;
  final String status;
  final String description;
  final String leadTime;
  final String stockStatus;

  // UI Compatibility fields
  final double rating;
  final int reviewCount;
  final List<String> tags;
  final List<String> features;
  final double? bulkPrice;
  final int? bulkMinQty;
  final bool vendorVerified;

  Product({
    required this.id,
    required this.productName,
    required this.category,
    required this.subCategory,
    required this.unitPrice,
    required this.moq,
    required this.mainPhotoUrl,
    required this.vendorId,
    required this.status,
    required this.description,
    required this.leadTime,
    required this.stockStatus,
    this.rating = 4.5,
    this.reviewCount = 20,
    this.tags = const [],
    this.features = const [],
    this.bulkPrice,
    this.bulkMinQty,
    this.vendorVerified = true,
  });

  // Aliases for UI compatibility
  String get title => productName;
  double get pricePerUnit => unitPrice;
  List<String> get images => [mainPhotoUrl];
  int get leadTimeDays => int.tryParse(leadTime.replaceAll(RegExp(r'[^0-9]'), '')) ?? 7;
  String get stock => stockStatus;

  factory Product.fromMap(Map<String, dynamic> map, String id) {
    // Robust Price Parsing
    final dynamic rawPrice = map['unitPrice'] ?? map['price'] ?? map['productPrice'] ?? 0;
    double parsedPrice = 0.0;
    if (rawPrice is num) {
      parsedPrice = rawPrice.toDouble();
    } else if (rawPrice is String) {
      parsedPrice = double.tryParse(rawPrice.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    }

    return Product(
      id: id,
      productName: map['productName'] ?? '',
      category: map['category'] ?? '',
      subCategory: map['subCategory'] ?? '',
      unitPrice: parsedPrice,
      moq: map['moq'] ?? 1,
      mainPhotoUrl: map['mainPhotoUrl'] ?? '',
      vendorId: map['vendorId'] ?? '',
      status: map['status'] ?? '',
      description: map['shortDescription'] ?? map['fullDescription'] ?? '',
      leadTime: map['leadTime'] ?? '',
      stockStatus: map['stockStatus'] ?? '',
      tags: List<String>.from(map['tags'] ?? []),
      features: List<String>.from(map['features'] ?? []),
    );
  }
}
