import '../../models/user.dart';

final AppUser mockCurrentUser = AppUser.fromMap({
  'id': 'cust001',
  'name': 'Ahmed Khan',
  'phone': '+92 300 1234567',
  'email': 'ahmed.khan@gmail.com',
  'buyerType': 'individual',
  'province': 'Federal',
  'city': 'Islamabad',
  'avatar': 'https://i.pravatar.cc/150?img=33',
  'verified': true,
  'addresses': [
    {
      'id': 'addr001',
      'label': 'Home',
      'address': 'House 123, Street 5, G-10, Islamabad',
      'isDefault': true,
    },
    {
      'id': 'addr002',
      'label': 'Office',
      'address': 'Office 45, Plaza, Blue Area, Islamabad',
      'isDefault': false,
    },
  ],
  'savedProducts': ['p002', 'p005'],
  'savedVendors': ['v001', 'v002'],
  'totalOrders': 12,
  'totalReviews': 8,
  'language': 'en',
  'currency': 'PKR',
  'notifications': true,
});
