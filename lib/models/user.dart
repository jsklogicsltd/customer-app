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
  String phone;
  String email;
  String buyerType;
  String province;
  String city;
  String profileImageUrl;
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
  String role;

  AppUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.buyerType,
    required this.province,
    required this.city,
    required this.profileImageUrl,
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
    this.role = 'customer',
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
      profileImageUrl: map['profileImageUrl'] ?? map['avatar'] ?? '',
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
      role: map['role'] ?? 'customer',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'buyerType': buyerType,
      'province': province,
      'city': city,
      'profileImageUrl': profileImageUrl,
      'verified': verified,
      'addresses': addresses.map((a) => {
        'id': a.id,
        'label': a.label,
        'address': a.address,
        'isDefault': a.isDefault,
      }).toList(),
      'savedProducts': savedProducts,
      'savedVendors': savedVendors,
      'totalOrders': totalOrders,
      'totalReviews': totalReviews,
      'language': language,
      'currency': currency,
      'notifications': notifications,
      'fcmToken': fcmToken,
      'profileSetupComplete': profileSetupComplete,
      'role': role,
    };
  }
}
