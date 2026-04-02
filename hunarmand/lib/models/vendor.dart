class AppVendor {
  final String id;
  final String name;
  final String avatar;
  final String coverPhoto;
  final String city;
  final String province;
  final bool verified;
  final double rating;
  final int totalOrders;
  final int responseRate;
  final String memberSince;
  final String about;
  final List<String> specialties;
  final String businessType;
  final String capacity;
  final bool exportReady;
  final List<String> languages;
  final String phone;
  final String whatsapp;

  const AppVendor({
    required this.id,
    required this.name,
    required this.avatar,
    required this.coverPhoto,
    required this.city,
    required this.province,
    required this.verified,
    required this.rating,
    required this.totalOrders,
    required this.responseRate,
    required this.memberSince,
    required this.about,
    required this.specialties,
    required this.businessType,
    required this.capacity,
    required this.exportReady,
    required this.languages,
    required this.phone,
    required this.whatsapp,
  });

  factory AppVendor.fromMap(Map<String, dynamic> map) {
    return AppVendor(
      id: map['id'],
      name: map['name'],
      avatar: map['avatar'],
      coverPhoto: map['coverPhoto'],
      city: map['city'],
      province: map['province'],
      verified: map['verified'],
      rating: (map['rating'] as num).toDouble(),
      totalOrders: map['totalOrders'],
      responseRate: map['responseRate'],
      memberSince: map['memberSince'],
      about: map['about'],
      specialties: List<String>.from(map['specialties']),
      businessType: map['businessType'],
      capacity: map['capacity'],
      exportReady: map['exportReady'],
      languages: List<String>.from(map['languages']),
      phone: map['phone'],
      whatsapp: map['whatsapp'],
    );
  }
}
