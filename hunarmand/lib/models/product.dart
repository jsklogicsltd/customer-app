class AppProduct {
  final String id;
  final String vendorId;
  final String vendorName;
  final bool vendorVerified;
  final String title;
  final String category;
  final String subCategory;
  final List<String> images;
  final int pricePerUnit;
  final int? bulkPrice;
  final int? bulkMinQty;
  final String currency;
  final int moq;
  final String leadTimeDays;
  final String stock;
  final double rating;
  final int reviewCount;
  final List<String> tags;
  final String description;
  final List<String> features;
  final String status;
  bool saved;

  AppProduct({
    required this.id,
    required this.vendorId,
    required this.vendorName,
    required this.vendorVerified,
    required this.title,
    required this.category,
    required this.subCategory,
    required this.images,
    required this.pricePerUnit,
    this.bulkPrice,
    this.bulkMinQty,
    required this.currency,
    required this.moq,
    required this.leadTimeDays,
    required this.stock,
    required this.rating,
    required this.reviewCount,
    required this.tags,
    required this.description,
    required this.features,
    required this.status,
    this.saved = false,
  });

  factory AppProduct.fromMap(Map<String, dynamic> map) {
    return AppProduct(
      id: map['id'],
      vendorId: map['vendorId'],
      vendorName: map['vendorName'],
      vendorVerified: map['vendorVerified'],
      title: map['title'],
      category: map['category'],
      subCategory: map['subCategory'],
      images: List<String>.from(map['images']),
      pricePerUnit: map['pricePerUnit'],
      bulkPrice: map['bulkPrice'],
      bulkMinQty: map['bulkMinQty'],
      currency: map['currency'],
      moq: map['moq'],
      leadTimeDays: map['leadTimeDays'],
      stock: map['stock'],
      rating: (map['rating'] as num).toDouble(),
      reviewCount: map['reviewCount'],
      tags: List<String>.from(map['tags']),
      description: map['description'],
      features: List<String>.from(map['features']),
      status: map['status'],
      saved: map['saved'] ?? false,
    );
  }

  AppProduct copyWith({bool? saved}) {
    return AppProduct(
      id: id,
      vendorId: vendorId,
      vendorName: vendorName,
      vendorVerified: vendorVerified,
      title: title,
      category: category,
      subCategory: subCategory,
      images: images,
      pricePerUnit: pricePerUnit,
      bulkPrice: bulkPrice,
      bulkMinQty: bulkMinQty,
      currency: currency,
      moq: moq,
      leadTimeDays: leadTimeDays,
      stock: stock,
      rating: rating,
      reviewCount: reviewCount,
      tags: tags,
      description: description,
      features: features,
      status: status,
      saved: saved ?? this.saved,
    );
  }
}
