class Vendor {
  final String id;
  final String businessName;
  final String fullName;
  final String city;
  final String province;
  final String businessType;
  final String avatarUrl;
  final String coverPhotoUrl;
  final double averageRating;
  final int totalOrders;
  final bool isVerified;
  final String description;
  final String whatsappNumber;

  // UI Compatibility fields
  final String memberSince;
  final int responseRate;
  final List<String> specialties;
  final String capacity;
  final bool exportReady;
  final List<String> languages;

  Vendor({
    required this.id,
    required this.businessName,
    required this.fullName,
    required this.city,
    required this.province,
    required this.businessType,
    required this.avatarUrl,
    required this.coverPhotoUrl,
    required this.averageRating,
    required this.totalOrders,
    required this.isVerified,
    required this.description,
    required this.whatsappNumber,
    this.memberSince = 'Jan 2024',
    this.responseRate = 95,
    this.specialties = const [],
    this.capacity = 'High',
    this.exportReady = true,
    this.languages = const ['English', 'Urdu'],
  });

  String get name => businessName.isNotEmpty ? businessName : fullName;
  
  // Aliases for UI compatibility
  String get avatar => avatarUrl;
  bool get verified => isVerified;
  double get rating => averageRating;
  String get about => description;

  factory Vendor.fromMap(Map<String, dynamic> map, String id) {
    return Vendor(
      id: id,
      businessName: map['businessName'] ?? '',
      fullName: map['fullName'] ?? '',
      city: map['city'] ?? '',
      province: map['province'] ?? '',
      businessType: map['businessType'] ?? '',
      avatarUrl: map['avatarUrl'] ?? '',
      coverPhotoUrl: map['coverPhotoUrl'] ?? '',
      averageRating: (map['averageRating'] ?? 0).toDouble(),
      totalOrders: map['totalOrdersCompleted'] ?? 0,
      isVerified: map['status'] == 'verified',
      description: map['shortDescription'] ?? '',
      whatsappNumber: map['whatsappNumber'] ?? '',
      specialties: List<String>.from(map['specialties'] ?? []),
    );
  }
}
