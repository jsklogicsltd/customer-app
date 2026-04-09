class UserAddress {
  final String id;
  final String label;
  final String address;
  bool isDefault;

  UserAddress({
    required this.id,
    required this.label,
    required this.address,
    required this.isDefault,
  });

  factory UserAddress.fromMap(Map<String, dynamic> map) {
    return UserAddress(
      id: map['id'],
      label: map['label'],
      address: map['address'],
      isDefault: map['isDefault'],
    );
  }
}

class AppUser {
  final String id;
  String name;
  final String phone;
  String email;
  String buyerType;
  String province;
  String city;
  String avatar;
  final bool verified;
  List<UserAddress> addresses;
  List<String> savedProducts;
  List<String> savedVendors;
  int totalOrders;
  int totalReviews;
  String language;
  String currency;
  bool notifications;
  String? fcmToken;
  bool profileSetupComplete;

  AppUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.buyerType,
    required this.province,
    required this.city,
    required this.avatar,
    required this.verified,
    required this.addresses,
    required this.savedProducts,
    required this.savedVendors,
    required this.totalOrders,
    required this.totalReviews,
    required this.language,
    required this.currency,
    required this.notifications,
    this.fcmToken,
    this.profileSetupComplete = false,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      buyerType: map['buyerType'] ?? 'individual',
      province: map['province'] ?? '',
      city: map['city'] ?? '',
      avatar: map['avatar'] ?? '',
      verified: map['verified'] ?? false,
      addresses: (map['addresses'] as List? ?? [])
          .map((a) => UserAddress.fromMap(a))
          .toList(),
      savedProducts: List<String>.from(map['savedProducts'] ?? []),
      savedVendors: List<String>.from(map['savedVendors'] ?? []),
      totalOrders: map['totalOrders'] ?? 0,
      totalReviews: map['totalReviews'] ?? 0,
      language: map['language'] ?? 'English',
      currency: map['currency'] ?? 'PKR',
      notifications: map['notifications'] ?? true,
      fcmToken: map['fcmToken'],
      profileSetupComplete: map['profileSetupComplete'] ?? false,
    );
  }
}
