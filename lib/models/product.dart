class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String mainImageUrl;
  final List<String> images;
  final String category;
  final String productType;
  final String material;
  final List<String> availableSizes;
  final List<String> colors; // stored as hex/int strings
  final String careInstructions;
  final String packagingType;
  final List<String> searchTags;
  final String stockStatus;
  final bool isInStock;
  final String vendorId;
  final String vendorName;
  final String status;
  final String videoUrl;

  // UI Compatibility fields (inherited or added for backward compatibility)
  final double rating;
  final int reviewCount;
  final List<String> features;
  final String subCategory;
  final String leadTime;
  final int moq;
  final bool vendorVerified;
  final String deliveryTo;
  final bool isExportCompliant;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.mainImageUrl,
    required this.images,
    required this.category,
    required this.productType,
    required this.material,
    required this.availableSizes,
    required this.colors,
    required this.careInstructions,
    required this.packagingType,
    required this.searchTags,
    required this.stockStatus,
    required this.isInStock,
    required this.vendorId,
    required this.vendorName,
    required this.status,
    required this.videoUrl,
    this.rating = 4.5,
    this.reviewCount = 20,
    this.features = const [],
    this.subCategory = '',
    this.leadTime = '7 days',
    this.moq = 1,
    this.vendorVerified = false,
    this.deliveryTo = 'All Pakistan',
    this.isExportCompliant = false,
  });

  // Aliases for UI compatibility
  String get title => name;
  String get productName => name;
  double get unitPrice => price;
  double get pricePerUnit => price;
  String get mainPhotoUrl => mainImageUrl;
  int get leadTimeDays => int.tryParse(leadTime.replaceAll(RegExp(r'[^0-9]'), '')) ?? 7;
  String get stock => isInStock ? 'In Stock' : 'Out of Stock';

  factory Product.fromMap(Map<String, dynamic> data, String id) {
    String safeString(dynamic value, [String defaultValue = '']) {
      if (value == null) return defaultValue;
      if (value is String) return value;
      if (value is List) return value.join(', ');
      return value.toString();
    }

    return Product(
      id: id,
      name: safeString(data['name'] ?? data['productName']),
      description: safeString(data['description'] ?? data['shortDescription'] ?? data['fullDescription']),
      price: (data['price'] ?? data['unitPrice'] ?? data['basePrice'] ?? data['pricePerUnit'] ?? 0).toDouble(),
      mainImageUrl: safeString(data['mainImageUrl'] ?? data['imageUrl'] ?? data['mainPhotoUrl'] ?? data['image']),
      images: List<String>.from(data['images'] ?? data['gallery'] ?? data['additionalImages'] ?? []),
      category: safeString(data['category']),
      productType: safeString(data['productType'] ?? data['type']),
      material: safeString(data['material']),
      availableSizes: List<String>.from(data['availableSizes'] ?? []),
      colors: List<String>.from(data['colors'] ?? []),
      careInstructions: safeString(data['careInstructions']),
      packagingType: safeString(data['packagingType']),
      searchTags: List<String>.from(data['searchTags'] ?? data['tags'] ?? []),
      stockStatus: safeString(data['stockStatus'], 'in_stock'),
      isInStock: data['isInStock'] ?? (data['stockStatus'] == 'in_stock' || data['stockStatus'] == 'Available'),
      vendorId: safeString(data['vendorId']),
      vendorName: safeString(data['vendorName']),
      status: safeString(data['status'], 'active'),
      videoUrl: safeString(data['videoUrl']),
      rating: (data['rating'] ?? 4.5).toDouble(),
      reviewCount: (data['reviewCount'] ?? 20).toInt(),
      features: List<String>.from(data['features'] ?? []),
      subCategory: safeString(data['subCategory']),
      leadTime: safeString(data['leadTime'], '7 days'),
      moq: (data['moq'] ?? 1).toInt(),
      vendorVerified: data['vendorVerified'] ?? false,
      deliveryTo: safeString(data['deliveryTo'], 'All Pakistan'),
      isExportCompliant: data['isExportCompliant'] ?? false,
    );
  }
}

